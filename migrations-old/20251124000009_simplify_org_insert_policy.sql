-- Migration: Temporarily simplify organization insert policy for debugging
-- Purpose: Remove get_user_account_id() requirement to isolate RLS issue
-- Date: 2025-11-24

BEGIN;

DROP POLICY IF EXISTS "authenticated_users_create_organizations" ON public.accounts;

-- Simplified policy: only require authenticated user with type=Organization and status<>deleted
CREATE POLICY "authenticated_users_create_organizations" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'Organization'
  AND status <> 'deleted'
);

COMMENT ON POLICY "authenticated_users_create_organizations" ON public.accounts IS 
'Allows authenticated users to create organizations. The trigger add_creator_as_org_owner will add them as owner if they have a User account.';

COMMIT;

