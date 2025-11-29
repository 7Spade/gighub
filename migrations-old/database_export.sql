


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."add_creator_as_org_owner"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "row_security" TO 'off'
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


ALTER FUNCTION "public"."add_creator_as_org_owner"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."add_creator_as_org_owner"() IS 'Trigger function that automatically adds the organization creator as an owner in organization_members table.';



CREATE OR REPLACE FUNCTION "public"."count_user_workspaces"("user_uuid" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT w.id)
    FROM workspaces w
    LEFT JOIN workspace_members wm ON wm.workspace_id = w.id
    WHERE w.owner_id = user_uuid
    OR wm.account_id = user_uuid
  );
END;
$$;


ALTER FUNCTION "public"."count_user_workspaces"("user_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_account_id"() RETURNS "uuid"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "row_security" TO 'off'
    AS $$
DECLARE
  v_account_id UUID;
BEGIN
  -- Query accounts table without triggering RLS (row_security = off)
  -- Only returns data for the current authenticated user (auth.uid())
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;
  
  RETURN v_account_id;
END;
$$;


ALTER FUNCTION "public"."get_user_account_id"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_user_account_id"() IS 'Helper function to get account_id for current user without triggering RLS recursion. Uses SECURITY DEFINER to bypass RLS safely.';



CREATE OR REPLACE FUNCTION "public"."get_workspace_role"("workspace_uuid" "uuid", "user_uuid" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM workspace_members
  WHERE workspace_id = workspace_uuid
  AND account_id = user_uuid;
  
  RETURN user_role;
END;
$$;


ALTER FUNCTION "public"."get_workspace_role"("workspace_uuid" "uuid", "user_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.accounts (auth_user_id, type, name, email, status)
  VALUES (
    NEW.id,
    'User',
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    'active'
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."handle_new_user"() IS 'Automatically creates an account record when a new auth user is created';



CREATE OR REPLACE FUNCTION "public"."is_org_admin"("target_org_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
      AND role = ANY(ARRAY['owner', 'admin'])
  );
END;
$$;


ALTER FUNCTION "public"."is_org_admin"("target_org_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_org_admin"("target_org_id" "uuid") IS 'Returns true if auth.uid() is an owner or admin of the specified organization.';



CREATE OR REPLACE FUNCTION "public"."is_org_member"("target_org_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
  );
END;
$$;


ALTER FUNCTION "public"."is_org_member"("target_org_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_org_member"("target_org_id" "uuid") IS 'Returns true if auth.uid() is a member of the specified organization.';



CREATE OR REPLACE FUNCTION "public"."is_org_owner"("target_org_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
      AND role = 'owner'
  );
END;
$$;


ALTER FUNCTION "public"."is_org_owner"("target_org_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_org_owner"("target_org_id" "uuid") IS 'Returns true if auth.uid() is an owner of the specified organization.';



CREATE OR REPLACE FUNCTION "public"."is_team_leader"("target_team_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.team_members
    WHERE team_id = target_team_id
      AND auth_user_id = auth.uid()
      AND role = 'leader'
  );
END;
$$;


ALTER FUNCTION "public"."is_team_leader"("target_team_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_team_leader"("target_team_id" "uuid") IS 'Returns true if auth.uid() is a leader of the specified team.';



CREATE OR REPLACE FUNCTION "public"."is_team_member"("target_team_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.team_members
    WHERE team_id = target_team_id
      AND auth_user_id = auth.uid()
  );
END;
$$;


ALTER FUNCTION "public"."is_team_member"("target_team_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_team_member"("target_team_id" "uuid") IS 'Returns true if auth.uid() is a member of the specified team.';



CREATE OR REPLACE FUNCTION "public"."is_workspace_member"("workspace_uuid" "uuid", "user_uuid" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = workspace_uuid
    AND account_id = user_uuid
  );
END;
$$;


ALTER FUNCTION "public"."is_workspace_member"("workspace_uuid" "uuid", "user_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."organization_has_members"("target_org_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE organization_id = target_org_id
  );
END;
$$;


ALTER FUNCTION "public"."organization_has_members"("target_org_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."organization_has_members"("target_org_id" "uuid") IS 'Returns true if the organization already has at least one member.';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_updated_at_column"() IS 'Automatically updates the updated_at timestamp on row modification';



CREATE OR REPLACE FUNCTION "public"."update_work_items_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_work_items_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "text" NOT NULL,
    "name" character varying(255) NOT NULL,
    "email" character varying(255),
    "avatar" character varying(500),
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "auth_user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "accounts_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'suspended'::"text", 'deleted'::"text"]))),
    CONSTRAINT "accounts_type_check" CHECK (("type" = ANY (ARRAY['User'::"text", 'Bot'::"text", 'Organization'::"text"]))),
    CONSTRAINT "email_format" CHECK ((("email" IS NULL) OR (("email")::"text" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::"text")))
);


ALTER TABLE "public"."accounts" OWNER TO "postgres";


COMMENT ON TABLE "public"."accounts" IS 'Accounts table with comprehensive RLS policies - Infinite recursion completely eliminated (2025-11-23)';



CREATE TABLE IF NOT EXISTS "public"."organization_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "account_id" "uuid",
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "auth_user_id" "uuid",
    CONSTRAINT "organization_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))
);


ALTER TABLE "public"."organization_members" OWNER TO "postgres";


COMMENT ON TABLE "public"."organization_members" IS 'Organization membership with owner, admin, and member roles';



CREATE TABLE IF NOT EXISTS "public"."team_bots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "bot_id" "uuid" NOT NULL,
    "added_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "added_by_auth_user_id" "uuid"
);


ALTER TABLE "public"."team_bots" OWNER TO "postgres";


COMMENT ON TABLE "public"."team_bots" IS 'Junction table mapping bots to teams for team-based bot access control.';



CREATE TABLE IF NOT EXISTS "public"."team_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "account_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "auth_user_id" "uuid",
    CONSTRAINT "team_members_role_check" CHECK (("role" = ANY (ARRAY['leader'::"text", 'member'::"text"])))
);


ALTER TABLE "public"."team_members" OWNER TO "postgres";


COMMENT ON TABLE "public"."team_members" IS 'Team membership with leader and member roles';



CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "description" "text",
    "avatar" character varying(500),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


COMMENT ON TABLE "public"."teams" IS 'Teams belong to organizations and group accounts together';



ALTER TABLE ONLY "public"."accounts"
    ADD CONSTRAINT "accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_bots"
    ADD CONSTRAINT "team_bots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_bots"
    ADD CONSTRAINT "team_bots_team_id_bot_id_key" UNIQUE ("team_id", "bot_id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "unique_org_account" UNIQUE ("organization_id", "account_id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "unique_team_account" UNIQUE ("team_id", "account_id");



CREATE INDEX "idx_accounts_auth_user_id" ON "public"."accounts" USING "btree" ("auth_user_id");



CREATE INDEX "idx_accounts_email" ON "public"."accounts" USING "btree" ("email");



CREATE INDEX "idx_accounts_status" ON "public"."accounts" USING "btree" ("status");



CREATE INDEX "idx_accounts_type" ON "public"."accounts" USING "btree" ("type");



CREATE INDEX "idx_org_members_auth_user" ON "public"."organization_members" USING "btree" ("auth_user_id");



CREATE UNIQUE INDEX "idx_org_members_org_auth_user_unique" ON "public"."organization_members" USING "btree" ("organization_id", "auth_user_id") WHERE ("auth_user_id" IS NOT NULL);



CREATE INDEX "idx_organization_members_account_id" ON "public"."organization_members" USING "btree" ("account_id");



CREATE INDEX "idx_organization_members_auth_user" ON "public"."organization_members" USING "btree" ("auth_user_id");



CREATE INDEX "idx_organization_members_org_id" ON "public"."organization_members" USING "btree" ("organization_id");



CREATE INDEX "idx_organization_members_role" ON "public"."organization_members" USING "btree" ("role");



CREATE INDEX "idx_team_members_account_id" ON "public"."team_members" USING "btree" ("account_id");



CREATE INDEX "idx_team_members_auth_user" ON "public"."team_members" USING "btree" ("auth_user_id");



CREATE INDEX "idx_team_members_role" ON "public"."team_members" USING "btree" ("role");



CREATE INDEX "idx_team_members_team_id" ON "public"."team_members" USING "btree" ("team_id");



CREATE INDEX "idx_teams_organization_id" ON "public"."teams" USING "btree" ("organization_id");



CREATE UNIQUE INDEX "unique_user_auth_user_id" ON "public"."accounts" USING "btree" ("auth_user_id") WHERE ("type" = 'User'::"text");



COMMENT ON INDEX "public"."unique_user_auth_user_id" IS 'Ensures each auth.users has exactly one User account. Organizations and Bots can store creator auth_user_id for access control.';



CREATE OR REPLACE TRIGGER "trg_add_creator_as_org_owner" AFTER INSERT ON "public"."accounts" FOR EACH ROW WHEN (("new"."type" = 'Organization'::"text")) EXECUTE FUNCTION "public"."add_creator_as_org_owner"();



CREATE OR REPLACE TRIGGER "update_accounts_updated_at" BEFORE UPDATE ON "public"."accounts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_teams_updated_at" BEFORE UPDATE ON "public"."teams" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."accounts"
    ADD CONSTRAINT "accounts_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_bots"
    ADD CONSTRAINT "team_bots_added_by_auth_user_id_fkey" FOREIGN KEY ("added_by_auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."team_bots"
    ADD CONSTRAINT "team_bots_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_bots"
    ADD CONSTRAINT "team_bots_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE;



CREATE POLICY "Allow initial organization owner on creation" ON "public"."organization_members" FOR INSERT TO "authenticated" WITH CHECK ((("role" = 'owner'::"text") AND ("auth_user_id" = "auth"."uid"()) AND (NOT "public"."organization_has_members"("organization_id"))));



CREATE POLICY "Organization admins can update member roles" ON "public"."organization_members" FOR UPDATE TO "authenticated" USING ("public"."is_org_admin"("organization_id")) WITH CHECK (
CASE
    WHEN ("role" = 'owner'::"text") THEN "public"."is_org_owner"("organization_id")
    ELSE "public"."is_org_admin"("organization_id")
END);



CREATE POLICY "Organization owners can add members" ON "public"."organization_members" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_org_owner"("organization_id"));



CREATE POLICY "Organization owners can remove members" ON "public"."organization_members" FOR DELETE TO "authenticated" USING ("public"."is_org_owner"("organization_id"));



CREATE POLICY "Team leaders can add members" ON "public"."team_members" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_team_leader"("team_id"));



CREATE POLICY "Team leaders can remove members" ON "public"."team_members" FOR DELETE TO "authenticated" USING ("public"."is_team_leader"("team_id"));



CREATE POLICY "Team leaders can update member roles" ON "public"."team_members" FOR UPDATE TO "authenticated" USING ("public"."is_team_leader"("team_id")) WITH CHECK ("public"."is_team_leader"("team_id"));



CREATE POLICY "Users can leave organizations" ON "public"."organization_members" FOR DELETE TO "authenticated" USING ((("auth_user_id" = "auth"."uid"()) AND ("role" <> 'owner'::"text")));



CREATE POLICY "Users can remove themselves from teams" ON "public"."team_members" FOR DELETE TO "authenticated" USING (("auth_user_id" = "auth"."uid"()));



CREATE POLICY "Users can view organization members" ON "public"."organization_members" FOR SELECT TO "authenticated" USING ("public"."is_org_member"("organization_id"));



CREATE POLICY "Users can view team members in their teams" ON "public"."team_members" FOR SELECT TO "authenticated" USING ("public"."is_team_member"("team_id"));



ALTER TABLE "public"."accounts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "authenticated_users_create_bots" ON "public"."accounts" FOR INSERT TO "authenticated" WITH CHECK ((("type" = 'Bot'::"text") AND ("status" <> 'deleted'::"text") AND ("auth_user_id" = "auth"."uid"())));



COMMENT ON POLICY "authenticated_users_create_bots" ON "public"."accounts" IS 'Allows authenticated users to create new bots.';



CREATE POLICY "authenticated_users_create_organizations" ON "public"."accounts" FOR INSERT TO "authenticated" WITH CHECK ((("type" = 'Organization'::"text") AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "authenticated_users_create_organizations" ON "public"."accounts" IS 'Allows authenticated users to create organizations. The trigger add_creator_as_org_owner will add them as owner if they have a User account.';



CREATE POLICY "bot_creators_delete_bots" ON "public"."accounts" FOR UPDATE TO "authenticated" USING ((("type" = 'Bot'::"text") AND ("auth_user_id" = "auth"."uid"()))) WITH CHECK ((("type" = 'Bot'::"text") AND ("status" = 'deleted'::"text")));



COMMENT ON POLICY "bot_creators_delete_bots" ON "public"."accounts" IS 'Allows bot creators to soft-delete their bots (status = deleted).';



CREATE POLICY "bot_creators_update_bots" ON "public"."accounts" FOR UPDATE TO "authenticated" USING ((("type" = 'Bot'::"text") AND ("auth_user_id" = "auth"."uid"()))) WITH CHECK ((("type" = 'Bot'::"text") AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "bot_creators_update_bots" ON "public"."accounts" IS 'Allows bot creators to update their bots.';



CREATE POLICY "org_owners_create_teams" ON "public"."teams" FOR INSERT TO "authenticated" WITH CHECK (("organization_id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text")))));



COMMENT ON POLICY "org_owners_create_teams" ON "public"."teams" IS 'Allows organization owners to create new teams in their organizations.';



CREATE POLICY "org_owners_delete_organizations" ON "public"."accounts" FOR UPDATE TO "authenticated" USING ((("type" = 'Organization'::"text") AND ("id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text")))))) WITH CHECK ((("type" = 'Organization'::"text") AND ("status" = 'deleted'::"text")));



COMMENT ON POLICY "org_owners_delete_organizations" ON "public"."accounts" IS 'Allows organization owners to soft-delete organizations (status = deleted).';



CREATE POLICY "org_owners_delete_teams" ON "public"."teams" FOR DELETE TO "authenticated" USING (("organization_id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text")))));



