"""Routes for the auth blueprint."""
from flask import flash, redirect, render_template, request, url_for
from flask_login import current_user, login_user, logout_user, login_required
from urllib.parse import urlparse

from . import bp
from ..models.user import User
from ..extensions import db


@bp.route("/login", methods=["GET", "POST"])
def login():
    """User login route."""
    if current_user.is_authenticated:
        return redirect(url_for("main.index"))

    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        remember_me = request.form.get("remember_me") is not None

        user = User.query.filter_by(email=email).first()
        if user is None or not user.check_password(password):
            flash("Invalid email or password")
            return redirect(url_for("auth.login"))

        login_user(user, remember=remember_me)
        
        next_page = request.args.get("next")
        if not next_page or urlparse(next_page).netloc != "":
            next_page = url_for("main.index")
        
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
        return redirect(url_for("main.index"))

    if request.method == "POST":
        username = request.form.get("username")
        email = request.form.get("email")
        password = request.form.get("password")
        password2 = request.form.get("password2")
        
        # Validate form inputs
        if not username or not email or not password or not password2:
            flash("All fields are required", "error")
            return redirect(url_for("auth.register"))
            
        if password != password2:
            flash("Passwords do not match", "error")
            return redirect(url_for("auth.register"))
            
        # Check if username or email already exists
        user_by_username = User.query.filter_by(username=username).first()
        if user_by_username:
            flash("Username already in use", "error")
            return redirect(url_for("auth.register"))
            
        user_by_email = User.query.filter_by(email=email).first()
        if user_by_email:
            flash("Email already registered", "error")
            return redirect(url_for("auth.register"))
        
        # Create new user
        user = User(username=username, email=email)
        user.set_password(password)
        
        # Save to database
        db.session.add(user)
        db.session.commit()
        
        flash("Registration successful! Please log in.", "success")
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
            flash("All fields are required", "error")
            return redirect(url_for("auth.profile"))
            
        if not current_user.check_password(current_password):
            flash("Current password is incorrect", "error")
            return redirect(url_for("auth.profile"))
            
        if new_password != confirm_password:
            flash("New passwords do not match", "error")
            return redirect(url_for("auth.profile"))
            
        # Update password
        current_user.set_password(new_password)
        db.session.commit()
        flash("Password updated successfully")
        return redirect(url_for("auth.profile"))
        
    return render_template("auth/profile.html", title="Profile") 