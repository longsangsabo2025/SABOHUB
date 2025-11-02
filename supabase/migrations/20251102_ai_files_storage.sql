-- Create storage bucket for AI files
INSERT INTO storage.buckets (id, name, public)
VALUES ('ai-files', 'ai-files', false);

-- Enable RLS for the bucket
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Users can upload files to their company's folder
CREATE POLICY "Users can upload AI files to their company"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN profiles p ON p.company_id = c.id
    WHERE p.id = auth.uid()
  )
);

-- Policy: Users can view files from their company
CREATE POLICY "Users can view AI files from their company"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN profiles p ON p.company_id = c.id
    WHERE p.id = auth.uid()
  )
);

-- Policy: Users can delete files from their company
CREATE POLICY "Users can delete AI files from their company"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN profiles p ON p.company_id = c.id
    WHERE p.id = auth.uid()
  )
);

-- Add file size limit (10MB)
CREATE POLICY "Limit file size to 10MB"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ai-files' AND
  (octet_length(decode(content, 'base64')) / 1024 / 1024) <= 10
);
