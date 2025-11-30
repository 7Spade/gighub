-- Migration: Make handle_new_organization resilient to created_by being either accounts.id or auth.uid
-- Purpose: Some clients may POST `created_by` as the auth user's id (auth.uid()) instead of the accounts.id.
-- This migration replaces the trigger function to try resolving created_by as an accounts.id first,
-- and if not found, attempt to find an account with auth_user_id = created_by. If resolved, add the member.
-- Created: 2025-11-30

BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_organization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_account_id UUID;
BEGIN
  IF NEW.created_by IS NOT NULL THEN
    -- Try to treat created_by as a direct accounts.id first
    SELECT id INTO v_account_id FROM public.accounts WHERE id = NEW.created_by LIMIT 1;

    -- If not found, try interpreting created_by as auth_user_id
    IF v_account_id IS NULL THEN
      SELECT id INTO v_account_id FROM public.accounts WHERE auth_user_id = NEW.created_by LIMIT 1;
    END IF;

    -- Only insert if we resolved an accounts.id
    IF v_account_id IS NOT NULL THEN
      INSERT INTO public.organization_members (organization_id, account_id, role)
      VALUES (NEW.id, v_account_id, 'owner')
      ON CONFLICT (organization_id, account_id) DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMIT;

-- Notes:
-- - This is a defensive change: it avoids failing the INSERT in case the API submitted an auth UID instead
--   or any other non-accounts.id value for `created_by`.
-- - If your front-end sends created_by as the auth UID, consider updating the front-end to pass the
--   accounts.id instead (preferred), or call an API endpoint that uses the server side session to
--   resolve the current user's accounts.id when creating organizations.
-- - After applying migration: run the organization-create flow again and check Network/DB logs for any remaining errors.
