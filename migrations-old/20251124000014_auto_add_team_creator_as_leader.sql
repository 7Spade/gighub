-- Migration: Auto-add team creator as leader
-- Purpose: Automatically add the team creator as leader when a new team is created
-- Created: 2025-11-24
-- Solves: The chicken-and-egg problem of adding the first member to a team

BEGIN;

-- Create function to add creator as team leader
CREATE OR REPLACE FUNCTION public.add_team_creator_as_leader()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_user_account_id UUID;
BEGIN
  -- Get the user's account_id from auth_user_id
  SELECT id INTO v_user_account_id
  FROM public.accounts
  WHERE auth_user_id = (
    SELECT auth_user_id FROM public.accounts WHERE id = ( 
      SELECT organization_id FROM public.teams WHERE id = NEW.id
    ) LIMIT 1
  )
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;
  
  -- If we can find user account from organization creator, use it
  IF v_user_account_id IS NULL THEN
    -- Otherwise try to get from current auth context
    SELECT id INTO v_user_account_id
    FROM public.accounts
    WHERE auth_user_id = auth.uid()
      AND type = 'User'
      AND status != 'deleted'
    LIMIT 1;
  END IF;
  
  -- Add creator as team leader if user account exists
  IF v_user_account_id IS NOT NULL THEN
    INSERT INTO public.team_members (
      team_id,
      account_id,
      role,
      auth_user_id
    ) VALUES (
      NEW.id,
      v_user_account_id,
      'leader',
      auth.uid()
    )
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS add_team_creator_as_leader_trigger ON public.teams;

-- Create trigger
CREATE TRIGGER add_team_creator_as_leader_trigger
  AFTER INSERT ON public.teams
  FOR EACH ROW
  EXECUTE FUNCTION public.add_team_creator_as_leader();

COMMENT ON FUNCTION public.add_team_creator_as_leader() IS
'Automatically adds the team creator as a leader when a new team is created.
Solves the chicken-and-egg problem of needing a leader to add members.';

COMMIT;

