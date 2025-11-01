import os
import requests
from dotenv import load_dotenv

load_dotenv()
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")

def trigger_workflow(event_name, payload):
    """
    Trigger an external automation (n8n, Zapier, etc.)
    """
    if not N8N_WEBHOOK_URL:
        print(f"⚙️ [Automation Simulation] {event_name} => {payload}")
        return {"status": "simulated", "event": event_name}

    try:
        response = requests.post(N8N_WEBHOOK_URL, json={"event": event_name, "data": payload})
        print(f"✅ Automation triggered: {event_name}")

        # Safely parse JSON if available
        try:
            resp_data = response.json()
        except ValueError:
            resp_data = {"text": response.text}

        return {"status": "triggered", "response": resp_data, "code": response.status_code}

    except Exception as e:
        print(f"⚠️ Automation failed: {e}")
        return {"status": "failed", "error": str(e)}