COMMENT ON POLICY "org_owners_delete_teams" ON "public"."teams" IS 'Allows organization owners to delete teams from their organizations.';



CREATE POLICY "org_owners_update_organizations" ON "public"."accounts" FOR UPDATE TO "authenticated" USING ((("type" = 'Organization'::"text") AND ("id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text")))))) WITH CHECK ((("type" = 'Organization'::"text") AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "org_owners_update_organizations" ON "public"."accounts" IS 'Allows organization owners to update organization details.';



CREATE POLICY "org_owners_update_teams" ON "public"."teams" FOR UPDATE TO "authenticated" USING (("organization_id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text"))))) WITH CHECK (("organization_id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."role" = 'owner'::"text")))));



COMMENT ON POLICY "org_owners_update_teams" ON "public"."teams" IS 'Allows organization owners to update team details in their organizations.';



ALTER TABLE "public"."organization_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."team_bots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."team_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "team_owners_add_bots_to_teams" ON "public"."team_bots" FOR INSERT TO "authenticated" WITH CHECK (("team_id" IN ( SELECT "tm"."team_id"
   FROM "public"."team_members" "tm"
  WHERE (("tm"."account_id" = "public"."get_user_account_id"()) AND ("tm"."role" = 'leader'::"text")))));



CREATE POLICY "team_owners_remove_bots_from_teams" ON "public"."team_bots" FOR DELETE TO "authenticated" USING (("team_id" IN ( SELECT "tm"."team_id"
   FROM "public"."team_members" "tm"
  WHERE (("tm"."account_id" = "public"."get_user_account_id"()) AND ("tm"."role" = 'leader'::"text")))));



