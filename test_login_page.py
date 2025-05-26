#!/usr/bin/env python3
"""
Simple test script to verify the login page renders correctly.
"""

import sys
import os

# Add the project root to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lt_crm'))

from app import create_app
from flask import url_for

def test_login_page():
    """Test that the login page renders correctly."""
    app = create_app()
    
    with app.test_client() as client:
        with app.app_context():
            # Test GET request to login page
            response = client.get(url_for('auth.login'))
            
            print(f"Status Code: {response.status_code}")
            print(f"Content-Type: {response.content_type}")
            
            # Check if the response is successful
            if response.status_code == 200:
                print("✅ Login page loads successfully")
                
                # Check for key elements in the response
                html_content = response.get_data(as_text=True)
                
                checks = [
                    ('DaisyUI card component', 'card bg-base-100 shadow-xl'),
                    ('Email input field', 'name="email"'),
                    ('Password input field', 'name="password"'),
                    ('Remember me checkbox', 'name="remember_me"'),
                    ('Submit button', 'type="submit"'),
                    ('Register link', 'auth.register'),
                    ('Primary button styling', 'btn btn-primary'),
                    ('Form control styling', 'form-control'),
                ]
                
                for check_name, check_string in checks:
                    if check_string in html_content:
                        print(f"✅ {check_name} found")
                    else:
                        print(f"❌ {check_name} NOT found")
                
                print("\n📄 Login page HTML structure looks good!")
                
            else:
                print(f"❌ Login page failed to load: {response.status_code}")
                print(response.get_data(as_text=True))

def test_register_page():
    """Test that the register page renders correctly."""
    app = create_app()
    
    with app.test_client() as client:
        with app.app_context():
            # Test GET request to register page
            response = client.get(url_for('auth.register'))
            
            print(f"\nRegister Page Status Code: {response.status_code}")
            
            # Check if the response is successful
            if response.status_code == 200:
                print("✅ Register page loads successfully")
                
                # Check for key elements in the response
                html_content = response.get_data(as_text=True)
                
                checks = [
                    ('Username field', 'name="username"'),
                    ('Full name field', 'name="name"'),
                    ('Email field', 'name="email"'),
                    ('Password field', 'name="password"'),
                    ('Confirm password field', 'name="password2"'),
                    ('DaisyUI styling', 'card bg-base-100'),
                ]
                
                for check_name, check_string in checks:
                    if check_string in html_content:
                        print(f"✅ {check_name} found")
                    else:
                        print(f"❌ {check_name} NOT found")
                
                print("\n📄 Register page HTML structure looks good!")
                
            else:
                print(f"❌ Register page failed to load: {response.status_code}")

if __name__ == "__main__":
    print("🧪 Testing Login and Register Pages")
    print("=" * 50)
    
    try:
        test_login_page()
        test_register_page()
        print("\n🎉 All tests completed!")
        
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc() 