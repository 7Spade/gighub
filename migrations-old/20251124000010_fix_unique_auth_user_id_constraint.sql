-- Migration: Fix auth_user_id unique constraint to allow organizations with creator tracking
-- Purpose: Change UNIQUE constraint to partial index (User type only) to allow orgs/bots to store creator
-- Date: 2025-11-24
-- 
-- Problem: Currently accounts.auth_user_id has UNIQUE constraint preventing multiple rows with same auth_user_id.
--          This blocks organizations from storing creator's auth_user_id for SELECT policy visibility.
-- 
-- Solution: Replace global UNIQUE with partial UNIQUE index (User type only).
--           This allows User accounts to maintain 1:1 with auth.users,
--           while Organizations/Bots can store creator as auth_user_id.

BEGIN;

-- Drop existing unique constraint (this will also drop the index)
ALTER TABLE public.accounts DROP CONSTRAINT IF EXISTS unique_auth_user_id;

-- Create partial unique index: only enforce uniqueness for User type
-- This allows each auth.users to have exactly one User account,
-- while Organizations and Bots can store creator's auth_user_id
CREATE UNIQUE INDEX unique_user_auth_user_id 
ON public.accounts (auth_user_id) 
WHERE type = 'User';

COMMENT ON INDEX public.unique_user_auth_user_id IS
'Ensures each auth.users has exactly one User account. Organizations and Bots can store creator auth_user_id for access control.';

COMMIT;

