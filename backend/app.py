from flask import Flask, request, jsonify
from functools import wraps
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS,cross_origin
from flask_jwt_extended import JWTManager, create_access_token,get_jwt_identity,verify_jwt_in_request, get_jwt
from werkzeug.security import generate_password_hash, check_password_hash
from config import Config
from datetime import datetime
from utils.ai_agents import sentinel_agent, quartermaster_agent, chancellor_agent, foreman_agent
from utils.notification import notify_event
from utils.automation import trigger_workflow
from utils.analytics import get_dashboard_stats, get_trend_data, generate_analytics_insight


# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()


# ----------------------------------------------------------
# 🔐 ROLE-BASED ACCESS DECORATOR
# ----------------------------------------------------------
def role_required(*roles):
    """
    Restrict access to users with certain roles.
    Example:
        #@jwt_required()
        @role_required("admin", "manager")
        def protected(): ...
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            claims = get_jwt()
            user_role = claims.get("role")

            if user_role not in roles:
                return jsonify({
                    "error": "Forbidden: insufficient permissions",
                    "required_roles": roles,
                    "user_role": user_role
                }), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False  # ✅ Performance improvement

    # Initialize extensions
    CORS(app, 
        resources={
            r"/api/*": {
                "origins": ["*"],
                "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
                "allow_headers": ["Content-Type", "Authorization", "Accept"]
            }
        },
        supports_credentials=True)
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    # Import models
    from models.project import Project 
    from models.supplier import Supplier
    from models.maintenance import MaintenanceRecord
    from models.finance import Invoice
    from models.user import User, UserRole



# ------------------------------
# AUTH ROUTES
# ------------------------------

    @app.route("/api/auth/register", methods=["POST"])
    
    def register():
        data = request.get_json()
        name = data.get("name")
        email = data.get("email", "").lower()
        password = data.get("password")
        role = data.get("role", "driver").lower()

        # ✅ Validate role
        if role not in [r.value for r in UserRole]:
            return jsonify({"error": "Invalid role"}), 400

        if not all([name, email, password]):
            return jsonify({"error": "Missing fields"}), 400

        if User.query.filter_by(email=email).first():
            return jsonify({"error": "Email already registered"}), 400

        hashed_pw = generate_password_hash(password)
        new_user = User(
            name=name,
            email=email,
            password=hashed_pw,
            role=UserRole(role)  # ✅ wrap as Enum
        )

        try:
            db.session.add(new_user)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": f"User {name} registered successfully"}), 201


    @app.route("/api/auth/login", methods=["POST"])
    def login():
        data = request.get_json()
        email = data.get("email", "").lower()
        password = data.get("password")

        user = User.query.filter_by(email=email).first()
        if not user or not check_password_hash(user.password, password):
            return jsonify({"error": "Invalid credentials"}), 401

        # ✅ Use user.role.value for JWT since Enums aren’t JSON serializable
        access_token = create_access_token(
            identity=str(user.id),
            additional_claims={"role": user.role.value}
        )

        return jsonify({
            "token": access_token,
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "role": user.role.value  # ✅ convert Enum → string
            }
        }), 200


    @app.route("/api/auth/profile", methods=["GET"])
    #@jwt_required()
    def profile():
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        return jsonify({
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role.value  # ✅ convert Enum → string
        }), 200


    # -----------------------------------------
    # MAINTENANCE ROUTES
    # -----------------------------------------
    @app.route("/api/maintenance", methods=["POST"])
    #@jwt_required()
    @cross_origin()
    # @role_required("driver", "manager", "admin")
    
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

        try:
            db.session.add(record)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        if severity and severity.lower() == "critical":
            trigger_workflow(
                "critical_maintenance_reported",
                {"vehicle_id": vehicle_id, "description": description, "severity": severity}
            )
            notify_event(
                "email",
                "maintenance-team@example.com",
                "⚠️ Critical Maintenance Alert",
                f"Vehicle {vehicle_id} reported a CRITICAL issue: {description}"
            )

        return jsonify({"message": "Maintenance record created successfully"}), 201


    @app.route("/api/maintenance", methods=["GET"])
    #@jwt_required()
    @cross_origin()
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
    #@jwt_required()
    @cross_origin()
    # @role_required("manager", "admin")
    def update_maintenance(id):
        record = MaintenanceRecord.query.get(id)
        if not record:
            return jsonify({"error": "Record not found"}), 404

        data = request.get_json()
        record.status = data.get("status", record.status)
        record.severity = data.get("severity", record.severity)

        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Record updated successfully"}), 200


    @app.route("/api/maintenance/<int:id>", methods=["DELETE"])
    #@jwt_required()
    @cross_origin()
    def delete_maintenance(id):
        record = MaintenanceRecord.query.get(id)
        if not record:
            return jsonify({"error": "Record not found"}), 404

        try:
            db.session.delete(record)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Record deleted successfully"}), 200

    # -----------------------------------------
    # SUPPLIER ROUTES
    # -----------------------------------------
    @app.route("/api/suppliers", methods=["POST"])
    
    def create_supplier():
        data = request.get_json()
        name = data.get("name")
        contact = data.get("contact")

        if not name:
            return jsonify({"error": "Supplier name is required"}), 400

        supplier = Supplier(name=name, contact=contact)
        try:
            db.session.add(supplier)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": f"Supplier {name} added successfully"}), 201


    @app.route("/api/suppliers", methods=["GET"])
    
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
    
    def update_supplier(id):
        supplier = Supplier.query.get(id)
        if not supplier:
            return jsonify({"error": "Supplier not found"}), 404

        data = request.get_json()
        supplier.rating = data.get("rating", supplier.rating)
        supplier.last_bid_price = data.get("last_bid_price", supplier.last_bid_price)

        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Supplier updated successfully"}), 200


    @app.route("/api/suppliers/<int:id>", methods=["DELETE"])
    
    def delete_supplier(id):
        supplier = Supplier.query.get(id)
        if not supplier:
            return jsonify({"error": "Supplier not found"}), 404

        try:
            db.session.delete(supplier)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Supplier deleted successfully"}), 200

    # -----------------------------------------
    # FINANCE ROUTES (INVOICES)
    # -----------------------------------------
    @app.route("/api/finance/invoices", methods=["POST"])
    
    # @role_required("manager", "admin")
    def create_invoice():
        data = request.get_json(force=True)
        supplier_id = data.get("supplier_id")
        amount = data.get("amount")

        if not supplier_id or not amount:
            return jsonify({"error": "Supplier ID and amount are required"}), 400

        invoice = Invoice(supplier_id=supplier_id, amount=amount, status="pending")

        try:
            db.session.add(invoice)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Invoice created successfully"}), 201


    @app.route("/api/finance/invoices", methods=["GET"])
    
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
    
    def update_invoice(id):
        invoice = Invoice.query.get(id)
        if not invoice:
            return jsonify({"error": "Invoice not found"}), 404

        data = request.get_json()
        invoice.status = data.get("status", invoice.status)
        invoice.approval_level = data.get("approval_level", invoice.approval_level)

        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        trigger_workflow(
            "invoice_approval",
            {
                "invoice_id": invoice.id,
                "supplier_id": invoice.supplier_id,
                "amount": invoice.amount,
                "status": invoice.status,
            }
        )

        # Send notifications based on status
        if invoice.status and invoice.status.lower() == "approved":
            notify_event(
                "email",
                "finance@example.com",
                "✅ Invoice Approved",
                f"Invoice #{invoice.id} for supplier {invoice.supplier_id} has been approved."
            )
        elif invoice.status and invoice.status.lower() == "rejected":
            notify_event(
                "email",
                "finance@example.com",
                "❌ Invoice Rejected",
                f"Invoice #{invoice.id} has been rejected."
            )

        return jsonify({"message": "Invoice updated successfully"}), 200


    @app.route("/api/finance/invoices/<int:id>", methods=["DELETE"])

    def delete_invoice(id):
        invoice = Invoice.query.get(id)
        if not invoice:
            return jsonify({"error": "Invoice not found"}), 404

        try:
            db.session.delete(invoice)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Invoice deleted successfully"}), 200

    # -----------------------------------------
    # PROJECT ROUTES
    # -----------------------------------------
    @app.route("/api/projects", methods=["POST"])
    #@jwt_required()
    # @role_required("manager", "admin")
    def create_project():
        data = request.get_json()
        name = data.get("name")
        description = data.get("description")

        if not name:
            return jsonify({"error": "Project name is required"}), 400

        project = Project(name=name, description=description, status="active")

        try:
            db.session.add(project)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        trigger_workflow(
            "new_project_created",
            {
                "project_id": project.id,
                "project_name": project.name,
                "status": project.status,
                "description": project.description,
            }
        )

        return jsonify({"message": f"Project {name} created successfully"}), 201


    @app.route("/api/projects", methods=["GET"])
    #@jwt_required()
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
    #@jwt_required()
    def update_project(id):
        project = Project.query.get(id)
        if not project:
            return jsonify({"error": "Project not found"}), 404

        data = request.get_json()

        # ✅ Update all editable fields
        project.name = data.get("name", project.name)
        project.description = data.get("description", project.description)
        project.status = data.get("status", project.status)
        project.completion_forecast = data.get("completion_forecast", project.completion_forecast)

        try:
            db.session.commit()
            return jsonify({"message": "Project updated successfully"}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500


    @app.route("/api/projects/<int:id>", methods=["DELETE"])
    #@jwt_required()
    def delete_project(id):
        project = Project.query.get(id)
        if not project:
            return jsonify({"error": "Project not found"}), 404

        try:
            db.session.delete(project)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": str(e)}), 500

        return jsonify({"message": "Project deleted successfully"}), 200

    # -----------------------------------------
    # AI AGENT SIMULATION ROUTES
    # -----------------------------------------
    @app.route("/api/ai/sentinel", methods=["POST"])
    #@jwt_required()
    def simulate_sentinel():
        sensor_data = request.get_json()
        result = sentinel_agent(sensor_data)
        return jsonify(result), 200


    @app.route("/api/ai/quartermaster", methods=["GET"])
    #@jwt_required()
    def simulate_quartermaster():
        suppliers = Supplier.query.all()
        suppliers_data = [
            {"name": s.name, "rating": s.rating, "last_bid_price": s.last_bid_price}
            for s in suppliers
        ]
        result = quartermaster_agent(suppliers_data)
        return jsonify(result), 200


    @app.route("/api/ai/chancellor", methods=["GET"])
    #@jwt_required()
    def simulate_chancellor():
        invoices = Invoice.query.all()
        invoices_data = [{"amount": i.amount, "status": i.status} for i in invoices]
        result = chancellor_agent(invoices_data)
        return jsonify(result), 200


    @app.route("/api/ai/foreman", methods=["GET"])
    #@jwt_required()
    def simulate_foreman():
        projects = Project.query.all()
        projects_data = [{"name": p.name, "status": p.status} for p in projects]
        result = foreman_agent(projects_data)
        return jsonify(result), 200

    # -----------------------------------------
    # TEST ROUTES
    # -----------------------------------------
    @app.route("/api/notify/test", methods=["POST"])
    def test_notify():
        data = request.get_json()
        channel = data.get("channel", "email")
        recipient = data.get("recipient")
        subject = data.get("subject", "Test Notification")
        message = data.get("message", "This is a live notification test.")
        result = notify_event(channel, recipient, subject, message)
        return jsonify(result), 200

    @app.route("/api/automation/test", methods=["POST"])
    def test_automation():
        data = request.get_json()
        event_name = data.get("event", "test_event")
        payload = data.get("payload", {"test": "ok"})
        result = trigger_workflow(event_name, payload)
        return jsonify(result), 200
    
    
    # -----------------------------------------
    # ADVANCED ANALYTICS ROUTE
    # -----------------------------------------
    @app.route("/api/analytics/overview", methods=["GET"])
    def get_analytics_overview():
        try:
            total_projects = Project.query.count()
            total_maintenance = MaintenanceRecord.query.count()
            total_suppliers = Supplier.query.count()
            total_invoices = Invoice.query.count()

            return jsonify({
                "total_projects": total_projects,
                "total_maintenance": total_maintenance,
                "total_suppliers": total_suppliers,
                "total_invoices": total_invoices
            }), 200

        except Exception as e:
            print("Analytics error:", e)
            return jsonify({"error": str(e)}), 500

            

    # ------------------------------
    # ROOT TEST ROUTE
    # ------------------------------
    @app.route("/")
    def home():
        return {"message": "SiteSupervisor Backend API running 🚀", "version": "1.0.0"}

    return app


app = create_app()

if __name__ == "__main__":
    app.run(debug=True)
