-- Migration: Align add_creator_as_org_owner trigger with new organization insert flow
-- Purpose: Use auth.uid() for organization owner membership instead of NEW.auth_user_id
-- Date: 2025-11-24

BEGIN;

CREATE OR REPLACE FUNCTION public.add_creator_as_org_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_user_account_id UUID;
BEGIN
  IF NEW.type = 'Organization' AND TG_OP = 'INSERT' THEN
    SELECT id INTO v_user_account_id
    FROM public.accounts
    WHERE auth_user_id = auth.uid()
      AND type = 'User'
      AND status != 'deleted'
    LIMIT 1;

    IF v_user_account_id IS NOT NULL THEN
      INSERT INTO public.organization_members (
        organization_id,
        account_id,
        role,
        auth_user_id
      ) VALUES (
        NEW.id,
        v_user_account_id,
        'owner',
        auth.uid()
      )
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMIT;

