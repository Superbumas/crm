"""Routes for the auth blueprint."""
from flask import flash, redirect, render_template, request, url_for, jsonify
from flask_login import current_user, login_user, logout_user, login_required
from urllib.parse import urlparse
from datetime import datetime

from . import bp
from ..models.user import User
from ..extensions import db
from ..api.v1.utils import generate_jwt_token


@bp.route("/login", methods=["GET", "POST"])
def login():
    """User login route."""
    if current_user.is_authenticated:
        return redirect(url_for("main.dashboard"))

    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        remember_me = request.form.get("remember_me") is not None

        user = User.query.filter_by(email=email).first()
        if user is None or not user.check_password(password):
            flash("Neteisingas el. paštas arba slaptažodis", "error")
            return redirect(url_for("auth.login"))

        # Update last login timestamp
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        login_user(user, remember=remember_me)
        
        next_page = request.args.get("next")
        if not next_page or urlparse(next_page).netloc != "":
            next_page = url_for("main.dashboard")
        
        return redirect(next_page)

    return render_template("auth/login.html", title="Sign In")


@bp.route("/logout")
def logout():
    """User logout route."""
    logout_user()
    return redirect(url_for("main.index"))


@bp.route("/register", methods=["GET", "POST"])
def register():
    """User registration route."""
    if current_user.is_authenticated:
        return redirect(url_for("main.dashboard"))

    if request.method == "POST":
        username = request.form.get("username")
        email = request.form.get("email")
        name = request.form.get("name")
        password = request.form.get("password")
        password2 = request.form.get("password2")
        
        # Validate form inputs
        if not username or not email or not name or not password or not password2:
            flash("Visi laukai yra privalomi", "error")
            return redirect(url_for("auth.register"))
            
        if password != password2:
            flash("Slaptažodžiai nesutampa", "error")
            return redirect(url_for("auth.register"))
            
        # Check if username or email already exists
        user_by_username = User.query.filter_by(username=username).first()
        if user_by_username:
            flash("Vartotojo vardas jau naudojamas", "error")
            return redirect(url_for("auth.register"))
            
        user_by_email = User.query.filter_by(email=email).first()
        if user_by_email:
            flash("El. paštas jau užregistruotas", "error")
            return redirect(url_for("auth.register"))
        
        # Create new user
        user = User(username=username, email=email, name=name)
        user.set_password(password)
        
        # Save to database
        db.session.add(user)
        db.session.commit()
        
        flash("Registracija sėkminga! Prašome prisijungti.", "success")
        return redirect(url_for("auth.login"))

    return render_template("auth/register.html", title="Register")


@bp.route("/profile", methods=["GET", "POST"])
@login_required
def profile():
    """User profile route."""
    if request.method == "POST":
        current_password = request.form.get("current_password")
        new_password = request.form.get("new_password")
        confirm_password = request.form.get("confirm_password")
        
        # Validate form inputs
        if not current_password or not new_password or not confirm_password:
            flash("Visi laukai yra privalomi", "error")
            return redirect(url_for("auth.profile"))
            
        if not current_user.check_password(current_password):
            flash("Dabartinis slaptažodis neteisingas", "error")
            return redirect(url_for("auth.profile"))
            
        if new_password != confirm_password:
            flash("Nauji slaptažodžiai nesutampa", "error")
            return redirect(url_for("auth.profile"))
            
        # Update password
        current_user.set_password(new_password)
        db.session.commit()
        flash("Slaptažodis sėkmingai atnaujintas", "success")
        return redirect(url_for("auth.profile"))
        
    return render_template("auth/profile.html", title="Profile")


@bp.route("/api-token", methods=["GET"])
@login_required
def get_api_token():
    """Get API token for the current user."""
    if not current_user.is_authenticated:
        return jsonify({"error": "User not authenticated"}), 401
    
    token = generate_jwt_token(current_user.id, "access")
    return jsonify({
        "access_token": token,
        "token_type": "bearer"
    })


