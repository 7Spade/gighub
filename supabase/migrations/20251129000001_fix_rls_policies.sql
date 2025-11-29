-- ============================================================================
-- Migration: Fix RLS policies for organization, team, blueprint, and task creation
-- Purpose: Apply all necessary RLS policies and helper functions to allow
--          authenticated users to create organizations, teams, blueprints, and tasks.
-- Date: 2025-11-29
-- ============================================================================

BEGIN;

-- ============================================================================
-- HELPER FUNCTIONS (SECURITY DEFINER, row_security = off)
-- These functions allow RLS policies to check membership without causing recursion.
-- ============================================================================

-- Function to get current user's account_id without triggering RLS
CREATE OR REPLACE FUNCTION public.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_account_id UUID;
BEGIN
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;
  
  RETURN v_account_id;
END;
$$;

COMMENT ON FUNCTION public.get_user_account_id() IS 
'Helper function to get account_id for current user without triggering RLS recursion. Uses SECURITY DEFINER to bypass RLS safely.';

GRANT EXECUTE ON FUNCTION public.get_user_account_id() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_account_id() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_account_id() FROM public;

-- Function to check if user is an organization member
CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
  );
END;
$$;

COMMENT ON FUNCTION public.is_org_member(UUID) IS 
'Returns true if auth.uid() is a member of the specified organization. Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_org_member(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_org_member(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_org_member(UUID) FROM public;

-- Function to check if user is an organization owner
CREATE OR REPLACE FUNCTION public.is_org_owner(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
      AND role = 'owner'
  );
END;
$$;

COMMENT ON FUNCTION public.is_org_owner(UUID) IS 
'Returns true if auth.uid() is an owner of the specified organization. Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_org_owner(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_org_owner(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_org_owner(UUID) FROM public;

-- Function to check if user is an organization admin (owner or admin)
CREATE OR REPLACE FUNCTION public.is_org_admin(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
      AND role IN ('owner', 'admin')
  );
END;
$$;

COMMENT ON FUNCTION public.is_org_admin(UUID) IS 
'Returns true if auth.uid() is an owner or admin of the specified organization. Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_org_admin(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_org_admin(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_org_admin(UUID) FROM public;

-- Function to check if organization has any members
CREATE OR REPLACE FUNCTION public.organization_has_members(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
  );
END;
$$;

COMMENT ON FUNCTION public.organization_has_members(UUID) IS 
'Returns true if the organization has any members. Used to check initial owner setup.';

