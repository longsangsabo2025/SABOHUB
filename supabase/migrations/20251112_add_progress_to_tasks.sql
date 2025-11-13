-- Add progress column to tasks table
-- This migration adds a progress column (0-100%) to track task completion

-- Add progress column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'tasks' 
        AND column_name = 'progress'
    ) THEN
        ALTER TABLE public.tasks 
        ADD COLUMN progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100);
        
        RAISE NOTICE 'Added progress column to tasks table';
    ELSE
        RAISE NOTICE 'Progress column already exists';
    END IF;
END $$;

-- Add comment to the column
COMMENT ON COLUMN public.tasks.progress IS 'Task completion progress percentage (0-100)';

-- Update existing tasks to have appropriate progress based on status
UPDATE public.tasks
SET progress = CASE 
    WHEN status = 'COMPLETED' THEN 100
    WHEN status = 'IN_PROGRESS' THEN 50
    WHEN status = 'PENDING' THEN 0
    WHEN status = 'CANCELLED' THEN 0
    ELSE 0
END
WHERE progress IS NULL OR progress = 0;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_progress ON public.tasks(progress);

RAISE NOTICE 'Migration completed: Added progress column to tasks table';
