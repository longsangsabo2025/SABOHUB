#!/usr/bin/env python3
"""
SABOHUB - Complete Setup Script
Auto-setup Edge Functions and test CEO employee creation feature
"""

import os
import sys
import json
import webbrowser
from pathlib import Path
from dotenv import load_dotenv

def print_banner():
    banner = """
╔═══════════════════════════════════════════════════════════╗
║                🚀 SABOHUB AUTO SETUP 🚀                  ║
║            CEO Employee Creation Feature                   ║
╚═══════════════════════════════════════════════════════════╝
"""
    print(banner)

def print_status(message, status="info"):
    icons = {"info": "📡", "success": "✅", "warning": "⚠️", "error": "❌"}
    icon = icons.get(status, "📡")
    print(f"{icon} {message}")

def check_environment():
    """Check if all required files exist"""
    print_status("Checking project structure...", "info")
    
    required_files = [
        ".env",
        "supabase/functions/create-employee/index.ts",
        "lib/services/employee_service.dart",
        "lib/pages/ceo/create_employee_dialog.dart"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing_files.append(file_path)
    
    if missing_files:
        print_status("Missing required files:", "error")
        for file in missing_files:
            print(f"   ❌ {file}")
        return False
    
    print_status("All required files found!", "success")
    return True

def load_config():
    """Load Supabase configuration"""
    print_status("Loading Supabase configuration...", "info")
    
    load_dotenv()
    
    config = {
        "url": os.getenv('SUPABASE_URL'),
        "anon_key": os.getenv('SUPABASE_ANON_KEY'),
        "service_key": os.getenv('SUPABASE_SERVICE_ROLE_KEY'),
    }
    
    if not all(config.values()):
        print_status("Missing Supabase credentials in .env file", "error")
        return None
    
    # Extract project reference
    config["project_ref"] = config["url"].replace("https://", "").replace(".supabase.co", "")
    
    print_status(f"Project: {config['project_ref']}", "success")
    return config

def show_deployment_guide(config):
    """Show step-by-step deployment guide"""
    print()
    print("═" * 70)
    print("📝 DEPLOYMENT GUIDE - Follow these steps:")
    print("═" * 70)
    print()
    
    dashboard_url = f"https://supabase.com/dashboard/project/{config['project_ref']}/functions"
    
    print("🎯 STEP 1: Deploy Edge Function (5 minutes)")
    print(f"   Visit: {dashboard_url}")
    print("   1. Click 'New Function'")
    print("   2. Name: create-employee") 
    print("   3. Copy code from: supabase/functions/create-employee/index.ts")
    print("   4. Click 'Deploy'")
    print()
    
    print("🔐 STEP 2: Set Environment Variables")
    print("   In the function dashboard, add these 3 secrets:")
    print()
    print("   Secret 1:")
    print(f"   Name:  SUPABASE_URL")
    print(f"   Value: {config['url']}")
    print()
    print("   Secret 2:")
    print(f"   Name:  SUPABASE_ANON_KEY") 
    print(f"   Value: {config['anon_key']}")
    print()
    print("   Secret 3:")
    print(f"   Name:  SUPABASE_SERVICE_ROLE_KEY")
    print(f"   Value: {config['service_key']}")
    print()
    
    print("🧪 STEP 3: Test")
    print("   Run: python test_edge_function.py")
    print("   Or test in Flutter app: Login as CEO → Create employee")
    print()
    
    print("═" * 70)
    
    # Auto-open browser
    choice = input("Open Supabase Dashboard now? (Y/n): ").strip().lower()
    if choice != 'n':
        print_status("Opening browser...", "info")
        webbrowser.open(dashboard_url)
        print_status("Dashboard opened!", "success")

def show_files_summary():
    """Show summary of created files"""
    print()
    print("📁 FILES READY FOR DEPLOYMENT:")
    print()
    
    files = [
        ("supabase/functions/create-employee/index.ts", "Edge Function code"),
        ("supabase/functions/.env", "Environment variables"),
        ("lib/services/employee_service.dart", "Flutter service"),
        ("lib/pages/ceo/create_employee_dialog.dart", "UI Dialog"),
        ("auto_deploy_function.py", "Python deployment script"),
        ("test_edge_function.py", "Python test script"),
        ("QUICK-DEPLOY-3MIN.md", "Quick deployment guide")
    ]
    
    for file_path, description in files:
        status = "✅" if Path(file_path).exists() else "❌"
        print(f"   {status} {file_path:<45} - {description}")

def show_architecture():
    """Show system architecture"""
    print()
    print("🏗️ ARCHITECTURE:")
    print()
    print("   CEO (Flutter App)")
    print("        ↓")
    print("   EmployeeService.createEmployeeAccount()")
    print("        ↓")
    print("   Edge Function: create-employee")
    print("        ↓")
    print("   Supabase Auth.createUser() + Users table")
    print("        ↓")
    print("   Return credentials to CEO")
    print("        ↓")
    print("   Employee can login!")
    print()

def main():
    try:
        print_banner()
        
        # Check project structure
        if not check_environment():
            print_status("Please run this script from the project root directory", "error")
            sys.exit(1)
        
        # Load configuration
        config = load_config()
        if not config:
            sys.exit(1)
        
        # Show files summary
        show_files_summary()
        
        # Show architecture
        show_architecture()
        
        # Show deployment guide
        show_deployment_guide(config)
        
        print()
        print_status("🎉 Setup complete! Follow the deployment guide above.", "success")
        print_status("After deployment, test with: python test_edge_function.py", "info")
        print()
        
    except KeyboardInterrupt:
        print_status("Setup cancelled by user", "warning")
        sys.exit(1)
    except Exception as e:
        print_status(f"Unexpected error: {str(e)}", "error")
        sys.exit(1)

if __name__ == "__main__":
    main()