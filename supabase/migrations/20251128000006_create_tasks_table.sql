-- Migration: Create tasks table
-- Purpose: Task management system (per SETC-05)
-- Created: 2025-11-28
-- Phase: Business Layer - Task Module

-- ============================================================================
-- CREATE TASKS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked'
  )),
  priority TEXT DEFAULT 'medium' CHECK (priority IN (
    'lowest', 'low', 'medium', 'high', 'highest'
  )),
  task_type TEXT DEFAULT 'task' CHECK (task_type IN (
    'task', 'milestone', 'bug', 'feature', 'improvement'
  )),
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  weight DECIMAL(5,2) DEFAULT 1.0,
  area VARCHAR(255),
  tags TEXT[] DEFAULT '{}',
  assignee_id UUID REFERENCES public.accounts(id),
  reviewer_id UUID REFERENCES public.accounts(id),
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  completed_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

-- Indexes for common queries
CREATE INDEX idx_tasks_blueprint_id ON public.tasks(blueprint_id);
CREATE INDEX idx_tasks_parent_id ON public.tasks(parent_id);
CREATE INDEX idx_tasks_assignee_id ON public.tasks(assignee_id);
CREATE INDEX idx_tasks_reviewer_id ON public.tasks(reviewer_id);
CREATE INDEX idx_tasks_status ON public.tasks(status);
CREATE INDEX idx_tasks_priority ON public.tasks(priority);
CREATE INDEX idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX idx_tasks_sort_order ON public.tasks(blueprint_id, parent_id, sort_order);
CREATE INDEX idx_tasks_deleted_at ON public.tasks(deleted_at) WHERE deleted_at IS NULL;

-- Updated at trigger
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.tasks IS 'Task management with unlimited hierarchical structure';
COMMENT ON COLUMN public.tasks.status IS 'Task lifecycle: pending -> in_progress -> in_review -> completed/cancelled/blocked';
COMMENT ON COLUMN public.tasks.progress IS 'Completion percentage (0-100)';
COMMENT ON COLUMN public.tasks.weight IS 'Weight for parent task progress calculation';
COMMENT ON COLUMN public.tasks.assignee_id IS 'Task executor (施工人員)';
COMMENT ON COLUMN public.tasks.reviewer_id IS 'Task reviewer (監工)';
