# utils/ai_agents.py
from datetime import datetime, timedelta
import random

# 🧠 Sentinel Agent - Predictive Maintenance
def sentinel_agent(sensor_data):
    """
    Simulate predictive maintenance alerts based on simple thresholds.
    """
    temp = sensor_data.get("temperature", 70)
    pressure = sensor_data.get("oil_pressure", 50)
    vibration = sensor_data.get("vibration", 3.0)

    alerts = []

    if temp > 90:
        alerts.append("High engine temperature detected.")
    if pressure < 30:
        alerts.append("Low oil pressure warning.")
    if vibration > 5:
        alerts.append("Abnormal vibration detected - check suspension.")

    if not alerts:
        return {"status": "OK", "message": "All systems normal."}
    
    return {
        "status": "ALERT",
        "message": " | ".join(alerts),
        "recommended_action": "Schedule maintenance soon."
    }


# 🤝 Quartermaster Agent - Supplier Negotiation
def quartermaster_agent(suppliers):
    """
    Simulate picking the best supplier based on rating and bid price.
    """
    if not suppliers:
        return {"message": "No suppliers available."}

    best_supplier = sorted(
        suppliers, key=lambda x: (x.get("last_bid_price", 999999), -x.get("rating", 0))
    )[0]

    return {
        "selected_supplier": best_supplier["name"],
        "decision_reason": f"Chosen for best cost-performance ratio (Bid: {best_supplier.get('last_bid_price')} Rating: {best_supplier.get('rating')})"
    }


# 💰 Chancellor Agent - Financial Overview
def chancellor_agent(invoices):
    """
    Simulate cash flow and invoice insights.
    """
    total = sum(i.get("amount", 0) for i in invoices)
    pending = sum(i.get("amount", 0) for i in invoices if i.get("status") == "pending")
    approved = total - pending

    forecast = "Stable"
    if pending > total * 0.6:
        forecast = "Risk of cash shortage"
    elif approved > total * 0.8:
        forecast = "Healthy liquidity"

    return {
        "total_invoices": total,
        "pending": pending,
        "approved": approved,
        "cash_forecast": forecast
    }


# 📊 Foreman Agent - Project Forecasting
def foreman_agent(projects):
    """
    Simulate project completion forecast using random probability.
    """
    if not projects:
        return {"message": "No projects found."}

    results = []
    for project in projects:
        forecast_prob = round(random.uniform(0.7, 0.95), 2)
        results.append({
            "project_name": project.get("name"),
            "status": project.get("status"),
            "forecast_confidence": forecast_prob,
            "predicted_completion_date": (datetime.utcnow() + timedelta(days=random.randint(5, 15))).strftime("%Y-%m-%d")
        })

    return {"project_forecasts": results}
