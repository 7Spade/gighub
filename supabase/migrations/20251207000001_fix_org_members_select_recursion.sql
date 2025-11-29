-- Migration: Fix RLS infinite recursion in organization_members and accounts policies
-- Purpose: Fix RLS infinite recursion (PostgreSQL error 42P17)
-- Phase: 3 - RLS Policy Fix
-- Created: 2025-12-07
--
-- Issue 1: The org_members_select policy contains a self-referencing subquery
--          that causes infinite recursion.
--
-- Issue 2: The users_view_own_user_account policy on accounts table queries
--          organization_members which triggers RLS recursion.
--
-- Solution:
-- 1. Create is_same_org_user() helper function with SECURITY DEFINER
-- 2. Fix org_members_select policy to use is_org_member() function
-- 3. Fix users_view_own_user_account policy to use is_same_org_user() function

-- ============================================================================
-- CREATE HELPER FUNCTION: is_same_org_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_same_org_user(target_account_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  -- Check if the target account shares any organization with the current user
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members om1
    INNER JOIN public.organization_members om2
      ON om1.organization_id = om2.organization_id
    WHERE om1.account_id = target_account_id
      AND om2.auth_user_id = auth.uid()
  );
END;
$$;

COMMENT ON FUNCTION public.is_same_org_user(UUID) IS
'Returns true if the target account is in the same organization as the current user.
Uses SECURITY DEFINER with row_security = off to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_same_org_user(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_same_org_user(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_same_org_user(UUID) FROM public;

-- ============================================================================
-- FIX 1: organization_members SELECT policy
-- ============================================================================

DROP POLICY IF EXISTS "org_members_select" ON public.organization_members;

CREATE POLICY "org_members_select"
ON public.organization_members
FOR SELECT
USING (
  -- Allow users to query their own memberships directly (no recursion)
  auth_user_id = auth.uid()
  OR
  -- Allow viewing other members of organizations they belong to
  -- Uses is_org_member() which has SECURITY DEFINER and row_security = off
  public.is_org_member(organization_id)
);

COMMENT ON POLICY "org_members_select" ON public.organization_members IS
'Members can view their own membership and all members of organizations they belong to.
Uses auth_user_id directly for own membership check (no recursion).
Uses is_org_member() for organization membership check (SECURITY DEFINER bypasses RLS).
This fixes the infinite recursion error (42P17) that occurred with direct subqueries.';

-- ============================================================================
-- FIX 2: accounts SELECT policy
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
    -- Can see Organizations they are members of
    (type = 'Organization' AND public.is_org_member(id))
    OR
    -- Can see other Users in same organization
    -- Uses is_same_org_user() which has SECURITY DEFINER and row_security = off
    (type = 'User' AND public.is_same_org_user(id))
  )
);

COMMENT ON POLICY "users_view_own_user_account" ON public.accounts IS
'Users can view their own account, organizations they belong to, and other users in the same organization.
Uses is_same_org_user() helper function to avoid RLS recursion when checking organization membership.
This fixes the infinite recursion error (42P17) that occurred with direct subqueries to organization_members.';
