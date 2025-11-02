-- ============================================
-- AI Assistant Tables Migration (FIXED)
-- Created: November 2, 2025
-- Purpose: Enable AI-powered company analysis
-- ============================================

-- ============================================
-- 1. AI Assistants Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_assistants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    
    -- OpenAI Integration
    openai_assistant_id TEXT,
    openai_thread_id TEXT,
    
    -- Configuration
    name TEXT DEFAULT 'AI Trợ lý',
    instructions TEXT,
    model TEXT DEFAULT 'gpt-4-turbo-preview',
    settings JSONB DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    CONSTRAINT unique_company_assistant UNIQUE(company_id)
);

CREATE INDEX IF NOT EXISTS idx_ai_assistants_company ON public.ai_assistants(company_id);
CREATE INDEX IF NOT EXISTS idx_ai_assistants_active ON public.ai_assistants(is_active);

-- ============================================
-- 2. AI Messages Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assistant_id UUID NOT NULL REFERENCES public.ai_assistants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Message Content
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    
    -- Attachments
    attachments JSONB DEFAULT '[]',
    
    -- OpenAI Metadata
    openai_message_id TEXT,
    openai_run_id TEXT,
    
    -- Analysis Results
    analysis_type TEXT,
    analysis_results JSONB,
    
    -- Token Usage & Cost Tracking
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10, 6) DEFAULT 0.00,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_company ON public.ai_messages(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_assistant ON public.ai_messages(assistant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_user ON public.ai_messages(user_id, created_at DESC);

-- ============================================
-- 3. AI Uploaded Files Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_uploaded_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assistant_id UUID NOT NULL REFERENCES public.ai_assistants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- File Information
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT,
    file_url TEXT NOT NULL,
    
    -- OpenAI Integration
    openai_file_id TEXT,
    
    -- Processing Status
    status TEXT DEFAULT 'uploaded' CHECK (status IN ('uploaded', 'processing', 'analyzed', 'error')),
    error_message TEXT,
    
    -- Analysis Results
    analysis_status TEXT,
    analysis_results JSONB,
    extracted_text TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    analyzed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_files_company ON public.ai_uploaded_files(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_files_assistant ON public.ai_uploaded_files(assistant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_files_status ON public.ai_uploaded_files(status, created_at DESC);

-- ============================================
-- 4. AI Recommendations Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assistant_id UUID NOT NULL REFERENCES public.ai_assistants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    
    -- Recommendation Details
    category TEXT NOT NULL CHECK (category IN ('feature', 'process', 'growth', 'technology', 'finance', 'operations')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- Priority & Confidence
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    confidence DECIMAL(3, 2) CHECK (confidence >= 0 AND confidence <= 1),
    
    -- Implementation Details
    reasoning TEXT,
    implementation_plan TEXT,
    estimated_effort TEXT CHECK (estimated_effort IN ('low', 'medium', 'high')),
    expected_impact TEXT,
    
    -- Status Tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'accepted', 'rejected', 'implemented')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    
    -- Additional Data
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recommendations_company ON public.ai_recommendations(company_id, status, priority);
CREATE INDEX IF NOT EXISTS idx_recommendations_status ON public.ai_recommendations(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_priority ON public.ai_recommendations(priority, created_at DESC);

-- ============================================
-- 5. AI Usage Analytics Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_usage_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Action Tracking
    action_type TEXT NOT NULL CHECK (action_type IN ('chat', 'upload', 'analysis', 'recommendation', 'export')),
    
    -- Cost Tracking
    total_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10, 6) DEFAULT 0.00,
    
    -- Additional Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usage_company_date ON public.ai_usage_analytics(company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_usage_action_type ON public.ai_usage_analytics(action_type, created_at);
CREATE INDEX IF NOT EXISTS idx_usage_date ON public.ai_usage_analytics(created_at DESC);

-- ============================================
-- 6. Row Level Security (RLS) Policies
-- ============================================

ALTER TABLE public.ai_assistants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_uploaded_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_analytics ENABLE ROW LEVEL SECURITY;

-- ai_assistants policies
CREATE POLICY "Users can view their company's AI assistant"
    ON public.ai_assistants FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "CEO can manage their company's AI assistant"
    ON public.ai_assistants FOR ALL
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid() AND role = 'CEO'
        )
    );

-- ai_messages policies
CREATE POLICY "Users can view their company's AI messages"
    ON public.ai_messages FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can create AI messages for their company"
    ON public.ai_messages FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- ai_uploaded_files policies
CREATE POLICY "Users can view their company's uploaded files"
    ON public.ai_uploaded_files FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can upload files for their company"
    ON public.ai_uploaded_files FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "Users can delete their own uploaded files"
    ON public.ai_uploaded_files FOR DELETE
    USING (user_id = auth.uid());

-- ai_recommendations policies
CREATE POLICY "Users can view their company's recommendations"
    ON public.ai_recommendations FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "CEO can manage recommendations"
    ON public.ai_recommendations FOR ALL
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid() AND role = 'CEO'
        )
    );

-- ai_usage_analytics policies
CREATE POLICY "Users can view their company's usage analytics"
    ON public.ai_usage_analytics FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "System can insert usage analytics"
    ON public.ai_usage_analytics FOR INSERT
    WITH CHECK (true);

-- ============================================
-- 7. Triggers for updated_at
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ai_assistants_updated_at
    BEFORE UPDATE ON public.ai_assistants
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_ai_recommendations_updated_at
    BEFORE UPDATE ON public.ai_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 8. Helper Functions
-- ============================================

CREATE OR REPLACE FUNCTION public.get_or_create_ai_assistant(p_company_id UUID)
RETURNS UUID AS $$
DECLARE
    v_assistant_id UUID;
BEGIN
    SELECT id INTO v_assistant_id
    FROM public.ai_assistants
    WHERE company_id = p_company_id
    LIMIT 1;
    
    IF v_assistant_id IS NULL THEN
        INSERT INTO public.ai_assistants (company_id)
        VALUES (p_company_id)
        RETURNING id INTO v_assistant_id;
    END IF;
    
    RETURN v_assistant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_ai_total_cost(p_company_id UUID, p_start_date TIMESTAMPTZ DEFAULT NULL)
RETURNS DECIMAL AS $$
DECLARE
    v_total_cost DECIMAL(10, 6);
BEGIN
    SELECT COALESCE(SUM(estimated_cost), 0)
    INTO v_total_cost
    FROM public.ai_usage_analytics
    WHERE company_id = p_company_id
    AND (p_start_date IS NULL OR created_at >= p_start_date);
    
    RETURN v_total_cost;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_ai_usage_stats(p_company_id UUID, p_days INTEGER DEFAULT 30)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_chats', COUNT(*) FILTER (WHERE action_type = 'chat'),
        'total_uploads', COUNT(*) FILTER (WHERE action_type = 'upload'),
        'total_analyses', COUNT(*) FILTER (WHERE action_type = 'analysis'),
        'total_tokens', COALESCE(SUM(total_tokens), 0),
        'total_cost', COALESCE(SUM(estimated_cost), 0),
        'period_days', p_days
    )
    INTO v_stats
    FROM public.ai_usage_analytics
    WHERE company_id = p_company_id
    AND created_at >= now() - (p_days || ' days')::INTERVAL;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. Comments for Documentation
-- ============================================

COMMENT ON TABLE public.ai_assistants IS 'Stores AI assistant instances per company';
COMMENT ON TABLE public.ai_messages IS 'Chat messages between users and AI';
COMMENT ON TABLE public.ai_uploaded_files IS 'Files uploaded for AI analysis';
COMMENT ON TABLE public.ai_recommendations IS 'AI-generated recommendations for companies';
COMMENT ON TABLE public.ai_usage_analytics IS 'Tracks AI usage for billing and analytics';
