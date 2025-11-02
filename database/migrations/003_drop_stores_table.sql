-- Migration 003: Drop obsolete stores table (data already migrated to branches)

BEGIN;

-- Drop stores table (all data has been migrated to branches in migration 001)
DROP TABLE IF EXISTS stores CASCADE;

SELECT 'Migration 003 completed: stores table dropped successfully!' as message;

COMMIT;
