from app import db
from datetime import datetime


class MaintenanceRecord(db.Model):
    __tablename__ = "maintenance_records"

    id = db.Column(db.Integer, primary_key=True)
    vehicle_id = db.Column(db.String(50), nullable=False)
    description = db.Column(db.Text)
    severity = db.Column(db.String(20))
    image_path = db.Column(db.String(200))
    status = db.Column(db.String(50), default="pending")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Foreign Key to User
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"))
    user = db.relationship("User", back_populates="maintenance_records")
    def __repr__(self):
        return f"<MaintenanceRecord {self.id} - {self.vehicle_id} - {self.status}>"

    def to_dict(self):
        return {
            "id": self.id,
            "vehicle_id": self.vehicle_id,
            "description": self.description,
            "severity": self.severity,
            "image_path": self.image_path,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
            "user_id": self.user_id
        }