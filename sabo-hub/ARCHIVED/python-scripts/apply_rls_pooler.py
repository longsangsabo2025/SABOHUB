#!/usr/bin/env python3
"""
Apply RLS policies for customer_addresses and customer_visits tables
Uses the transaction pooler connection from .env
"""

import psycopg2

# Transaction pooler connection (from sabohub-nexus scripts)  
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

sql_statements = [
    # ======================
    # customer_addresses RLS
    # ======================
    "ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY",
    'DROP POLICY IF EXISTS "customer_addresses_select" ON public.customer_addresses',
    'DROP POLICY IF EXISTS "customer_addresses_insert" ON public.customer_addresses',
    'DROP POLICY IF EXISTS "customer_addresses_update" ON public.customer_addresses',
    'DROP POLICY IF EXISTS "customer_addresses_delete" ON public.customer_addresses',
    
    '''CREATE POLICY "customer_addresses_select" ON public.customer_addresses
       FOR SELECT USING (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',
    
    '''CREATE POLICY "customer_addresses_insert" ON public.customer_addresses
       FOR INSERT WITH CHECK (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',
    
    '''CREATE POLICY "customer_addresses_update" ON public.customer_addresses
       FOR UPDATE USING (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',
    
    '''CREATE POLICY "customer_addresses_delete" ON public.customer_addresses
       FOR DELETE USING (
         company_id IN (
           SELECT company_id FROM public.users 
           WHERE id = auth.uid() AND role IN ('ceo', 'manager')
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',

    # ======================
    # customer_visits RLS - Check and re-apply
    # ======================
    'DROP POLICY IF EXISTS "customer_visits_select_company" ON public.customer_visits',
    'DROP POLICY IF EXISTS "customer_visits_insert_company" ON public.customer_visits',
    'DROP POLICY IF EXISTS "customer_visits_update_company" ON public.customer_visits',
    
    '''CREATE POLICY "customer_visits_select_company" ON public.customer_visits
       FOR SELECT USING (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',
    
    '''CREATE POLICY "customer_visits_insert_company" ON public.customer_visits
       FOR INSERT WITH CHECK (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
         )
       )''',
    
    '''CREATE POLICY "customer_visits_update_company" ON public.customer_visits
       FOR UPDATE USING (
         company_id IN (
           SELECT company_id FROM public.users WHERE id = auth.uid()
           UNION
           SELECT id FROM public.companies WHERE owner_id = auth.uid()
        )
       )''',
]

print("🔧 Applying RLS policies for customer_addresses...")
print(f"   Connecting to database...")

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cursor = conn.cursor()
    
    for i, sql in enumerate(sql_statements):
        try:
            cursor.execute(sql)
            print(f"   ✅ Step {i+1}/{len(sql_statements)}: Success")
        except Exception as e:
            if "already exists" in str(e):
                print(f"   ⚠️ Step {i+1}: Policy already exists")
            else:
                print(f"   ❌ Step {i+1}: {e}")
    
    cursor.close()
    conn.close()
    
    print("\n✅ RLS policies applied successfully!")
    
except Exception as e:
    print(f"\n❌ Connection error: {e}")
    print("\n💡 If you see SSL/connection errors, run this SQL manually in Supabase SQL Editor")
