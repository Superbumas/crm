#!/usr/bin/env python
"""Test script for debugging user preferences."""
import os
import sys
import json
from sqlalchemy import create_engine, text

# Database connection string
DB_URI = "postgresql://postgres:postgres@postgres/lt_crm"

def main():
    """Main function to test user preferences."""
    try:
        # Connect to the database
        engine = create_engine(DB_URI)
        
        with engine.connect() as conn:
            # Check database connection
            print("Connected to database.")
            
            # Get user table info
            print("\nChecking users table:")
            result = conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_name = 'users'"))
            tables = [row[0] for row in result]
            if 'users' in tables:
                print("- Users table exists")
            else:
                # Check other potential table names
                result = conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%user%'"))
                tables = [row[0] for row in result]
                print(f"- Users table not found. Similar tables: {tables}")
                
                if tables:
                    user_table = tables[0]
                else:
                    print("No user tables found. Exiting.")
                    return
            
            # Get users with preferences
            user_table = 'users'  # Default, will be overridden if different
            try:
                result = conn.execute(text(f"SELECT id, username, preferences FROM {user_table}"))
                users = [dict(row) for row in result]
                if users:
                    print(f"- Found {len(users)} users")
                    
                    # Check user preferences
                    for user in users:
                        print(f"\nUser {user['username']} (ID: {user['id']}):")
                        print(f"- Preferences: {user['preferences']}")
                        
                        # Try to update preferences for the first user
                        if user['id'] == 1:  # Assuming admin is ID 1
                            # Create test preferences
                            test_prefs = {
                                'product_columns': ['sku', 'name', 'category', 'barcode', 'price_final', 'price_old', 'quantity', 'model']
                            }
                            
                            # Convert to JSON string for storage
                            prefs_json = json.dumps(test_prefs)
                            
                            # Update user preferences
                            conn.execute(
                                text(f"UPDATE {user_table} SET preferences = :prefs WHERE id = :user_id"),
                                {"prefs": prefs_json, "user_id": user['id']}
                            )
                            conn.commit()
                            
                            print(f"- Updated preferences for user {user['username']}")
                            
                            # Verify the update
                            result = conn.execute(
                                text(f"SELECT preferences FROM {user_table} WHERE id = :user_id"),
                                {"user_id": user['id']}
                            )
                            updated_prefs = result.fetchone()[0]
                            print(f"- After update: {updated_prefs}")
                else:
                    print("- No users found")
            except Exception as e:
                print(f"Error querying users: {e}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main() 