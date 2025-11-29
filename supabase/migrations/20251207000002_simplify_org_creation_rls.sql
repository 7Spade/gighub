-- Migration: Simplify Organization Creation RLS
-- Purpose: Use BEFORE INSERT trigger to set auth_user_id, simplifying RLS policies
-- Phase: 3 - RLS Policies (Simplification)
-- Created: 2025-12-07
-- Dependencies: 20251203000002_create_user_rls_policies.sql
-- 
-- Problem: INSERT policy requiring auth_user_id = auth.uid() causes issues because
-- the application must pass auth_user_id explicitly, and any mismatch fails the policy.
-- 
-- Solution (Simpler Approach):
-- 1. Create BEFORE INSERT trigger to automatically set auth_user_id = auth.uid()
-- 2. Simplify INSERT policy to just require authenticated user
-- 3. Keep SELECT policy to allow creator access via auth_user_id
-- 
-- Benefits:
-- - Application code doesn't need to pass auth_user_id
-- - Cannot spoof auth_user_id (set by database function)
-- - Simpler, more secure RLS policies

-- ============================================================================
-- STEP 1: CREATE BEFORE INSERT TRIGGER TO AUTO-SET auth_user_id
-- ============================================================================

-- Function to automatically set auth_user_id on INSERT
CREATE OR REPLACE FUNCTION public.set_auth_user_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Set auth_user_id to current authenticated user
  -- This ensures the value cannot be spoofed by the client
  NEW.auth_user_id := auth.uid();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_auth_user_id() IS
'Automatically sets auth_user_id to the current authenticated user on INSERT.
This ensures the value is always correct and cannot be spoofed.';

-- Create trigger to set auth_user_id BEFORE INSERT
DROP TRIGGER IF EXISTS set_auth_user_id_trigger ON public.accounts;
CREATE TRIGGER set_auth_user_id_trigger
  BEFORE INSERT ON public.accounts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_auth_user_id();

COMMENT ON TRIGGER set_auth_user_id_trigger ON public.accounts IS
'Automatically sets auth_user_id to auth.uid() before INSERT, ensuring secure ownership.';

-- ============================================================================
-- STEP 2: SIMPLIFY INSERT POLICY
-- ============================================================================

-- Drop old INSERT policy
DROP POLICY IF EXISTS "users_insert_own_user_account" ON public.accounts;

-- New simplified INSERT policy - just check user is authenticated
-- The trigger ensures auth_user_id is set correctly
CREATE POLICY "users_insert_own_user_account"
ON public.accounts
FOR INSERT
WITH CHECK (
  -- Only allow User and Organization types to be created by authenticated users
  -- Bot accounts may have different creation rules in the future
  auth.uid() IS NOT NULL AND
  type IN ('User', 'Organization')
);

COMMENT ON POLICY "users_insert_own_user_account" ON public.accounts IS
'Authenticated users can create User or Organization accounts.
The set_auth_user_id_trigger automatically sets auth_user_id to auth.uid().';

-- ============================================================================
-- STEP 3: ENSURE SELECT POLICY ALLOWS CREATOR ACCESS
-- ============================================================================

-- The SELECT policy was updated in 20251207000001_fix_org_select_policy_for_creators.sql
-- to include: (type = 'Organization' AND auth_user_id = auth.uid())
-- This ensures creators can see their organizations immediately after INSERT.
-- No changes needed here.

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION public.set_auth_user_id() TO authenticated;
