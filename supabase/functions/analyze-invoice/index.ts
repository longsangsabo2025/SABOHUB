// Supabase Edge Function: analyze-invoice
// Nhận ảnh hóa đơn → Gemini Vision phân tích → trả JSON kết quả
// Tự động phân loại chi phí và trích xuất thông tin

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

// Expense categories mapping
const EXPENSE_CATEGORIES = {
  salary: { vi: 'Lương nhân viên', dbColumn: 'salary_expenses' },
  rent: { vi: 'Mặt bằng', dbColumn: 'rent_expense' },
  electricity: { vi: 'Điện / Nước / Internet', dbColumn: 'electricity_expense' },
  advertising: { vi: 'Quảng cáo', dbColumn: 'advertising_expense' },
  invoiced_purchases: {
    vi: 'Nhập hàng có hóa đơn',
    dbColumn: 'invoiced_purchases',
  },
  equipment_maintenance: {
    vi: 'Sửa chữa / Bảo trì thiết bị',
    dbColumn: 'other_purchases',
  },
  other_purchases: {
    vi: 'Mua hàng hóa/vật dụng khác',
    dbColumn: 'other_purchases',
  },
  other: { vi: 'Chi phí khác', dbColumn: 'other_expenses' },
};

const GEMINI_PROMPT = `Bạn là trợ lý kế toán AI chuyên phân tích hóa đơn, chứng từ, biên lai cho QUÁN BIDA (billiard club).

## LOẠI CHỨNG TỪ BẠN SẼ GẶP:
1. Hóa đơn VAT / hóa đơn bán hàng
2. Bill thanh toán từ cửa hàng
3. **Biên lai chuyển khoản ngân hàng** (VietinBank, Vietcombank, MB, BIDV, ACB, Techcombank, v.v.)
4. Ảnh chụp màn hình banking app
5. Phiếu thu / phiếu chi
6. Biên nhận tiền mặt

## CÁCH ĐỌC BIÊN LAI CHUYỂN KHOẢN:
- "Số tiền" / "Amount" → amount
- "Nội dung" / "Lời nhắn" / "Ghi chú" → dùng để PHÂN LOẠI chi phí và viết description
- "Đến tài khoản" / người nhận → vendor
- "Ngày" / timestamp → invoice_date  
- "Mã giao dịch" → invoice_number

## CHI PHÍ ĐẶC THÙ QUÁN BIDA (rất quan trọng):
- "sửa cơ", "bọc cơ", "đầu cơ", "tip cơ" → equipment_maintenance (sửa chữa gậy bida)
- "bọc nỉ", "thay nỉ", "nỉ bàn", "thay mặt bàn" → equipment_maintenance (bảo trì bàn bida)
- "bi", "quả bi", "bộ bi" → equipment_maintenance (thay bi bida)
- "phấn", "phấn bi-a", "chalk" → other_purchases (vật tư tiêu hao)
- "bia", "nước", "nước ngọt", "đá", "café", "cà phê", "trà" → invoiced_purchases (đồ uống nhập kho)
- "đồ ăn", "mì", "snack", "khô", "bò khô" → invoiced_purchases (đồ ăn nhập kho)
- "điện", "EVN", "tiền điện", "nước sinh hoạt", "internet", "wifi", "FPT", "VNPT", "Viettel" → electricity
- "thuê", "mặt bằng", "tiền nhà", "tiền phòng" → rent
- "lương", "công", "bảo hiểm" → salary
- "ads", "quảng cáo", "facebook", "google", "banner", "tờ rơi" → advertising
- "sửa chữa", "thợ sửa", "bảo trì", "sơn", "điện nước (thợ)" → equipment_maintenance

## OUTPUT FORMAT:
Trả về JSON duy nhất:
{
  "category": "salary|rent|electricity|advertising|invoiced_purchases|equipment_maintenance|other_purchases|other",
  "amount": <số tiền VND, chỉ số nguyên, không có chữ, không có dấu phẩy>,
  "vendor": "<tên người nhận tiền / nhà cung cấp / tên trên biên lai>",
  "invoice_date": "<ngày giao dịch, format YYYY-MM-DD, null nếu không rõ>",
  "invoice_number": "<mã giao dịch / số hóa đơn, null nếu không có>",
  "description": "<mô tả ngắn gọn bằng tiếng Việt, kết hợp nội dung chuyển khoản + loại chứng từ>",
  "confidence": <0.0-1.0>,
  "items": [{"name": "<tên>", "quantity": 1, "unit_price": <giá>, "total": <tổng>}],
  "document_type": "invoice|bank_transfer|receipt|cash_note|other"
}

## QUY TẮC:
1. Đọc KỸ nội dung chuyển khoản / ghi chú để phân loại chính xác
2. Nếu nội dung ghi "sửa cơ", "sua co" → category = equipment_maintenance, description phải ghi rõ "Sửa cơ bida"
3. Nếu không rõ loại → category = "other", confidence thấp
4. Amount luôn là số nguyên VND (vd: 1400000), KHÔNG có dấu phẩy hay chữ
5. Với biên lai ngân hàng: vendor = tên người NHẬN tiền

CHỈ trả về JSON, không giải thích gì thêm.`;

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const contentType = req.headers.get('content-type') || '';

    let imageBase64: string;
    let mimeType: string;
    let companyId: string;
    let employeeId: string | null = null;

    if (contentType.includes('application/json')) {
      // JSON body with base64 image
      const body = await req.json();
      imageBase64 = body.image_base64;
      mimeType = body.mime_type || 'image/jpeg';
      companyId = body.company_id;
      employeeId = body.employee_id || null;

      if (!imageBase64 || !companyId) {
        return new Response(
          JSON.stringify({
            error: 'Missing required fields: image_base64, company_id',
          }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    } else {
      return new Response(
        JSON.stringify({ error: 'Content-Type must be application/json' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // ═══════════════════════════════════════════
    // Call Gemini Vision API
    // ═══════════════════════════════════════════
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`;

    const geminiBody = {
      contents: [
        {
          parts: [
            { text: GEMINI_PROMPT },
            {
              inline_data: {
                mime_type: mimeType,
                data: imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      },
    };

    const geminiRes = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(geminiBody),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      console.error('Gemini API error:', errText);
      return new Response(
        JSON.stringify({
          error: 'Gemini API error',
          details: errText,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const geminiData = await geminiRes.json();

    // Extract text from Gemini response
    const rawText =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // Parse JSON from Gemini response
    let analysisResult;
    try {
      // Clean up potential markdown code blocks
      const cleaned = rawText
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      analysisResult = JSON.parse(cleaned);
    } catch {
      console.error('Failed to parse Gemini response:', rawText);
      return new Response(
        JSON.stringify({
          error: 'Failed to parse AI response',
          raw_response: rawText,
        }),
        {
          status: 422,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Validate category
    const validCategories = Object.keys(EXPENSE_CATEGORIES);
    if (!validCategories.includes(analysisResult.category)) {
      analysisResult.category = 'other';
    }

    // ═══════════════════════════════════════════
    // Save to expense_transactions table
    // ═══════════════════════════════════════════
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Determine the target month from invoice date or current date
    const invoiceDate = analysisResult.invoice_date || null;
    let targetMonth: string;
    if (invoiceDate) {
      const d = new Date(invoiceDate);
      targetMonth = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`;
    } else {
      const now = new Date();
      targetMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    }

    // Save transaction record
    const { data: txRecord, error: txError } = await supabaseClient
      .from('expense_transactions')
      .insert({
        company_id: companyId,
        category: analysisResult.category,
        amount: analysisResult.amount || 0,
        vendor: analysisResult.vendor || null,
        invoice_date: invoiceDate,
        invoice_number: analysisResult.invoice_number || null,
        description: analysisResult.description || null,
        target_month: targetMonth,
        confidence: analysisResult.confidence || 0,
        ai_raw_response: analysisResult,
        status: 'pending', // pending → confirmed → applied
        created_by: employeeId,
        items: analysisResult.items || [],
      })
      .select()
      .single();

    if (txError) {
      console.error('DB insert error:', txError);
      // Still return the analysis even if DB save fails
      return new Response(
        JSON.stringify({
          success: true,
          analysis: analysisResult,
          saved: false,
          db_error: txError.message,
          category_info:
            EXPENSE_CATEGORIES[
              analysisResult.category as keyof typeof EXPENSE_CATEGORIES
            ],
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        analysis: analysisResult,
        transaction_id: txRecord.id,
        target_month: targetMonth,
        saved: true,
        category_info:
          EXPENSE_CATEGORIES[
            analysisResult.category as keyof typeof EXPENSE_CATEGORIES
          ],
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err) {
    console.error('Unexpected error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
