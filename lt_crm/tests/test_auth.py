"""Tests for authentication functionality."""


def test_login_page(client):
    """Test that the login page loads correctly."""
    response = client.get("/login")
    assert response.status_code == 200
    assert b"Sign In" in response.data


def test_login_logout(client, auth):
    """Test login and logout functionality."""
    # Test login with correct credentials
    response = auth.login()
    assert response.status_code == 200
    
    # Test logout
    response = auth.logout()
    assert response.status_code == 200
    
    # Test login with incorrect credentials
    response = auth.login("wrong@example.com", "wrongpassword")
    assert response.status_code == 200
    assert b"Invalid email or password" in response.data


def test_register_page(client):
    """Test that the register page loads correctly."""
    response = client.get("/register")
    assert response.status_code == 200
    assert b"Register" in response.data 