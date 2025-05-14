"""
Test file to validate the imports are working correctly
"""
try:
    from lt_crm.app import create_app
    print("Successfully imported create_app from lt_crm.app")
    app = create_app()
    print("Successfully created Flask app instance")
except ImportError as e:
    print(f"Import error: {e}")
except Exception as e:
    print(f"Error: {e}")

print("Done.") 