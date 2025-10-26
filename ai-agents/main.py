

from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os
import hmac
import hashlib
from datetime import datetime

from agents.sentinel import SiteSupervisorAgent
from agents.memory import AgentMemory
from config.models import config

# Configure logging
logging.basicConfig(
    level=config.log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Initialize components
memory = AgentMemory()
agent = SiteSupervisorAgent(memory)

def verify_webhook_signature(payload: bytes, signature: str) -> bool:
    """Verify webhook signature for security"""
    expected_signature = hmac.new(
        config.webhook_secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected_signature, signature)

def require_api_key(f):
    """Decorator to require API key for protected endpoints"""
    from functools import wraps
    
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not api_key or api_key != config.api_key:
            return jsonify({'error': 'Invalid or missing API key'}), 401
        return f(*args, **kwargs)
    return decorated_function

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'site-supervisor',
        'timestamp': datetime.now().isoformat(),
        'model': config.openai_model
    })

@app.route('/api/analyze', methods=['POST'])
@require_api_key
def analyze_site():
    """Analyze site data"""
    try:
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        logger.info(f"Analyzing site data: {len(str(data))} characters")
        
        result = agent.analyze_site_data(data)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in analyze_site: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/webhook/n8n', methods=['POST'])
def n8n_webhook():
    """n8n webhook endpoint"""
    try:
        # Verify webhook signature if provided
        signature = request.headers.get('X-Webhook-Signature')
        if signature and not verify_webhook_signature(request.data, signature):
            return jsonify({'error': 'Invalid webhook signature'}), 401
        
        n8n_data = request.json
        if not n8n_data:
            return jsonify({'error': 'No data provided'}), 400
        
        logger.info(f"Received n8n webhook: {n8n_data.get('action', 'unknown')}")
        
        result = agent.process_n8n_data(n8n_data)
        
        response = {
            'success': 'error' not in result,
            'result': result,
            'workflow_run_id': n8n_data.get('workflow_run_id', 'unknown'),
            'timestamp': datetime.now().isoformat()
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in n8n_webhook: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/memory/interactions', methods=['GET'])
@require_api_key
def get_recent_interactions():
    """Get recent interactions from memory"""
    try:
        limit = min(int(request.args.get('limit', 10)), 100)
        interactions = memory.get_recent_interactions(limit)
        return jsonify({'interactions': interactions, 'count': len(interactions)})
    except Exception as e:
        logger.error(f"Error getting interactions: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/status', methods=['GET'])
@require_api_key
def get_status():
    """Get agent status and configuration"""
    return jsonify({
        'status': 'running',
        'model': config.openai_model,
        'model_provider': config.provider,
        'memory_entries': len(memory.memory.get('interactions', [])),
        'startup_time': datetime.now().isoformat()
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info(f"Starting Site Supervisor Agent with model: {config.openai_model}")
    app.run(
        host=config.flask_host,
        port=config.flask_port,
        debug=(config.flask_env == 'development')
    )
