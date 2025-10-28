import datetime

def send_sms(to, message):
    """Simulate sending an SMS (placeholder for Twilio integration)."""
    log = f"[{datetime.datetime.now()}] SMS to {to}: {message}"
    print(log)
    return {"status": "sent", "type": "sms", "to": to, "message": message}


def send_email(to, subject, body):
    """Simulate sending an Email (placeholder for Resend/SendGrid)."""
    log = f"[{datetime.datetime.now()}] EMAIL to {to} | Subject: {subject} | Body: {body}"
    print(log)
    return {"status": "sent", "type": "email", "to": to, "subject": subject}


def notify_admins(message):
    """Simulated broadcast to admin users (logs only)."""
    log = f"[{datetime.datetime.now()}] ADMIN ALERT: {message}"
    print(log)
    return {"status": "broadcasted", "to": "admins", "message": message}

def log_notification(notification_type, details):
    """Log notification details for auditing purposes."""
    log = f"[{datetime.datetime.now()}] LOG {notification_type.upper()}: {details}"
    print(log)
    return {"status": "logged", "type": notification_type, "details": details}

def notify_event(channel, recipient, subject, message):
    """
    Universal function that chooses the right channel (email or sms).
    """
    if channel == "email":
        return send_email(recipient, subject, message)
    elif channel == "sms":
        return send_sms(recipient, message)
    else:
        # fallback to console logging
        print(f"\n🔔 [NOTIFICATION]: {message}")
        return {"status": "logged", "type": "system"}