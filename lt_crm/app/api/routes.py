"""Routes for the API blueprint."""
from flask_restx import Resource

from . import api
from ..models.user import User

# Define API namespaces
ns_users = api.namespace("users", description="User operations")
ns_customers = api.namespace("customers", description="Customer operations")


@ns_users.route("/")
class UserList(Resource):
    """User collection resource."""

    def get(self):
        """List all users."""
        users = User.query.all()
        return [
            {"id": user.id, "username": user.username, "email": user.email} for user in users
        ]


@ns_users.route("/<int:id>")
class UserResource(Resource):
    """User resource."""

    def get(self, id):
        """Get user by ID."""
        user = User.query.get_or_404(id)
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
        }


# Define Customer namespace routes
@ns_customers.route("/")
class CustomerList(Resource):
    """Customer collection resource."""

    def get(self):
        """List all customers."""
        # Implementation would retrieve customers from database
        return [{"message": "Customer list not yet implemented"}] 