-- Migration: Create task RLS policies
-- Purpose: Row Level Security for task module tables (per SETC-05)
-- Created: 2025-11-28
-- Phase: Business Layer - Task Module Security

-- ============================================================================
-- ENABLE RLS ON ALL TASK MODULE TABLES
-- ============================================================================

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_acceptances ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- TASKS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view tasks
CREATE POLICY "tasks_select" ON public.tasks
FOR SELECT
TO authenticated
USING (public.is_blueprint_member(blueprint_id));

COMMENT ON POLICY "tasks_select" ON public.tasks IS
'Allows blueprint members to view all tasks in their blueprints.';

-- INSERT: Blueprint members can create tasks
CREATE POLICY "tasks_insert" ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (public.is_blueprint_member(blueprint_id));

COMMENT ON POLICY "tasks_insert" ON public.tasks IS
'Allows blueprint members to create tasks.';

-- UPDATE: Members can update if admin, assignee, or creator
CREATE POLICY "tasks_update" ON public.tasks
FOR UPDATE
TO authenticated
USING (
  public.is_blueprint_member(blueprint_id) AND (
    public.is_blueprint_admin(blueprint_id) OR
    assignee_id = public.get_user_account_id() OR
    created_by = public.get_user_account_id()
  )
)
WITH CHECK (deleted_at IS NULL);

COMMENT ON POLICY "tasks_update" ON public.tasks IS
'Allows admins, assignees, or creators to update tasks.';

-- DELETE: Admins can soft delete
CREATE POLICY "tasks_soft_delete" ON public.tasks
FOR UPDATE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id))
WITH CHECK (deleted_at IS NOT NULL);

COMMENT ON POLICY "tasks_soft_delete" ON public.tasks IS
'Allows admins to soft delete tasks by setting deleted_at.';

-- ============================================================================
-- FILES RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view files
CREATE POLICY "files_select" ON public.files
FOR SELECT
TO authenticated
USING (public.is_blueprint_member(blueprint_id));

-- INSERT: Blueprint members can upload files
CREATE POLICY "files_insert" ON public.files
FOR INSERT
TO authenticated
WITH CHECK (public.is_blueprint_member(blueprint_id));

-- UPDATE: Uploaders and admins can update
CREATE POLICY "files_update" ON public.files
FOR UPDATE
TO authenticated
USING (
  public.is_blueprint_member(blueprint_id) AND (
    public.is_blueprint_admin(blueprint_id) OR
    uploaded_by = public.get_user_account_id()
  )
);

-- DELETE: Admins can soft delete
CREATE POLICY "files_soft_delete" ON public.files
FOR UPDATE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id))
WITH CHECK (deleted_at IS NOT NULL);

-- ============================================================================
-- TASK_ATTACHMENTS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view attachments
CREATE POLICY "task_attachments_select" ON public.task_attachments
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_member(t.blueprint_id)
  )
);

-- INSERT: Members can add attachments
CREATE POLICY "task_attachments_insert" ON public.task_attachments
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_member(t.blueprint_id)
  )
);

-- DELETE: Creators and admins can delete
CREATE POLICY "task_attachments_delete" ON public.task_attachments
FOR DELETE
TO authenticated
USING (
  created_by = public.get_user_account_id() OR
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_admin(t.blueprint_id)
  )
);

-- ============================================================================
-- CHECKLISTS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view checklists
CREATE POLICY "checklists_select" ON public.checklists
FOR SELECT
TO authenticated
USING (public.is_blueprint_member(blueprint_id));

-- INSERT: Admins can create checklists
CREATE POLICY "checklists_insert" ON public.checklists
FOR INSERT
TO authenticated
WITH CHECK (public.is_blueprint_admin(blueprint_id));

-- UPDATE: Admins can update checklists
CREATE POLICY "checklists_update" ON public.checklists
FOR UPDATE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id));

-- DELETE: Admins can delete checklists
CREATE POLICY "checklists_delete" ON public.checklists
FOR DELETE
TO authenticated
USING (public.is_blueprint_admin(blueprint_id));

-- ============================================================================
-- CHECKLIST_ITEMS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view checklist items
CREATE POLICY "checklist_items_select" ON public.checklist_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    WHERE c.id = checklist_id
    AND public.is_blueprint_member(c.blueprint_id)
  )
);

-- INSERT: Admins can create checklist items
CREATE POLICY "checklist_items_insert" ON public.checklist_items
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklists c
    WHERE c.id = checklist_id
    AND public.is_blueprint_admin(c.blueprint_id)
  )
);

-- UPDATE: Admins can update checklist items
CREATE POLICY "checklist_items_update" ON public.checklist_items
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    WHERE c.id = checklist_id
    AND public.is_blueprint_admin(c.blueprint_id)
  )
);

-- DELETE: Admins can delete checklist items
CREATE POLICY "checklist_items_delete" ON public.checklist_items
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    WHERE c.id = checklist_id
    AND public.is_blueprint_admin(c.blueprint_id)
  )
);

-- ============================================================================
-- TASK_ACCEPTANCES RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view acceptances
CREATE POLICY "task_acceptances_select" ON public.task_acceptances
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_member(t.blueprint_id)
  )
);

-- INSERT: QA staff and admins can create acceptances
CREATE POLICY "task_acceptances_insert" ON public.task_acceptances
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_member(t.blueprint_id)
  )
);

-- UPDATE: Inspector or admin can update
CREATE POLICY "task_acceptances_update" ON public.task_acceptances
FOR UPDATE
TO authenticated
USING (
  inspector_id = public.get_user_account_id() OR
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_id
    AND public.is_blueprint_admin(t.blueprint_id)
  )
);