GRANT EXECUTE ON FUNCTION public.organization_has_members(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.organization_has_members(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.organization_has_members(UUID) FROM public;

-- Function to check if user is a team member
CREATE OR REPLACE FUNCTION public.is_team_member(target_team_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.team_members
    WHERE team_id = target_team_id
      AND auth_user_id = auth.uid()
  );
END;
$$;

COMMENT ON FUNCTION public.is_team_member(UUID) IS 
'Returns true if auth.uid() is a member of the specified team. Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_team_member(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_team_member(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_team_member(UUID) FROM public;

-- Function to check if user is a team leader
CREATE OR REPLACE FUNCTION public.is_team_leader(target_team_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.team_members
    WHERE team_id = target_team_id
      AND auth_user_id = auth.uid()
      AND role = 'leader'
  );
END;
$$;

COMMENT ON FUNCTION public.is_team_leader(UUID) IS 
'Returns true if auth.uid() is a leader of the specified team. Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_team_leader(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_team_leader(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_team_leader(UUID) FROM public;

-- ============================================================================
-- TRIGGER FUNCTION: Auto-add organization creator as owner
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_creator_as_org_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_user_account_id UUID;
BEGIN
  IF NEW.type = 'Organization' AND TG_OP = 'INSERT' THEN
    SELECT id INTO v_user_account_id
    FROM public.accounts
    WHERE auth_user_id = auth.uid()
      AND type = 'User'
      AND status != 'deleted'
    LIMIT 1;

    IF v_user_account_id IS NOT NULL THEN
      INSERT INTO public.organization_members (
        organization_id,
        account_id,
        role,
        auth_user_id
      ) VALUES (
        NEW.id,
        v_user_account_id,
        'owner',
        auth.uid()
      )
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.add_creator_as_org_owner() IS
'Trigger function that automatically adds the organization creator as an owner in organization_members table.';

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trg_add_creator_as_org_owner ON public.accounts;

CREATE TRIGGER trg_add_creator_as_org_owner
  AFTER INSERT ON public.accounts
  FOR EACH ROW
  WHEN (NEW.type = 'Organization')
  EXECUTE FUNCTION public.add_creator_as_org_owner();



-- ============================================================================
-- ENABLE RLS ON ALL RELEVANT TABLES
-- ============================================================================

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_bots ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DROP EXISTING ACCOUNT POLICIES (for clean re-application)
-- ============================================================================

DROP POLICY IF EXISTS "users_view_own_user_account" ON public.accounts;
DROP POLICY IF EXISTS "users_insert_own_user_account" ON public.accounts;
DROP POLICY IF EXISTS "users_update_own_user_account" ON public.accounts;
DROP POLICY IF EXISTS "users_view_organizations_they_belong_to" ON public.accounts;
DROP POLICY IF EXISTS "authenticated_users_create_organizations" ON public.accounts;
DROP POLICY IF EXISTS "org_owners_update_organizations" ON public.accounts;
DROP POLICY IF EXISTS "org_owners_delete_organizations" ON public.accounts;
DROP POLICY IF EXISTS "users_view_bots_they_created" ON public.accounts;
DROP POLICY IF EXISTS "users_view_bots_in_their_teams" ON public.accounts;
DROP POLICY IF EXISTS "authenticated_users_create_bots" ON public.accounts;
DROP POLICY IF EXISTS "bot_creators_update_bots" ON public.accounts;
DROP POLICY IF EXISTS "bot_creators_delete_bots" ON public.accounts;

-- ============================================================================
-- ACCOUNTS TABLE: RLS POLICIES FOR USERS
-- ============================================================================

-- Users can view their own user account
CREATE POLICY "users_view_own_user_account" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_view_own_user_account" ON public.accounts IS 
'Allows users to view their own User account using direct auth_user_id check. No recursion.';

-- Users can create their own user account
CREATE POLICY "users_insert_own_user_account" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_insert_own_user_account" ON public.accounts IS 
'Allows users to create their own User account.';

-- Users can update their own user account
CREATE POLICY "users_update_own_user_account" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'User'
  AND auth_user_id = auth.uid()
)
WITH CHECK (
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_update_own_user_account" ON public.accounts IS 
'Allows users to update their own User account.';

-- ============================================================================
-- ACCOUNTS TABLE: RLS POLICIES FOR ORGANIZATIONS
-- ============================================================================

-- Users can view organizations they belong to OR organizations they created (via auth_user_id)
CREATE POLICY "users_view_organizations_they_belong_to" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'Organization'
  AND status <> 'deleted'
  AND (
    -- User is a member of this organization
    id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE account_id = public.get_user_account_id()
        AND account_id IS NOT NULL
    )
    OR
    -- User created this organization (auth_user_id stored for SELECT visibility)
    auth_user_id = auth.uid()
  )
);

COMMENT ON POLICY "users_view_organizations_they_belong_to" ON public.accounts IS 
'Allows users to view organizations they are members of. Uses get_user_account_id() to avoid recursion.';

-- Authenticated users can create organizations
CREATE POLICY "authenticated_users_create_organizations" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'Organization'
  AND status <> 'deleted'
);

COMMENT ON POLICY "authenticated_users_create_organizations" ON public.accounts IS 
'Allows authenticated users to create organizations. The trigger add_creator_as_org_owner will add them as owner if they have a User account.';

-- Organization owners can update their organizations
CREATE POLICY "org_owners_update_organizations" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Organization'
  AND id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
)
WITH CHECK (
  type = 'Organization'
  AND status <> 'deleted'
);

