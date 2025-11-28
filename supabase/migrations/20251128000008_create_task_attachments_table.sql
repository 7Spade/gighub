-- Migration: Create task_attachments table
-- Purpose: Task attachment management (per SETC-05)
-- Created: 2025-11-28
-- Phase: Business Layer - Task Module

-- ============================================================================
-- CREATE TASK_ATTACHMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES public.files(id),
  attachment_type TEXT DEFAULT 'general' CHECK (attachment_type IN (
    'general', 'completion_photo', 'reference', 'issue_evidence'
  )),
  caption TEXT,
  is_completion_photo BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX idx_task_attachments_task_id ON public.task_attachments(task_id);
CREATE INDEX idx_task_attachments_file_id ON public.task_attachments(file_id);
CREATE INDEX idx_task_attachments_type ON public.task_attachments(attachment_type);

COMMENT ON TABLE public.task_attachments IS 'Task attachments including completion photos and references';
COMMENT ON COLUMN public.task_attachments.attachment_type IS 'Type: general, completion_photo, reference, issue_evidence';
COMMENT ON COLUMN public.task_attachments.is_completion_photo IS 'Flag for completion verification photos';
