-- Migration: Fix team_members initial leader policy
-- Purpose: Correctly check if team has no members
-- Created: 2025-11-24
-- Issue: Previous policy had incorrect subquery (team_id = team_id always true)

BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow initial team leader" ON public.team_members;
DROP POLICY IF EXISTS "Team leaders can add members" ON public.team_members;

-- Create corrected policy for initial leader
CREATE POLICY "Allow initial team leader" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  role = 'leader'
  AND auth_user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 
    FROM public.team_members tm
    WHERE tm.team_id = team_members.team_id  -- Correctly reference the inserting row
  )
);

-- Recreate policy for team leaders to add members
CREATE POLICY "Team leaders can add members" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_team_leader(team_id)
);

COMMENT ON POLICY "Allow initial team leader" ON public.team_members IS
'Allows adding the first leader to a team that has no members yet.';

COMMENT ON POLICY "Team leaders can add members" ON public.team_members IS
'Allows existing team leaders to add new members.';

COMMIT;

