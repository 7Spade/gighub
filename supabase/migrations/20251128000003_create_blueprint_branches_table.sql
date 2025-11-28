-- Migration: Create blueprint_branches table
-- Purpose: Git-like branch management for blueprints (per SETC-02)
-- Created: 2025-11-28
-- Phase: Blueprint Container Layer

-- ============================================================================
-- CREATE BLUEPRINT_BRANCHES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.blueprint_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  source_branch_id UUID REFERENCES public.blueprint_branches(id),
  is_default BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'merged', 'closed')),
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (blueprint_id, name)
);

-- Indexes
CREATE INDEX idx_blueprint_branches_blueprint_id ON public.blueprint_branches(blueprint_id);
CREATE INDEX idx_blueprint_branches_status ON public.blueprint_branches(status);

-- Updated at trigger
CREATE TRIGGER update_blueprint_branches_updated_at
  BEFORE UPDATE ON public.blueprint_branches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.blueprint_branches IS 'Git-like branch management for blueprint versioning';
COMMENT ON COLUMN public.blueprint_branches.is_default IS 'Whether this is the main/default branch';
