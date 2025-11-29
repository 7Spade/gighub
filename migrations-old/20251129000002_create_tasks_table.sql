-- Migration: Create tasks table with RLS policies
-- Purpose: Create tasks table with proper RLS to avoid 42501 permission errors
-- Created: 2025-11-29
-- Phase: Business Layer - Task Module
--
-- Security Design:
-- - Tasks inherit access from blueprint membership
-- - Uses is_blueprint_member() helper function
-- - Task status: pending, in_progress, in_review, completed, cancelled, blocked
-- - Soft delete with deleted_at column

BEGIN;

-- ============================================================================
-- CREATE TASKS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN (
    'pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked'
  )),
  priority TEXT DEFAULT 'medium' NOT NULL CHECK (priority IN (
    'lowest', 'low', 'medium', 'high', 'highest'
  )),
  task_type TEXT DEFAULT 'task' NOT NULL CHECK (task_type IN (
    'task', 'milestone', 'bug', 'feature', 'improvement'
  )),
  progress INTEGER DEFAULT 0 NOT NULL CHECK (progress >= 0 AND progress <= 100),
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  weight DECIMAL(5,2) DEFAULT 1.0 NOT NULL,
  assignee_id UUID REFERENCES public.accounts(id),
  reviewer_id UUID REFERENCES public.accounts(id),
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  completed_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.tasks IS
'Tasks are work items within a blueprint. Supports hierarchical structure via parent_id.
Status: pending, in_progress, in_review, completed, cancelled, blocked.
Priority: lowest, low, medium, high, highest.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tasks_blueprint_id ON public.tasks(blueprint_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON public.tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_reviewer_id ON public.tasks(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_sort_order ON public.tasks(blueprint_id, parent_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON public.tasks(created_by);

-- Create trigger for updated_at
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CREATE TASK_ATTACHMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  file_type VARCHAR(100),
  thumbnail_path TEXT,
  attachment_type TEXT DEFAULT 'general' NOT NULL CHECK (attachment_type IN (
    'general', 'completion_photo', 'reference', 'issue_evidence'
  )),
  caption TEXT,
  is_completion_photo BOOLEAN DEFAULT false NOT NULL,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.task_attachments IS
'Attachments for tasks including photos, documents, and references.
attachment_type: general, completion_photo, reference, issue_evidence.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id ON public.task_attachments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_attachments_attachment_type ON public.task_attachments(attachment_type);

-- ============================================================================
-- CREATE CHECKLISTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_template BOOLEAN DEFAULT false NOT NULL,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.checklists IS
'Checklist templates for task acceptance/QA processes.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_checklists_blueprint_id ON public.checklists(blueprint_id);

-- Create trigger for updated_at
CREATE TRIGGER update_checklists_updated_at
  BEFORE UPDATE ON public.checklists
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CREATE CHECKLIST_ITEMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  is_required BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.checklist_items IS
'Individual items within a checklist.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id ON public.checklist_items(checklist_id);

-- ============================================================================
-- CREATE TASK_ACCEPTANCES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.task_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  checklist_id UUID REFERENCES public.checklists(id),
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'passed', 'failed', 'conditional')),
  inspector_id UUID NOT NULL REFERENCES public.accounts(id),
  inspection_date DATE NOT NULL,
  notes TEXT,
  conditions TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.task_acceptances IS
'Task acceptance/QA records. Status: pending, passed, failed, conditional.';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_task_acceptances_task_id ON public.task_acceptances(task_id);
CREATE INDEX IF NOT EXISTS idx_task_acceptances_status ON public.task_acceptances(status);
CREATE INDEX IF NOT EXISTS idx_task_acceptances_inspector_id ON public.task_acceptances(inspector_id);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_task_acceptances_updated_at ON public.task_acceptances;
CREATE TRIGGER update_task_acceptances_updated_at
  BEFORE UPDATE ON public.task_acceptances
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_acceptances ENABLE ROW LEVEL SECURITY;
-- ============================================================================
-- DROP EXISTING POLICIES (for clean re-application)
-- ============================================================================

-- Tasks policies
DROP POLICY IF EXISTS "blueprint_members_view_tasks" ON public.tasks;
DROP POLICY IF EXISTS "blueprint_members_create_tasks" ON public.tasks;
DROP POLICY IF EXISTS "blueprint_members_update_tasks" ON public.tasks;
DROP POLICY IF EXISTS "blueprint_admins_delete_tasks" ON public.tasks;

-- Task attachments policies
DROP POLICY IF EXISTS "task_access_view_attachments" ON public.task_attachments;
DROP POLICY IF EXISTS "task_access_create_attachments" ON public.task_attachments;
DROP POLICY IF EXISTS "task_access_delete_attachments" ON public.task_attachments;

-- Checklists policies
DROP POLICY IF EXISTS "blueprint_members_view_checklists" ON public.checklists;
DROP POLICY IF EXISTS "blueprint_admins_create_checklists" ON public.checklists;
DROP POLICY IF EXISTS "blueprint_admins_update_checklists" ON public.checklists;
DROP POLICY IF EXISTS "blueprint_admins_delete_checklists" ON public.checklists;

-- Checklist items policies
DROP POLICY IF EXISTS "checklist_access_view_items" ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_admins_create_items" ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_admins_update_items" ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_admins_delete_items" ON public.checklist_items;

-- Task acceptances policies
DROP POLICY IF EXISTS "task_access_view_acceptances" ON public.task_acceptances;
DROP POLICY IF EXISTS "task_access_create_acceptances" ON public.task_acceptances;
DROP POLICY IF EXISTS "task_access_update_acceptances" ON public.task_acceptances;
DROP POLICY IF EXISTS "task_admins_delete_acceptances" ON public.task_acceptances;


-- ============================================================================
-- TASKS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view tasks
CREATE POLICY "blueprint_members_view_tasks" ON public.tasks
FOR SELECT
TO authenticated
USING (
  deleted_at IS NULL
  AND public.is_blueprint_member(blueprint_id)
);

COMMENT ON POLICY "blueprint_members_view_tasks" ON public.tasks IS
'Allows blueprint members to view tasks within their blueprints.';

-- INSERT: Blueprint members can create tasks
CREATE POLICY "blueprint_members_create_tasks" ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_blueprint_member(blueprint_id)
);

