-- Migration: Relax organization insert policy to avoid auth_user_id uniqueness conflicts
-- Purpose: Allow authenticated users to create organizations without assigning auth_user_id
-- Date: 2025-11-24

BEGIN;

DROP POLICY IF EXISTS "authenticated_users_create_organizations" ON public.accounts;

CREATE POLICY "authenticated_users_create_organizations" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'Organization'
  AND status <> 'deleted'
  AND public.get_user_account_id() IS NOT NULL
);

COMMIT;

