#!/usr/bin/env python3
"""
SABOHUB - Update Function Secrets Only
Chỉ update environment variables với tên mới
"""

import os
import requests
from dotenv import load_dotenv

def print_status(message, status="info"):
    icons = {"info": "📡", "success": "✅", "warning": "⚠️", "error": "❌"}
    icon = icons.get(status, "📡")
    print(f"{icon} {message}")

def main():
    print("🔐 SABOHUB - Update Function Secrets")
    print("=" * 42)
    
    load_dotenv()
    
    config = {
        "url": os.getenv('SUPABASE_URL'),
        "anon_key": os.getenv('SUPABASE_ANON_KEY'),
        "service_key": os.getenv('SUPABASE_SERVICE_ROLE_KEY'),
        "access_token": "sbp_80a51e44c740fae0a8ecee4523c4c952d3b2e921"
    }
    
    project_ref = config["url"].replace("https://", "").replace(".supabase.co", "")
    print_status(f"Project: {project_ref}", "info")
    
    # Update secrets với tên mới
    secrets_url = f"https://api.supabase.com/v1/projects/{project_ref}/secrets"
    
    headers = {
        "Authorization": f"Bearer {config['access_token']}",
        "Content-Type": "application/json",
    }
    
    secrets = [
        {"name": "SB_URL", "value": config["url"]},
        {"name": "SB_ANON_KEY", "value": config["anon_key"]}, 
        {"name": "SB_SERVICE_KEY", "value": config["service_key"]}
    ]
    
    print_status("Setting new secret names...", "info")
    
    try:
        response = requests.post(secrets_url, headers=headers, json=secrets, timeout=15)
        
        if response.status_code in [200, 201]:
            print_status("✅ All secrets updated!", "success")
            
            print("\n📊 Environment Variables Set:")
            print("   SB_URL = ✅")
            print("   SB_ANON_KEY = ✅") 
            print("   SB_SERVICE_KEY = ✅")
            
        else:
            print_status(f"API Error: {response.text}", "error")
            
            print("\n📝 Manual Setup Required:")
            print("Go to: https://supabase.com/dashboard/project/{}/functions".format(project_ref))
            print("Add these secrets:")
            print(f"   SB_URL = {config['url']}")
            print(f"   SB_ANON_KEY = {config['anon_key']}")
            print(f"   SB_SERVICE_KEY = {config['service_key']}")
            
    except Exception as e:
        print_status(f"Request error: {str(e)}", "error")
        
        print("\n📝 Manual Setup Required:")
        print("Go to: https://supabase.com/dashboard/project/{}/functions".format(project_ref))
        print("Add these secrets:")
        print(f"   SB_URL = {config['url']}")
        print(f"   SB_ANON_KEY = {config['anon_key']}")
        print(f"   SB_SERVICE_KEY = {config['service_key']}")
    
    print("\n🚀 Next Steps:")
    print("1. Function code updated in local file")
    print("2. Copy updated code to Supabase Dashboard if needed")
    print("3. Test: python test_edge_function.py")

if __name__ == "__main__":
    main()