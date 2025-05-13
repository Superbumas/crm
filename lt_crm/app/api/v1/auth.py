"""Authentication endpoints for API v1."""
from datetime import datetime
from flask import request, current_app
from flask_restx import Namespace, Resource, fields
from app.models.user import User
from app.extensions import db
from app.api.v1.utils import (
    generate_jwt_token, 
    decode_jwt_token, 
    get_token_from_header, 
    token_required,
    validate_schema
)
from app.api.v1.schemas import UserLoginSchema, TokenSchema

ns = Namespace("auth", description="Authentication operations")

# API models for Swagger docs
login_model = ns.model("Login", {
    "username": fields.String(required=True, description="Username"),
    "password": fields.String(required=True, description="Password")
})

token_model = ns.model("Token", {
    "access_token": fields.String(description="JWT access token"),
    "refresh_token": fields.String(description="JWT refresh token"),
    "token_type": fields.String(description="Token type", default="bearer")
})

@ns.route("/login")
class LoginResource(Resource):
    """Login resource."""
    
    @ns.doc("user_login")
    @ns.expect(login_model)
    @ns.response(200, "Login successful", token_model)
    @ns.response(401, "Invalid credentials")
    @validate_schema(UserLoginSchema)
    def post(self, data):
        """Login a user and return access and refresh tokens."""
        user = User.query.filter_by(username=data["username"]).first()
        
        if not user or not user.check_password(data["password"]):
            return {"message": "Invalid credentials"}, 401
        
        if not user.is_active:
            return {"message": "Account is inactive"}, 401
        
        # Update last login timestamp
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # Generate tokens
        access_token = generate_jwt_token(user.id, "access")
        refresh_token = generate_jwt_token(user.id, "refresh")
        
        token_schema = TokenSchema()
        return token_schema.dump({
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        })

@ns.route("/refresh")
class TokenRefreshResource(Resource):
    """Token refresh resource."""
    
    @ns.doc("refresh_token")
    @ns.response(200, "Token refreshed", token_model)
    @ns.response(401, "Invalid refresh token")
    @token_required(token_type="refresh")
    def post(self, current_user):
        """Refresh access token using a refresh token."""
        # Generate new tokens
        access_token = generate_jwt_token(current_user.id, "access")
        
        token_schema = TokenSchema()
        return token_schema.dump({
            "access_token": access_token,
            "token_type": "bearer"
        })

@ns.route("/logout")
class LogoutResource(Resource):
    """Logout resource."""
    
    @ns.doc("user_logout")
    @ns.response(200, "Logout successful")
    @token_required()
    def post(self, current_user):
        """Logout a user by invalidating their tokens.
        
        Note: As JWT tokens are stateless, true invalidation requires implementing 
        a token blacklist, which is not part of this simple implementation.
        For a production system, consider using Redis for blacklisting tokens.
        """
        return {"message": "Logout successful"} 