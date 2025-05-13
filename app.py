"""
Simple wrapper to make Fly.io happy by providing an app at the root level.
"""
from lt_crm.app import create_app

# This makes the app importable directly from the root
app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000) 