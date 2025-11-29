-- Migration: Create Extensions
-- Purpose: Enable required PostgreSQL extensions
-- Phase: 1 - Core Schema
-- Created: 2025-12-01

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "ltree";

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';
COMMENT ON EXTENSION "pgcrypto" IS 'cryptographic functions';
COMMENT ON EXTENSION "ltree" IS 'data type for hierarchical tree-like structures';
