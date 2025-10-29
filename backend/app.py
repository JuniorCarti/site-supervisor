from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from config import Config
from datetime import datetime
from utils.ai_agents import sentinel_agent, quartermaster_agent, chancellor_agent, foreman_agent
from utils.notification import send_sms, send_email, notify_event

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize extensions
    CORS(app)
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    # models
    from models.project import Project 
    from models.supplier import Supplier
    from models.maintenance import MaintenanceRecord
    from models.finance import Invoice
    from models.user import User

    # ------------------------------
    # AUTH ROUTES (No Blueprint)
    # ------------------------------

    # --- Register ---
    @app.route("/api/auth/register", methods=["POST"])
    def register():
        data = request.get_json()
        name = data.get("name")
        email = data.get("email")
        password = data.get("password")
        role = data.get("role", "driver")

        if not all([name, email, password]):
            return jsonify({"error": "Missing fields"}), 400

        if User.query.filter_by(email=email).first():
            return jsonify({"error": "Email already registered"}), 400

        hashed_pw = generate_password_hash(password)
        new_user = User(name=name, email=email, password=hashed_pw, role=role)
        db.session.add(new_user)
        db.session.commit()

        return jsonify({"message": f"User {name} registered successfully"}), 201


    # --- Login ---
    @app.route("/api/auth/login", methods=["POST"])
    def login():
        data = request.get_json()
        email = data.get("email")
        password = data.get("password")

        user = User.query.filter_by(email=email).first()
        if not user or not check_password_hash(user.password, password):
            return jsonify({"error": "Invalid credentials"}), 401

        access_token = create_access_token(identity=user.id, additional_claims={"role": user.role})
        return jsonify({
            "token": access_token,
            "user": {"id": user.id, "name": user.name, "email": user.email, "role": user.role}
        }), 200


    # --- Profile (Protected) ---
    @app.route("/api/auth/profile", methods=["GET"])
    @jwt_required()
    def profile():
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        return jsonify({
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role
        }), 200
    
    # -----------------------------------------
    # MAINTENANCE ROUTES
    # -----------------------------------------

    @app.route("/api/maintenance", methods=["POST"])
    @jwt_required()
    def create_maintenance():
        data = request.get_json()
        vehicle_id = data.get("vehicle_id")
        description = data.get("description")
        severity = data.get("severity", "low")
        image_path = data.get("image_path")

        if not vehicle_id or not description:
            return jsonify({"error": "Missing required fields"}), 400

        record = MaintenanceRecord(
            vehicle_id=vehicle_id,
            description=description,
            severity=severity,
            image_path=image_path,
            status="pending",
            created_at=datetime.utcnow(),
        )
        db.session.add(record)
        db.session.commit()

        if severity.lower() == "critical":
            notify_admins(f"🚨 Critical maintenance reported for vehicle {vehicle_id}")

        if severity.lower() == "critical":
            notify_event(
                "email",
                "maintenance-team@example.com",
                "⚠️ Critical Maintenance Alert",
                f"Vehicle {vehicle_id} reported a CRITICAL issue: {description}"
            )

        return jsonify({"message": "Maintenance record created successfully"}), 201


    @app.route("/api/maintenance", methods=["GET"])
    @jwt_required()
    def get_maintenance():
        records = MaintenanceRecord.query.order_by(MaintenanceRecord.created_at.desc()).all()
        results = [
            {
                "id": r.id,
                "vehicle_id": r.vehicle_id,
                "description": r.description,
                "severity": r.severity,
                "status": r.status,
                "created_at": r.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            }
            for r in records
        ]
        return jsonify(results), 200


    @app.route("/api/maintenance/<int:id>", methods=["PATCH"])
    @jwt_required()
    def update_maintenance(id):
        record = MaintenanceRecord.query.get(id)
        if not record:
            return jsonify({"error": "Record not found"}), 404

        data = request.get_json()
        record.status = data.get("status", record.status)
        record.severity = data.get("severity", record.severity)
        db.session.commit()

        return jsonify({"message": "Record updated successfully"}), 200


    @app.route("/api/maintenance/<int:id>", methods=["DELETE"])
    @jwt_required()
    def delete_maintenance(id):
        record = MaintenanceRecord.query.get(id)
        if not record:
            return jsonify({"error": "Record not found"}), 404

        db.session.delete(record)
        db.session.commit()

        return jsonify({"message": "Record deleted successfully"}), 200
    

    # -----------------------------------------
    # SUPPLIER ROUTES
    # -----------------------------------------



    @app.route("/api/suppliers", methods=["POST"])
    @jwt_required()
    def create_supplier():
        data = request.get_json()
        name = data.get("name")
        contact = data.get("contact")

        if not name:
            return jsonify({"error": "Supplier name is required"}), 400

        supplier = Supplier(name=name, contact=contact)
        db.session.add(supplier)
        db.session.commit()

        return jsonify({"message": f"Supplier {name} added successfully"}), 201


    @app.route("/api/suppliers", methods=["GET"])
    @jwt_required()
    def get_suppliers():
        suppliers = Supplier.query.all()
        results = [
            {
                "id": s.id,
                "name": s.name,
                "contact": s.contact,
                "rating": s.rating,
                "last_bid_price": s.last_bid_price,
            }
            for s in suppliers
        ]
        return jsonify(results), 200


    @app.route("/api/suppliers/<int:id>", methods=["PATCH"])
    @jwt_required()
    def update_supplier(id):
        supplier = Supplier.query.get(id)
        if not supplier:
            return jsonify({"error": "Supplier not found"}), 404

        data = request.get_json()
        supplier.rating = data.get("rating", supplier.rating)
        supplier.last_bid_price = data.get("last_bid_price", supplier.last_bid_price)
        db.session.commit()

        return jsonify({"message": "Supplier updated successfully"}), 200


    @app.route("/api/suppliers/<int:id>", methods=["DELETE"])
    @jwt_required()
    def delete_supplier(id):
        supplier = Supplier.query.get(id)
        if not supplier:
            return jsonify({"error": "Supplier not found"}), 404

        db.session.delete(supplier)
        db.session.commit()

        return jsonify({"message": "Supplier deleted successfully"}), 200



    # -----------------------------------------
    # FINANCE ROUTES (INVOICES)
    # -----------------------------------------

   

    @app.route("/api/finance/invoices", methods=["POST"])
    @jwt_required()
    def create_invoice():
        data = request.get_json()
        supplier_id = data.get("supplier_id")
        amount = data.get("amount")

        if not supplier_id or not amount:
            return jsonify({"error": "Supplier ID and amount are required"}), 400

        invoice = Invoice(supplier_id=supplier_id, amount=amount, status="pending")
        db.session.add(invoice)
        db.session.commit()

        return jsonify({"message": "Invoice created successfully"}), 201


    @app.route("/api/finance/invoices", methods=["GET"])
    @jwt_required()
    def get_invoices():
        invoices = Invoice.query.all()
        results = [
            {
                "id": i.id,
                "supplier_id": i.supplier_id,
                "amount": i.amount,
                "status": i.status,
                "created_at": i.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            }
            for i in invoices
        ]
        return jsonify(results), 200


    @app.route("/api/finance/invoices/<int:id>", methods=["PATCH"])
    @jwt_required()
    def update_invoice(id):
        invoice = Invoice.query.get(id)
        if not invoice:
            return jsonify({"error": "Invoice not found"}), 404

        data = request.get_json()
        invoice.status = data.get("status", invoice.status)
        invoice.approval_level = data.get("approval_level", invoice.approval_level)
        db.session.commit()

        if invoice.status.lower() == "approved":
            send_email("finance@sitesupervisor.com", "Invoice Approved", f"Invoice #{invoice.id} approved.")
        elif invoice.status.lower() == "rejected":
            send_email("finance@sitesupervisor.com", "Invoice Rejected", f"Invoice #{invoice.id} was rejected.")

        if invoice.status == "approved":
            notify_event(
                "email",
                "finance@example.com",
                "✅ Invoice Approved",
                f"Invoice #{invoice.id} for supplier {invoice.supplier_id} has been approved."
            )
        elif invoice.status == "rejected":
            notify_event(
                "email",
                "finance@example.com",
                "❌ Invoice Rejected",
                f"Invoice #{invoice.id} has been rejected."
            )

        return jsonify({"message": "Invoice updated successfully"}), 200    


    @app.route("/api/finance/invoices/<int:id>", methods=["DELETE"])
    @jwt_required()
    def delete_invoice(id):
        invoice = Invoice.query.get(id)
        if not invoice:
            return jsonify({"error": "Invoice not found"}), 404

        db.session.delete(invoice)
        db.session.commit()

        return jsonify({"message": "Invoice deleted successfully"}), 200
    

    # -----------------------------------------
    # PROJECT ROUTES
    # -----------------------------------------

   

    @app.route("/api/projects", methods=["POST"])
    @jwt_required()
    def create_project():
        data = request.get_json()
        name = data.get("name")
        description = data.get("description")

        if not name:
            return jsonify({"error": "Project name is required"}), 400

        project = Project(name=name, description=description, status="active")
        db.session.add(project)
        db.session.commit()

        return jsonify({"message": f"Project {name} created successfully"}), 201


    @app.route("/api/projects", methods=["GET"])
    @jwt_required()
    def get_projects():
        projects = Project.query.all()
        results = [
            {
                "id": p.id,
                "name": p.name,
                "description": p.description,
                "status": p.status,
                "completion_forecast": p.completion_forecast,
            }
            for p in projects
        ]
        return jsonify(results), 200


    @app.route("/api/projects/<int:id>", methods=["PATCH"])
    @jwt_required()
    def update_project(id):
        project = Project.query.get(id)
        if not project:
            return jsonify({"error": "Project not found"}), 404

        data = request.get_json()
        project.status = data.get("status", project.status)
        project.completion_forecast = data.get("completion_forecast", project.completion_forecast)
        db.session.commit()

        if project.status.lower() == "delayed":
            notify_admins(f"⚠️ Project '{project.name}' has been delayed.")
        
        if project.status.lower() == "delayed":
            notify_event(
                "sms",
                "+254700000000",
                None,
                f"🚧 Project '{project.name}' is delayed. Please review timeline adjustments."
            )


        return jsonify({"message": "Project updated successfully"}), 200


    @app.route("/api/projects/<int:id>", methods=["DELETE"])
    @jwt_required()
    def delete_project(id):
        project = Project.query.get(id)
        if not project:
            return jsonify({"error": "Project not found"}), 404

        db.session.delete(project)
        db.session.commit()

        return jsonify({"message": "Project deleted successfully"}), 200
    
    # -----------------------------------------
    # AI AGENT SIMULATION ROUTES
    # -----------------------------------------


    # 🔧 1. Sentinel Agent (Predictive Maintenance)
    @app.route("/api/ai/sentinel", methods=["POST"])
    @jwt_required()
    def simulate_sentinel():
        sensor_data = request.get_json()
        result = sentinel_agent(sensor_data)
        return jsonify(result), 200


    # 🔧 2. Quartermaster Agent (Supplier Selection)
    @app.route("/api/ai/quartermaster", methods=["GET"])
    @jwt_required()
    def simulate_quartermaster():
        suppliers = Supplier.query.all()
        suppliers_data = [
            {"name": s.name, "rating": s.rating, "last_bid_price": s.last_bid_price}
            for s in suppliers
        ]
        result = quartermaster_agent(suppliers_data)
        return jsonify(result), 200


    # 🔧 3. Chancellor Agent (Finance Overview)
    @app.route("/api/ai/chancellor", methods=["GET"])
    @jwt_required()
    def simulate_chancellor():
        invoices = Invoice.query.all()
        invoices_data = [
            {"amount": i.amount, "status": i.status} for i in invoices
        ]
        result = chancellor_agent(invoices_data)
        return jsonify(result), 200


    # 🔧 4. Foreman Agent (Project Forecast)
    @app.route("/api/ai/foreman", methods=["GET"])
    @jwt_required()
    def simulate_foreman():
        projects = Project.query.all()
        projects_data = [
            {"name": p.name, "status": p.status} for p in projects
        ]
        result = foreman_agent(projects_data)
        return jsonify(result), 200

    @app.route("/api/notify/test", methods=["POST"])
    def test_notify():
        data = request.get_json()
        channel = data.get("channel", "email")
        recipient = data.get("recipient")
        subject = data.get("subject", "Test Notification")
        message = data.get("message", "This is a live notification test.")
        result = notify_event(channel, recipient, subject, message)
        return jsonify(result), 200




    # ------------------------------
    # ROOT TEST ROUTE
    # ------------------------------
    @app.route("/")
    def home():
        return {"message": "SiteSupervisor Backend API running 🚀"}

    return app




app = create_app()

if __name__ == "__main__":
    app.run(debug=True)
