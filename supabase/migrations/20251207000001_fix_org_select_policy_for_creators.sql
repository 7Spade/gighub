-- Migration: Fix Organization SELECT Policy for Creators
-- Purpose: Allow organization creators to view their organization immediately after creation
-- Phase: 3 - RLS Policies (Fix)
-- Created: 2025-12-07
-- Dependencies: 20251203000002_create_user_rls_policies.sql
-- 
-- Problem: When creating an organization, the INSERT succeeds but the RETURNING SELECT
-- fails because the user isn't a member yet (the membership trigger hasn't fired yet).
-- 
-- Solution: Add condition to allow creators (identified by auth_user_id) to view their
-- own organizations, similar to how the INSERT policy works.

-- ============================================================================
-- DROP AND RECREATE SELECT POLICY
-- ============================================================================

DROP POLICY IF EXISTS "users_view_own_user_account" ON public.accounts;

CREATE POLICY "users_view_own_user_account"
ON public.accounts
FOR SELECT
USING (
  status != 'deleted' AND
  (
    -- Can see own User account
    (type = 'User' AND auth_user_id = auth.uid())
    OR
    -- Can see Organizations they created (allows SELECT right after INSERT)
    (type = 'Organization' AND auth_user_id = auth.uid())
    OR
    -- Can see Organizations they are members of
    (type = 'Organization' AND public.is_org_member(id))
    OR
    -- Can see other Users in same organization
    (type = 'User' AND EXISTS (
      SELECT 1 FROM public.organization_members om1
      INNER JOIN public.organization_members om2 ON om1.organization_id = om2.organization_id
      WHERE om1.account_id = accounts.id
        AND om2.auth_user_id = auth.uid()
    ))
  )
);

COMMENT ON POLICY "users_view_own_user_account" ON public.accounts IS
'Users can view:
- Their own User account
- Organizations they created (via auth_user_id)
- Organizations they are members of (via organization_members)
- Other users in the same organization';
