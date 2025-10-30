from app import db
from datetime import datetime
import enum


# --------------------------------------------------------
# 🧩 ENUM CLASS FOR USER ROLES
# --------------------------------------------------------
class UserRole(enum.Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    DRIVER = "driver"


# --------------------------------------------------------
# 👤 USER MODEL
# --------------------------------------------------------
class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

    # ✅ Use Enum for role
    role = db.Column(
        db.Enum(UserRole, values_callable=lambda obj: [e.value for e in obj]),
        nullable=False,
        default=UserRole.DRIVER
    )

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship
    maintenance_records = db.relationship("MaintenanceRecord", back_populates="user", lazy=True)

    def __repr__(self):
        return f"<User {self.email} ({self.role.value})>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "role": self.role.value,  # get the enum string
            "created_at": self.created_at.isoformat(),
        }
