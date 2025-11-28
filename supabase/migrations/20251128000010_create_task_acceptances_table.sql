-- Migration: Create task_acceptances table
-- Purpose: Task quality acceptance records (per SETC-05)
-- Created: 2025-11-28
-- Phase: Business Layer - Task Module (Acceptance)

-- ============================================================================
-- CREATE TASK_ACCEPTANCES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.task_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  checklist_id UUID REFERENCES public.checklists(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'passed', 'failed', 'conditional')),
  inspector_id UUID NOT NULL REFERENCES public.accounts(id),
  inspection_date DATE NOT NULL,
  notes TEXT,
  conditions TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX idx_task_acceptances_task_id ON public.task_acceptances(task_id);
CREATE INDEX idx_task_acceptances_status ON public.task_acceptances(status);
CREATE INDEX idx_task_acceptances_inspector_id ON public.task_acceptances(inspector_id);
CREATE INDEX idx_task_acceptances_inspection_date ON public.task_acceptances(inspection_date);

-- Updated at trigger
CREATE TRIGGER update_task_acceptances_updated_at
  BEFORE UPDATE ON public.task_acceptances
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.task_acceptances IS 'Task quality acceptance records';
COMMENT ON COLUMN public.task_acceptances.status IS 'Acceptance result: pending, passed, failed, conditional';
COMMENT ON COLUMN public.task_acceptances.conditions IS 'Conditions for conditional acceptance';
