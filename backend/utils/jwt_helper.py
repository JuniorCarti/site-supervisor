from flask_jwt_extended import verify_jwt_in_request, get_jwt
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from flask import jsonify

# Password utilities
def hash_password(password):
    return generate_password_hash(password)

def verify_password(password, hashed_password):
    return check_password_hash(hashed_password, password)

# Role-based access control decorator
def role_required(required_roles):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            claims = get_jwt()
            user_role = claims.get("role")
            if user_role not in required_roles:
                return jsonify({"error": "Unauthorized: Insufficient role"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator
