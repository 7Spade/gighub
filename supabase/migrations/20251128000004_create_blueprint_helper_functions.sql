-- Migration: Create blueprint helper functions
-- Purpose: Helper functions for RLS policies (per SETC-02)
-- Created: 2025-11-28
-- Phase: Blueprint Container Layer - RLS Support

-- ============================================================================
-- HELPER FUNCTIONS FOR BLUEPRINT RLS
-- ============================================================================

-- Check if current user is a member of a blueprint
CREATE OR REPLACE FUNCTION public.is_blueprint_member(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_account_id UUID;
BEGIN
  v_account_id := public.get_user_account_id();
  IF v_account_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN EXISTS (
    SELECT 1 FROM public.blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = v_account_id
  );
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_member(UUID) IS 
'Returns true if the current authenticated user is a member of the specified blueprint.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_member(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_member(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_member(UUID) FROM public;

-- Get user role in a blueprint
CREATE OR REPLACE FUNCTION public.get_user_role_in_blueprint(p_blueprint_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_role TEXT;
  v_account_id UUID;
BEGIN
  v_account_id := public.get_user_account_id();
  IF v_account_id IS NULL THEN
    RETURN 'none';
  END IF;
  
  SELECT role INTO v_role
  FROM public.blueprint_members
  WHERE blueprint_id = p_blueprint_id
  AND account_id = v_account_id;
  
  RETURN COALESCE(v_role, 'none');
END;
$$;

COMMENT ON FUNCTION public.get_user_role_in_blueprint(UUID) IS 
'Returns the role of the current authenticated user in the specified blueprint (owner, admin, member, viewer, or none).';

GRANT EXECUTE ON FUNCTION public.get_user_role_in_blueprint(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_role_in_blueprint(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_role_in_blueprint(UUID) FROM public;

-- Check if user is blueprint admin (owner or admin role)
CREATE OR REPLACE FUNCTION public.is_blueprint_admin(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN public.get_user_role_in_blueprint(p_blueprint_id) IN ('owner', 'admin');
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_admin(UUID) IS 
'Returns true if the current authenticated user has admin privileges (owner or admin role) in the specified blueprint.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) FROM public;

-- Check if user is blueprint owner
CREATE OR REPLACE FUNCTION public.is_blueprint_owner(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN public.get_user_role_in_blueprint(p_blueprint_id) = 'owner';
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_owner(UUID) IS 
'Returns true if the current authenticated user is the owner of the specified blueprint.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) FROM public;
