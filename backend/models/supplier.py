from app import db
from datetime import datetime

class Supplier(db.Model):
    __tablename__ = "suppliers"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    contact = db.Column(db.String(120))
    rating = db.Column(db.Float, default=0.0)
    last_bid_price = db.Column(db.Float)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    invoices = db.relationship("Invoice", back_populates="supplier", lazy=True)
    def __repr__(self):
        return f"<Supplier {self.name}>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "contact": self.contact,
            "rating": self.rating,
            "last_bid_price": self.last_bid_price,
            "created_at": self.created_at.isoformat()
        }
