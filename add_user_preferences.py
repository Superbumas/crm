"""
Script to generate migration for adding preferences column to User model.
Run this script from the project root directory with:
python add_user_preferences.py
"""
import os
import sys
import subprocess

def main():
    # Change to the project directory (in case script is run from elsewhere)
    project_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(project_dir)
    
    # Generate migration
    print("Generating migration for adding preferences column to User model...")
    result = subprocess.run(
        ["flask", "db", "migrate", "-m", "Add preferences column to User model"],
        capture_output=True,
        text=True
    )
    
    # Check result
    if result.returncode == 0:
        print("Migration generated successfully!")
        print("Output:")
        print(result.stdout)
        
        # Apply migration
        print("\nApplying migration...")
        apply_result = subprocess.run(
            ["flask", "db", "upgrade"],
            capture_output=True,
            text=True
        )
        
        if apply_result.returncode == 0:
            print("Migration applied successfully!")
            print("Output:")
            print(apply_result.stdout)
        else:
            print("Error applying migration:")
            print(apply_result.stderr)
            return 1
    else:
        print("Error generating migration:")
        print(result.stderr)
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 