/**
 * CEO Telegram Daily Report Bot
 * 
 * Sends daily business summary to CEO via Telegram.
 * Can be triggered by: Supabase cron job, manual invoke, or webhook.
 * 
 * Required Supabase Secrets:
 *   TELEGRAM_BOT_TOKEN - from @BotFather on Telegram
 *   TELEGRAM_CHAT_ID   - CEO's chat ID (use @userinfobot to get it)
 * 
 * Deploy:
 *   supabase functions deploy telegram-notify
 *   supabase secrets set TELEGRAM_BOT_TOKEN=xxx TELEGRAM_CHAT_ID=xxx
 * 
 * Cron setup (in Supabase Dashboard > Database > Extensions > pg_cron):
 *   SELECT cron.schedule('daily-ceo-report', '0 20 * * *',
 *     $$SELECT net.http_post(
 *       url := 'https://dqddxowyikefqcdiioyh.supabase.co/functions/v1/telegram-notify',
 *       headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')),
 *       body := jsonb_build_object('type', 'daily_report')
 *     )$$
 *   );
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DailyStats {
  todayRevenue: number
  todayOrders: number
  completedOrders: number
  pendingOrders: number
  newCustomers: number
  totalCustomers: number
  attendanceRate: number
  employeeCount: number
  checkedInCount: number
  lateCount: number
  lowStockCount: number
  deliveryCount: number
  totalDebt: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')
    const TELEGRAM_CHAT_ID = Deno.env.get('TELEGRAM_CHAT_ID')

    if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) {
      return new Response(
        JSON.stringify({
          error: 'Missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID',
          setup: 'Run: supabase secrets set TELEGRAM_BOT_TOKEN=xxx TELEGRAM_CHAT_ID=xxx',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Parse request body
    const body = await req.json().catch(() => ({}))
    const companyId = body.company_id || '9f8921df-3760-44b5-9a7f-20f8484b0300' // Default: Odori
    const type = body.type || 'daily_report'

    let message = ''

    if (type === 'daily_report') {
      const stats = await getDailyStats(supabaseAdmin, companyId)
      message = formatDailyReport(stats)
    } else if (type === 'alert') {
      message = `⚠️ *CẢNH BÁO*\n\n${body.message || 'Có vấn đề cần chú ý.'}`
    } else if (type === 'test') {
      message = '✅ *SABOHUB Bot đã kết nối thành công!*\n\nBot sẽ gửi báo cáo hàng ngày lúc 20:00.'
    } else {
      message = body.message || '📢 Thông báo từ SABOHUB'
    }

    // Send via Telegram Bot API
    const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`
    const telegramResponse = await fetch(telegramUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TELEGRAM_CHAT_ID,
        text: message,
        parse_mode: 'Markdown',
        disable_web_page_preview: true,
      }),
    })

    const telegramResult = await telegramResponse.json()

    if (!telegramResult.ok) {
      throw new Error(`Telegram API error: ${JSON.stringify(telegramResult)}`)
    }

    return new Response(
      JSON.stringify({ success: true, message_id: telegramResult.result?.message_id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('telegram-notify error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function getDailyStats(supabase: any, companyId: string): Promise<DailyStats> {
  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]

  // Parallel queries for speed
  const [
    ordersResult,
    customersResult,
    newCustomersResult,
    employeesResult,
    attendanceResult,
    productsResult,
    deliveriesResult,
    debtResult,
  ] = await Promise.all([
    // Today's orders
    supabase
      .from('sales_orders')
      .select('total, status')
      .eq('company_id', companyId)
      .gte('created_at', `${todayStr}T00:00:00`),
    // Total active customers
    supabase
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true),
    // New customers today
    supabase
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .gte('created_at', `${todayStr}T00:00:00`),
    // Active employees
    supabase
      .from('employees')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true),
    // Today's attendance
    supabase
      .from('attendance')
      .select('employee_id, is_late')
      .eq('company_id', companyId)
      .gte('check_in_time', `${todayStr}T00:00:00`)
      .lte('check_in_time', `${todayStr}T23:59:59`),
    // Low stock products
    supabase
      .rpc('get_low_stock_count', { p_company_id: companyId })
      .single(),
    // Today's deliveries
    supabase
      .from('deliveries')
      .select('status', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .gte('created_at', `${todayStr}T00:00:00`),
    // Outstanding debt
    supabase
      .from('sales_orders')
      .select('total, paid_amount')
      .eq('company_id', companyId)
      .neq('status', 'cancelled'),
  ])

  // Calculate revenue
  const orders = ordersResult.data || []
  let todayRevenue = 0
  let completedOrders = 0
  let pendingOrders = 0
  for (const o of orders) {
    todayRevenue += o.total || 0
    if (o.status === 'completed' || o.status === 'delivered') completedOrders++
    if (o.status === 'pending' || o.status === 'confirmed') pendingOrders++
  }

  // Attendance
  const attendance = attendanceResult.data || []
  const checkedInCount = attendance.length
  const lateCount = attendance.filter((a: any) => a.is_late).length
  const employeeCount = employeesResult.count || 0

  // Debt
  let totalDebt = 0
  for (const o of (debtResult.data || [])) {
    const debt = (o.total || 0) - (o.paid_amount || 0)
    if (debt > 0) totalDebt += debt
  }

  return {
    todayRevenue,
    todayOrders: orders.length,
    completedOrders,
    pendingOrders,
    newCustomers: newCustomersResult.count || 0,
    totalCustomers: customersResult.count || 0,
    attendanceRate: employeeCount > 0 ? Math.round((checkedInCount / employeeCount) * 100) : 0,
    employeeCount,
    checkedInCount,
    lateCount,
    lowStockCount: productsResult.data?.count || 0,
    deliveryCount: deliveriesResult.count || 0,
    totalDebt,
  }
}

function formatDailyReport(stats: DailyStats): string {
  const now = new Date()
  const dateStr = `${now.getDate().toString().padStart(2, '0')}/${(now.getMonth() + 1).toString().padStart(2, '0')}/${now.getFullYear()}`
  
  const formatVND = (n: number) => new Intl.NumberFormat('vi-VN').format(n) + '₫'

  return `📊 *BÁO CÁO NGÀY ${dateStr}*
━━━━━━━━━━━━━━━━
  
💰 *DOANH THU*
• Hôm nay: *${formatVND(stats.todayRevenue)}*
• Đơn hàng: ${stats.todayOrders} (✅${stats.completedOrders} | ⏳${stats.pendingOrders})

👥 *KHÁCH HÀNG*
• Tổng: ${stats.totalCustomers.toLocaleString()}
• Mới hôm nay: +${stats.newCustomers}

👨‍💼 *NHÂN SỰ*
• Chấm công: ${stats.checkedInCount}/${stats.employeeCount} (${stats.attendanceRate}%)
• Đi trễ: ${stats.lateCount}

📦 *VẬN HÀNH*
• Giao hàng: ${stats.deliveryCount} chuyến
• Tồn kho thấp: ${stats.lowStockCount} SP

💳 *CÔNG NỢ*
• Tổng: *${formatVND(stats.totalDebt)}*

━━━━━━━━━━━━━━━━
🔗 [Xem chi tiết](https://sabohub-app.vercel.app)
_SABOHUB Daily Report_`
}
