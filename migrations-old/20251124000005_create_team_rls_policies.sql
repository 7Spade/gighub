-- Migration: Create Team RLS policies
-- Purpose: Add RLS policies for teams table to enable proper access control
-- Created: 2025-11-24
-- Phase: 4 - RLS Policy Fixes (Additional)
--
-- Teams belong to organizations and should be accessible to organization members.
-- Only organization owners can create, update, or delete teams.
--
-- Key principle: Use get_user_account_id() in subqueries to avoid recursion.

-- ============================================================================
-- DROP EXISTING POLICIES (if any)
-- ============================================================================

DROP POLICY IF EXISTS "users_view_teams_in_their_organizations" ON public.teams;
DROP POLICY IF EXISTS "org_owners_create_teams" ON public.teams;
DROP POLICY IF EXISTS "org_owners_update_teams" ON public.teams;
DROP POLICY IF EXISTS "org_owners_delete_teams" ON public.teams;

-- ============================================================================
-- SELECT POLICY - Users can view teams in their organizations
-- ============================================================================

CREATE POLICY "users_view_teams_in_their_organizations" ON public.teams
FOR SELECT
TO authenticated
USING (
  organization_id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
  )
);

COMMENT ON POLICY "users_view_teams_in_their_organizations" ON public.teams IS
'Allows users to view teams in organizations they are members of.
Uses get_user_account_id() to avoid infinite recursion.';

-- ============================================================================
-- INSERT POLICY - Organization owners can create teams
-- ============================================================================

CREATE POLICY "org_owners_create_teams" ON public.teams
FOR INSERT
TO authenticated
WITH CHECK (
  organization_id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
);

COMMENT ON POLICY "org_owners_create_teams" ON public.teams IS
'Allows organization owners to create teams in their organizations.
Requires owner role in organization_members table.
Uses get_user_account_id() to avoid recursion.';

-- ============================================================================
-- UPDATE POLICY - Organization owners can update teams
-- ============================================================================

CREATE POLICY "org_owners_update_teams" ON public.teams
FOR UPDATE
TO authenticated
USING (
  organization_id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
)
WITH CHECK (
  -- Ensure updates maintain data integrity
  organization_id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
);

COMMENT ON POLICY "org_owners_update_teams" ON public.teams IS
'Allows organization owners to update teams in their organizations.
Requires owner role in organization_members table.
Uses get_user_account_id() to avoid recursion.';

-- ============================================================================
-- DELETE POLICY - Organization owners can delete teams
-- ============================================================================

CREATE POLICY "org_owners_delete_teams" ON public.teams
FOR DELETE
TO authenticated
USING (
  organization_id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
);

COMMENT ON POLICY "org_owners_delete_teams" ON public.teams IS
'Allows organization owners to delete teams in their organizations.
Requires owner role in organization_members table.
Uses get_user_account_id() to avoid recursion.';

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

-- Enable RLS on teams table if not already enabled
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.teams IS
'Teams belong to organizations and group accounts (users/bots).
RLS policies ensure users can only access teams in their organizations.';
