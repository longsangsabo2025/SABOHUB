/**
 * SABOHUB Health Check Endpoint
 * 
 * Returns system health status for uptime monitoring.
 * Use with Uptime Kuma, BetterStack, or any monitoring service.
 * 
 * Checks:
 *   - Edge Function runtime (always passes if this runs)
 *   - Supabase DB connectivity
 *   - Table accessibility
 * 
 * Deploy:
 *   supabase functions deploy health-check
 * 
 * Monitor URL:
 *   https://dqddxowyikefqcdiioyh.supabase.co/functions/v1/health-check
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

serve(async (req) => {
  const startTime = Date.now()

  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const checks: Record<string, { status: string; latency?: number; error?: string }> = {}

  // Check 1: Runtime (always passes)
  checks['runtime'] = { status: 'ok' }

  // Check 2: Database connectivity
  try {
    const dbStart = Date.now()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data, error } = await supabase
      .from('companies')
      .select('id')
      .limit(1)

    if (error) throw error

    checks['database'] = {
      status: 'ok',
      latency: Date.now() - dbStart,
    }
  } catch (e) {
    checks['database'] = {
      status: 'error',
      error: e.message,
    }
  }

  // Check 3: Auth service
  try {
    const authStart = Date.now()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    // Just check that auth endpoint responds
    const { error } = await supabase.auth.getSession()
    checks['auth'] = {
      status: error ? 'degraded' : 'ok',
      latency: Date.now() - authStart,
    }
  } catch (e) {
    checks['auth'] = {
      status: 'error',
      error: e.message,
    }
  }

  // Check 4: Storage
  try {
    const storageStart = Date.now()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { error } = await supabase.storage.listBuckets()
    checks['storage'] = {
      status: error ? 'degraded' : 'ok',
      latency: Date.now() - storageStart,
    }
  } catch (e) {
    checks['storage'] = {
      status: 'error',
      error: e.message,
    }
  }

  // Determine overall status
  const allStatuses = Object.values(checks).map((c) => c.status)
  let overallStatus = 'healthy'
  if (allStatuses.includes('error')) overallStatus = 'unhealthy'
  else if (allStatuses.includes('degraded')) overallStatus = 'degraded'

  const totalLatency = Date.now() - startTime

  const response = {
    status: overallStatus,
    version: '1.1.0',
    timestamp: new Date().toISOString(),
    latency: `${totalLatency}ms`,
    checks,
    uptime: {
      note: 'Edge Function is stateless. Track uptime via external monitor.',
    },
  }

  const httpStatus = overallStatus === 'healthy' ? 200 : overallStatus === 'degraded' ? 200 : 503

  return new Response(JSON.stringify(response, null, 2), {
    status: httpStatus,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
    },
  })
})
