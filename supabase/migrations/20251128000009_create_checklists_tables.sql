-- Migration: Create checklists tables
-- Purpose: Quality acceptance checklists (per SETC-05)
-- Created: 2025-11-28
-- Phase: Business Layer - Task Module (Acceptance)

-- ============================================================================
-- CREATE CHECKLISTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_template BOOLEAN DEFAULT false,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX idx_checklists_blueprint_id ON public.checklists(blueprint_id);
CREATE INDEX idx_checklists_is_template ON public.checklists(is_template);

-- Updated at trigger
CREATE TRIGGER update_checklists_updated_at
  BEFORE UPDATE ON public.checklists
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.checklists IS 'Quality acceptance checklist templates';

-- ============================================================================
-- CREATE CHECKLIST_ITEMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX idx_checklist_items_checklist_id ON public.checklist_items(checklist_id);
CREATE INDEX idx_checklist_items_sort_order ON public.checklist_items(checklist_id, sort_order);

COMMENT ON TABLE public.checklist_items IS 'Individual items within a checklist';
