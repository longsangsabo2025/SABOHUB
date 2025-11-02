-- Update purchase_requests table to add new fields for Phase 6
ALTER TABLE public.purchase_requests 
ADD COLUMN IF NOT EXISTS estimated_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS actual_quantity INTEGER,
ADD COLUMN IF NOT EXISTS actual_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS total_cost DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS photo_urls TEXT[],
ADD COLUMN IF NOT EXISTS receipt_photo_urls TEXT[],
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS approval_notes TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS completed_by UUID REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS completion_notes TEXT;

-- Update status enum to include PURCHASING and COMPLETED
ALTER TABLE public.purchase_requests 
DROP CONSTRAINT IF EXISTS purchase_requests_status_check;

ALTER TABLE public.purchase_requests 
ADD CONSTRAINT purchase_requests_status_check 
CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PURCHASING', 'COMPLETED'));

-- Create RLS policy for purchase requests
DROP POLICY IF EXISTS "Users can manage store purchase requests" ON public.purchase_requests;

CREATE POLICY "Users can manage store purchase requests" ON public.purchase_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = purchase_requests.store_id OR role = 'CEO')
    )
  );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_purchase_requests_requested_by ON public.purchase_requests(requested_by);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_approved_by ON public.purchase_requests(approved_by);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_completed_by ON public.purchase_requests(completed_by);

-- Create functions for inventory management
CREATE OR REPLACE FUNCTION add_inventory_stock(
  p_item_id UUID,
  p_quantity DECIMAL,
  p_unit_cost DECIMAL,
  p_user_id UUID,
  p_reference TEXT
)
RETURNS void AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM public.inventory_items WHERE id = p_item_id;
  
  UPDATE public.inventory_items
  SET current_quantity = current_quantity + p_quantity,
      updated_at = NOW()
  WHERE id = p_item_id;
  
  INSERT INTO public.inventory_transactions (
    store_id,
    inventory_item_id,
    transaction_type,
    quantity,
    unit_cost,
    total_cost,
    reference_number,
    created_by
  ) VALUES (
    v_store_id,
    p_item_id,
    'IN',
    p_quantity,
    p_unit_cost,
    p_quantity * p_unit_cost,
    p_reference,
    p_user_id
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_beverage_stock(
  p_beverage_id UUID,
  p_quantity DECIMAL,
  p_unit_cost DECIMAL,
  p_user_id UUID,
  p_reference TEXT
)
RETURNS void AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM public.beverage_inventory WHERE id = p_beverage_id;
  
  UPDATE public.beverage_inventory
  SET current_quantity = current_quantity + p_quantity,
      updated_at = NOW()
  WHERE id = p_beverage_id;
  
  INSERT INTO public.beverage_transactions (
    store_id,
    beverage_inventory_id,
    transaction_type,
    quantity,
    unit_cost,
    total_cost,
    reference_number,
    created_by
  ) VALUES (
    v_store_id,
    p_beverage_id,
    'IN',
    p_quantity,
    p_unit_cost,
    p_quantity * p_unit_cost,
    p_reference,
    p_user_id
  );
END;
$$ LANGUAGE plpgsql;