COMMENT ON POLICY "org_owners_update_organizations" ON public.accounts IS 
'Allows organization owners to update their organizations.';

-- Organization owners can soft delete their organizations
CREATE POLICY "org_owners_delete_organizations" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Organization'
  AND id IN (
    SELECT organization_id
    FROM public.organization_members
    WHERE account_id = public.get_user_account_id()
      AND role = 'owner'
  )
)
WITH CHECK (
  type = 'Organization'
  AND status = 'deleted'
);

COMMENT ON POLICY "org_owners_delete_organizations" ON public.accounts IS 
'Allows organization owners to soft-delete their organizations (status = deleted).';

-- ============================================================================
-- ACCOUNTS TABLE: RLS POLICIES FOR BOTS
-- ============================================================================

-- Users can view bots they created
CREATE POLICY "users_view_bots_they_created" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'Bot'
  AND status <> 'deleted'
  AND auth_user_id = auth.uid()
);

COMMENT ON POLICY "users_view_bots_they_created" ON public.accounts IS 
'Allows users to view bots they created.';

-- Users can view bots in their teams
CREATE POLICY "users_view_bots_in_their_teams" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'Bot'
  AND status <> 'deleted'
  AND id IN (
    SELECT tb.bot_id
    FROM public.team_bots tb
    JOIN public.team_members tm ON tm.team_id = tb.team_id
    WHERE tm.auth_user_id = auth.uid()
  )
);

COMMENT ON POLICY "users_view_bots_in_their_teams" ON public.accounts IS 
'Allows users to view bots that are in their teams.';

-- Authenticated users can create bots
CREATE POLICY "authenticated_users_create_bots" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'Bot'
  AND status <> 'deleted'
  AND auth_user_id = auth.uid()
);

COMMENT ON POLICY "authenticated_users_create_bots" ON public.accounts IS 
'Allows authenticated users to create new bots.';

-- Bot creators can update their bots
CREATE POLICY "bot_creators_update_bots" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Bot'
  AND auth_user_id = auth.uid()
)
WITH CHECK (
  type = 'Bot'
  AND status <> 'deleted'
);

COMMENT ON POLICY "bot_creators_update_bots" ON public.accounts IS 
'Allows bot creators to update their bots.';

-- Bot creators can soft-delete their bots
CREATE POLICY "bot_creators_delete_bots" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Bot'
  AND auth_user_id = auth.uid()
)
WITH CHECK (
  type = 'Bot'
  AND status = 'deleted'
);

COMMENT ON POLICY "bot_creators_delete_bots" ON public.accounts IS 
'Allows bot creators to soft-delete their bots (status = deleted).';

-- ============================================================================
-- ORGANIZATION_MEMBERS TABLE: RLS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Organization owners can add members" ON public.organization_members;
DROP POLICY IF EXISTS "Allow initial organization owner on creation" ON public.organization_members;
DROP POLICY IF EXISTS "Organization admins can update member roles" ON public.organization_members;
DROP POLICY IF EXISTS "Organization owners can remove members" ON public.organization_members;
DROP POLICY IF EXISTS "Users can leave organizations" ON public.organization_members;

-- Users can view their own memberships or members of orgs they belong to
CREATE POLICY "Users can view organization members" ON public.organization_members
FOR SELECT
TO authenticated
USING (
  -- Allow users to query their own memberships directly
  auth_user_id = auth.uid()
  OR
  -- Allow viewing other members of organizations they already belong to
  public.is_org_member(organization_id)
);

COMMENT ON POLICY "Users can view organization members" ON public.organization_members IS 
'Allows users to view their own organization memberships or view other members of organizations they belong to.';

-- Organization owners can add members
CREATE POLICY "Organization owners can add members" ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_org_owner(organization_id)
);

COMMENT ON POLICY "Organization owners can add members" ON public.organization_members IS 
'Allows organization owners to add new members.';

