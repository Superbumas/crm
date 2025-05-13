"""Tests for the Flask application factory."""


def test_config():
    """Test create_app without passing test config."""
    from app import create_app
    assert not create_app().testing
    assert create_app({"TESTING": True}).testing


def test_health_check(client):
    """Test that the health check endpoint works."""
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json["status"] == "healthy" 