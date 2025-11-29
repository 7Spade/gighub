-- Migration: Rewrite Bot RLS policies
-- Purpose: Fix Bot account RLS policies using get_user_account_id() to avoid recursion
-- Created: 2025-11-24
-- Phase: 4 - RLS Policy Fixes (RLS-004)
--
-- Bot policies control access to bot accounts. Bots are visible to:
-- 1. The user who created the bot (auth_user_id)
-- 2. Members of teams where the bot is assigned
--
-- Key principle: Use get_user_account_id() to avoid infinite recursion.

-- ============================================================================
-- DROP EXISTING POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "users_view_bots_they_created" ON public.accounts;
DROP POLICY IF EXISTS "users_view_bots_in_their_teams" ON public.accounts;
DROP POLICY IF EXISTS "bot_creators_update_bots" ON public.accounts;
DROP POLICY IF EXISTS "bot_creators_delete_bots" ON public.accounts;
DROP POLICY IF EXISTS "authenticated_users_create_bots" ON public.accounts;

-- ============================================================================
-- SELECT POLICIES - Who can view bots
-- ============================================================================

-- Policy 1: Users can view bots they created
CREATE POLICY "users_view_bots_they_created" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'Bot'
  AND status <> 'deleted'
  AND auth_user_id = auth.uid()
);

COMMENT ON POLICY "users_view_bots_they_created" ON public.accounts IS
'Allows users to view bots they created directly.
Uses auth.uid() check to avoid recursion.';

-- Policy 2: Users can view bots in teams they belong to
CREATE POLICY "users_view_bots_in_their_teams" ON public.accounts
FOR SELECT
TO authenticated
USING (
  type = 'Bot'
  AND status <> 'deleted'
  AND id IN (
    -- Get bots from teams where user is a member
    SELECT tb.bot_id
    FROM public.team_bots tb
    JOIN public.team_members tm ON tm.team_id = tb.team_id
    WHERE tm.account_id = public.get_user_account_id()
  )
);

COMMENT ON POLICY "users_view_bots_in_their_teams" ON public.accounts IS
'Allows users to view bots assigned to teams they are members of.
Uses get_user_account_id() to avoid infinite recursion.';

-- ============================================================================
-- UPDATE POLICY - Bot creators can update their bots
-- ============================================================================

CREATE POLICY "bot_creators_update_bots" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Bot'
  AND status <> 'deleted'
  AND auth_user_id = auth.uid()
)
WITH CHECK (
  -- Ensure updates maintain data integrity
  type = 'Bot'  -- Cannot change account type
  AND auth_user_id = auth.uid()  -- Cannot change creator
  AND status <> 'deleted'
);

COMMENT ON POLICY "bot_creators_update_bots" ON public.accounts IS
'Allows bot creators to update their bots.
Prevents changing account type or creator.';

-- ============================================================================
-- DELETE POLICY - Bot creators can soft-delete their bots
-- ============================================================================

CREATE POLICY "bot_creators_delete_bots" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  type = 'Bot'
  AND auth_user_id = auth.uid()
)
WITH CHECK (
  -- Allow setting status to deleted (soft delete)
  type = 'Bot'
  AND status = 'deleted'
);

COMMENT ON POLICY "bot_creators_delete_bots" ON public.accounts IS
'Allows bot creators to soft-delete their bots.
Soft delete is implemented by setting status = deleted.';

-- ============================================================================
-- INSERT POLICY - Authenticated users can create bots
-- ============================================================================

CREATE POLICY "authenticated_users_create_bots" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'Bot'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "authenticated_users_create_bots" ON public.accounts IS
'Allows authenticated users to create new bots.
Sets auth_user_id to the authenticated user.';

-- ============================================================================
-- ADDITIONAL TABLES - team_bots junction table
-- ============================================================================

-- Create team_bots table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.team_bots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  bot_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  added_by_auth_user_id UUID REFERENCES auth.users(id),
  
  -- Ensure same bot isn't added to team twice
  UNIQUE(team_id, bot_id)
);

COMMENT ON TABLE public.team_bots IS
'Junction table mapping bots to teams. 
Enables team-level bot access control through RLS policies.';

-- Enable RLS on team_bots
ALTER TABLE public.team_bots ENABLE ROW LEVEL SECURITY;

-- RLS: Users can view team_bots for teams they belong to
CREATE POLICY "users_view_team_bots_for_their_teams" ON public.team_bots
FOR SELECT
TO authenticated
USING (
  team_id IN (
    SELECT team_id
    FROM public.team_members
    WHERE account_id = public.get_user_account_id()
  )
);

-- RLS: Team owners can manage team_bots
CREATE POLICY "team_owners_manage_team_bots" ON public.team_bots
FOR ALL
TO authenticated
USING (
  team_id IN (
    SELECT tm.team_id
    FROM public.team_members tm
    WHERE tm.account_id = public.get_user_account_id()
      AND tm.role = 'leader'
  )
)
WITH CHECK (
  team_id IN (
    SELECT tm.team_id
    FROM public.team_members tm
    WHERE tm.account_id = public.get_user_account_id()
      AND tm.role = 'leader'
  )
);

COMMENT ON POLICY "users_view_team_bots_for_their_teams" ON public.team_bots IS
'Allows users to view bot assignments for teams they belong to.';

COMMENT ON POLICY "team_owners_manage_team_bots" ON public.team_bots IS
'Allows team owners to add/remove/update bots in their teams.';
