-- Migration: Create blueprints table with RLS policies
-- Purpose: Create blueprints container table with proper RLS to avoid 42501 permission errors
-- Created: 2025-11-29
-- Phase: Blueprint Container Layer
--
-- Security Design:
-- - Uses SECURITY DEFINER helper functions to avoid RLS recursion
-- - Follows the pattern established in get_user_account_id()
-- - Blueprint visibility: private, internal, public
-- - Blueprint status: draft, active, archived, deleted
--
-- IMPORTANT: Tables must be created BEFORE helper functions that reference them

BEGIN;

-- ============================================================================
-- CREATE BLUEPRINTS TABLE (FIRST)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  slug VARCHAR(100),
  status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility TEXT DEFAULT 'private' NOT NULL CHECK (visibility IN ('private', 'internal', 'public')),
  category TEXT CHECK (category IN ('construction', 'renovation', 'maintenance', 'inspection', 'other')),
  settings JSONB DEFAULT '{}' NOT NULL,
  metadata JSONB DEFAULT '{}' NOT NULL,
  cover_image_url TEXT,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  deleted_at TIMESTAMPTZ,
  UNIQUE (owner_id, slug)
);

COMMENT ON TABLE public.blueprints IS
'Blueprints are logical containers providing data isolation for workspaces.
Each blueprint belongs to an owner (user, organization, or team).
Status: draft, active, archived, deleted. Visibility: private, internal, public.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_blueprints_owner_id ON public.blueprints(owner_id);
CREATE INDEX IF NOT EXISTS idx_blueprints_status ON public.blueprints(status) WHERE status != 'deleted';
CREATE INDEX IF NOT EXISTS idx_blueprints_visibility ON public.blueprints(visibility);
CREATE INDEX IF NOT EXISTS idx_blueprints_slug ON public.blueprints(slug);
CREATE INDEX IF NOT EXISTS idx_blueprints_created_by ON public.blueprints(created_by);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_blueprints_updated_at ON public.blueprints;
CREATE TRIGGER update_blueprints_updated_at
  BEFORE UPDATE ON public.blueprints
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CREATE BLUEPRINT_MEMBERS TABLE (SECOND)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  account_id UUID REFERENCES public.accounts(id) ON DELETE CASCADE,
  auth_user_id UUID,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  business_role TEXT,
  joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  invited_by UUID REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (blueprint_id, account_id)
);

COMMENT ON TABLE public.blueprint_members IS
'Blueprint membership with owner, admin, member, viewer roles.
auth_user_id is used for direct RLS checks to avoid recursion.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_blueprint_members_blueprint_id ON public.blueprint_members(blueprint_id);
CREATE INDEX IF NOT EXISTS idx_blueprint_members_account_id ON public.blueprint_members(account_id);
CREATE INDEX IF NOT EXISTS idx_blueprint_members_auth_user_id ON public.blueprint_members(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_blueprint_members_role ON public.blueprint_members(role);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_blueprint_members_updated_at ON public.blueprint_members;
CREATE TRIGGER update_blueprint_members_updated_at
  BEFORE UPDATE ON public.blueprint_members
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CREATE BLUEPRINT HELPER FUNCTIONS (THIRD - after tables exist)
-- ============================================================================

-- Function to check if user is a blueprint member
CREATE OR REPLACE FUNCTION public.is_blueprint_member(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()
  );
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_member(UUID) IS
'Returns true if auth.uid() is a member of the specified blueprint.
Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_member(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_member(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_member(UUID) FROM public;

-- Function to check if user is a blueprint owner or admin
CREATE OR REPLACE FUNCTION public.is_blueprint_admin(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()
      AND role IN ('owner', 'admin')
  );
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_admin(UUID) IS
'Returns true if auth.uid() is an owner or admin of the specified blueprint.
Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_admin(UUID) FROM public;

-- Function to check if user is a blueprint owner
CREATE OR REPLACE FUNCTION public.is_blueprint_owner(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()
      AND role = 'owner'
  );
END;
$$;

COMMENT ON FUNCTION public.is_blueprint_owner(UUID) IS
'Returns true if auth.uid() is an owner of the specified blueprint.
Uses SECURITY DEFINER to avoid RLS recursion.';

GRANT EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_blueprint_owner(UUID) FROM public;

-- ============================================================================
-- AUTO-ADD CREATOR AS BLUEPRINT OWNER
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_blueprint_creator_as_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_user_account_id UUID;
BEGIN
  -- Get creator's account_id
  SELECT id INTO v_user_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;

  -- Add creator as blueprint owner
  IF v_user_account_id IS NOT NULL THEN
    INSERT INTO public.blueprint_members (
      blueprint_id,
      account_id,
      auth_user_id,
      role,
      invited_by
    ) VALUES (
      NEW.id,
      v_user_account_id,
      auth.uid(),
      'owner',
      v_user_account_id
    )
    ON CONFLICT (blueprint_id, account_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.add_blueprint_creator_as_owner() IS
'Automatically adds the blueprint creator as owner when a new blueprint is created.';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS add_blueprint_creator_as_owner_trigger ON public.blueprints;

CREATE TRIGGER add_blueprint_creator_as_owner_trigger
  AFTER INSERT ON public.blueprints
  FOR EACH ROW
  EXECUTE FUNCTION public.add_blueprint_creator_as_owner();

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

ALTER TABLE public.blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blueprint_members ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DROP EXISTING POLICIES (for clean re-application)
-- ============================================================================

DROP POLICY IF EXISTS "blueprint_members_can_view" ON public.blueprints;
DROP POLICY IF EXISTS "authenticated_users_create_blueprints" ON public.blueprints;
DROP POLICY IF EXISTS "blueprint_admins_update" ON public.blueprints;
DROP POLICY IF EXISTS "blueprint_owners_delete" ON public.blueprints;
DROP POLICY IF EXISTS "blueprint_members_view" ON public.blueprint_members;
DROP POLICY IF EXISTS "blueprint_admins_add_members" ON public.blueprint_members;
DROP POLICY IF EXISTS "blueprint_admins_update_members" ON public.blueprint_members;
DROP POLICY IF EXISTS "blueprint_admins_remove_members" ON public.blueprint_members;

-- ============================================================================
-- BLUEPRINTS RLS POLICIES
-- ============================================================================

-- SELECT: Members can view their blueprints, public blueprints visible to all
CREATE POLICY "blueprint_members_can_view" ON public.blueprints
FOR SELECT
TO authenticated
USING (
  status != 'deleted'
  AND (
    -- User is a member of this blueprint
    public.is_blueprint_member(id)
    OR
    -- Public blueprints are visible to all authenticated users
    visibility = 'public'
    OR
    -- User created this blueprint
    created_by = public.get_user_account_id()
  )
);

COMMENT ON POLICY "blueprint_members_can_view" ON public.blueprints IS
'Allows blueprint members to view their blueprints. Public blueprints visible to all authenticated users.';

-- INSERT: Authenticated users can create blueprints
CREATE POLICY "authenticated_users_create_blueprints" ON public.blueprints
FOR INSERT
TO authenticated
WITH CHECK (
  status != 'deleted'
  AND public.get_user_account_id() IS NOT NULL
);

COMMENT ON POLICY "authenticated_users_create_blueprints" ON public.blueprints IS
'Allows authenticated users with an account to create blueprints.
The trigger add_blueprint_creator_as_owner will add them as owner.';

-- UPDATE: Blueprint admins/owners can update blueprints
CREATE POLICY "blueprint_admins_update" ON public.blueprints
FOR UPDATE
TO authenticated
USING (
  status != 'deleted'
  AND public.is_blueprint_admin(id)
)
WITH CHECK (
  status != 'deleted'
  AND public.is_blueprint_admin(id)
);

COMMENT ON POLICY "blueprint_admins_update" ON public.blueprints IS
'Allows blueprint owners and admins to update blueprint settings.';

-- DELETE: Blueprint owners can delete (soft delete via status='deleted')
CREATE POLICY "blueprint_owners_delete" ON public.blueprints
FOR DELETE
TO authenticated
USING (
  public.is_blueprint_owner(id)
);

COMMENT ON POLICY "blueprint_owners_delete" ON public.blueprints IS
'Allows blueprint owners to delete blueprints. Use soft delete (status=deleted) instead.';

-- ============================================================================
-- BLUEPRINT_MEMBERS RLS POLICIES
-- ============================================================================

-- SELECT: Users can view members of their blueprints or their own membership
CREATE POLICY "blueprint_members_view" ON public.blueprint_members
FOR SELECT
TO authenticated
USING (
  -- User is a member of this blueprint
  public.is_blueprint_member(blueprint_id)
  OR
  -- User's own membership record (for self-discovery)
  auth_user_id = auth.uid()
);

COMMENT ON POLICY "blueprint_members_view" ON public.blueprint_members IS
'Allows users to view members of blueprints they belong to, or their own membership record.';

-- INSERT: Blueprint admins can add members, or first owner
CREATE POLICY "blueprint_admins_add_members" ON public.blueprint_members
FOR INSERT
TO authenticated
WITH CHECK (
  -- Blueprint admins can add members
  public.is_blueprint_admin(blueprint_id)
  OR
  -- Allow initial owner insertion (no members exist yet)
  (
    role = 'owner'
    AND auth_user_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.blueprint_members bm
      WHERE bm.blueprint_id = blueprint_members.blueprint_id
    )
  )
);

COMMENT ON POLICY "blueprint_admins_add_members" ON public.blueprint_members IS
'Allows blueprint admins to add new members. Also allows initial owner insertion.';

-- UPDATE: Blueprint admins can update member roles
CREATE POLICY "blueprint_admins_update_members" ON public.blueprint_members
FOR UPDATE
TO authenticated
USING (
  public.is_blueprint_admin(blueprint_id)
)
WITH CHECK (
  public.is_blueprint_admin(blueprint_id)
);

COMMENT ON POLICY "blueprint_admins_update_members" ON public.blueprint_members IS
'Allows blueprint admins to update member roles.';

-- DELETE: Blueprint admins can remove members, users can leave
CREATE POLICY "blueprint_admins_remove_members" ON public.blueprint_members
FOR DELETE
TO authenticated
USING (
  -- Blueprint admins can remove members
  public.is_blueprint_admin(blueprint_id)
  OR
  -- Users can remove themselves (leave blueprint)
  auth_user_id = auth.uid()
);

COMMENT ON POLICY "blueprint_admins_remove_members" ON public.blueprint_members IS
'Allows blueprint admins to remove members. Users can also leave blueprints themselves.';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON TABLE public.blueprints TO authenticated;
GRANT ALL ON TABLE public.blueprints TO service_role;
GRANT ALL ON TABLE public.blueprint_members TO authenticated;
GRANT ALL ON TABLE public.blueprint_members TO service_role;

COMMIT;
