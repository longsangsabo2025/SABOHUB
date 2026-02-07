#!/usr/bin/env python3
"""
Deploy additional delivery RPC functions for transaction safety
"""

import psycopg2
from psycopg2 import sql

# Supabase transaction pooler connection
POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def deploy_rpc_functions():
    print("🚀 Deploying additional delivery RPC functions...")
    
    conn = psycopg2.connect(POOLER_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    # 1. RPC for failed delivery - updates both tables atomically
    fail_delivery_rpc = """
    CREATE OR REPLACE FUNCTION fail_delivery(
        p_delivery_id UUID,
        p_order_id UUID,
        p_reason TEXT DEFAULT NULL
    )
    RETURNS JSONB
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    DECLARE
        v_now TIMESTAMPTZ := NOW();
    BEGIN
        -- Update deliveries table
        UPDATE deliveries SET
            status = 'failed',
            notes = p_reason,
            completed_at = v_now,
            updated_at = v_now
        WHERE id = p_delivery_id;
        
        -- Update sales_orders table
        UPDATE sales_orders SET
            delivery_status = 'failed',
            delivery_failed_reason = p_reason,
            updated_at = v_now
        WHERE id = p_order_id;
        
        RETURN jsonb_build_object('success', true);
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
    END;
    $$;
    """
    
    # 2. RPC for transfer payment completion
    complete_delivery_transfer_rpc = """
    CREATE OR REPLACE FUNCTION complete_delivery_transfer(
        p_delivery_id UUID,
        p_order_id UUID
    )
    RETURNS JSONB
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    DECLARE
        v_now TIMESTAMPTZ := NOW();
    BEGIN
        -- Update deliveries table
        UPDATE deliveries SET
            status = 'completed',
            completed_at = v_now,
            updated_at = v_now
        WHERE id = p_delivery_id;
        
        -- Update sales_orders table - transfer needs finance confirmation
        UPDATE sales_orders SET
            delivery_status = 'delivered',
            payment_status = 'pending_transfer',
            payment_method = 'transfer',
            updated_at = v_now
        WHERE id = p_order_id;
        
        RETURN jsonb_build_object('success', true);
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
    END;
    $$;
    """
    
    # 3. RPC for debt payment with customer debt update
    complete_delivery_debt_rpc = """
    CREATE OR REPLACE FUNCTION complete_delivery_debt(
        p_delivery_id UUID,
        p_order_id UUID,
        p_customer_id UUID,
        p_amount NUMERIC
    )
    RETURNS JSONB
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    DECLARE
        v_now TIMESTAMPTZ := NOW();
        v_current_debt NUMERIC;
    BEGIN
        -- Get current customer debt
        SELECT COALESCE(total_debt, 0) INTO v_current_debt
        FROM customers WHERE id = p_customer_id;
        
        -- Update deliveries table
        UPDATE deliveries SET
            status = 'completed',
            completed_at = v_now,
            updated_at = v_now
        WHERE id = p_delivery_id;
        
        -- Update sales_orders table
        UPDATE sales_orders SET
            delivery_status = 'delivered',
            payment_status = 'debt',
            payment_method = 'debt',
            updated_at = v_now
        WHERE id = p_order_id;
        
        -- Update customer debt
        UPDATE customers SET
            total_debt = v_current_debt + p_amount,
            updated_at = v_now
        WHERE id = p_customer_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'new_debt', v_current_debt + p_amount
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
    END;
    $$;
    """
    
    try:
        print("📦 Creating fail_delivery RPC...")
        cur.execute(fail_delivery_rpc)
        print("✅ fail_delivery created!")
        
        print("📦 Creating complete_delivery_transfer RPC...")
        cur.execute(complete_delivery_transfer_rpc)
        print("✅ complete_delivery_transfer created!")
        
        print("📦 Creating complete_delivery_debt RPC...")
        cur.execute(complete_delivery_debt_rpc)
        print("✅ complete_delivery_debt created!")
        
        # Grant permissions
        print("🔐 Granting permissions...")
        cur.execute("GRANT EXECUTE ON FUNCTION fail_delivery(UUID, UUID, TEXT) TO authenticated;")
        cur.execute("GRANT EXECUTE ON FUNCTION complete_delivery_transfer(UUID, UUID) TO authenticated;")
        cur.execute("GRANT EXECUTE ON FUNCTION complete_delivery_debt(UUID, UUID, UUID, NUMERIC) TO authenticated;")
        
        print("\n✨ All RPC functions deployed successfully!")
        
        # Test the functions exist
        print("\n🔍 Verifying functions...")
        cur.execute("""
            SELECT routine_name 
            FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name IN ('fail_delivery', 'complete_delivery_transfer', 'complete_delivery_debt', 'complete_delivery', 'start_delivery')
        """)
        functions = cur.fetchall()
        print(f"📋 Available delivery RPC functions: {[f[0] for f in functions]}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    deploy_rpc_functions()