-- Allow initial owner to be added when creating an organization
CREATE POLICY "Allow initial organization owner on creation" ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (
  role = 'owner'
  AND auth_user_id = auth.uid()
  AND NOT public.organization_has_members(organization_id)
);

COMMENT ON POLICY "Allow initial organization owner on creation" ON public.organization_members IS 
'Allows the initial owner to be added when an organization is created. Used by the trigger.';

-- Organization admins can update member roles
CREATE POLICY "Organization admins can update member roles" ON public.organization_members
FOR UPDATE
TO authenticated
USING (
  public.is_org_admin(organization_id)
)
WITH CHECK (
  public.is_org_admin(organization_id)
);

COMMENT ON POLICY "Organization admins can update member roles" ON public.organization_members IS 
'Allows organization owners and admins to update member roles.';

-- Organization owners can remove members
CREATE POLICY "Organization owners can remove members" ON public.organization_members
FOR DELETE
TO authenticated
USING (
  public.is_org_owner(organization_id)
);

COMMENT ON POLICY "Organization owners can remove members" ON public.organization_members IS 
'Allows organization owners to remove members.';

-- Users can leave organizations (except owners)
CREATE POLICY "Users can leave organizations" ON public.organization_members
FOR DELETE
TO authenticated
USING (
  auth_user_id = auth.uid()
  AND role <> 'owner'
);

COMMENT ON POLICY "Users can leave organizations" ON public.organization_members IS 
'Allows users to leave organizations they belong to (except owners).';

-- ============================================================================
-- TEAMS TABLE: RLS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "users_view_teams_in_their_organizations" ON public.teams;
DROP POLICY IF EXISTS "org_owners_create_teams" ON public.teams;
DROP POLICY IF EXISTS "org_owners_update_teams" ON public.teams;
DROP POLICY IF EXISTS "org_owners_delete_teams" ON public.teams;

-- Users can view teams in their organizations
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
'Allows users to view teams in organizations they belong to.';

-- Organization owners can create teams
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
'Allows organization owners to create new teams in their organizations.';

-- Organization owners can update teams
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
);

COMMENT ON POLICY "org_owners_update_teams" ON public.teams IS 
'Allows organization owners to update teams in their organizations.';

-- Organization owners can delete teams
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
'Allows organization owners to delete teams in their organizations.';

-- ============================================================================
-- TEAM_MEMBERS TABLE: RLS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view team members in their teams" ON public.team_members;
DROP POLICY IF EXISTS "Allow initial team leader" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can add members" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can update member roles" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can remove members" ON public.team_members;
DROP POLICY IF EXISTS "Users can remove themselves from teams" ON public.team_members;

-- Users can view team members in their teams
CREATE POLICY "Users can view team members in their teams" ON public.team_members
FOR SELECT
TO authenticated
USING (
  public.is_team_member(team_id)
);

COMMENT ON POLICY "Users can view team members in their teams" ON public.team_members IS 
'Allows users to view members in teams they belong to.';

-- Allow initial team leader (first member of team)
CREATE POLICY "Allow initial team leader" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  role = 'leader'
  AND auth_user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 
    FROM public.team_members tm
    WHERE tm.team_id = team_members.team_id
  )
);

COMMENT ON POLICY "Allow initial team leader" ON public.team_members IS 
'Allows the first member of a team to be added as a leader. Used by the trigger.';

-- Team leaders can add members
CREATE POLICY "Team leaders can add members" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_team_leader(team_id)
);

COMMENT ON POLICY "Team leaders can add members" ON public.team_members IS 
'Allows team leaders to add new members.';

-- Team leaders can update member roles
CREATE POLICY "Team leaders can update member roles" ON public.team_members
FOR UPDATE
TO authenticated
USING (
  public.is_team_leader(team_id)
)
WITH CHECK (
  public.is_team_leader(team_id)
);

COMMENT ON POLICY "Team leaders can update member roles" ON public.team_members IS 
'Allows team leaders to update member roles.';

