-- Create documents table for Google Drive integration
-- This table stores metadata about files stored in Google Drive

CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Google Drive info
    google_drive_file_id TEXT NOT NULL UNIQUE,
    google_drive_web_view_link TEXT,
    google_drive_download_link TEXT,
    
    -- File info
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL, -- mime type
    file_size BIGINT, -- in bytes
    file_extension TEXT,
    
    -- Ownership & Relations
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Categories
    document_type TEXT DEFAULT 'general', -- general, contract, invoice, report, etc.
    category TEXT,
    tags TEXT[], -- array of tags for search
    
    -- Description
    description TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Soft delete
    deleted_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_documents_company_id ON public.documents(company_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON public.documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_documents_google_drive_file_id ON public.documents(google_drive_file_id);
CREATE INDEX IF NOT EXISTS idx_documents_document_type ON public.documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON public.documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_is_deleted ON public.documents(is_deleted) WHERE is_deleted = FALSE;

-- Create index for full-text search on file_name and description
CREATE INDEX IF NOT EXISTS idx_documents_search ON public.documents 
USING gin(to_tsvector('english', coalesce(file_name, '') || ' ' || coalesce(description, '')));

-- Enable RLS
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "documents_select_policy" ON public.documents;
DROP POLICY IF EXISTS "documents_insert_policy" ON public.documents;
DROP POLICY IF EXISTS "documents_update_policy" ON public.documents;
DROP POLICY IF EXISTS "documents_delete_policy" ON public.documents;

-- RLS Policies
-- CEO can see all documents of all companies
-- Manager can see documents of their company
-- Employee can see documents of their company

-- SELECT Policy
CREATE POLICY "documents_select_policy" ON public.documents
FOR SELECT
USING (
    is_deleted = FALSE
    AND (
        -- CEO can see all
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.role = 'ceo'
        )
        OR
        -- Manager/Employee can see their company's documents
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.company_id = documents.company_id
        )
    )
);

-- INSERT Policy
CREATE POLICY "documents_insert_policy" ON public.documents
FOR INSERT
WITH CHECK (
    uploaded_by = auth.uid()
    AND (
        -- CEO can upload to any company
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.role = 'ceo'
        )
        OR
        -- Manager/Employee can upload to their company
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.company_id = documents.company_id
        )
    )
);

-- UPDATE Policy
CREATE POLICY "documents_update_policy" ON public.documents
FOR UPDATE
USING (
    -- CEO can update any document
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'ceo'
    )
    OR
    -- Manager can update their company's documents
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'manager'
        AND users.company_id = documents.company_id
    )
    OR
    -- User can update their own uploaded documents
    uploaded_by = auth.uid()
);

-- DELETE Policy (Soft delete)
CREATE POLICY "documents_delete_policy" ON public.documents
FOR UPDATE
USING (
    -- CEO can delete any document
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'ceo'
    )
    OR
    -- Manager can delete their company's documents
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND users.role = 'manager'
        AND users.company_id = documents.company_id
    )
    OR
    -- User can delete their own uploaded documents
    uploaded_by = auth.uid()
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS trigger_update_documents_updated_at ON public.documents;
CREATE TRIGGER trigger_update_documents_updated_at
    BEFORE UPDATE ON public.documents
    FOR EACH ROW
    EXECUTE FUNCTION update_documents_updated_at();

-- Grant permissions
GRANT ALL ON public.documents TO authenticated;
GRANT ALL ON public.documents TO service_role;

-- Comments
COMMENT ON TABLE public.documents IS 'Stores metadata about files stored in Google Drive';
COMMENT ON COLUMN public.documents.google_drive_file_id IS 'The unique file ID from Google Drive';
COMMENT ON COLUMN public.documents.document_type IS 'Type of document: general, contract, invoice, report, etc.';
