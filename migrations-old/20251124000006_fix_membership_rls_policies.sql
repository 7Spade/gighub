-- Migration: Fix membership RLS policies to eliminate accounts recursion
-- Purpose: Rewrite organization_members and team_members policies so they never query
--          the accounts table (or themselves with RLS enabled). Adds helper functions
--          that run with row_security = off.
-- Date: 2025-11-24

BEGIN;

-- ============================================================================
-- Helper functions (SECURITY DEFINER, row_security = off)
-- ============================================================================

DROP FUNCTION IF EXISTS public.is_org_member(uuid);
DROP FUNCTION IF EXISTS public.is_org_owner(uuid);
DROP FUNCTION IF EXISTS public.is_org_admin(uuid);
DROP FUNCTION IF EXISTS public.organization_has_members(uuid);
DROP FUNCTION IF EXISTS public.is_team_member(uuid);
DROP FUNCTION IF EXISTS public.is_team_leader(uuid);

CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
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

CREATE OR REPLACE FUNCTION public.is_org_owner(target_org_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
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

CREATE OR REPLACE FUNCTION public.is_org_admin(target_org_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
      AND role = ANY(ARRAY['owner', 'admin'])
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.organization_has_members(target_org_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_team_member(target_team_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
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

CREATE OR REPLACE FUNCTION public.is_team_leader(target_team_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
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

COMMENT ON FUNCTION public.is_org_member(uuid) IS 'Returns true if auth.uid() is a member of the specified organization.';
COMMENT ON FUNCTION public.is_org_owner(uuid) IS 'Returns true if auth.uid() is an owner of the specified organization.';
COMMENT ON FUNCTION public.is_org_admin(uuid) IS 'Returns true if auth.uid() is an owner or admin of the specified organization.';
COMMENT ON FUNCTION public.organization_has_members(uuid) IS 'Returns true if the organization already has at least one member.';
COMMENT ON FUNCTION public.is_team_member(uuid) IS 'Returns true if auth.uid() is a member of the specified team.';
COMMENT ON FUNCTION public.is_team_leader(uuid) IS 'Returns true if auth.uid() is a leader of the specified team.';

GRANT EXECUTE ON FUNCTION public.is_org_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_owner(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.organization_has_members(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_team_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_team_leader(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.is_org_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_org_owner(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_org_admin(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.organization_has_members(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_team_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_team_leader(uuid) FROM PUBLIC, anon;

-- ============================================================================
-- Indexes to support auth_user_id lookups
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_organization_members_auth_user
  ON public.organization_members (auth_user_id);

CREATE INDEX IF NOT EXISTS idx_team_members_auth_user
  ON public.team_members (auth_user_id);

-- ============================================================================
-- Rewrite organization_members policies (all TO authenticated)
-- ============================================================================

DROP POLICY IF EXISTS "Allow initial organization owner on creation" ON public.organization_members;
DROP POLICY IF EXISTS "Organization admins can update member roles" ON public.organization_members;
DROP POLICY IF EXISTS "Organization owners can add members" ON public.organization_members;
DROP POLICY IF EXISTS "Organization owners can remove members" ON public.organization_members;
DROP POLICY IF EXISTS "Users can leave organizations" ON public.organization_members;
DROP POLICY IF EXISTS "Users can view organization members" ON public.organization_members;

-- Users can view memberships for organizations they belong to (used by accounts RLS)
CREATE POLICY "Users can view organization members" ON public.organization_members
FOR SELECT
TO authenticated
USING (
  public.is_org_member(organization_id)
);

-- Initial owner creation (first member)
CREATE POLICY "Allow initial organization owner on creation" ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (
  role = 'owner'
  AND auth_user_id = auth.uid()
  AND NOT public.organization_has_members(organization_id)
);

-- Organization owners can add members
CREATE POLICY "Organization owners can add members" ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_org_owner(organization_id)
);

-- Organization admins (owners + admins) can update member roles
CREATE POLICY "Organization admins can update member roles" ON public.organization_members
FOR UPDATE
TO authenticated
USING (
  public.is_org_admin(organization_id)
)
WITH CHECK (
  CASE
    WHEN role = 'owner' THEN public.is_org_owner(organization_id)
    ELSE public.is_org_admin(organization_id)
  END
);

-- Users can leave organizations (but cannot delete their owner row)
CREATE POLICY "Users can leave organizations" ON public.organization_members
FOR DELETE
TO authenticated
USING (
  auth_user_id = auth.uid()
  AND role <> 'owner'
);

-- Organization owners can remove members
CREATE POLICY "Organization owners can remove members" ON public.organization_members
FOR DELETE
TO authenticated
USING (
  public.is_org_owner(organization_id)
);

-- ============================================================================
-- Rewrite team_members policies (all TO authenticated)
-- ============================================================================

DROP POLICY IF EXISTS "Team leaders can add members" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can remove members" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can update member roles" ON public.team_members;
DROP POLICY IF EXISTS "Users can remove themselves from teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can view team members in their teams" ON public.team_members;

-- Users can view teams they belong to (used by accounts/bots RLS)
CREATE POLICY "Users can view team members in their teams" ON public.team_members
FOR SELECT
TO authenticated
USING (
  public.is_team_member(team_id)
);

-- Team leaders can add members
CREATE POLICY "Team leaders can add members" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_team_leader(team_id)
);

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

-- Users can remove themselves from teams
CREATE POLICY "Users can remove themselves from teams" ON public.team_members
FOR DELETE
TO authenticated
USING (
  auth_user_id = auth.uid()
);

-- Team leaders can remove members
CREATE POLICY "Team leaders can remove members" ON public.team_members
FOR DELETE
TO authenticated
USING (
  public.is_team_leader(team_id)
);

COMMIT;