-- Team leaders can remove members
CREATE POLICY "Team leaders can remove members" ON public.team_members
FOR DELETE
TO authenticated
USING (
  public.is_team_leader(team_id)
);

COMMENT ON POLICY "Team leaders can remove members" ON public.team_members IS 
'Allows team leaders to remove members.';

-- Users can remove themselves from teams
CREATE POLICY "Users can remove themselves from teams" ON public.team_members
FOR DELETE
TO authenticated
USING (
  auth_user_id = auth.uid()
);

COMMENT ON POLICY "Users can remove themselves from teams" ON public.team_members IS 
'Allows users to leave teams themselves.';

-- ============================================================================
-- TEAM_BOTS TABLE: RLS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "team_owners_view_team_bots" ON public.team_bots;
DROP POLICY IF EXISTS "team_owners_add_bots_to_teams" ON public.team_bots;
DROP POLICY IF EXISTS "team_owners_remove_bots_from_teams" ON public.team_bots;

-- Team leaders can view team bots
CREATE POLICY "team_owners_view_team_bots" ON public.team_bots
FOR SELECT
TO authenticated
USING (
  team_id IN (
    SELECT tm.team_id
    FROM public.team_members tm
    WHERE tm.auth_user_id = auth.uid()
      AND tm.role = 'leader'
  )
);

COMMENT ON POLICY "team_owners_view_team_bots" ON public.team_bots IS 
'Allows team leaders to view bots in their teams.';

-- Team leaders can add bots to teams
CREATE POLICY "team_owners_add_bots_to_teams" ON public.team_bots
FOR INSERT
TO authenticated
WITH CHECK (
  team_id IN (
    SELECT tm.team_id
    FROM public.team_members tm
    WHERE tm.auth_user_id = auth.uid()
      AND tm.role = 'leader'
  )
);

COMMENT ON POLICY "team_owners_add_bots_to_teams" ON public.team_bots IS 
'Allows team leaders to add bots to their teams.';

-- Team leaders can remove bots from teams
CREATE POLICY "team_owners_remove_bots_from_teams" ON public.team_bots
FOR DELETE
TO authenticated
USING (
  team_id IN (
    SELECT tm.team_id
    FROM public.team_members tm
    WHERE tm.auth_user_id = auth.uid()
      AND tm.role = 'leader'
  )
);

COMMENT ON POLICY "team_owners_remove_bots_from_teams" ON public.team_bots IS 
'Allows team leaders to remove bots from their teams.';

-- ============================================================================
-- UNIQUE CONSTRAINT FIX: Allow organizations to store creator auth_user_id
-- ============================================================================

-- Drop existing unique constraint if exists
ALTER TABLE public.accounts DROP CONSTRAINT IF EXISTS unique_auth_user_id;

-- Create partial unique index: only enforce uniqueness for User type
-- This allows each auth.users to have exactly one User account,
-- while Organizations and Bots can store creator's auth_user_id
DROP INDEX IF EXISTS unique_user_auth_user_id;

CREATE UNIQUE INDEX IF NOT EXISTS unique_user_auth_user_id 
ON public.accounts (auth_user_id) 
WHERE type = 'User';

COMMENT ON INDEX public.unique_user_auth_user_id IS
'Ensures each auth.users has exactly one User account. Organizations and Bots can store creator auth_user_id for access control.';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON TABLE public.accounts TO authenticated;
GRANT ALL ON TABLE public.accounts TO service_role;
GRANT ALL ON TABLE public.organization_members TO authenticated;
GRANT ALL ON TABLE public.organization_members TO service_role;
GRANT ALL ON TABLE public.teams TO authenticated;
GRANT ALL ON TABLE public.teams TO service_role;
GRANT ALL ON TABLE public.team_members TO authenticated;
GRANT ALL ON TABLE public.team_members TO service_role;
GRANT ALL ON TABLE public.team_bots TO authenticated;
GRANT ALL ON TABLE public.team_bots TO service_role;

COMMIT;