CREATE POLICY "team_owners_view_team_bots" ON "public"."team_bots" FOR SELECT TO "authenticated" USING (("team_id" IN ( SELECT "tm"."team_id"
   FROM "public"."team_members" "tm"
  WHERE ("tm"."account_id" = "public"."get_user_account_id"()))));



ALTER TABLE "public"."teams" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_insert_own_user_account" ON "public"."accounts" FOR INSERT TO "authenticated" WITH CHECK ((("type" = 'User'::"text") AND ("auth_user_id" = "auth"."uid"()) AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "users_insert_own_user_account" ON "public"."accounts" IS 'Allows authenticated users to create their own User account.';



CREATE POLICY "users_update_own_user_account" ON "public"."accounts" FOR UPDATE TO "authenticated" USING ((("type" = 'User'::"text") AND ("auth_user_id" = "auth"."uid"()))) WITH CHECK ((("type" = 'User'::"text") AND ("auth_user_id" = "auth"."uid"()) AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "users_update_own_user_account" ON "public"."accounts" IS 'Allows users to update their own User account profile information.';



CREATE POLICY "users_view_bots_in_their_teams" ON "public"."accounts" FOR SELECT TO "authenticated" USING ((("type" = 'Bot'::"text") AND ("status" <> 'deleted'::"text") AND ("id" IN ( SELECT "tb"."bot_id"
   FROM ("public"."team_bots" "tb"
     JOIN "public"."team_members" "tm" ON (("tm"."team_id" = "tb"."team_id")))
  WHERE ("tm"."account_id" = "public"."get_user_account_id"())))));



COMMENT ON POLICY "users_view_bots_in_their_teams" ON "public"."accounts" IS 'Allows users to view bots that are in their teams. Uses get_user_account_id() to avoid recursion.';



CREATE POLICY "users_view_bots_they_created" ON "public"."accounts" FOR SELECT TO "authenticated" USING ((("type" = 'Bot'::"text") AND ("status" <> 'deleted'::"text") AND ("auth_user_id" = "auth"."uid"())));



COMMENT ON POLICY "users_view_bots_they_created" ON "public"."accounts" IS 'Allows users to view bots they created using direct auth_user_id check.';



CREATE POLICY "users_view_organizations_they_belong_to" ON "public"."accounts" FOR SELECT TO "authenticated" USING ((("type" = 'Organization'::"text") AND ("status" <> 'deleted'::"text") AND (("id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."account_id" = "public"."get_user_account_id"()) AND ("organization_members"."account_id" IS NOT NULL)))) OR ("auth_user_id" = "auth"."uid"()))));



COMMENT ON POLICY "users_view_organizations_they_belong_to" ON "public"."accounts" IS 'Allows users to view organizations they are members of. Uses get_user_account_id() to avoid recursion.';



CREATE POLICY "users_view_own_user_account" ON "public"."accounts" FOR SELECT TO "authenticated" USING ((("type" = 'User'::"text") AND ("auth_user_id" = "auth"."uid"()) AND ("status" <> 'deleted'::"text")));



COMMENT ON POLICY "users_view_own_user_account" ON "public"."accounts" IS 'Allows users to view their own User account using direct auth_user_id check. No recursion.';



CREATE POLICY "users_view_teams_in_their_organizations" ON "public"."teams" FOR SELECT TO "authenticated" USING (("organization_id" IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE ("organization_members"."account_id" = "public"."get_user_account_id"()))));



COMMENT ON POLICY "users_view_teams_in_their_organizations" ON "public"."teams" IS 'Allows users to view teams in organizations they are members of. Uses get_user_account_id() to avoid recursion.';



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."add_creator_as_org_owner"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_creator_as_org_owner"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_creator_as_org_owner"() TO "service_role";



GRANT ALL ON FUNCTION "public"."count_user_workspaces"("user_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."count_user_workspaces"("user_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."count_user_workspaces"("user_uuid" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_user_account_id"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_user_account_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_account_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_workspace_role"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_workspace_role"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_workspace_role"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_org_admin"("target_org_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_org_admin"("target_org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_org_admin"("target_org_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_org_member"("target_org_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_org_member"("target_org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_org_member"("target_org_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_org_owner"("target_org_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_org_owner"("target_org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_org_owner"("target_org_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_team_leader"("target_team_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_team_leader"("target_team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_team_leader"("target_team_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_team_member"("target_team_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_team_member"("target_team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_team_member"("target_team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_workspace_member"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_workspace_member"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_workspace_member"("workspace_uuid" "uuid", "user_uuid" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."organization_has_members"("target_org_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."organization_has_members"("target_org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."organization_has_members"("target_org_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_work_items_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_work_items_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_work_items_updated_at"() TO "service_role";



GRANT ALL ON TABLE "public"."accounts" TO "anon";
GRANT ALL ON TABLE "public"."accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."accounts" TO "service_role";



GRANT ALL ON TABLE "public"."organization_members" TO "anon";
GRANT ALL ON TABLE "public"."organization_members" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_members" TO "service_role";



GRANT ALL ON TABLE "public"."team_bots" TO "anon";
GRANT ALL ON TABLE "public"."team_bots" TO "authenticated";
GRANT ALL ON TABLE "public"."team_bots" TO "service_role";



GRANT ALL ON TABLE "public"."team_members" TO "anon";
GRANT ALL ON TABLE "public"."team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."team_members" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







