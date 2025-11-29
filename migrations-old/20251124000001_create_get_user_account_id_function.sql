-- Migration: Create get_user_account_id() helper function
-- Purpose: Provide a SECURITY DEFINER function to query user's account_id without triggering RLS recursion
-- Created: 2025-11-24
-- Phase: 4 - RLS Policy Fixes (RLS-001)
--
-- This function is critical for fixing infinite recursion in RLS policies.
-- By using SECURITY DEFINER and SET row_security = off, it can query the accounts
-- table without triggering RLS policies, breaking the recursive chain.
--
-- Usage in RLS policies:
--   WHERE account_id = public.get_user_account_id()
--
-- Security considerations:
-- - Function only returns data for auth.uid(), ensuring users can only get their own account_id
-- - SECURITY DEFINER is safe here because the function doesn't expose sensitive data
-- - The function is intentionally simple to minimize security surface area

-- Drop function if it exists (for re-running migration)
DROP FUNCTION IF EXISTS public.get_user_account_id();

-- Create the helper function
CREATE OR REPLACE FUNCTION public.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
STABLE
AS $$
DECLARE
  v_account_id UUID;
BEGIN
  -- Query accounts table without triggering RLS
  -- This is safe because we only return the account_id for auth.uid()
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;
  
  -- Return NULL if no account found (user hasn't created an account yet)
  RETURN v_account_id;
END;
$$;

-- Add comment to document the function
COMMENT ON FUNCTION public.get_user_account_id() IS 
'Returns the account_id (UUID) for the currently authenticated user (auth.uid()). 
Uses SECURITY DEFINER to bypass RLS and avoid infinite recursion. 
Only returns User-type accounts with status != deleted. Returns NULL if no matching account found.';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_account_id() TO authenticated;

-- Revoke from other roles for security
REVOKE EXECUTE ON FUNCTION public.get_user_account_id() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_account_id() FROM public;