@bp.route("/users")
@login_required
def users():
    """Users administration page."""
    # Only allow admin users to access
    if not current_user.is_admin:
        flash("Jūs neturite teisių atlikti šį veiksmą.", "error")
        return redirect(url_for("main.dashboard"))
    
    # Get all users
    users_list = User.query.all()
    
    return render_template(
        "auth/users.html",
        title="Vartotojų administravimas",
        users=users_list
    )


@bp.route("/users/create", methods=["POST"])
@login_required
def create_user():
    """Create a new user."""
    # Only allow admin users
    if not current_user.is_admin:
        flash("Jūs neturite teisių atlikti šį veiksmą.", "error")
        return redirect(url_for("main.dashboard"))
    
    # Get form data
    username = request.form.get("username")
    email = request.form.get("email")
    name = request.form.get("name", username)  # Default to username if name not provided
    password = request.form.get("password")
    confirm_password = request.form.get("confirm_password")
    is_admin = "is_admin" in request.form
    
    # Validate form data
    if not username or not email or not password or not confirm_password:
        flash("Visi laukai yra privalomi", "error")
        return redirect(url_for("auth.users"))
    
    if password != confirm_password:
        flash("Slaptažodžiai nesutampa", "error")
        return redirect(url_for("auth.users"))
    
    # Check if username or email already exists
    if User.query.filter_by(username=username).first():
        flash(f"Vartotojas su vardu {username} jau egzistuoja", "error")
        return redirect(url_for("auth.users"))
    
    if User.query.filter_by(email=email).first():
        flash(f"Vartotojas su el. paštu {email} jau egzistuoja", "error")
        return redirect(url_for("auth.users"))
    
    # Create user
    user = User(
        username=username,
        email=email,
        name=name,
        is_admin=is_admin,
        is_active=True
    )
    user.set_password(password)
    
    # Save to database
    db.session.add(user)
    db.session.commit()
    
    flash(f"Vartotojas {username} sėkmingai sukurtas", "success")
    return redirect(url_for("auth.users"))


@bp.route("/users/<int:id>/edit", methods=["POST"])
@login_required
def edit_user(id):
    """Edit user."""
    # Only allow admin users
    if not current_user.is_admin:
        flash("Jūs neturite teisių atlikti šį veiksmą.", "error")
        return redirect(url_for("main.dashboard"))
    
    # Get user
    user = User.query.get_or_404(id)
    
    # Get form data
    username = request.form.get("username")
    email = request.form.get("email")
    is_admin = "is_admin" in request.form
    is_active = "is_active" in request.form
    
    # Validate form data
    if not username or not email:
        flash("Vartotojo vardas ir el. paštas yra privalomi", "error")
        return redirect(url_for("auth.users"))
    
    # Check if username or email already exists for other users
    username_exists = User.query.filter(User.username == username, User.id != id).first()
    if username_exists:
        flash(f"Vartotojas su vardu {username} jau egzistuoja", "error")
        return redirect(url_for("auth.users"))
    
    email_exists = User.query.filter(User.email == email, User.id != id).first()
    if email_exists:
        flash(f"Vartotojas su el. paštu {email} jau egzistuoja", "error")
        return redirect(url_for("auth.users"))
    
    # Update user
    user.username = username
    user.email = email
    user.is_admin = is_admin
    user.is_active = is_active
    
    # Save to database
    db.session.commit()
    
    flash(f"Vartotojas {username} sėkmingai atnaujintas", "success")
    return redirect(url_for("auth.users"))


@bp.route("/users/<int:id>/delete", methods=["POST"])
@login_required
def delete_user(id):
    """Delete user."""
    # Only allow admin users
    if not current_user.is_admin:
        flash("Jūs neturite teisių atlikti šį veiksmą.", "error")
        return redirect(url_for("main.dashboard"))
    
    # Get user
    user = User.query.get_or_404(id)
    
    # Check if user is the current user
    if user.id == current_user.id:
        flash("Negalima ištrinti savo paskyros", "error")
        return redirect(url_for("auth.users"))
    
    # Delete user
    db.session.delete(user)
    db.session.commit()
    
    flash(f"Vartotojas {user.username} sėkmingai ištrintas", "success")
    return redirect(url_for("auth.users")) 