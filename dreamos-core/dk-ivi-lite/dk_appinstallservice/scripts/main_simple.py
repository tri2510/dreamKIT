#!/usr/bin/env python3

import json
import os
import sys
import time

def main():
    print("=== DK App Install Service (Embedded Mode) ===")
    
    # Check if the file path is passed as an argument
    if len(sys.argv) != 2:
        print("Usage: python main_simple.py <data.json>")
        return 1
    
    # Get the file path from the command-line arguments
    json_installcfg_path = sys.argv[1]
    print(f"Processing installation config: {json_installcfg_path}")
    
    # Determine the base directory for .dk folder
    # In container environments, use DK_CONTAINER_ROOT if available
    dk_container_root = os.getenv("DK_CONTAINER_ROOT")
    if dk_container_root:
        dk_base_dir = dk_container_root
        if not dk_base_dir.endswith("/"):
            dk_base_dir += "/"
        dk_base_dir = dk_base_dir.rstrip("/")  # Remove trailing slash for consistency
        print(f"Using DK_CONTAINER_ROOT: {dk_base_dir}")
    else:
        # Fallback to user home directory
        dk_user = os.getenv("DK_USER", os.getenv("USER", "root"))
        dk_base_dir = f"/home/{dk_user}/.dk"
        print(f"Using user home directory: {dk_base_dir}")
    
    print(f"DK base directory: {dk_base_dir}")
    
    # Read installation config
    try:
        with open(json_installcfg_path, 'r') as file:
            json_data = json.load(file)
        print(f"Loaded installation config successfully")
    except FileNotFoundError:
        print(f"Error: {json_installcfg_path} file not found.")
        return 1
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse {json_installcfg_path} - {e}")
        return 1
    
    # Extract basic info
    app_id = json_data.get('_id', 'unknown')
    name = json_data.get('name', 'Unknown App')
    category = json_data.get('category', 'unknown')
    
    print(f"App ID: {app_id}")
    print(f"App Name: {name}")
    print(f"Category: {category}")
    
    # Determine target directory based on category
    if category == "vehicle":
        root_folder = f"{dk_base_dir}/dk_installedapps/"
        installed_file = f"{root_folder}installedapps.json"
        print("Installing vehicle app...")
    elif category == "vehicle-service":
        root_folder = f"{dk_base_dir}/dk_installedservices/"
        installed_file = f"{root_folder}installedservices.json"
        print("Installing vehicle service...")
    else:
        print(f"Error: Unsupported category '{category}'")
        return 1
    
    app_folder = f"{root_folder}{app_id}"
    print(f"App folder: {app_folder}")
    print(f"Installed file: {installed_file}")
    
    # Create directories
    print("Creating directories...")
    os.makedirs(root_folder, exist_ok=True)
    os.makedirs(app_folder, exist_ok=True)
    
    # Create runtime config file
    runtime_cfg_file = f"{app_folder}/runtimecfg.json"
    with open(runtime_cfg_file, 'w') as f:
        json.dump({}, f, indent=2)
    print(f"Created runtime config: {runtime_cfg_file}")
    
    # Create deployment status file for embedded mode
    deployment_status_file = f"{app_folder}/deployment_status.json"
    deployment_info = {
        "app_id": app_id,
        "name": name,
        "category": category,
        "deployment_mode": "embedded",
        "status": "deployed",
        "timestamp": time.time()
    }
    
    with open(deployment_status_file, 'w') as f:
        json.dump(deployment_info, f, indent=2)
    print(f"Created deployment status: {deployment_status_file}")
    
    # Update installed apps/services list
    print("Updating installed apps list...")
    print(f"Target file: {installed_file}")
    
    # Read existing installed list with detailed logging
    installed_list = []
    if os.path.exists(installed_file):
        print(f"File exists, reading...")
        try:
            with open(installed_file, 'r') as f:
                content = f.read()
            print(f"Raw file content: {repr(content)}")
            
            if content.strip():
                installed_list = json.loads(content)
                print(f"Parsed JSON successfully: {installed_list}")
                print(f"Number of items in list: {len(installed_list)}")
            else:
                print("File is empty or whitespace, starting with empty list")
                installed_list = []
        except (json.JSONDecodeError, FileNotFoundError) as e:
            print(f"Error reading file: {e}")
            print("Starting with empty list")
            installed_list = []
    else:
        print("File does not exist, creating new list")
    
    print(f"Current installed list: {installed_list}")
    
    # Check if app is already in the list
    app_already_installed = False
    for i, item in enumerate(installed_list):
        print(f"Checking item {i}: {item}")
        if item.get('_id') == app_id:
            app_already_installed = True
            print(f"✅ Found app {app_id} at index {i}")
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
        print(f"➕ Added {name} to installed list")
        print(f"New list: {installed_list}")
    else:
        print(f"App {app_id} already in list, skipping addition")
    
    # Write updated installed list with verification
    print(f"Writing to file: {installed_file}")
    try:
        with open(installed_file, 'w') as f:
            json.dump(installed_list, f, indent=2)
        print("✅ File written successfully")
        
        # Verify what was written
        with open(installed_file, 'r') as f:
            verification = f.read()
        print(f"📋 Verification read: {repr(verification)}")
        
    except Exception as e:
        print(f"❌ Error writing file: {e}")
        return 1
    
    print(f"✅ Updated installed list: {installed_file}")
    
    print("=" * 50)
    print(f"✅ Installation completed successfully!")
    print(f"App: {name} ({app_id})")
    print(f"Category: {category}")
    print(f"Installation folder: {app_folder}")
    print(f"Registered in: {installed_file}")
    print("=" * 50)
    
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)