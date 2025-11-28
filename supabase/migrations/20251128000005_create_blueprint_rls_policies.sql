-- Migration: Create blueprint RLS policies
-- Purpose: Row Level Security for blueprints (per SETC-02)
-- Created: 2025-11-28
-- Phase: Blueprint Container Layer - Security

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

ALTER TABLE public.blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blueprint_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blueprint_branches ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- BLUEPRINTS RLS POLICIES
-- ============================================================================

-- SELECT: Members can view their blueprints
CREATE POLICY "blueprint_members_can_view" ON public.blueprints
FOR SELECT
TO authenticated
USING (
  public.is_blueprint_member(id) OR 
  owner_id = public.get_user_account_id() OR
  created_by = public.get_user_account_id()
);

COMMENT ON POLICY "blueprint_members_can_view" ON public.blueprints IS
'Allows blueprint members, owners, and creators to view blueprints.';

-- INSERT: Any authenticated user can create blueprints
CREATE POLICY "authenticated_users_can_create_blueprints" ON public.blueprints
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL AND
  status <> 'deleted'
);

COMMENT ON POLICY "authenticated_users_can_create_blueprints" ON public.blueprints IS
'Allows any authenticated user to create new blueprints.';

-- UPDATE: Only admins can update blueprints
CREATE POLICY "blueprint_admins_can_update" ON public.blueprints
FOR UPDATE
TO authenticated
USING (public.is_blueprint_admin(id))
WITH CHECK (
  public.is_blueprint_admin(id) AND
  status <> 'deleted'
);

COMMENT ON POLICY "blueprint_admins_can_update" ON public.blueprints IS
'Allows blueprint owners and admins to update blueprint settings.';

-- DELETE: Only owner can delete (soft delete via status)
CREATE POLICY "blueprint_owner_can_soft_delete" ON public.blueprints
FOR UPDATE
TO authenticated
USING (public.is_blueprint_owner(id))
WITH CHECK (status = 'deleted');

COMMENT ON POLICY "blueprint_owner_can_soft_delete" ON public.blueprints IS
'Allows blueprint owners to soft delete blueprints by setting status to deleted.';

-- ============================================================================
-- BLUEPRINT_MEMBERS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view member list
CREATE POLICY "members_can_view_members" ON public.blueprint_members
FOR SELECT
TO authenticated
USING (public.is_blueprint_member(blueprint_id));

COMMENT ON POLICY "members_can_view_members" ON public.blueprint_members IS
'Allows blueprint members to view the member list.';

-- INSERT: Admins can add members
CREATE POLICY "admins_can_add_members" ON public.blueprint_members
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_blueprint_admin(blueprint_id) OR
  -- Allow blueprint creator to add themselves as owner
  (account_id = public.get_user_account_id() AND role = 'owner')
);

COMMENT ON POLICY "admins_can_add_members" ON public.blueprint_members IS
'Allows blueprint admins to add new members, or creators to add themselves as owner.';

-- UPDATE: Owner can update member roles
CREATE POLICY "owner_can_update_roles" ON public.blueprint_members
FOR UPDATE
TO authenticated
USING (public.is_blueprint_owner(blueprint_id));

COMMENT ON POLICY "owner_can_update_roles" ON public.blueprint_members IS
'Allows blueprint owners to update member roles.';

-- DELETE: Admins can remove members
CREATE POLICY "admins_can_remove_members" ON public.blueprint_members
FOR DELETE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id));

COMMENT ON POLICY "admins_can_remove_members" ON public.blueprint_members IS
'Allows blueprint admins to remove members.';

-- ============================================================================
-- BLUEPRINT_BRANCHES RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view branches
CREATE POLICY "members_can_view_branches" ON public.blueprint_branches
FOR SELECT
TO authenticated
USING (public.is_blueprint_member(blueprint_id));

-- INSERT: Members can create branches
CREATE POLICY "members_can_create_branches" ON public.blueprint_branches
FOR INSERT
TO authenticated
WITH CHECK (public.is_blueprint_member(blueprint_id));

-- UPDATE: Admins can update branches
CREATE POLICY "admins_can_update_branches" ON public.blueprint_branches
FOR UPDATE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id));

-- DELETE: Admins can delete branches
CREATE POLICY "admins_can_delete_branches" ON public.blueprint_branches
FOR DELETE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id));