COMMENT ON POLICY "blueprint_members_create_tasks" ON public.tasks IS
'Allows blueprint members to create tasks within their blueprints.';

-- UPDATE: Blueprint members can update tasks
CREATE POLICY "blueprint_members_update_tasks" ON public.tasks
FOR UPDATE
TO authenticated
USING (
  deleted_at IS NULL
  AND public.is_blueprint_member(blueprint_id)
)
WITH CHECK (
  public.is_blueprint_member(blueprint_id)
);

COMMENT ON POLICY "blueprint_members_update_tasks" ON public.tasks IS
'Allows blueprint members to update tasks within their blueprints.';

-- DELETE: Blueprint admins can delete tasks
CREATE POLICY "blueprint_admins_delete_tasks" ON public.tasks
FOR DELETE
TO authenticated
USING (
  public.is_blueprint_admin(blueprint_id)
);

COMMENT ON POLICY "blueprint_admins_delete_tasks" ON public.tasks IS
'Allows blueprint admins to delete tasks. Prefer soft delete via deleted_at.';

-- ============================================================================
-- TASK_ATTACHMENTS RLS POLICIES
-- ============================================================================

-- Helper function to check task access
CREATE OR REPLACE FUNCTION public.can_access_task(target_task_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_blueprint_id UUID;
BEGIN
  SELECT blueprint_id INTO v_blueprint_id
  FROM public.tasks
  WHERE id = target_task_id
    AND deleted_at IS NULL;
  
  IF v_blueprint_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN public.is_blueprint_member(v_blueprint_id);
END;
$$;

COMMENT ON FUNCTION public.can_access_task(UUID) IS
'Returns true if auth.uid() can access the specified task (via blueprint membership).';

GRANT EXECUTE ON FUNCTION public.can_access_task(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.can_access_task(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.can_access_task(UUID) FROM public;

-- SELECT: Users who can access the task can view attachments
CREATE POLICY "task_access_view_attachments" ON public.task_attachments
FOR SELECT
TO authenticated
USING (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_view_attachments" ON public.task_attachments IS
'Allows users with task access to view task attachments.';

-- INSERT: Users who can access the task can add attachments
CREATE POLICY "task_access_create_attachments" ON public.task_attachments
FOR INSERT
TO authenticated
WITH CHECK (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_create_attachments" ON public.task_attachments IS
'Allows users with task access to create task attachments.';

-- DELETE: Users who can access the task can delete attachments
CREATE POLICY "task_access_delete_attachments" ON public.task_attachments
FOR DELETE
TO authenticated
USING (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_delete_attachments" ON public.task_attachments IS
'Allows users with task access to delete task attachments.';

-- ============================================================================
-- CHECKLISTS RLS POLICIES
-- ============================================================================

-- SELECT: Blueprint members can view checklists
CREATE POLICY "blueprint_members_view_checklists" ON public.checklists
FOR SELECT
TO authenticated
USING (
  public.is_blueprint_member(blueprint_id)
);

COMMENT ON POLICY "blueprint_members_view_checklists" ON public.checklists IS
'Allows blueprint members to view checklists.';

-- INSERT: Blueprint admins can create checklists
CREATE POLICY "blueprint_admins_create_checklists" ON public.checklists
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_blueprint_admin(blueprint_id)
);

COMMENT ON POLICY "blueprint_admins_create_checklists" ON public.checklists IS
'Allows blueprint admins to create checklists.';

-- UPDATE: Blueprint admins can update checklists
CREATE POLICY "blueprint_admins_update_checklists" ON public.checklists
FOR UPDATE
TO authenticated
USING (
  public.is_blueprint_admin(blueprint_id)
)
WITH CHECK (
  public.is_blueprint_admin(blueprint_id)
);

COMMENT ON POLICY "blueprint_admins_update_checklists" ON public.checklists IS
'Allows blueprint admins to update checklists.';

-- DELETE: Blueprint admins can delete checklists
CREATE POLICY "blueprint_admins_delete_checklists" ON public.checklists
FOR DELETE
TO authenticated
USING (
  public.is_blueprint_admin(blueprint_id)
);

COMMENT ON POLICY "blueprint_admins_delete_checklists" ON public.checklists IS
'Allows blueprint admins to delete checklists.';

-- ============================================================================
-- CHECKLIST_ITEMS RLS POLICIES
-- ============================================================================

-- Helper function to check checklist access
CREATE OR REPLACE FUNCTION public.can_access_checklist(target_checklist_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_blueprint_id UUID;
BEGIN
  SELECT blueprint_id INTO v_blueprint_id
  FROM public.checklists
  WHERE id = target_checklist_id;
  
  IF v_blueprint_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN public.is_blueprint_member(v_blueprint_id);
END;
$$;

COMMENT ON FUNCTION public.can_access_checklist(UUID) IS
'Returns true if auth.uid() can access the specified checklist (via blueprint membership).';

GRANT EXECUTE ON FUNCTION public.can_access_checklist(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.can_access_checklist(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.can_access_checklist(UUID) FROM public;

-- Helper function to check if user is checklist admin
CREATE OR REPLACE FUNCTION public.is_checklist_admin(target_checklist_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_blueprint_id UUID;
BEGIN
  SELECT blueprint_id INTO v_blueprint_id
  FROM public.checklists
  WHERE id = target_checklist_id;
  
  IF v_blueprint_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN public.is_blueprint_admin(v_blueprint_id);
END;
$$;

COMMENT ON FUNCTION public.is_checklist_admin(UUID) IS
'Returns true if auth.uid() is an admin of the blueprint containing the checklist.';

GRANT EXECUTE ON FUNCTION public.is_checklist_admin(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_checklist_admin(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_checklist_admin(UUID) FROM public;

-- SELECT: Users who can access the checklist can view items
CREATE POLICY "checklist_access_view_items" ON public.checklist_items
FOR SELECT
TO authenticated
USING (
  public.can_access_checklist(checklist_id)
);

COMMENT ON POLICY "checklist_access_view_items" ON public.checklist_items IS
'Allows users with checklist access to view checklist items.';

-- INSERT: Blueprint admins can create checklist items
CREATE POLICY "checklist_admins_create_items" ON public.checklist_items
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_checklist_admin(checklist_id)
);

COMMENT ON POLICY "checklist_admins_create_items" ON public.checklist_items IS
'Allows blueprint admins to create checklist items.';

-- UPDATE: Blueprint admins can update checklist items
CREATE POLICY "checklist_admins_update_items" ON public.checklist_items
FOR UPDATE
TO authenticated
USING (
  public.is_checklist_admin(checklist_id)
)
WITH CHECK (
  public.is_checklist_admin(checklist_id)
);

COMMENT ON POLICY "checklist_admins_update_items" ON public.checklist_items IS
'Allows blueprint admins to update checklist items.';

-- DELETE: Blueprint admins can delete checklist items
CREATE POLICY "checklist_admins_delete_items" ON public.checklist_items
FOR DELETE
TO authenticated
USING (
  public.is_checklist_admin(checklist_id)
);

COMMENT ON POLICY "checklist_admins_delete_items" ON public.checklist_items IS
'Allows blueprint admins to delete checklist items.';

-- ============================================================================
-- TASK_ACCEPTANCES RLS POLICIES
-- ============================================================================

-- SELECT: Users who can access the task can view acceptances
CREATE POLICY "task_access_view_acceptances" ON public.task_acceptances
FOR SELECT
TO authenticated
USING (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_view_acceptances" ON public.task_acceptances IS
'Allows users with task access to view task acceptances.';

-- INSERT: Users who can access the task can create acceptances
CREATE POLICY "task_access_create_acceptances" ON public.task_acceptances
FOR INSERT
TO authenticated
WITH CHECK (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_create_acceptances" ON public.task_acceptances IS
'Allows users with task access to create task acceptances.';

-- UPDATE: Users who can access the task can update acceptances
CREATE POLICY "task_access_update_acceptances" ON public.task_acceptances
FOR UPDATE
TO authenticated
USING (
  public.can_access_task(task_id)
)
WITH CHECK (
  public.can_access_task(task_id)
);

COMMENT ON POLICY "task_access_update_acceptances" ON public.task_acceptances IS
'Allows users with task access to update task acceptances.';

-- DELETE: Blueprint admins can delete acceptances
CREATE POLICY "task_admins_delete_acceptances" ON public.task_acceptances
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = task_acceptances.task_id
      AND public.is_blueprint_admin(t.blueprint_id)
  )
);

COMMENT ON POLICY "task_admins_delete_acceptances" ON public.task_acceptances IS
'Allows blueprint admins to delete task acceptances.';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON TABLE public.tasks TO authenticated;
GRANT ALL ON TABLE public.tasks TO service_role;
GRANT ALL ON TABLE public.task_attachments TO authenticated;
GRANT ALL ON TABLE public.task_attachments TO service_role;
GRANT ALL ON TABLE public.checklists TO authenticated;
GRANT ALL ON TABLE public.checklists TO service_role;
GRANT ALL ON TABLE public.checklist_items TO authenticated;
GRANT ALL ON TABLE public.checklist_items TO service_role;
GRANT ALL ON TABLE public.task_acceptances TO authenticated;
GRANT ALL ON TABLE public.task_acceptances TO service_role;

COMMIT;
