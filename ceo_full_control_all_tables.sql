-- ████████████████████████████████████████████████████████████████████████████████
-- 🔥 CEO FULL CONTROL - ALL TABLES RLS POLICIES
-- CEO = GOD MODE: SELECT, INSERT, UPDATE, DELETE mọi thứ trong công ty
-- ████████████████████████████████████████████████████████████████████████████████

-- Helper function to check CEO ownership
CREATE OR REPLACE FUNCTION is_ceo_of_company(check_company_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM companies 
    WHERE id = check_company_id 
    AND created_by = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 1. COMPANIES TABLE - CEO owns their companies
-- ============================================================================
DROP POLICY IF EXISTS "ceo_companies_all" ON companies;
CREATE POLICY "ceo_companies_all" ON companies FOR ALL USING (created_by = auth.uid());

-- ============================================================================
-- 2. BRANCHES TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_branches_all" ON branches;
CREATE POLICY "ceo_branches_all" ON branches FOR ALL 
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 3. EMPLOYEES TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_employees_all" ON employees;
CREATE POLICY "ceo_employees_all" ON employees FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 4. USERS TABLE (if needed for legacy support)
-- ============================================================================
DROP POLICY IF EXISTS "ceo_users_all" ON users;
CREATE POLICY "ceo_users_all" ON users FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 5. TASKS TABLE (already fixed earlier, but ensure it's here)
-- ============================================================================
DROP POLICY IF EXISTS "ceo_tasks_all" ON tasks;
CREATE POLICY "ceo_tasks_all" ON tasks FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 6. TASK_TEMPLATES TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_task_templates_all" ON task_templates;
CREATE POLICY "ceo_task_templates_all" ON task_templates FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 7. TASK_APPROVALS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_task_approvals_all" ON task_approvals;
CREATE POLICY "ceo_task_approvals_all" ON task_approvals FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 8. ORDERS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_orders_all" ON orders;
CREATE POLICY "ceo_orders_all" ON orders FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 9. ACCOUNTING_TRANSACTIONS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_accounting_all" ON accounting_transactions;
CREATE POLICY "ceo_accounting_all" ON accounting_transactions FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 10. COMMISSION_RULES TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_commission_all" ON commission_rules;
CREATE POLICY "ceo_commission_all" ON commission_rules FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 11. LABOR_CONTRACTS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_contracts_all" ON labor_contracts;
CREATE POLICY "ceo_contracts_all" ON labor_contracts FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 12. EMPLOYEE_INVITATIONS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_invitations_all" ON employee_invitations;
CREATE POLICY "ceo_invitations_all" ON employee_invitations FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 13. EMPLOYEE_DOCUMENTS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_employee_docs_all" ON employee_documents;
CREATE POLICY "ceo_employee_docs_all" ON employee_documents FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 14. BUSINESS_DOCUMENTS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_business_docs_all" ON business_documents;
CREATE POLICY "ceo_business_docs_all" ON business_documents FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 15. ACTIVITY_LOGS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_activity_logs_all" ON activity_logs;
CREATE POLICY "ceo_activity_logs_all" ON activity_logs FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 16. DAILY_REVENUE TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_daily_revenue_all" ON daily_revenue;
CREATE POLICY "ceo_daily_revenue_all" ON daily_revenue FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 17. REVENUE_SUMMARY TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_revenue_summary_all" ON revenue_summary;
CREATE POLICY "ceo_revenue_summary_all" ON revenue_summary FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 18. BILLS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_bills_all" ON bills;
CREATE POLICY "ceo_bills_all" ON bills FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 19. MENU_ITEMS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_menu_items_all" ON menu_items;
CREATE POLICY "ceo_menu_items_all" ON menu_items FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 20. TABLES TABLE (restaurant tables)
-- ============================================================================
DROP POLICY IF EXISTS "ceo_tables_all" ON tables;
CREATE POLICY "ceo_tables_all" ON tables FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 21. TABLE_SESSIONS TABLE
-- ============================================================================
DROP POLICY IF EXISTS "ceo_table_sessions_all" ON table_sessions;
CREATE POLICY "ceo_table_sessions_all" ON table_sessions FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ============================================================================
-- 22. AI TABLES - CEO controls AI features
-- ============================================================================
DROP POLICY IF EXISTS "ceo_ai_assistants_all" ON ai_assistants;
CREATE POLICY "ceo_ai_assistants_all" ON ai_assistants FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

DROP POLICY IF EXISTS "ceo_ai_messages_all" ON ai_messages;
CREATE POLICY "ceo_ai_messages_all" ON ai_messages FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

DROP POLICY IF EXISTS "ceo_ai_recommendations_all" ON ai_recommendations;
CREATE POLICY "ceo_ai_recommendations_all" ON ai_recommendations FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

DROP POLICY IF EXISTS "ceo_ai_uploaded_files_all" ON ai_uploaded_files;
CREATE POLICY "ceo_ai_uploaded_files_all" ON ai_uploaded_files FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

DROP POLICY IF EXISTS "ceo_ai_usage_analytics_all" ON ai_usage_analytics;
CREATE POLICY "ceo_ai_usage_analytics_all" ON ai_usage_analytics FOR ALL
USING (company_id IN (SELECT id FROM companies WHERE created_by = auth.uid()));

-- ████████████████████████████████████████████████████████████████████████████████
-- ✅ COMPLETE! CEO HAS FULL CONTROL OVER 27 TABLES!
-- ████████████████████████████████████████████████████████████████████████████████
