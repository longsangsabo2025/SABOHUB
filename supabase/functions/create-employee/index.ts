// ============================================================================
// CREATE EMPLOYEE EDGE FUNCTION
// ============================================================================
// Handles employee account creation by CEO
// Uses admin API to create user without affecting CEO's auth session
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get auth token
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    // Create Supabase client with service role (for admin access)
    const supabaseUrl = Deno.env.get('SB_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SB_SERVICE_KEY') ?? '';
    
    if (!supabaseServiceKey) {
      throw new Error('Missing SB_SERVICE_KEY');
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Verify CEO is making the request
    const supabaseClient = createClient(
      supabaseUrl,
      Deno.env.get('SB_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();

    if (!user) {
      throw new Error('Unauthorized');
    }

    // Check if user is CEO
    const { data: userData, error: userError } = await supabaseClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (userError || userData?.role !== 'CEO') {
      throw new Error('Only CEOs can create employees');
    }

    // Parse request body
    const body = await req.json();
    const { email, password, role, company_id, full_name } = body;

    // Validate required fields
    if (!email || !password || !role || !company_id) {
      throw new Error('Missing required fields: email, password, role, company_id');
    }

    // Create auth user using admin API
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        role,
        company_id,
        full_name: full_name || 'New Employee',
      },
    });

    if (createError || !newUser.user) {
      console.error('Create user error:', createError);
      throw new Error(`Failed to create auth user: ${createError?.message || 'Unknown error'}`);
    }

    // Create/update user record in users table
    const { error: dbError } = await supabaseAdmin.from('users').upsert({
      id: newUser.user.id,
      email,
      role,
      company_id,
      full_name: full_name || 'New Employee',
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (dbError) {
      console.error('Database error:', dbError);
      // Try to delete auth user if database insert fails
      await supabaseAdmin.auth.admin.deleteUser(newUser.user.id);
      throw new Error(`Failed to create user record: ${dbError.message}`);
    }

    // Return success
    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: newUser.user.id,
          email,
          role,
          company_id,
          full_name,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 201,
      }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
