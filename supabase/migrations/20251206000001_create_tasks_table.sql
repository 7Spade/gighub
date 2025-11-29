-- Migration: Create Tasks Table
-- Purpose: Create the tasks table for task management
-- Phase: 6 - Task System
-- Created: 2025-12-01
-- Dependencies: Phase 5 (Blueprint System)
-- Source: migrations-old/20251129000002_create_tasks_table.sql

-- ============================================================================
-- TASKS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked')),
  priority TEXT DEFAULT 'medium' NOT NULL CHECK (priority IN ('lowest', 'low', 'medium', 'high', 'highest')),
  task_type TEXT DEFAULT 'task' NOT NULL CHECK (task_type IN ('task', 'milestone', 'bug', 'feature', 'improvement')),
  assignee_id UUID REFERENCES public.accounts(id),
  reviewer_id UUID REFERENCES public.accounts(id),
  due_date DATE,
  start_date DATE,
  completed_at TIMESTAMPTZ,
  estimated_hours NUMERIC(8, 2),
  actual_hours NUMERIC(8, 2),
  sort_order INTEGER DEFAULT 0 NOT NULL,
  path LTREE,
  settings JSONB DEFAULT '{}' NOT NULL,
  metadata JSONB DEFAULT '{}' NOT NULL,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.tasks IS
'Tasks belong to blueprints and can be hierarchical via parent_id.
Status: pending, in_progress, in_review, completed, cancelled, blocked.
Priority: lowest, low, medium, high, highest.
Type: task, milestone, bug, feature, improvement.';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_tasks_blueprint_id ON public.tasks(blueprint_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON public.tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status) WHERE status != 'cancelled' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_reviewer_id ON public.tasks(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON public.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_sort_order ON public.tasks(blueprint_id, parent_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_tasks_path ON public.tasks USING GIST (path);

-- ============================================================================
-- TRIGGER
-- ============================================================================

DROP TRIGGER IF EXISTS update_tasks_updated_at ON public.tasks;
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL ON TABLE public.tasks TO authenticated;
GRANT ALL ON TABLE public.tasks TO service_role;
