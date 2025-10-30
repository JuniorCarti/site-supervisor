from datetime import datetime, timedelta
from sqlalchemy import func
from utils.ai_agents import chancellor_agent


# --------------------------------------------------------
# 📊 CORE AGGREGATION: Dashboard Summary
# --------------------------------------------------------
def get_dashboard_stats(db):
    """
    Aggregate summarized data for dashboard KPIs.
    """
    from models.project import Project
    from models.finance import Invoice
    from models.maintenance import MaintenanceRecord
    from models.supplier import Supplier

    total_projects = db.session.query(func.count(Project.id)).scalar() or 0
    delayed_projects = db.session.query(func.count(Project.id)).filter(Project.status.ilike("delayed")).scalar() or 0
    active_projects = db.session.query(func.count(Project.id)).filter(Project.status.ilike("active")).scalar() or 0

    total_invoices = db.session.query(func.count(Invoice.id)).scalar() or 0
    approved_invoices = db.session.query(func.count(Invoice.id)).filter(Invoice.status.ilike("approved")).scalar() or 0
    rejected_invoices = db.session.query(func.count(Invoice.id)).filter(Invoice.status.ilike("rejected")).scalar() or 0
    total_invoice_amount = db.session.query(func.sum(Invoice.amount)).scalar() or 0

    total_suppliers = db.session.query(func.count(Supplier.id)).scalar() or 0
    avg_supplier_rating = db.session.query(func.avg(Supplier.rating)).scalar() or 0

    total_maintenance = db.session.query(func.count(MaintenanceRecord.id)).scalar() or 0
    critical_maintenance = db.session.query(func.count(MaintenanceRecord.id)).filter(
        MaintenanceRecord.severity.ilike("critical")
    ).scalar() or 0

    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    recent_maintenance = db.session.query(func.count(MaintenanceRecord.id)).filter(
        MaintenanceRecord.created_at >= seven_days_ago
    ).scalar() or 0

    return {
        "projects": {"total": total_projects, "active": active_projects, "delayed": delayed_projects},
        "invoices": {
            "total": total_invoices,
            "approved": approved_invoices,
            "rejected": rejected_invoices,
            "total_amount": float(total_invoice_amount),
        },
        "suppliers": {"total": total_suppliers, "average_rating": round(float(avg_supplier_rating or 0), 2)},
        "maintenance": {
            "total": total_maintenance,
            "critical": critical_maintenance,
            "recent_7_days": recent_maintenance,
        },
    }


# --------------------------------------------------------
# 📈 TREND DATA: For line or bar charts
# --------------------------------------------------------
def get_trend_data(db, days=30):
    """
    Generate daily trends for maintenance, projects, and invoices.
    """
    from models.project import Project
    from models.finance import Invoice
    from models.maintenance import MaintenanceRecord

    today = datetime.utcnow()
    start_date = today - timedelta(days=days)
    trend = []

    for i in range(days):
        day = start_date + timedelta(days=i)
        next_day = day + timedelta(days=1)

        maintenance_count = db.session.query(func.count(MaintenanceRecord.id)).filter(
            MaintenanceRecord.created_at >= day,
            MaintenanceRecord.created_at < next_day,
        ).scalar() or 0

        invoices_count = db.session.query(func.count(Invoice.id)).filter(
            Invoice.created_at >= day,
            Invoice.created_at < next_day,
        ).scalar() or 0

        projects_created = db.session.query(func.count(Project.id)).filter(
            Project.created_at >= day,
            Project.created_at < next_day,
        ).scalar() or 0

        trend.append(
            {
                "date": day.strftime("%Y-%m-%d"),
                "maintenance": maintenance_count,
                "invoices": invoices_count,
                "projects": projects_created,
            }
        )

    return trend


# --------------------------------------------------------
# 💬 AI INSIGHT: Natural-language summary
# --------------------------------------------------------
def generate_analytics_insight(stats, trend):
    """
    Use AI (Chancellor Agent) to generate summary insights.
    """
    try:
        summary = [
            {"category": "projects", **stats["projects"]},
            {"category": "invoices", **stats["invoices"]},
            {"category": "suppliers", **stats["suppliers"]},
            {"category": "maintenance", **stats["maintenance"]},
        ]

        trend_summary = trend[-7:]  # last week only
        ai_input = {
            "summary": summary,
            "trend_last_7_days": trend_summary,
        }

        insight = chancellor_agent(ai_input)
        return insight
    except Exception as e:
        print(f"AI insight error: {e}")
        return "Unable to generate AI insight at this time."
