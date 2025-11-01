from app import db
from datetime import datetime

class Invoice(db.Model):
    __tablename__ = "invoices"

    id = db.Column(db.Integer, primary_key=True)
    supplier_id = db.Column(db.Integer, db.ForeignKey("suppliers.id"))
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(50), default="pending")  # pending, approved, rejected
    approval_level = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    supplier = db.relationship("Supplier", back_populates="invoices")
    def __repr__(self):
        return f"<Invoice {self.id} - {self.amount} - {self.status}>"

    def to_dict(self):
        return {
            "id": self.id,
            "supplier_id": self.supplier_id,
            "amount": self.amount,
            "status": self.status,
            "approval_level": self.approval_level,
            "created_at": self.created_at.isoformat()
        }
