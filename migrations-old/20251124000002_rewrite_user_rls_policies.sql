-- Migration: Rewrite User RLS policies
-- Purpose: Fix User account RLS policies to avoid infinite recursion
-- Created: 2025-11-24
-- Phase: 4 - RLS Policy Fixes (RLS-002)
--
-- User policies are simpler than Organization/Bot policies because they can
-- directly check auth_user_id = auth.uid() without needing to JOIN the accounts table.
-- This avoids the infinite recursion issue entirely.
--
-- Key principle: User policies check auth_user_id column directly, not through JOINs.

-- ============================================================================
-- DROP EXISTING POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "users_view_own_user_account" ON public.accounts;
DROP POLICY IF EXISTS "users_update_own_user_account" ON public.accounts;
DROP POLICY IF EXISTS "users_insert_own_user_account" ON public.accounts;

-- ============================================================================
-- SELECT POLICY - Users can view their own User account
-- ============================================================================

CREATE POLICY "users_view_own_user_account" ON public.accounts
FOR SELECT
TO authenticated
USING (
  -- Direct check against auth_user_id - no JOIN needed
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_view_own_user_account" ON public.accounts IS
'Allows authenticated users to view their own User-type account. 
Uses direct auth_user_id check to avoid recursion.';

-- ============================================================================
-- UPDATE POLICY - Users can update their own User account
-- ============================================================================

CREATE POLICY "users_update_own_user_account" ON public.accounts
FOR UPDATE
TO authenticated
USING (
  -- Check current row before update
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
)
WITH CHECK (
  -- Ensure updates maintain data integrity
  type = 'User'  -- Cannot change account type
  AND auth_user_id = auth.uid()  -- Cannot change owner
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_update_own_user_account" ON public.accounts IS
'Allows authenticated users to update their own User-type account.
Prevents changing account type or owner through WITH CHECK clause.';

-- ============================================================================
-- INSERT POLICY - Users can create their own User account
-- ============================================================================

CREATE POLICY "users_insert_own_user_account" ON public.accounts
FOR INSERT
TO authenticated
WITH CHECK (
  type = 'User'
  AND auth_user_id = auth.uid()
  AND status <> 'deleted'
);

COMMENT ON POLICY "users_insert_own_user_account" ON public.accounts IS
'Allows authenticated users to create their own User-type account.
Ensures auth_user_id matches the authenticated user.';

-- ============================================================================
-- NO DELETE POLICY
-- ============================================================================
-- We use soft delete (status = 'deleted') instead of hard delete.
-- Updates handle soft delete through the update policy above.
