#!/usr/bin/env python3

import json
import os
import sys
import time

def main():
    print("=== DEBUG DK App Install Service ===")
    
    if len(sys.argv) != 2:
        print("Usage: python debug_install.py <data.json>")
        return 1
    
    json_installcfg_path = sys.argv[1]
    print(f"Processing installation config: {json_installcfg_path}")
    
    # Determine the base directory for .dk folder
    dk_user = os.getenv("DK_USER", os.getenv("USER", "root"))
    dk_base_dir = f"/home/{dk_user}/.dk"
    print(f"DK base directory: {dk_base_dir}")
    
    # Read installation config
    try:
        with open(json_installcfg_path, 'r') as file:
            json_data = json.load(file)
        print(f"Loaded installation config successfully")
    except Exception as e:
        print(f"Error loading config: {e}")
        return 1
    
    # Extract basic info
    app_id = json_data.get('_id', 'unknown')
    name = json_data.get('name', 'Unknown App')
    category = json_data.get('category', 'unknown')
    
    print(f"App ID: {app_id}")
    print(f"App Name: {name}")
    print(f"Category: {category}")
    
    # Determine paths
    root_folder = f"{dk_base_dir}/dk_installedservices/"
    installed_file = f"{root_folder}installedservices.json"
    app_folder = f"{root_folder}{app_id}"
    
    print(f"Root folder: {root_folder}")
    print(f"App folder: {app_folder}")
    print(f"Installed file: {installed_file}")
    
    # Create directories
    print("Creating directories...")
    os.makedirs(root_folder, exist_ok=True)
    os.makedirs(app_folder, exist_ok=True)
    
    # Debug the installed list reading
    print("=" * 50)
    print("DEBUGGING INSTALLED LIST READING:")
    print(f"File exists: {os.path.exists(installed_file)}")
    
    if os.path.exists(installed_file):
        print("File exists, reading...")
        try:
            with open(installed_file, 'r') as f:
                content = f.read()
            print(f"Raw file content: {repr(content)}")
            print(f"Content length: {len(content)}")
            
            if content.strip():
                installed_list = json.loads(content)
                print(f"Parsed JSON: {installed_list}")
                print(f"Type: {type(installed_list)}")
                print(f"Length: {len(installed_list)}")
            else:
                print("File is empty or whitespace only")
                installed_list = []
        except Exception as e:
            print(f"Error reading/parsing file: {e}")
            installed_list = []
    else:
        print("File does not exist, creating new list")
        installed_list = []
    
    print(f"Final installed_list: {installed_list}")
    print("=" * 50)
    
    # Check if app is already in the list
    app_already_installed = False
    for i, item in enumerate(installed_list):
        print(f"Checking item {i}: {item}")
        if item.get('_id') == app_id:
            app_already_installed = True
            print(f"Found app {app_id} at index {i}")
            break
    
    print(f"App already installed: {app_already_installed}")
    
    # Add to installed list if not already there
    if not app_already_installed:
        installed_entry = {
            "_id": app_id,
            "name": name,
            "category": category,
            "installed_timestamp": time.time()
        }
        installed_list.append(installed_entry)
        print(f"Added {name} to installed list")
        print(f"New list: {installed_list}")
    else:
        print(f"App {app_id} already in list, not adding")
    
    # Write updated installed list
    print("Writing updated list...")
    try:
        with open(installed_file, 'w') as f:
            json.dump(installed_list, f, indent=2)
        print(f"Successfully wrote to {installed_file}")
        
        # Verify what was written
        with open(installed_file, 'r') as f:
            verification = f.read()
        print(f"Verification read: {repr(verification)}")
        
    except Exception as e:
        print(f"Error writing file: {e}")
        return 1
    
    print("=" * 50)
    print(f"✅ Debug installation completed!")
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)