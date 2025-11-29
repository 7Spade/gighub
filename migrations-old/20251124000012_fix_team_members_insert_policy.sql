-- Migration: Fix team_members INSERT policy - allow initial leader
-- Purpose: Allow adding the first leader to a new team
-- Created: 2025-11-24
-- Issue: Cannot add members to a newly created team because no leader exists yet

BEGIN;

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "Team leaders can add members" ON public.team_members;

-- Create policy for initial leader (first member of team)
CREATE POLICY "Allow initial team leader" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  role = 'leader'
  AND auth_user_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 
    FROM public.team_members 
    WHERE team_id = team_members.team_id
  )
);

-- Create policy for team leaders to add members
CREATE POLICY "Team leaders can add members" ON public.team_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_team_leader(team_id)
);

COMMENT ON POLICY "Allow initial team leader" ON public.team_members IS
'Allows adding the first leader to a new team. Required for initial team setup.';

COMMENT ON POLICY "Team leaders can add members" ON public.team_members IS
'Allows existing team leaders to add new members.';

COMMIT;

