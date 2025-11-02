-- Migration: Create Tasks Management Tables
-- Description: Tables for CEO/Manager task management system
-- Author: AI Assistant
-- Date: 2025-11-02

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. TASKS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Task Details
    title TEXT NOT NULL,
    description TEXT,
    
    -- Classification
    priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue', 'cancelled')),
    
    -- Progress tracking
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    
    -- Dates
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Assignments
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Organization
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes for better query performance
    CONSTRAINT tasks_title_not_empty CHECK (char_length(title) > 0)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON public.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_company_id ON public.tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_branch_id ON public.tasks(branch_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks(created_at DESC);

-- =============================================
-- 2. TASK COMMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.task_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_comments_task_id ON public.task_comments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_user_id ON public.task_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_created_at ON public.task_comments(created_at DESC);

-- =============================================
-- 3. TASK ATTACHMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.task_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id ON public.task_attachments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_attachments_uploaded_by ON public.task_attachments(uploaded_by);

-- =============================================
-- 4. TASK APPROVALS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.task_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Approval Details
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('report', 'budget', 'proposal', 'other')),
    
    -- Related task (optional)
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    
    -- Workflow
    submitted_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    
    -- Organization
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    
    -- Metadata
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_approvals_submitted_by ON public.task_approvals(submitted_by);
CREATE INDEX IF NOT EXISTS idx_task_approvals_approved_by ON public.task_approvals(approved_by);
CREATE INDEX IF NOT EXISTS idx_task_approvals_status ON public.task_approvals(status);
CREATE INDEX IF NOT EXISTS idx_task_approvals_company_id ON public.task_approvals(company_id);
CREATE INDEX IF NOT EXISTS idx_task_approvals_type ON public.task_approvals(type);

-- =============================================
-- 5. AUTO UPDATE TIMESTAMP TRIGGER
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_comments_updated_at BEFORE UPDATE ON public.task_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_approvals_updated_at BEFORE UPDATE ON public.task_approvals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_approvals ENABLE ROW LEVEL SECURITY;

-- Tasks Policies
-- CEO can see all tasks
CREATE POLICY "CEO can view all tasks"
    ON public.tasks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'ceo'
        )
    );

-- Manager can see tasks created by them or assigned to them
CREATE POLICY "Manager can view their tasks"
    ON public.tasks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'manager'
            AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
        )
    );

-- Staff can see tasks assigned to them
CREATE POLICY "Staff can view assigned tasks"
    ON public.tasks FOR SELECT
    USING (
        tasks.assigned_to = auth.uid()
    );

-- CEO and Manager can create tasks
CREATE POLICY "CEO and Manager can create tasks"
    ON public.tasks FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role IN ('ceo', 'manager')
        )
    );

-- Users can update their own created tasks or assigned tasks
CREATE POLICY "Users can update their tasks"
    ON public.tasks FOR UPDATE
    USING (
        tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid()
    );

-- Only task creators can delete
CREATE POLICY "Creators can delete tasks"
    ON public.tasks FOR DELETE
    USING (tasks.created_by = auth.uid());

-- Task Comments Policies
CREATE POLICY "Users can view comments on accessible tasks"
    ON public.task_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks
            WHERE tasks.id = task_comments.task_id
            AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
        )
    );

CREATE POLICY "Users can add comments to accessible tasks"
    ON public.task_comments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.tasks
            WHERE tasks.id = task_comments.task_id
            AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
        )
    );

-- Task Attachments Policies
CREATE POLICY "Users can view attachments on accessible tasks"
    ON public.task_attachments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks
            WHERE tasks.id = task_attachments.task_id
            AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
        )
    );

CREATE POLICY "Users can upload attachments to accessible tasks"
    ON public.task_attachments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.tasks
            WHERE tasks.id = task_attachments.task_id
            AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
        )
    );

-- Task Approvals Policies
-- CEO can see all approvals
CREATE POLICY "CEO can view all approvals"
    ON public.task_approvals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'ceo'
        )
    );

-- Manager can see their submitted approvals
CREATE POLICY "Manager can view their approvals"
    ON public.task_approvals FOR SELECT
    USING (
        task_approvals.submitted_by = auth.uid()
    );

-- Manager can create approval requests
CREATE POLICY "Manager can create approvals"
    ON public.task_approvals FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'manager'
        )
    );

-- CEO can update approval status
CREATE POLICY "CEO can update approvals"
    ON public.task_approvals FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'ceo'
        )
    );

-- =============================================
-- 7. COMMENTS
-- =============================================

COMMENT ON TABLE public.tasks IS 'Task management for CEO and Manager workflow';
COMMENT ON TABLE public.task_comments IS 'Comments and discussions on tasks';
COMMENT ON TABLE public.task_attachments IS 'File attachments for tasks';
COMMENT ON TABLE public.task_approvals IS 'Approval requests from Manager to CEO';

-- =============================================
-- END OF MIGRATION
-- =============================================
