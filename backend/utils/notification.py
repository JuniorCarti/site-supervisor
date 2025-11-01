import datetime
import os
from dotenv import load_dotenv
from twilio.rest import Client
import resend

load_dotenv()

# --- Load credentials ---
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")
RESEND_API_KEY = os.getenv("RESEND_API_KEY")

# Initialize clients (if credentials exist)
twilio_client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN else None
if RESEND_API_KEY:
    resend.api_key = RESEND_API_KEY


# -------------------------------------------------------
# ✉️ EMAIL NOTIFICATION (Resend or Fallback)
# -------------------------------------------------------
def send_email(to, subject, message):
    """
    Try to send email via Resend API.
    Fallback: log simulated email if domain not verified or credentials missing.
    """
    html_content = f"""
    <html>
    <body style="font-family:Arial,sans-serif; background-color:#f8f9fa; padding:20px;">
        <div style="max-width:600px; margin:auto; background:#fff; padding:20px; border-radius:10px;">
            <h2 style="color:#007BFF;">SiteSupervisor Notification</h2>
            <p style="font-size:16px;">{message}</p>
            <hr>
            <footer style="font-size:12px; color:gray;">
                This message was sent by SiteSupervisor AI System.
            </footer>
        </div>
    </body>
    </html>
    """

    # If Resend API key not available, fallback to print
    if not RESEND_API_KEY:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\n📧 [EMAIL - SIMULATION] {timestamp}\nTo: {to}\nSubject: {subject}\nMessage: {message}\n")
        return {"status": "simulated", "provider": "console", "to": to}

    try:
        email = resend.Emails.send({
            "from": "SiteSupervisor <noreply@sitesupervisor.ai>",
            "to": [to],
            "subject": subject,
            "html": html_content,
        })
        print(f"✅ Email sent to {to} via Resend")
        return {"status": "sent", "provider": "Resend", "to": to}
    except Exception as e:
        # Fallback if domain not verified or error occurred
        print(f"⚠️ Resend failed: {e}")
        print(f"📧 [EMAIL - SIMULATION] To: {to}, Subject: {subject}, Message: {message}")
        return {"status": "simulated", "error": str(e), "to": to}


# -------------------------------------------------------
# 📱 SMS NOTIFICATION (Twilio or Fallback)
# -------------------------------------------------------
def send_sms(to, message):
    """
    Try to send SMS via Twilio.
    Fallback: print simulated message if Twilio credentials missing.
    """
    # If Twilio credentials not set
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\n📱 [SMS - SIMULATION] {timestamp}\nTo: {to}\nMessage: {message}\n")
        return {"status": "simulated", "provider": "console", "to": to}

    try:
        sms = twilio_client.messages.create(
            body=f"🚨 SiteSupervisor Alert:\n{message}",
            from_=TWILIO_PHONE_NUMBER,
            to=to,
        )
        print(f"✅ SMS sent to {to}, SID: {sms.sid}")
        return {"status": "sent", "provider": "Twilio", "to": to}
    except Exception as e:
        # Fallback on failure
        print(f"⚠️ Twilio failed: {e}")
        print(f"📱 [SMS - SIMULATION] To: {to}, Message: {message}")
        return {"status": "simulated", "error": str(e), "to": to}


# -------------------------------------------------------
# 🔔 UNIVERSAL NOTIFICATION HANDLER
# -------------------------------------------------------
def notify_event(channel, recipient, subject, message):
    """
    Sends a notification through the requested channel.
    If credentials are missing, falls back to simulation automatically.
    """
    if channel == "email":
        return send_email(recipient, subject, message)
    elif channel == "sms":
        return send_sms(recipient, message)
    else:
        print(f"ℹ️ [SYSTEM LOG] {message}")
        return {"status": "logged", "type": "system", "to": recipient}
