-- Migration: Create blueprints table
-- Purpose: Blueprint container for data isolation (per SETC-02)
-- Created: 2025-11-28
-- Phase: Blueprint Container Layer

-- ============================================================================
-- CREATE BLUEPRINTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.accounts(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  slug VARCHAR(100),
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'internal', 'public')),
  settings JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  cover_image_url TEXT,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  deleted_at TIMESTAMPTZ,
  UNIQUE (owner_id, slug)
);

-- Indexes for common queries
CREATE INDEX idx_blueprints_owner_id ON public.blueprints(owner_id);
CREATE INDEX idx_blueprints_status ON public.blueprints(status);
CREATE INDEX idx_blueprints_slug ON public.blueprints(slug);
CREATE INDEX idx_blueprints_created_by ON public.blueprints(created_by);

-- Updated at trigger
CREATE TRIGGER update_blueprints_updated_at
  BEFORE UPDATE ON public.blueprints
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.blueprints IS 'Blueprint container for project/workspace data isolation';
COMMENT ON COLUMN public.blueprints.owner_id IS 'Account ID that owns this blueprint (User, Organization, or Bot)';
COMMENT ON COLUMN public.blueprints.status IS 'Lifecycle status: draft -> active -> archived -> deleted (soft delete)';
COMMENT ON COLUMN public.blueprints.visibility IS 'Access level: private (members only), internal (org visible), public';
