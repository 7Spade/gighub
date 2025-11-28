-- Migration: Create files table
-- Purpose: File storage metadata (required by task_attachments)
-- Created: 2025-11-28
-- Phase: Business Layer - File System Support

-- ============================================================================
-- CREATE FILES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES public.blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  original_name VARCHAR(255),
  mime_type VARCHAR(100),
  size_bytes BIGINT,
  storage_path TEXT NOT NULL,
  thumbnail_path TEXT,
  checksum VARCHAR(64),
  metadata JSONB DEFAULT '{}',
  uploaded_by UUID NOT NULL REFERENCES public.accounts(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_files_blueprint_id ON public.files(blueprint_id);
CREATE INDEX idx_files_uploaded_by ON public.files(uploaded_by);
CREATE INDEX idx_files_mime_type ON public.files(mime_type);
CREATE INDEX idx_files_deleted_at ON public.files(deleted_at) WHERE deleted_at IS NULL;

-- Updated at trigger
CREATE TRIGGER update_files_updated_at
  BEFORE UPDATE ON public.files
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.files IS 'File storage metadata for blueprint attachments';
COMMENT ON COLUMN public.files.storage_path IS 'Path in Supabase Storage bucket';
COMMENT ON COLUMN public.files.thumbnail_path IS 'Path to generated thumbnail for images';
