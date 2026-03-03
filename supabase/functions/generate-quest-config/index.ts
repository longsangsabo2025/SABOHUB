import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_PROMPT = `You are an expert game designer for SABOHUB — a business management app gamified as an RPG.

Given a business type, you must generate:
1. A "config" array — mapping abstract concepts to concrete database tables for this business.
2. A "quests" array — custom quests tailored to this specific business type.

## Config Format
Each config entry maps an abstract concept to a concrete reality:
- concept: one of "primary_transaction", "revenue_event", "inventory_object", "customer_object", "delivery_object", "workspace_object", "peak_hours", "daily_transaction_target"
- table_name: the Supabase table name (or null for metadata-only concepts)
- filter: JSON filter applied when querying (e.g. {"status": "completed"})
- display_name: Vietnamese display name (singular)
- display_name_plural: Vietnamese display name (plural)
- icon: Material icon name
- metadata: extra data (e.g. {"threshold": 5} for targets, {"start": 8, "end": 17} for hours)

## Quest Format  
Each quest is a custom quest for this business type:
- code: unique snake_case identifier (prefix with business type)
- name: Vietnamese quest name (catchy, RPG-style)
- description: Vietnamese description
- quest_type: "main", "daily", "weekly", or "boss"
- act: 2 (business-specific quests go in Act II)
- category: "operate", "sell", or "finance"
- conditions: JSONB condition for the quest engine
- xp_reward: 50-500
- reputation_reward: 5-50
- sort_order: ordering number

## Important Rules
- All text MUST be in Vietnamese
- Quest names should be fun, RPG-themed
- Quests should reflect real KPIs for this business type
- Generate 5-8 quests per business type
- Include a mix of operate/sell/finance categories
- Include at least one "boss" type quest (hard challenge)

Respond with ONLY valid JSON, no markdown:
{"config": [...], "quests": [...]}`;

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { company_id, business_type } = await req.json();

    if (!company_id || !business_type) {
      return new Response(
        JSON.stringify({ error: 'company_id and business_type required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Fetch company info for context
    const { data: company } = await supabase
      .from('companies')
      .select('name, business_type, employee_count, monthly_revenue')
      .eq('id', company_id)
      .single();

    // Fetch existing configs as reference
    const { data: existingConfigs } = await supabase
      .from('business_type_config')
      .select('*')
      .limit(10);

    // Fetch existing quest templates as reference
    const { data: existingTemplates } = await supabase
      .from('quest_templates')
      .select('code, name_pattern, quest_type, concept')
      .limit(10);

    const userPrompt = `Generate gamification config for business type: "${business_type}"

Company context:
- Name: ${company?.name ?? 'Unknown'}
- Type: ${business_type}
- Employees: ${company?.employee_count ?? 'Unknown'}
- Monthly Revenue: ${company?.monthly_revenue ?? 'Unknown'}

Reference existing configs (use similar structure):
${JSON.stringify(existingConfigs?.slice(0, 5) ?? [], null, 2)}

Reference existing quest templates:
${JSON.stringify(existingTemplates ?? [], null, 2)}

Generate the config and quests JSON now.`;

    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            { role: 'user', parts: [{ text: SYSTEM_PROMPT + '\n\n' + userPrompt }] },
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 4096,
            responseMimeType: 'application/json',
          },
        }),
      }
    );

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      throw new Error(`Gemini API error: ${geminiResponse.status} ${errText}`);
    }

    const geminiData = await geminiResponse.json();
    const rawText =
      geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}';

    let generated: { config: unknown[]; quests: unknown[] };
    try {
      generated = JSON.parse(rawText);
    } catch {
      const jsonMatch = rawText.match(/\{[\s\S]*\}/);
      generated = jsonMatch ? JSON.parse(jsonMatch[0]) : { config: [], quests: [] };
    }

    // Store in DB for CEO review
    const { data: inserted, error: insertError } = await supabase
      .from('ai_generated_configs')
      .insert({
        company_id,
        business_type,
        generated_config: generated.config ?? [],
        generated_quests: generated.quests ?? [],
        ai_model: 'gemini-2.0-flash',
        prompt_used: userPrompt.substring(0, 500),
        status: 'pending',
      })
      .select('id')
      .single();

    if (insertError) throw insertError;

    return new Response(
      JSON.stringify({
        config_id: inserted.id,
        business_type,
        config_count: (generated.config ?? []).length,
        quest_count: (generated.quests ?? []).length,
        status: 'pending',
        message: 'Config đã được tạo. CEO cần duyệt trước khi áp dụng.',
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
