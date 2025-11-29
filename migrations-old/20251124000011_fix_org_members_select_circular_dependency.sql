-- Migration: Fix organization_members SELECT policy circular dependency
-- Purpose: Allow users to query their own organization memberships
-- Created: 2025-11-24
-- Issue: Users cannot discover which organizations they belong to because
--        the SELECT policy requires is_org_member() check, which creates
--        a circular dependency when querying by auth_user_id.
--
-- Solution: Allow direct auth_user_id queries OR is_org_member checks

BEGIN;

-- Drop existing policy
DROP POLICY IF EXISTS "Users can view organization members" ON public.organization_members;

-- Create corrected policy
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
'Allows users to view their own organization memberships (auth_user_id check)
or view other members of organizations they belong to (is_org_member check).
Fixes circular dependency issue in organization discovery.';

COMMIT;

