#!/usr/bin/env python3
"""
SABOHUB - Quick Fix Deploy
Fix Edge Function deployment issues
"""

import os
import webbrowser
from dotenv import load_dotenv

def print_status(message, status="info"):
    icons = {"info": "📡", "success": "✅", "warning": "⚠️", "error": "❌"}
    icon = icons.get(status, "📡")
    print(f"{icon} {message}")

def main():
    load_dotenv()
    
    project_ref = os.getenv('SUPABASE_URL', '').replace("https://", "").replace(".supabase.co", "")
    
    print("🚨 EDGE FUNCTION BOOT ERROR - QUICK FIX")
    print("=" * 50)
    
    print_status(f"Project: {project_ref}", "info")
    print_status("Function has BOOT_ERROR - needs manual fix", "error")
    
    print("\n🔧 MANUAL FIX STEPS:")
    print("1. Open Supabase Dashboard")
    print("2. Go to Functions → create-employee")  
    print("3. Check function logs for specific error")
    print("4. Replace function code with working version")
    print("5. Verify environment variables are set")
    
    print("\n📝 WORKING FUNCTION CODE:")
    print("Copy this code to replace the broken function:")
    print("-" * 50)
    
    working_code = '''// Simple working Edge Function
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const supabaseUrl = Deno.env.get('SB_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SB_SERVICE_KEY') ?? '';
    
    if (!supabaseServiceKey) {
      throw new Error('Missing SB_SERVICE_KEY');
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const supabaseClient = createClient(supabaseUrl, Deno.env.get('SB_ANON_KEY') ?? '', {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { data: userData } = await supabaseClient.from('users').select('role').eq('id', user.id).single();
    if (userData?.role !== 'CEO') throw new Error('Only CEOs can create employees');

    const body = await req.json();
    const { email, password, role, company_id, full_name } = body;

    const { data: newUser, error } = await supabaseAdmin.auth.admin.createUser({
      email, password, email_confirm: true,
      user_metadata: { role, company_id, full_name: full_name || 'New Employee' }
    });

    if (error) throw new Error(`Failed to create user: ${error.message}`);

    await supabaseAdmin.from('users').upsert({
      id: newUser.user.id, email, role, company_id,
      full_name: full_name || 'New Employee', is_active: true,
      created_at: new Date().toISOString(), updated_at: new Date().toISOString()
    });

    return new Response(JSON.stringify({
      success: true,
      user: { id: newUser.user.id, email, role, company_id, full_name }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 201
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400
    });
  }
});'''
    
    print(working_code)
    print("-" * 50)
    
    print("\n🔐 ENVIRONMENT VARIABLES:")
    print("Ensure these are set in the function:")
    print(f"SB_URL = {os.getenv('SUPABASE_URL')}")
    print(f"SB_ANON_KEY = {os.getenv('SUPABASE_ANON_KEY')}")
    print(f"SB_SERVICE_KEY = {os.getenv('SUPABASE_SERVICE_ROLE_KEY')}")
    
    dashboard_url = f"https://supabase.com/dashboard/project/{project_ref}/functions"
    
    print(f"\n🌐 Opening Dashboard: {dashboard_url}")
    
    choice = input("\nOpen Supabase Dashboard now? (Y/n): ").strip().lower()
    if choice != 'n':
        webbrowser.open(dashboard_url)
        print_status("Dashboard opened! Fix the function and redeploy.", "success")
    
    print("\n📋 AFTER FIXING:")
    print("Run: python test_edge_function.py")
    print("Should work without BOOT_ERROR")

if __name__ == "__main__":
    main()