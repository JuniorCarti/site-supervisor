from app import db
from datetime import datetime

class Project(db.Model):
    __tablename__ = "projects"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(50), default="active")  # active, delayed, completed
    start_date = db.Column(db.DateTime, default=datetime.utcnow)
    expected_completion = db.Column(db.DateTime)
    completion_forecast = db.Column(db.Float)  # 0.0 - 1.0 probability of on-time completion
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    def __repr__(self):
        return f"<Project {self.name} - {self.status}>"
    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "status": self.status,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "expected_completion": self.expected_completion.isoformat() if self.expected_completion else None,
            "completion_forecast": self.completion_forecast,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }