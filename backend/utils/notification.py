# Comment out Twilio imports and create mock functions
# from twilio.rest import Client

# Mock Twilio credentials (won't be used)
TWILIO_ACCOUNT_SID = "mock"
TWILIO_AUTH_TOKEN = "mock"
TWILIO_PHONE_NUMBER = "mock"

def send_sms(to, message):
    print(f"📱 [MOCK SMS] To: {to}, Message: {message}")
    return {"status": "sent", "message": "Mock SMS sent successfully"}

def send_email(to, subject, message):
    print(f"📧 [MOCK EMAIL] To: {to}, Subject: {subject}, Message: {message}")
    return {"status": "sent", "message": "Mock email sent successfully"}

def notify_event(channel, recipient, subject, message):
    print(f"🔔 [MOCK NOTIFICATION] Channel: {channel}, To: {recipient}, Subject: {subject}")
    
    if channel == "sms":
        return send_sms(recipient, message)
    elif channel == "email":
        return send_email(recipient, subject, message)
    else:
        return {"status": "error", "message": f"Unknown channel: {channel}"}