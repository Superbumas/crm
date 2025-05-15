"""Utilities for API v1."""
import datetime
import functools
import jwt
from flask import current_app, request, jsonify
from lt_crm.app.models.user import User
from marshmallow import ValidationError

# JWT utilities
def generate_jwt_token(user_id, token_type="access"):
    """Generate a JWT token for the user."""
    now = datetime.datetime.utcnow()
    
    if token_type == "access":
        expires_in = current_app.config.get("JWT_ACCESS_TOKEN_EXPIRES", 3600)  # Default 1 hour
    else:  # refresh token
        expires_in = current_app.config.get("JWT_REFRESH_TOKEN_EXPIRES", 2592000)  # Default 30 days
    
    payload = {
        "sub": user_id,
        "type": token_type,
        "iat": now,
        "exp": now + datetime.timedelta(seconds=expires_in)
    }
    
    token = jwt.encode(
        payload,
        current_app.config.get("JWT_SECRET_KEY"),
        algorithm="HS256"
    )
    
    return token

def decode_jwt_token(token):
    """Decode a JWT token and return the payload."""
    try:
        payload = jwt.decode(
            token,
            current_app.config.get("JWT_SECRET_KEY"),
            algorithms=["HS256"]
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def get_token_from_header():
    """Extract token from Authorization header."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    
    return auth_header.split(" ")[1]

def get_token_from_form():
    """Extract token from form data."""
    # Check for token in form data (for POST requests)
    if request.method == "POST":
        # Check for JSON payload
        if request.is_json:
            json_data = request.get_json()
            if json_data and "jwt_token" in json_data:
                return json_data.get("jwt_token")
        
        # Check for form data
        return request.form.get("jwt_token")
    
    return None

# Decorators
def token_required(token_type="access"):
    """Decorator to check if a valid JWT token is provided."""
    def decorator(f):
        @functools.wraps(f)
        def decorated_function(*args, **kwargs):
            # Try to get token from header first, then from form data
            token = get_token_from_header() or get_token_from_form()
            
            if not token:
                return {"message": "Token is missing"}, 401
            
            payload = decode_jwt_token(token)
            if not payload:
                return {"message": "Token is invalid or expired"}, 401
            
            if payload.get("type") != token_type:
                return {"message": f"Invalid token type. {token_type.capitalize()} token required"}, 401
            
            # Get user from database
            user = User.query.get(payload.get("sub"))
            if not user or not user.is_active:
                return {"message": "User not found or inactive"}, 401
            
            return f(*args, **kwargs, current_user=user)
        return decorated_function
    return decorator

# Request parsing utilities
def validate_schema(schema_cls):
    """Decorator to validate request data against schema."""
    def decorator(f):
        @functools.wraps(f)
        def decorated_function(*args, **kwargs):
            try:
                schema = schema_cls()
                data = request.get_json() or {}
                kwargs["data"] = schema.load(data)
                return f(*args, **kwargs)
            except ValidationError as err:
                return {"errors": err.messages}, 400
        return decorated_function
    return decorator

# Pagination helpers
def get_pagination_params():
    """Get pagination parameters from query string."""
    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)  # Max 100 per page
    return page, per_page

def paginate(query, schema_cls, page, per_page):
    """Return paginated response for query."""
    paginated = query.paginate(page=page, per_page=per_page)
    
    schema = schema_cls(many=True)
    items = schema.dump(paginated.items)
    
    return {
        "items": items,
        "total": paginated.total,
        "page": page,
        "per_page": per_page,
        "pages": paginated.pages
    }

# File processing helpers
def allowed_file(filename, allowed_extensions=None):
    """Check if file has an allowed extension."""
    if not allowed_extensions:
        allowed_extensions = {'csv', 'xlsx'}
        
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in allowed_extensions 