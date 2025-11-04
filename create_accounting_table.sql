-- Create accounting_transactions table for tracking all financial transactions

CREATE TABLE IF NOT EXISTS public.accounting_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company and Branch
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  
  -- Transaction Info
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense', 'salary', 'utility', 'maintenance', 'other')),
  amount DECIMAL(15, 2) NOT NULL CHECK (amount >= 0),
  description TEXT NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'bank', 'card', 'momo', 'other')),
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Additional Info
  category TEXT,
  reference_id TEXT, -- Link to other records (employee_id for salary, etc.)
  notes TEXT,
  
  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_accounting_company ON accounting_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_accounting_branch ON accounting_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_accounting_date ON accounting_transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_accounting_type ON accounting_transactions(type);
CREATE INDEX IF NOT EXISTS idx_accounting_created_by ON accounting_transactions(created_by);

-- RLS Policies
ALTER TABLE accounting_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view transactions in their company" ON accounting_transactions
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Managers and CEOs can create transactions" ON accounting_transactions
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND company_id = accounting_transactions.company_id
      AND role IN ('CEO', 'Manager')
    )
  );

CREATE POLICY "Managers and CEOs can update transactions" ON accounting_transactions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND company_id = accounting_transactions.company_id
      AND role IN ('CEO', 'Manager')
    )
  );

CREATE POLICY "Only CEOs can delete transactions" ON accounting_transactions
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND company_id = accounting_transactions.company_id
      AND role = 'CEO'
    )
  );

-- Update trigger
CREATE OR REPLACE FUNCTION update_accounting_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER accounting_updated_at
  BEFORE UPDATE ON accounting_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_accounting_updated_at();

-- Comment
COMMENT ON TABLE accounting_transactions IS 'Stores all financial transactions including revenue, expenses, salaries, etc.';
