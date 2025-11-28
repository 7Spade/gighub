-- Migration: Create blueprint_members table
-- Purpose: Blueprint membership and role management (per SETC-02)
-- Created: 2025-11-28
-- Phase: Blueprint Container Layer

-- ============================================================================
-- CREATE BLUEPRINT_MEMBERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES public.accounts(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  business_role TEXT,
  joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  invited_by UUID REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (blueprint_id, account_id)
);

-- Indexes for common queries
CREATE INDEX idx_blueprint_members_blueprint_id ON public.blueprint_members(blueprint_id);
CREATE INDEX idx_blueprint_members_account_id ON public.blueprint_members(account_id);
CREATE INDEX idx_blueprint_members_role ON public.blueprint_members(role);

-- Updated at trigger
CREATE TRIGGER update_blueprint_members_updated_at
  BEFORE UPDATE ON public.blueprint_members
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.blueprint_members IS 'Blueprint membership with role-based access control';
COMMENT ON COLUMN public.blueprint_members.role IS 'System role: owner, admin, member, viewer';
COMMENT ON COLUMN public.blueprint_members.business_role IS 'Business role: 專案經理, 工地主任, 施工人員, 品管人員';
