#!/usr/bin/env python3
"""
Test create-employee Edge Function after deployment
Quick Python script to test if Edge Function is working
"""

import os
import requests
import json
from dotenv import load_dotenv

def print_status(message, emoji="📡"):
    print(f"{emoji} {message}")

def main():
    print_status("Testing create-employee Edge Function...", "🧪")
    print()
    
    # Load environment
    load_dotenv()
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_anon_key = os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_anon_key:
        print_status("Missing Supabase credentials in .env", "❌")
        return
    
    # Test endpoint
    endpoint = f"{supabase_url}/functions/v1/create-employee"
    print_status(f"Testing endpoint: {endpoint}", "📡")
    
    # Get CEO token from user
    print_status("You need a CEO auth token to test", "📋")
    print("How to get token:")
    print("1. Login as CEO in browser")
    print("2. Open DevTools (F12)")
    print("3. Go to Application > Local Storage > supabase.auth.token")
    print("4. Copy the 'access_token' value")
    print()
    
    ceo_token = input("Enter CEO auth token: ").strip()
    if not ceo_token:
        print_status("Token required to test", "❌")
        return
    
    print()
    
    # Test data
    test_data = {
        "email": f"teststaff{int(__import__('time').time())}@sabohub.com",
        "password": "TempPass123!",
        "role": "STAFF", 
        "company_id": input("Enter Company ID (UUID): ").strip(),
        "full_name": "Test Employee"
    }
    
    if not test_data["company_id"]:
        print_status("Company ID required", "❌")
        return
    
    print()
    print_status("Sending test request...", "📡")
    
    # Make request
    headers = {
        "Authorization": f"Bearer {ceo_token}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            endpoint,
            headers=headers,
            json=test_data,
            timeout=30
        )
        
        print_status(f"Status Code: {response.status_code}", "📊")
        
        if response.status_code == 201:
            print_status("SUCCESS! Employee created!", "✅")
            result = response.json()
            print()
            print("═══════════════════════════════════════")
            print_status(f"📧 Email:    {result['user']['email']}", "")
            print_status(f"🔒 Password: {test_data['password']}", "")
            print_status(f"👤 Role:     {result['user']['role']}", "")
            print_status(f"🆔 User ID:  {result['user']['id']}", "")
            print("═══════════════════════════════════════")
            print()
            print_status("Employee can login with these credentials!", "✅")
            
        elif response.status_code == 401:
            print_status("UNAUTHORIZED - Check CEO token", "❌")
            print_status("Token may be expired or invalid", "⚠️")
            
        elif response.status_code == 404:
            print_status("FUNCTION NOT FOUND", "❌")
            print_status("Edge Function not deployed yet", "⚠️")
            print_status("Please deploy via Supabase Dashboard first", "📝")
            
        else:
            print_status(f"ERROR {response.status_code}", "❌")
            try:
                error_data = response.json()
                print_status(f"Error: {error_data.get('error', 'Unknown')}", "⚠️")
            except:
                print_status(f"Response: {response.text[:200]}", "⚠️")
                
    except requests.exceptions.RequestException as e:
        print_status(f"Request failed: {str(e)}", "❌")
        print_status("Check network connection and Edge Function deployment", "⚠️")

if __name__ == "__main__":
    main()