create schema if not exists "private";

create type "public"."acceptance_result" as enum ('pending', 'passed', 'failed', 'conditional');

create type "public"."account_status" as enum ('active', 'inactive', 'suspended', 'deleted');

create type "public"."account_type" as enum ('user', 'org', 'bot');

create type "public"."blueprint_role" as enum ('viewer', 'contributor', 'maintainer');

create type "public"."blueprint_team_access" as enum ('read', 'write', 'admin');

create type "public"."issue_severity" as enum ('low', 'medium', 'high', 'critical');

create type "public"."issue_status" as enum ('new', 'assigned', 'in_progress', 'pending_confirm', 'resolved', 'closed', 'reopened');

create type "public"."module_type" as enum ('tasks', 'diary', 'dashboard', 'bot_workflow', 'files', 'todos', 'checklists', 'issues');

create type "public"."organization_role" as enum ('owner', 'admin', 'member');

create type "public"."task_priority" as enum ('lowest', 'low', 'medium', 'high', 'highest');

create type "public"."task_status" as enum ('pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked');

create type "public"."team_role" as enum ('leader', 'member');

create type "public"."weather_type" as enum ('sunny', 'cloudy', 'rainy', 'stormy', 'snowy', 'foggy');


  create table "public"."accounts" (
    "id" uuid not null default gen_random_uuid(),
    "auth_user_id" uuid,
    "type" public.account_type not null default 'user'::public.account_type,
    "status" public.account_status not null default 'active'::public.account_status,
    "name" character varying(255) not null,
    "email" character varying(255),
    "avatar_url" text,
    "metadata" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone,
    "avatar" text
      );


alter table "public"."accounts" enable row level security;


  create table "public"."blueprint_members" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "account_id" uuid not null,
    "role" public.blueprint_role not null default 'viewer'::public.blueprint_role,
    "is_external" boolean not null default false,
    "invited_by" uuid,
    "invited_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."blueprint_members" enable row level security;


  create table "public"."blueprint_team_roles" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "team_id" uuid not null,
    "access_level" public.blueprint_team_access not null default 'read'::public.blueprint_team_access,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."blueprint_team_roles" enable row level security;


  create table "public"."blueprints" (
    "id" uuid not null default gen_random_uuid(),
    "owner_id" uuid not null,
    "name" character varying(255) not null,
    "slug" character varying(100) not null,
    "description" text,
    "cover_url" text,
    "is_public" boolean not null default false,
    "status" public.account_status not null default 'active'::public.account_status,
    "metadata" jsonb default '{}'::jsonb,
    "enabled_modules" public.module_type[] default ARRAY['tasks'::public.module_type],
    "created_by" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."blueprints" enable row level security;


  create table "public"."checklist_items" (
    "id" uuid not null default gen_random_uuid(),
    "checklist_id" uuid not null,
    "title" character varying(500) not null,
    "description" text,
    "sort_order" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."checklist_items" enable row level security;


  create table "public"."checklists" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "name" character varying(255) not null,
    "description" text,
    "sort_order" integer not null default 0,
    "created_by" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."checklists" enable row level security;


  create table "public"."diaries" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "work_date" date not null,
    "weather" public.weather_type,
    "temperature_min" integer,
    "temperature_max" integer,
    "work_hours" numeric(4,2),
    "worker_count" integer,
    "summary" text,
    "notes" text,
    "status" public.account_status not null default 'active'::public.account_status,
    "created_by" uuid,
    "approved_by" uuid,
    "approved_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."diaries" enable row level security;


  create table "public"."diary_attachments" (
    "id" uuid not null default gen_random_uuid(),
    "diary_id" uuid not null,
    "file_name" character varying(255) not null,
    "file_path" text not null,
    "file_size" bigint,
    "mime_type" character varying(100),
    "caption" text,
    "uploaded_by" uuid,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."diary_attachments" enable row level security;


  create table "public"."issue_comments" (
    "id" uuid not null default gen_random_uuid(),
    "issue_id" uuid not null,
    "account_id" uuid not null,
    "content" text not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."issue_comments" enable row level security;


  create table "public"."issues" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "task_id" uuid,
    "title" character varying(500) not null,
    "description" text,
    "severity" public.issue_severity not null default 'medium'::public.issue_severity,
    "status" public.issue_status not null default 'new'::public.issue_status,
    "reported_by" uuid,
    "assigned_to" uuid,
    "resolved_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."issues" enable row level security;


  create table "public"."notifications" (
    "id" uuid not null default gen_random_uuid(),
    "account_id" uuid not null,
    "blueprint_id" uuid,
    "type" character varying(50) not null,
    "title" character varying(255) not null,
    "content" text,
    "is_read" boolean not null default false,
    "metadata" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."notifications" enable row level security;


  create table "public"."organization_members" (
    "id" uuid not null default gen_random_uuid(),
    "organization_id" uuid not null,
    "account_id" uuid not null,
    "role" public.organization_role not null default 'member'::public.organization_role,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."organization_members" enable row level security;


  create table "public"."organizations" (
    "id" uuid not null default gen_random_uuid(),
    "account_id" uuid not null,
    "name" character varying(255) not null,
    "slug" character varying(100) not null,
    "description" text,
    "logo_url" text,
    "metadata" jsonb default '{}'::jsonb,
    "created_by" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."organizations" enable row level security;


  create table "public"."task_acceptances" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "checklist_id" uuid,
    "result" public.acceptance_result not null default 'pending'::public.acceptance_result,
    "notes" text,
    "accepted_by" uuid,
    "accepted_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."task_acceptances" enable row level security;


  create table "public"."task_attachments" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "file_name" character varying(255) not null,
    "file_path" text not null,
    "file_size" bigint,
    "mime_type" character varying(100),
    "uploaded_by" uuid,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."task_attachments" enable row level security;


  create table "public"."tasks" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "parent_id" uuid,
    "title" character varying(500) not null,
    "description" text,
    "status" public.task_status not null default 'pending'::public.task_status,
    "priority" public.task_priority not null default 'medium'::public.task_priority,
    "assignee_id" uuid,
    "reviewer_id" uuid,
    "due_date" date,
    "start_date" date,
    "completion_rate" integer default 0,
    "sort_order" integer not null default 0,
    "metadata" jsonb default '{}'::jsonb,
    "created_by" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."tasks" enable row level security;


  create table "public"."team_members" (
    "id" uuid not null default gen_random_uuid(),
    "team_id" uuid not null,
    "account_id" uuid not null,
    "role" public.team_role not null default 'member'::public.team_role,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."team_members" enable row level security;


  create table "public"."teams" (
    "id" uuid not null default gen_random_uuid(),
    "organization_id" uuid not null,
    "name" character varying(255) not null,
    "description" text,
    "metadata" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."teams" enable row level security;


  create table "public"."todos" (
    "id" uuid not null default gen_random_uuid(),
    "blueprint_id" uuid not null,
    "account_id" uuid not null,
    "title" character varying(500) not null,
    "description" text,
    "is_completed" boolean not null default false,
    "due_date" date,
    "sort_order" integer not null default 0,
    "related_task_id" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "deleted_at" timestamp with time zone
      );


alter table "public"."todos" enable row level security;

CREATE UNIQUE INDEX accounts_auth_user_id_unique ON public.accounts USING btree (auth_user_id);

CREATE UNIQUE INDEX accounts_email_unique ON public.accounts USING btree (email);

CREATE UNIQUE INDEX accounts_pkey ON public.accounts USING btree (id);

CREATE UNIQUE INDEX blueprint_members_pkey ON public.blueprint_members USING btree (id);

CREATE UNIQUE INDEX blueprint_members_unique ON public.blueprint_members USING btree (blueprint_id, account_id);

CREATE UNIQUE INDEX blueprint_team_roles_pkey ON public.blueprint_team_roles USING btree (id);

CREATE UNIQUE INDEX blueprint_team_roles_unique ON public.blueprint_team_roles USING btree (blueprint_id, team_id);

CREATE UNIQUE INDEX blueprints_pkey ON public.blueprints USING btree (id);

CREATE UNIQUE INDEX blueprints_slug_unique ON public.blueprints USING btree (owner_id, slug);

CREATE UNIQUE INDEX checklist_items_pkey ON public.checklist_items USING btree (id);

CREATE UNIQUE INDEX checklists_pkey ON public.checklists USING btree (id);

CREATE UNIQUE INDEX diaries_pkey ON public.diaries USING btree (id);

CREATE UNIQUE INDEX diaries_unique ON public.diaries USING btree (blueprint_id, work_date);

CREATE UNIQUE INDEX diary_attachments_pkey ON public.diary_attachments USING btree (id);

CREATE INDEX idx_accounts_auth_user_id ON public.accounts USING btree (auth_user_id);

CREATE INDEX idx_accounts_status ON public.accounts USING btree (status);

CREATE INDEX idx_accounts_type ON public.accounts USING btree (type);

CREATE INDEX idx_blueprint_members_account ON public.blueprint_members USING btree (account_id);

CREATE INDEX idx_blueprint_members_blueprint ON public.blueprint_members USING btree (blueprint_id);

CREATE INDEX idx_blueprint_members_role ON public.blueprint_members USING btree (role);

CREATE INDEX idx_blueprint_team_roles_blueprint ON public.blueprint_team_roles USING btree (blueprint_id);

CREATE INDEX idx_blueprint_team_roles_team ON public.blueprint_team_roles USING btree (team_id);

CREATE INDEX idx_blueprints_owner ON public.blueprints USING btree (owner_id);

CREATE INDEX idx_blueprints_status ON public.blueprints USING btree (status);

CREATE INDEX idx_checklist_items_checklist ON public.checklist_items USING btree (checklist_id);

CREATE INDEX idx_checklists_blueprint ON public.checklists USING btree (blueprint_id);

CREATE INDEX idx_diaries_blueprint ON public.diaries USING btree (blueprint_id);

CREATE INDEX idx_diaries_work_date ON public.diaries USING btree (work_date);

CREATE INDEX idx_diary_attachments_diary ON public.diary_attachments USING btree (diary_id);

CREATE INDEX idx_issue_comments_issue ON public.issue_comments USING btree (issue_id);

CREATE INDEX idx_issues_blueprint ON public.issues USING btree (blueprint_id);

CREATE INDEX idx_issues_severity ON public.issues USING btree (severity);

CREATE INDEX idx_issues_status ON public.issues USING btree (status);

CREATE INDEX idx_issues_task ON public.issues USING btree (task_id);

CREATE INDEX idx_notifications_account ON public.notifications USING btree (account_id);

CREATE INDEX idx_notifications_blueprint ON public.notifications USING btree (blueprint_id);

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);

CREATE INDEX idx_organization_members_account ON public.organization_members USING btree (account_id);

CREATE INDEX idx_organization_members_org ON public.organization_members USING btree (organization_id);

CREATE INDEX idx_organizations_slug ON public.organizations USING btree (slug);

CREATE INDEX idx_task_acceptances_result ON public.task_acceptances USING btree (result);

CREATE INDEX idx_task_acceptances_task ON public.task_acceptances USING btree (task_id);

CREATE INDEX idx_task_attachments_task ON public.task_attachments USING btree (task_id);

CREATE INDEX idx_tasks_assignee ON public.tasks USING btree (assignee_id);

CREATE INDEX idx_tasks_blueprint ON public.tasks USING btree (blueprint_id);

CREATE INDEX idx_tasks_due_date ON public.tasks USING btree (due_date);

CREATE INDEX idx_tasks_parent ON public.tasks USING btree (parent_id);

CREATE INDEX idx_tasks_status ON public.tasks USING btree (status);

CREATE INDEX idx_team_members_account ON public.team_members USING btree (account_id);

CREATE INDEX idx_team_members_team ON public.team_members USING btree (team_id);

CREATE INDEX idx_teams_organization ON public.teams USING btree (organization_id);

CREATE INDEX idx_todos_account ON public.todos USING btree (account_id);

CREATE INDEX idx_todos_blueprint ON public.todos USING btree (blueprint_id);

CREATE INDEX idx_todos_completed ON public.todos USING btree (is_completed);

CREATE UNIQUE INDEX issue_comments_pkey ON public.issue_comments USING btree (id);

CREATE UNIQUE INDEX issues_pkey ON public.issues USING btree (id);

CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);

CREATE UNIQUE INDEX organization_members_pkey ON public.organization_members USING btree (id);

CREATE UNIQUE INDEX organization_members_unique ON public.organization_members USING btree (organization_id, account_id);

CREATE UNIQUE INDEX organizations_account_id_unique ON public.organizations USING btree (account_id);

CREATE UNIQUE INDEX organizations_pkey ON public.organizations USING btree (id);

CREATE UNIQUE INDEX organizations_slug_key ON public.organizations USING btree (slug);

CREATE UNIQUE INDEX task_acceptances_pkey ON public.task_acceptances USING btree (id);

CREATE UNIQUE INDEX task_attachments_pkey ON public.task_attachments USING btree (id);

CREATE UNIQUE INDEX tasks_pkey ON public.tasks USING btree (id);

CREATE UNIQUE INDEX team_members_pkey ON public.team_members USING btree (id);

CREATE UNIQUE INDEX team_members_unique ON public.team_members USING btree (team_id, account_id);

CREATE UNIQUE INDEX teams_name_unique ON public.teams USING btree (organization_id, name);

CREATE UNIQUE INDEX teams_pkey ON public.teams USING btree (id);

CREATE UNIQUE INDEX todos_pkey ON public.todos USING btree (id);

alter table "public"."accounts" add constraint "accounts_pkey" PRIMARY KEY using index "accounts_pkey";

alter table "public"."blueprint_members" add constraint "blueprint_members_pkey" PRIMARY KEY using index "blueprint_members_pkey";

alter table "public"."blueprint_team_roles" add constraint "blueprint_team_roles_pkey" PRIMARY KEY using index "blueprint_team_roles_pkey";

alter table "public"."blueprints" add constraint "blueprints_pkey" PRIMARY KEY using index "blueprints_pkey";

alter table "public"."checklist_items" add constraint "checklist_items_pkey" PRIMARY KEY using index "checklist_items_pkey";

alter table "public"."checklists" add constraint "checklists_pkey" PRIMARY KEY using index "checklists_pkey";

alter table "public"."diaries" add constraint "diaries_pkey" PRIMARY KEY using index "diaries_pkey";

alter table "public"."diary_attachments" add constraint "diary_attachments_pkey" PRIMARY KEY using index "diary_attachments_pkey";

alter table "public"."issue_comments" add constraint "issue_comments_pkey" PRIMARY KEY using index "issue_comments_pkey";

alter table "public"."issues" add constraint "issues_pkey" PRIMARY KEY using index "issues_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."organization_members" add constraint "organization_members_pkey" PRIMARY KEY using index "organization_members_pkey";

alter table "public"."organizations" add constraint "organizations_pkey" PRIMARY KEY using index "organizations_pkey";

alter table "public"."task_acceptances" add constraint "task_acceptances_pkey" PRIMARY KEY using index "task_acceptances_pkey";

alter table "public"."task_attachments" add constraint "task_attachments_pkey" PRIMARY KEY using index "task_attachments_pkey";

alter table "public"."tasks" add constraint "tasks_pkey" PRIMARY KEY using index "tasks_pkey";

alter table "public"."team_members" add constraint "team_members_pkey" PRIMARY KEY using index "team_members_pkey";

alter table "public"."teams" add constraint "teams_pkey" PRIMARY KEY using index "teams_pkey";

alter table "public"."todos" add constraint "todos_pkey" PRIMARY KEY using index "todos_pkey";

alter table "public"."accounts" add constraint "accounts_auth_user_id_unique" UNIQUE using index "accounts_auth_user_id_unique";

alter table "public"."accounts" add constraint "accounts_email_unique" UNIQUE using index "accounts_email_unique";

alter table "public"."blueprint_members" add constraint "blueprint_members_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."blueprint_members" validate constraint "blueprint_members_account_id_fkey";

alter table "public"."blueprint_members" add constraint "blueprint_members_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."blueprint_members" validate constraint "blueprint_members_blueprint_id_fkey";

alter table "public"."blueprint_members" add constraint "blueprint_members_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES public.accounts(id) not valid;

alter table "public"."blueprint_members" validate constraint "blueprint_members_invited_by_fkey";

alter table "public"."blueprint_members" add constraint "blueprint_members_unique" UNIQUE using index "blueprint_members_unique";

alter table "public"."blueprint_team_roles" add constraint "blueprint_team_roles_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."blueprint_team_roles" validate constraint "blueprint_team_roles_blueprint_id_fkey";

alter table "public"."blueprint_team_roles" add constraint "blueprint_team_roles_team_id_fkey" FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE not valid;

alter table "public"."blueprint_team_roles" validate constraint "blueprint_team_roles_team_id_fkey";

alter table "public"."blueprint_team_roles" add constraint "blueprint_team_roles_unique" UNIQUE using index "blueprint_team_roles_unique";

alter table "public"."blueprints" add constraint "blueprints_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.accounts(id) not valid;

alter table "public"."blueprints" validate constraint "blueprints_created_by_fkey";

alter table "public"."blueprints" add constraint "blueprints_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."blueprints" validate constraint "blueprints_owner_id_fkey";

alter table "public"."blueprints" add constraint "blueprints_slug_unique" UNIQUE using index "blueprints_slug_unique";

alter table "public"."checklist_items" add constraint "checklist_items_checklist_id_fkey" FOREIGN KEY (checklist_id) REFERENCES public.checklists(id) ON DELETE CASCADE not valid;

alter table "public"."checklist_items" validate constraint "checklist_items_checklist_id_fkey";

alter table "public"."checklists" add constraint "checklists_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."checklists" validate constraint "checklists_blueprint_id_fkey";

alter table "public"."checklists" add constraint "checklists_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.accounts(id) not valid;

alter table "public"."checklists" validate constraint "checklists_created_by_fkey";

alter table "public"."diaries" add constraint "diaries_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES public.accounts(id) not valid;

alter table "public"."diaries" validate constraint "diaries_approved_by_fkey";

alter table "public"."diaries" add constraint "diaries_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."diaries" validate constraint "diaries_blueprint_id_fkey";

alter table "public"."diaries" add constraint "diaries_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.accounts(id) not valid;

alter table "public"."diaries" validate constraint "diaries_created_by_fkey";

alter table "public"."diaries" add constraint "diaries_unique" UNIQUE using index "diaries_unique";

alter table "public"."diary_attachments" add constraint "diary_attachments_diary_id_fkey" FOREIGN KEY (diary_id) REFERENCES public.diaries(id) ON DELETE CASCADE not valid;

alter table "public"."diary_attachments" validate constraint "diary_attachments_diary_id_fkey";

alter table "public"."diary_attachments" add constraint "diary_attachments_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES public.accounts(id) not valid;

alter table "public"."diary_attachments" validate constraint "diary_attachments_uploaded_by_fkey";

alter table "public"."issue_comments" add constraint "issue_comments_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."issue_comments" validate constraint "issue_comments_account_id_fkey";

alter table "public"."issue_comments" add constraint "issue_comments_issue_id_fkey" FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE not valid;

alter table "public"."issue_comments" validate constraint "issue_comments_issue_id_fkey";

alter table "public"."issues" add constraint "issues_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES public.accounts(id) not valid;

alter table "public"."issues" validate constraint "issues_assigned_to_fkey";

alter table "public"."issues" add constraint "issues_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."issues" validate constraint "issues_blueprint_id_fkey";

alter table "public"."issues" add constraint "issues_reported_by_fkey" FOREIGN KEY (reported_by) REFERENCES public.accounts(id) not valid;

alter table "public"."issues" validate constraint "issues_reported_by_fkey";

alter table "public"."issues" add constraint "issues_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE SET NULL not valid;

alter table "public"."issues" validate constraint "issues_task_id_fkey";

alter table "public"."notifications" add constraint "notifications_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_account_id_fkey";

alter table "public"."notifications" add constraint "notifications_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_blueprint_id_fkey";

alter table "public"."organization_members" add constraint "organization_members_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."organization_members" validate constraint "organization_members_account_id_fkey";

alter table "public"."organization_members" add constraint "organization_members_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE not valid;

alter table "public"."organization_members" validate constraint "organization_members_organization_id_fkey";

alter table "public"."organization_members" add constraint "organization_members_unique" UNIQUE using index "organization_members_unique";

alter table "public"."organizations" add constraint "organizations_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."organizations" validate constraint "organizations_account_id_fkey";

alter table "public"."organizations" add constraint "organizations_account_id_unique" UNIQUE using index "organizations_account_id_unique";

alter table "public"."organizations" add constraint "organizations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.accounts(id) not valid;

alter table "public"."organizations" validate constraint "organizations_created_by_fkey";

alter table "public"."organizations" add constraint "organizations_slug_key" UNIQUE using index "organizations_slug_key";

alter table "public"."task_acceptances" add constraint "task_acceptances_accepted_by_fkey" FOREIGN KEY (accepted_by) REFERENCES public.accounts(id) not valid;

alter table "public"."task_acceptances" validate constraint "task_acceptances_accepted_by_fkey";

alter table "public"."task_acceptances" add constraint "task_acceptances_checklist_id_fkey" FOREIGN KEY (checklist_id) REFERENCES public.checklists(id) ON DELETE SET NULL not valid;

alter table "public"."task_acceptances" validate constraint "task_acceptances_checklist_id_fkey";

alter table "public"."task_acceptances" add constraint "task_acceptances_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_acceptances" validate constraint "task_acceptances_task_id_fkey";

alter table "public"."task_attachments" add constraint "task_attachments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_attachments" validate constraint "task_attachments_task_id_fkey";

alter table "public"."task_attachments" add constraint "task_attachments_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES public.accounts(id) not valid;

alter table "public"."task_attachments" validate constraint "task_attachments_uploaded_by_fkey";

alter table "public"."tasks" add constraint "tasks_assignee_id_fkey" FOREIGN KEY (assignee_id) REFERENCES public.accounts(id) ON DELETE SET NULL not valid;

alter table "public"."tasks" validate constraint "tasks_assignee_id_fkey";

alter table "public"."tasks" add constraint "tasks_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_blueprint_id_fkey";

alter table "public"."tasks" add constraint "tasks_completion_rate_check" CHECK (((completion_rate >= 0) AND (completion_rate <= 100))) not valid;

alter table "public"."tasks" validate constraint "tasks_completion_rate_check";

alter table "public"."tasks" add constraint "tasks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.accounts(id) not valid;

alter table "public"."tasks" validate constraint "tasks_created_by_fkey";

alter table "public"."tasks" add constraint "tasks_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES public.tasks(id) ON DELETE SET NULL not valid;

alter table "public"."tasks" validate constraint "tasks_parent_id_fkey";

alter table "public"."tasks" add constraint "tasks_reviewer_id_fkey" FOREIGN KEY (reviewer_id) REFERENCES public.accounts(id) ON DELETE SET NULL not valid;

alter table "public"."tasks" validate constraint "tasks_reviewer_id_fkey";

alter table "public"."team_members" add constraint "team_members_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."team_members" validate constraint "team_members_account_id_fkey";

alter table "public"."team_members" add constraint "team_members_team_id_fkey" FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE not valid;

alter table "public"."team_members" validate constraint "team_members_team_id_fkey";

alter table "public"."team_members" add constraint "team_members_unique" UNIQUE using index "team_members_unique";

alter table "public"."teams" add constraint "teams_name_unique" UNIQUE using index "teams_name_unique";

alter table "public"."teams" add constraint "teams_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE not valid;

alter table "public"."teams" validate constraint "teams_organization_id_fkey";

alter table "public"."todos" add constraint "todos_account_id_fkey" FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE not valid;

alter table "public"."todos" validate constraint "todos_account_id_fkey";

alter table "public"."todos" add constraint "todos_blueprint_id_fkey" FOREIGN KEY (blueprint_id) REFERENCES public.blueprints(id) ON DELETE CASCADE not valid;

alter table "public"."todos" validate constraint "todos_blueprint_id_fkey";

alter table "public"."todos" add constraint "todos_related_task_id_fkey" FOREIGN KEY (related_task_id) REFERENCES public.tasks(id) ON DELETE SET NULL not valid;

alter table "public"."todos" validate constraint "todos_related_task_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION private.can_write_blueprint(p_blueprint_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF (SELECT private.is_blueprint_owner(p_blueprint_id)) THEN
    RETURN TRUE;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM public.blueprint_members bm
    JOIN public.accounts a ON a.id = bm.account_id
    WHERE bm.blueprint_id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
    AND bm.role IN ('contributor', 'maintainer')
  ) THEN
    RETURN TRUE;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM public.blueprint_team_roles btr
    JOIN public.team_members tm ON tm.team_id = btr.team_id
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE btr.blueprint_id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
    AND btr.access_level IN ('write', 'admin')
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN EXISTS (
    SELECT 1 FROM public.blueprints b
    JOIN public.organizations o ON o.account_id = b.owner_id
    JOIN public.organization_members om ON om.organization_id = o.id
    JOIN public.accounts a ON a.id = om.account_id
    WHERE b.id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
    AND om.role IN ('owner', 'admin')
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.get_organization_role(p_org_id uuid)
 RETURNS public.organization_role
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_role public.organization_role;
BEGIN
  SELECT om.role INTO v_role
  FROM public.organization_members om
  JOIN public.accounts a ON a.id = om.account_id
  WHERE om.organization_id = p_org_id
  AND a.auth_user_id = auth.uid();
  
  RETURN v_role;
END;
$function$
;

CREATE OR REPLACE FUNCTION private.get_user_account_id()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_account_id UUID;
BEGIN
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'user'
    AND status != 'deleted'
  LIMIT 1;
  
  RETURN v_account_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION private.has_blueprint_access(p_blueprint_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.blueprints
    WHERE id = p_blueprint_id AND is_public = true
  ) THEN
    RETURN TRUE;
  END IF;
  
  IF (SELECT private.is_blueprint_owner(p_blueprint_id)) THEN
    RETURN TRUE;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM public.blueprint_members bm
    JOIN public.accounts a ON a.id = bm.account_id
    WHERE bm.blueprint_id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM public.blueprint_team_roles btr
    JOIN public.team_members tm ON tm.team_id = btr.team_id
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE btr.blueprint_id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN EXISTS (
    SELECT 1 FROM public.blueprints b
    JOIN public.organizations o ON o.account_id = b.owner_id
    JOIN public.organization_members om ON om.organization_id = o.id
    JOIN public.accounts a ON a.id = om.account_id
    WHERE b.id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_account_owner(p_account_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.accounts
    WHERE id = p_account_id
    AND auth_user_id = auth.uid()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_blueprint_owner(p_blueprint_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.blueprints b
    JOIN public.accounts a ON a.id = b.owner_id
    WHERE b.id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
    AND a.type = 'user'
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN EXISTS (
    SELECT 1 FROM public.blueprints b
    JOIN public.organizations o ON o.account_id = b.owner_id
    JOIN public.organization_members om ON om.organization_id = o.id
    JOIN public.accounts a ON a.id = om.account_id
    WHERE b.id = p_blueprint_id
    AND a.auth_user_id = auth.uid()
    AND om.role = 'owner'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_organization_admin(p_org_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members om
    JOIN public.accounts a ON a.id = om.account_id
    WHERE om.organization_id = p_org_id
    AND a.auth_user_id = auth.uid()
    AND om.role IN ('owner', 'admin')
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_organization_member(p_org_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members om
    JOIN public.accounts a ON a.id = om.account_id
    WHERE om.organization_id = p_org_id
    AND a.auth_user_id = auth.uid()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_team_leader(p_team_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.team_members tm
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE tm.team_id = p_team_id
    AND a.auth_user_id = auth.uid()
    AND tm.role = 'leader'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION private.is_team_member(p_team_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.team_members tm
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE tm.team_id = p_team_id
    AND a.auth_user_id = auth.uid()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_blueprint()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_owner_type public.account_type;
BEGIN
  -- Only add member if created_by is provided
  IF NEW.created_by IS NOT NULL THEN
    -- Get the owner account type
    SELECT type INTO v_owner_type
    FROM public.accounts
    WHERE id = NEW.owner_id;
    
    -- For both personal (user) and organization blueprints,
    -- add the creator as maintainer
    INSERT INTO public.blueprint_members (blueprint_id, account_id, role, is_external)
    VALUES (NEW.id, NEW.created_by, 'maintainer', false)
    ON CONFLICT (blueprint_id, account_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_organization()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.accounts (auth_user_id, type, name, email, status)
  VALUES (
    NEW.id,
    'user',
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    'active'
  );
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."accounts" to "anon";

grant insert on table "public"."accounts" to "anon";

grant references on table "public"."accounts" to "anon";

grant select on table "public"."accounts" to "anon";

grant trigger on table "public"."accounts" to "anon";

grant truncate on table "public"."accounts" to "anon";

grant update on table "public"."accounts" to "anon";

grant delete on table "public"."accounts" to "authenticated";

grant insert on table "public"."accounts" to "authenticated";

grant references on table "public"."accounts" to "authenticated";

grant select on table "public"."accounts" to "authenticated";

grant trigger on table "public"."accounts" to "authenticated";

grant truncate on table "public"."accounts" to "authenticated";

grant update on table "public"."accounts" to "authenticated";

grant delete on table "public"."accounts" to "service_role";

grant insert on table "public"."accounts" to "service_role";

grant references on table "public"."accounts" to "service_role";

grant select on table "public"."accounts" to "service_role";

grant trigger on table "public"."accounts" to "service_role";

grant truncate on table "public"."accounts" to "service_role";

grant update on table "public"."accounts" to "service_role";

grant delete on table "public"."blueprint_members" to "anon";

grant insert on table "public"."blueprint_members" to "anon";

grant references on table "public"."blueprint_members" to "anon";

grant select on table "public"."blueprint_members" to "anon";

grant trigger on table "public"."blueprint_members" to "anon";

grant truncate on table "public"."blueprint_members" to "anon";

grant update on table "public"."blueprint_members" to "anon";

grant delete on table "public"."blueprint_members" to "authenticated";

grant insert on table "public"."blueprint_members" to "authenticated";

grant references on table "public"."blueprint_members" to "authenticated";

grant select on table "public"."blueprint_members" to "authenticated";

grant trigger on table "public"."blueprint_members" to "authenticated";

grant truncate on table "public"."blueprint_members" to "authenticated";

grant update on table "public"."blueprint_members" to "authenticated";

grant delete on table "public"."blueprint_members" to "service_role";

grant insert on table "public"."blueprint_members" to "service_role";

grant references on table "public"."blueprint_members" to "service_role";

grant select on table "public"."blueprint_members" to "service_role";

grant trigger on table "public"."blueprint_members" to "service_role";

grant truncate on table "public"."blueprint_members" to "service_role";

grant update on table "public"."blueprint_members" to "service_role";

grant delete on table "public"."blueprint_team_roles" to "anon";

grant insert on table "public"."blueprint_team_roles" to "anon";

grant references on table "public"."blueprint_team_roles" to "anon";

grant select on table "public"."blueprint_team_roles" to "anon";

grant trigger on table "public"."blueprint_team_roles" to "anon";

grant truncate on table "public"."blueprint_team_roles" to "anon";

grant update on table "public"."blueprint_team_roles" to "anon";

grant delete on table "public"."blueprint_team_roles" to "authenticated";

grant insert on table "public"."blueprint_team_roles" to "authenticated";

grant references on table "public"."blueprint_team_roles" to "authenticated";

grant select on table "public"."blueprint_team_roles" to "authenticated";

grant trigger on table "public"."blueprint_team_roles" to "authenticated";

grant truncate on table "public"."blueprint_team_roles" to "authenticated";

grant update on table "public"."blueprint_team_roles" to "authenticated";

grant delete on table "public"."blueprint_team_roles" to "service_role";

grant insert on table "public"."blueprint_team_roles" to "service_role";

grant references on table "public"."blueprint_team_roles" to "service_role";

grant select on table "public"."blueprint_team_roles" to "service_role";

grant trigger on table "public"."blueprint_team_roles" to "service_role";

grant truncate on table "public"."blueprint_team_roles" to "service_role";

grant update on table "public"."blueprint_team_roles" to "service_role";

grant delete on table "public"."blueprints" to "anon";

grant insert on table "public"."blueprints" to "anon";

grant references on table "public"."blueprints" to "anon";

grant select on table "public"."blueprints" to "anon";

grant trigger on table "public"."blueprints" to "anon";

grant truncate on table "public"."blueprints" to "anon";

grant update on table "public"."blueprints" to "anon";

grant delete on table "public"."blueprints" to "authenticated";

grant insert on table "public"."blueprints" to "authenticated";

grant references on table "public"."blueprints" to "authenticated";

grant select on table "public"."blueprints" to "authenticated";

grant trigger on table "public"."blueprints" to "authenticated";

grant truncate on table "public"."blueprints" to "authenticated";

grant update on table "public"."blueprints" to "authenticated";

grant delete on table "public"."blueprints" to "service_role";

grant insert on table "public"."blueprints" to "service_role";

grant references on table "public"."blueprints" to "service_role";

grant select on table "public"."blueprints" to "service_role";

grant trigger on table "public"."blueprints" to "service_role";

grant truncate on table "public"."blueprints" to "service_role";

grant update on table "public"."blueprints" to "service_role";

grant delete on table "public"."checklist_items" to "anon";

grant insert on table "public"."checklist_items" to "anon";

grant references on table "public"."checklist_items" to "anon";

grant select on table "public"."checklist_items" to "anon";

grant trigger on table "public"."checklist_items" to "anon";

grant truncate on table "public"."checklist_items" to "anon";

grant update on table "public"."checklist_items" to "anon";

grant delete on table "public"."checklist_items" to "authenticated";

grant insert on table "public"."checklist_items" to "authenticated";

grant references on table "public"."checklist_items" to "authenticated";

grant select on table "public"."checklist_items" to "authenticated";

grant trigger on table "public"."checklist_items" to "authenticated";

grant truncate on table "public"."checklist_items" to "authenticated";

grant update on table "public"."checklist_items" to "authenticated";

grant delete on table "public"."checklist_items" to "service_role";

grant insert on table "public"."checklist_items" to "service_role";

grant references on table "public"."checklist_items" to "service_role";

grant select on table "public"."checklist_items" to "service_role";

grant trigger on table "public"."checklist_items" to "service_role";

grant truncate on table "public"."checklist_items" to "service_role";

grant update on table "public"."checklist_items" to "service_role";

grant delete on table "public"."checklists" to "anon";

grant insert on table "public"."checklists" to "anon";

grant references on table "public"."checklists" to "anon";

grant select on table "public"."checklists" to "anon";

grant trigger on table "public"."checklists" to "anon";

grant truncate on table "public"."checklists" to "anon";

grant update on table "public"."checklists" to "anon";

grant delete on table "public"."checklists" to "authenticated";

grant insert on table "public"."checklists" to "authenticated";

grant references on table "public"."checklists" to "authenticated";

grant select on table "public"."checklists" to "authenticated";

grant trigger on table "public"."checklists" to "authenticated";

grant truncate on table "public"."checklists" to "authenticated";

grant update on table "public"."checklists" to "authenticated";

grant delete on table "public"."checklists" to "service_role";

grant insert on table "public"."checklists" to "service_role";

grant references on table "public"."checklists" to "service_role";

grant select on table "public"."checklists" to "service_role";

grant trigger on table "public"."checklists" to "service_role";

grant truncate on table "public"."checklists" to "service_role";

grant update on table "public"."checklists" to "service_role";

grant delete on table "public"."diaries" to "anon";

grant insert on table "public"."diaries" to "anon";

grant references on table "public"."diaries" to "anon";

grant select on table "public"."diaries" to "anon";

grant trigger on table "public"."diaries" to "anon";

grant truncate on table "public"."diaries" to "anon";

grant update on table "public"."diaries" to "anon";

grant delete on table "public"."diaries" to "authenticated";

grant insert on table "public"."diaries" to "authenticated";

grant references on table "public"."diaries" to "authenticated";

grant select on table "public"."diaries" to "authenticated";

grant trigger on table "public"."diaries" to "authenticated";

grant truncate on table "public"."diaries" to "authenticated";

grant update on table "public"."diaries" to "authenticated";

grant delete on table "public"."diaries" to "service_role";

grant insert on table "public"."diaries" to "service_role";

grant references on table "public"."diaries" to "service_role";

grant select on table "public"."diaries" to "service_role";

grant trigger on table "public"."diaries" to "service_role";

grant truncate on table "public"."diaries" to "service_role";

grant update on table "public"."diaries" to "service_role";

grant delete on table "public"."diary_attachments" to "anon";

grant insert on table "public"."diary_attachments" to "anon";

grant references on table "public"."diary_attachments" to "anon";

grant select on table "public"."diary_attachments" to "anon";

grant trigger on table "public"."diary_attachments" to "anon";

grant truncate on table "public"."diary_attachments" to "anon";

grant update on table "public"."diary_attachments" to "anon";

grant delete on table "public"."diary_attachments" to "authenticated";

grant insert on table "public"."diary_attachments" to "authenticated";

grant references on table "public"."diary_attachments" to "authenticated";

grant select on table "public"."diary_attachments" to "authenticated";

grant trigger on table "public"."diary_attachments" to "authenticated";

grant truncate on table "public"."diary_attachments" to "authenticated";

grant update on table "public"."diary_attachments" to "authenticated";

grant delete on table "public"."diary_attachments" to "service_role";

grant insert on table "public"."diary_attachments" to "service_role";

grant references on table "public"."diary_attachments" to "service_role";

grant select on table "public"."diary_attachments" to "service_role";

grant trigger on table "public"."diary_attachments" to "service_role";

grant truncate on table "public"."diary_attachments" to "service_role";

grant update on table "public"."diary_attachments" to "service_role";

grant delete on table "public"."issue_comments" to "anon";

grant insert on table "public"."issue_comments" to "anon";

grant references on table "public"."issue_comments" to "anon";

grant select on table "public"."issue_comments" to "anon";

grant trigger on table "public"."issue_comments" to "anon";

grant truncate on table "public"."issue_comments" to "anon";

grant update on table "public"."issue_comments" to "anon";

grant delete on table "public"."issue_comments" to "authenticated";

grant insert on table "public"."issue_comments" to "authenticated";

grant references on table "public"."issue_comments" to "authenticated";

grant select on table "public"."issue_comments" to "authenticated";

grant trigger on table "public"."issue_comments" to "authenticated";

grant truncate on table "public"."issue_comments" to "authenticated";

grant update on table "public"."issue_comments" to "authenticated";

grant delete on table "public"."issue_comments" to "service_role";

grant insert on table "public"."issue_comments" to "service_role";

grant references on table "public"."issue_comments" to "service_role";

grant select on table "public"."issue_comments" to "service_role";

grant trigger on table "public"."issue_comments" to "service_role";

grant truncate on table "public"."issue_comments" to "service_role";

grant update on table "public"."issue_comments" to "service_role";

grant delete on table "public"."issues" to "anon";

grant insert on table "public"."issues" to "anon";

grant references on table "public"."issues" to "anon";

grant select on table "public"."issues" to "anon";

grant trigger on table "public"."issues" to "anon";

grant truncate on table "public"."issues" to "anon";

grant update on table "public"."issues" to "anon";

grant delete on table "public"."issues" to "authenticated";

grant insert on table "public"."issues" to "authenticated";

grant references on table "public"."issues" to "authenticated";

grant select on table "public"."issues" to "authenticated";

grant trigger on table "public"."issues" to "authenticated";

grant truncate on table "public"."issues" to "authenticated";

grant update on table "public"."issues" to "authenticated";

grant delete on table "public"."issues" to "service_role";

grant insert on table "public"."issues" to "service_role";

grant references on table "public"."issues" to "service_role";

grant select on table "public"."issues" to "service_role";

grant trigger on table "public"."issues" to "service_role";

grant truncate on table "public"."issues" to "service_role";

grant update on table "public"."issues" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."organization_members" to "anon";

grant insert on table "public"."organization_members" to "anon";

grant references on table "public"."organization_members" to "anon";

grant select on table "public"."organization_members" to "anon";

grant trigger on table "public"."organization_members" to "anon";

grant truncate on table "public"."organization_members" to "anon";

grant update on table "public"."organization_members" to "anon";

grant delete on table "public"."organization_members" to "authenticated";

grant insert on table "public"."organization_members" to "authenticated";

grant references on table "public"."organization_members" to "authenticated";

grant select on table "public"."organization_members" to "authenticated";

grant trigger on table "public"."organization_members" to "authenticated";

grant truncate on table "public"."organization_members" to "authenticated";

grant update on table "public"."organization_members" to "authenticated";

grant delete on table "public"."organization_members" to "service_role";

grant insert on table "public"."organization_members" to "service_role";

grant references on table "public"."organization_members" to "service_role";

grant select on table "public"."organization_members" to "service_role";

grant trigger on table "public"."organization_members" to "service_role";

grant truncate on table "public"."organization_members" to "service_role";

grant update on table "public"."organization_members" to "service_role";

grant delete on table "public"."organizations" to "anon";

grant insert on table "public"."organizations" to "anon";

grant references on table "public"."organizations" to "anon";

grant select on table "public"."organizations" to "anon";

grant trigger on table "public"."organizations" to "anon";

grant truncate on table "public"."organizations" to "anon";

grant update on table "public"."organizations" to "anon";

grant delete on table "public"."organizations" to "authenticated";

grant insert on table "public"."organizations" to "authenticated";

grant references on table "public"."organizations" to "authenticated";

grant select on table "public"."organizations" to "authenticated";

grant trigger on table "public"."organizations" to "authenticated";

grant truncate on table "public"."organizations" to "authenticated";

grant update on table "public"."organizations" to "authenticated";

grant delete on table "public"."organizations" to "service_role";

grant insert on table "public"."organizations" to "service_role";

grant references on table "public"."organizations" to "service_role";

grant select on table "public"."organizations" to "service_role";

grant trigger on table "public"."organizations" to "service_role";

grant truncate on table "public"."organizations" to "service_role";

grant update on table "public"."organizations" to "service_role";

grant delete on table "public"."task_acceptances" to "anon";

grant insert on table "public"."task_acceptances" to "anon";

grant references on table "public"."task_acceptances" to "anon";

grant select on table "public"."task_acceptances" to "anon";

grant trigger on table "public"."task_acceptances" to "anon";

grant truncate on table "public"."task_acceptances" to "anon";

grant update on table "public"."task_acceptances" to "anon";

grant delete on table "public"."task_acceptances" to "authenticated";

grant insert on table "public"."task_acceptances" to "authenticated";

grant references on table "public"."task_acceptances" to "authenticated";

grant select on table "public"."task_acceptances" to "authenticated";

grant trigger on table "public"."task_acceptances" to "authenticated";

grant truncate on table "public"."task_acceptances" to "authenticated";

grant update on table "public"."task_acceptances" to "authenticated";

grant delete on table "public"."task_acceptances" to "service_role";

grant insert on table "public"."task_acceptances" to "service_role";

grant references on table "public"."task_acceptances" to "service_role";

grant select on table "public"."task_acceptances" to "service_role";

grant trigger on table "public"."task_acceptances" to "service_role";

grant truncate on table "public"."task_acceptances" to "service_role";

grant update on table "public"."task_acceptances" to "service_role";

grant delete on table "public"."task_attachments" to "anon";

grant insert on table "public"."task_attachments" to "anon";

grant references on table "public"."task_attachments" to "anon";

grant select on table "public"."task_attachments" to "anon";

grant trigger on table "public"."task_attachments" to "anon";

grant truncate on table "public"."task_attachments" to "anon";

grant update on table "public"."task_attachments" to "anon";

grant delete on table "public"."task_attachments" to "authenticated";

grant insert on table "public"."task_attachments" to "authenticated";

grant references on table "public"."task_attachments" to "authenticated";

grant select on table "public"."task_attachments" to "authenticated";

grant trigger on table "public"."task_attachments" to "authenticated";

grant truncate on table "public"."task_attachments" to "authenticated";

grant update on table "public"."task_attachments" to "authenticated";

grant delete on table "public"."task_attachments" to "service_role";

grant insert on table "public"."task_attachments" to "service_role";

grant references on table "public"."task_attachments" to "service_role";

grant select on table "public"."task_attachments" to "service_role";

grant trigger on table "public"."task_attachments" to "service_role";

grant truncate on table "public"."task_attachments" to "service_role";

grant update on table "public"."task_attachments" to "service_role";

grant delete on table "public"."tasks" to "anon";

grant insert on table "public"."tasks" to "anon";

grant references on table "public"."tasks" to "anon";

grant select on table "public"."tasks" to "anon";

grant trigger on table "public"."tasks" to "anon";

grant truncate on table "public"."tasks" to "anon";

grant update on table "public"."tasks" to "anon";

grant delete on table "public"."tasks" to "authenticated";

grant insert on table "public"."tasks" to "authenticated";

grant references on table "public"."tasks" to "authenticated";

grant select on table "public"."tasks" to "authenticated";

grant trigger on table "public"."tasks" to "authenticated";

grant truncate on table "public"."tasks" to "authenticated";

grant update on table "public"."tasks" to "authenticated";

grant delete on table "public"."tasks" to "service_role";

grant insert on table "public"."tasks" to "service_role";

grant references on table "public"."tasks" to "service_role";

grant select on table "public"."tasks" to "service_role";

grant trigger on table "public"."tasks" to "service_role";

grant truncate on table "public"."tasks" to "service_role";

grant update on table "public"."tasks" to "service_role";

grant delete on table "public"."team_members" to "anon";

grant insert on table "public"."team_members" to "anon";

grant references on table "public"."team_members" to "anon";

grant select on table "public"."team_members" to "anon";

grant trigger on table "public"."team_members" to "anon";

grant truncate on table "public"."team_members" to "anon";

grant update on table "public"."team_members" to "anon";

grant delete on table "public"."team_members" to "authenticated";

grant insert on table "public"."team_members" to "authenticated";

grant references on table "public"."team_members" to "authenticated";

grant select on table "public"."team_members" to "authenticated";

grant trigger on table "public"."team_members" to "authenticated";

grant truncate on table "public"."team_members" to "authenticated";

grant update on table "public"."team_members" to "authenticated";

grant delete on table "public"."team_members" to "service_role";

grant insert on table "public"."team_members" to "service_role";

grant references on table "public"."team_members" to "service_role";

grant select on table "public"."team_members" to "service_role";

grant trigger on table "public"."team_members" to "service_role";

grant truncate on table "public"."team_members" to "service_role";

grant update on table "public"."team_members" to "service_role";

grant delete on table "public"."teams" to "anon";

grant insert on table "public"."teams" to "anon";

grant references on table "public"."teams" to "anon";

grant select on table "public"."teams" to "anon";

grant trigger on table "public"."teams" to "anon";

grant truncate on table "public"."teams" to "anon";

grant update on table "public"."teams" to "anon";

grant delete on table "public"."teams" to "authenticated";

grant insert on table "public"."teams" to "authenticated";

grant references on table "public"."teams" to "authenticated";

grant select on table "public"."teams" to "authenticated";

grant trigger on table "public"."teams" to "authenticated";

grant truncate on table "public"."teams" to "authenticated";

grant update on table "public"."teams" to "authenticated";

grant delete on table "public"."teams" to "service_role";

grant insert on table "public"."teams" to "service_role";

grant references on table "public"."teams" to "service_role";

grant select on table "public"."teams" to "service_role";

grant trigger on table "public"."teams" to "service_role";

grant truncate on table "public"."teams" to "service_role";

grant update on table "public"."teams" to "service_role";

grant delete on table "public"."todos" to "anon";

grant insert on table "public"."todos" to "anon";

grant references on table "public"."todos" to "anon";

grant select on table "public"."todos" to "anon";

grant trigger on table "public"."todos" to "anon";

grant truncate on table "public"."todos" to "anon";

grant update on table "public"."todos" to "anon";

grant delete on table "public"."todos" to "authenticated";

grant insert on table "public"."todos" to "authenticated";

grant references on table "public"."todos" to "authenticated";

grant select on table "public"."todos" to "authenticated";

grant trigger on table "public"."todos" to "authenticated";

grant truncate on table "public"."todos" to "authenticated";

grant update on table "public"."todos" to "authenticated";

grant delete on table "public"."todos" to "service_role";

grant insert on table "public"."todos" to "service_role";

grant references on table "public"."todos" to "service_role";

grant select on table "public"."todos" to "service_role";

grant trigger on table "public"."todos" to "service_role";

grant truncate on table "public"."todos" to "service_role";

grant update on table "public"."todos" to "service_role";


  create policy "accounts_delete_own"
  on "public"."accounts"
  as permissive
  for delete
  to authenticated
using ((auth_user_id = ( SELECT auth.uid() AS uid)));



  create policy "accounts_insert_own"
  on "public"."accounts"
  as permissive
  for insert
  to authenticated
with check (((auth_user_id = ( SELECT auth.uid() AS uid)) AND (type = 'user'::public.account_type)));



  create policy "accounts_select_own"
  on "public"."accounts"
  as permissive
  for select
  to authenticated
using ((auth_user_id = ( SELECT auth.uid() AS uid)));



  create policy "accounts_update_own"
  on "public"."accounts"
  as permissive
  for update
  to authenticated
using ((auth_user_id = ( SELECT auth.uid() AS uid)))
with check ((auth_user_id = ( SELECT auth.uid() AS uid)));



  create policy "blueprint_members_delete"
  on "public"."blueprint_members"
  as permissive
  for delete
  to authenticated
using ((( SELECT private.is_blueprint_owner(blueprint_members.blueprint_id) AS is_blueprint_owner) OR (EXISTS ( SELECT 1
   FROM (public.blueprint_members bm
     JOIN public.accounts a ON ((a.id = bm.account_id)))
  WHERE ((bm.blueprint_id = blueprint_members.blueprint_id) AND (a.auth_user_id = ( SELECT auth.uid() AS uid)) AND (bm.role = 'maintainer'::public.blueprint_role))))));



  create policy "blueprint_members_insert"
  on "public"."blueprint_members"
  as permissive
  for insert
  to authenticated
with check ((( SELECT private.is_blueprint_owner(blueprint_members.blueprint_id) AS is_blueprint_owner) OR (EXISTS ( SELECT 1
   FROM (public.blueprint_members bm
     JOIN public.accounts a ON ((a.id = bm.account_id)))
  WHERE ((bm.blueprint_id = blueprint_members.blueprint_id) AND (a.auth_user_id = ( SELECT auth.uid() AS uid)) AND (bm.role = 'maintainer'::public.blueprint_role))))));



  create policy "blueprint_members_select"
  on "public"."blueprint_members"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(blueprint_members.blueprint_id) AS has_blueprint_access));



  create policy "blueprint_members_update"
  on "public"."blueprint_members"
  as permissive
  for update
  to authenticated
using ((( SELECT private.is_blueprint_owner(blueprint_members.blueprint_id) AS is_blueprint_owner) OR (EXISTS ( SELECT 1
   FROM (public.blueprint_members bm
     JOIN public.accounts a ON ((a.id = bm.account_id)))
  WHERE ((bm.blueprint_id = blueprint_members.blueprint_id) AND (a.auth_user_id = ( SELECT auth.uid() AS uid)) AND (bm.role = 'maintainer'::public.blueprint_role))))));



  create policy "blueprint_team_roles_delete"
  on "public"."blueprint_team_roles"
  as permissive
  for delete
  to authenticated
using (( SELECT private.is_blueprint_owner(blueprint_team_roles.blueprint_id) AS is_blueprint_owner));



  create policy "blueprint_team_roles_insert"
  on "public"."blueprint_team_roles"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.is_blueprint_owner(blueprint_team_roles.blueprint_id) AS is_blueprint_owner));



  create policy "blueprint_team_roles_select"
  on "public"."blueprint_team_roles"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(blueprint_team_roles.blueprint_id) AS has_blueprint_access));



  create policy "blueprint_team_roles_update"
  on "public"."blueprint_team_roles"
  as permissive
  for update
  to authenticated
using (( SELECT private.is_blueprint_owner(blueprint_team_roles.blueprint_id) AS is_blueprint_owner));



  create policy "blueprints_delete"
  on "public"."blueprints"
  as permissive
  for delete
  to authenticated
using (( SELECT private.is_blueprint_owner(blueprints.id) AS is_blueprint_owner));



  create policy "blueprints_insert"
  on "public"."blueprints"
  as permissive
  for insert
  to authenticated
with check ((( SELECT private.is_account_owner(blueprints.owner_id) AS is_account_owner) OR (EXISTS ( SELECT 1
   FROM ((public.organizations o
     JOIN public.organization_members om ON ((om.organization_id = o.id)))
     JOIN public.accounts a ON ((a.id = om.account_id)))
  WHERE ((o.account_id = blueprints.owner_id) AND (a.auth_user_id = ( SELECT auth.uid() AS uid)) AND (om.role = ANY (ARRAY['owner'::public.organization_role, 'admin'::public.organization_role])))))));



  create policy "blueprints_select"
  on "public"."blueprints"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(blueprints.id) AS has_blueprint_access));



  create policy "blueprints_select_public"
  on "public"."blueprints"
  as permissive
  for select
  to anon
using (((is_public = true) AND (status = 'active'::public.account_status)));



  create policy "blueprints_update"
  on "public"."blueprints"
  as permissive
  for update
  to authenticated
using (( SELECT private.is_blueprint_owner(blueprints.id) AS is_blueprint_owner))
with check (( SELECT private.is_blueprint_owner(blueprints.id) AS is_blueprint_owner));



  create policy "checklist_items_delete"
  on "public"."checklist_items"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.checklists c
  WHERE ((c.id = checklist_items.checklist_id) AND ( SELECT private.can_write_blueprint(c.blueprint_id) AS can_write_blueprint)))));



  create policy "checklist_items_insert"
  on "public"."checklist_items"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.checklists c
  WHERE ((c.id = checklist_items.checklist_id) AND ( SELECT private.can_write_blueprint(c.blueprint_id) AS can_write_blueprint)))));



  create policy "checklist_items_select"
  on "public"."checklist_items"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.checklists c
  WHERE ((c.id = checklist_items.checklist_id) AND ( SELECT private.has_blueprint_access(c.blueprint_id) AS has_blueprint_access)))));



  create policy "checklist_items_update"
  on "public"."checklist_items"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.checklists c
  WHERE ((c.id = checklist_items.checklist_id) AND ( SELECT private.can_write_blueprint(c.blueprint_id) AS can_write_blueprint)))));



  create policy "checklists_delete"
  on "public"."checklists"
  as permissive
  for delete
  to authenticated
using (( SELECT private.can_write_blueprint(checklists.blueprint_id) AS can_write_blueprint));



  create policy "checklists_insert"
  on "public"."checklists"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.can_write_blueprint(checklists.blueprint_id) AS can_write_blueprint));



  create policy "checklists_select"
  on "public"."checklists"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(checklists.blueprint_id) AS has_blueprint_access));



  create policy "checklists_update"
  on "public"."checklists"
  as permissive
  for update
  to authenticated
using (( SELECT private.can_write_blueprint(checklists.blueprint_id) AS can_write_blueprint));



  create policy "diaries_delete"
  on "public"."diaries"
  as permissive
  for delete
  to authenticated
using (( SELECT private.can_write_blueprint(diaries.blueprint_id) AS can_write_blueprint));



  create policy "diaries_insert"
  on "public"."diaries"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.can_write_blueprint(diaries.blueprint_id) AS can_write_blueprint));



  create policy "diaries_select"
  on "public"."diaries"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(diaries.blueprint_id) AS has_blueprint_access));



  create policy "diaries_update"
  on "public"."diaries"
  as permissive
  for update
  to authenticated
using (( SELECT private.can_write_blueprint(diaries.blueprint_id) AS can_write_blueprint));



  create policy "diary_attachments_delete"
  on "public"."diary_attachments"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.diaries d
  WHERE ((d.id = diary_attachments.diary_id) AND ( SELECT private.can_write_blueprint(d.blueprint_id) AS can_write_blueprint)))));



  create policy "diary_attachments_insert"
  on "public"."diary_attachments"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.diaries d
  WHERE ((d.id = diary_attachments.diary_id) AND ( SELECT private.can_write_blueprint(d.blueprint_id) AS can_write_blueprint)))));



  create policy "diary_attachments_select"
  on "public"."diary_attachments"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.diaries d
  WHERE ((d.id = diary_attachments.diary_id) AND ( SELECT private.has_blueprint_access(d.blueprint_id) AS has_blueprint_access)))));



  create policy "issue_comments_delete"
  on "public"."issue_comments"
  as permissive
  for delete
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "issue_comments_insert"
  on "public"."issue_comments"
  as permissive
  for insert
  to authenticated
with check (((EXISTS ( SELECT 1
   FROM public.issues i
  WHERE ((i.id = issue_comments.issue_id) AND ( SELECT private.has_blueprint_access(i.blueprint_id) AS has_blueprint_access)))) AND (account_id = ( SELECT private.get_user_account_id() AS get_user_account_id))));



  create policy "issue_comments_select"
  on "public"."issue_comments"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.issues i
  WHERE ((i.id = issue_comments.issue_id) AND ( SELECT private.has_blueprint_access(i.blueprint_id) AS has_blueprint_access)))));



  create policy "issue_comments_update"
  on "public"."issue_comments"
  as permissive
  for update
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "issues_delete"
  on "public"."issues"
  as permissive
  for delete
  to authenticated
using (( SELECT private.can_write_blueprint(issues.blueprint_id) AS can_write_blueprint));



  create policy "issues_insert"
  on "public"."issues"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.can_write_blueprint(issues.blueprint_id) AS can_write_blueprint));



  create policy "issues_select"
  on "public"."issues"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(issues.blueprint_id) AS has_blueprint_access));



  create policy "issues_update"
  on "public"."issues"
  as permissive
  for update
  to authenticated
using (( SELECT private.can_write_blueprint(issues.blueprint_id) AS can_write_blueprint));



  create policy "notifications_delete"
  on "public"."notifications"
  as permissive
  for delete
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "notifications_insert"
  on "public"."notifications"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "notifications_select"
  on "public"."notifications"
  as permissive
  for select
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "notifications_update"
  on "public"."notifications"
  as permissive
  for update
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "organization_members_delete"
  on "public"."organization_members"
  as permissive
  for delete
  to authenticated
using ((( SELECT private.is_organization_admin(organization_members.organization_id) AS is_organization_admin) AND (role <> 'owner'::public.organization_role)));



  create policy "organization_members_insert"
  on "public"."organization_members"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.is_organization_admin(organization_members.organization_id) AS is_organization_admin));



  create policy "organization_members_select"
  on "public"."organization_members"
  as permissive
  for select
  to authenticated
using (( SELECT private.is_organization_member(organization_members.organization_id) AS is_organization_member));



  create policy "organization_members_update"
  on "public"."organization_members"
  as permissive
  for update
  to authenticated
using (( SELECT private.is_organization_admin(organization_members.organization_id) AS is_organization_admin))
with check ((( SELECT private.is_organization_admin(organization_members.organization_id) AS is_organization_admin) AND ((role <> 'owner'::public.organization_role) OR (( SELECT private.get_organization_role(organization_members.organization_id) AS get_organization_role) = 'owner'::public.organization_role))));



  create policy "organizations_delete_owner"
  on "public"."organizations"
  as permissive
  for delete
  to authenticated
using ((( SELECT private.get_organization_role(organizations.id) AS get_organization_role) = 'owner'::public.organization_role));



  create policy "organizations_insert"
  on "public"."organizations"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "organizations_select_member"
  on "public"."organizations"
  as permissive
  for select
  to authenticated
using (( SELECT private.is_organization_member(organizations.id) AS is_organization_member));



  create policy "organizations_update_admin"
  on "public"."organizations"
  as permissive
  for update
  to authenticated
using (( SELECT private.is_organization_admin(organizations.id) AS is_organization_admin))
with check (( SELECT private.is_organization_admin(organizations.id) AS is_organization_admin));



  create policy "task_acceptances_insert"
  on "public"."task_acceptances"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_acceptances.task_id) AND ( SELECT private.can_write_blueprint(t.blueprint_id) AS can_write_blueprint)))));



  create policy "task_acceptances_select"
  on "public"."task_acceptances"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_acceptances.task_id) AND ( SELECT private.has_blueprint_access(t.blueprint_id) AS has_blueprint_access)))));



  create policy "task_acceptances_update"
  on "public"."task_acceptances"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_acceptances.task_id) AND ( SELECT private.can_write_blueprint(t.blueprint_id) AS can_write_blueprint)))));



  create policy "task_attachments_delete"
  on "public"."task_attachments"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_attachments.task_id) AND ( SELECT private.can_write_blueprint(t.blueprint_id) AS can_write_blueprint)))));



  create policy "task_attachments_insert"
  on "public"."task_attachments"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_attachments.task_id) AND ( SELECT private.can_write_blueprint(t.blueprint_id) AS can_write_blueprint)))));



  create policy "task_attachments_select"
  on "public"."task_attachments"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_attachments.task_id) AND ( SELECT private.has_blueprint_access(t.blueprint_id) AS has_blueprint_access)))));



  create policy "tasks_delete"
  on "public"."tasks"
  as permissive
  for delete
  to authenticated
using (( SELECT private.can_write_blueprint(tasks.blueprint_id) AS can_write_blueprint));



  create policy "tasks_insert"
  on "public"."tasks"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.can_write_blueprint(tasks.blueprint_id) AS can_write_blueprint));



  create policy "tasks_select"
  on "public"."tasks"
  as permissive
  for select
  to authenticated
using (( SELECT private.has_blueprint_access(tasks.blueprint_id) AS has_blueprint_access));



  create policy "tasks_update"
  on "public"."tasks"
  as permissive
  for update
  to authenticated
using (( SELECT private.can_write_blueprint(tasks.blueprint_id) AS can_write_blueprint));



  create policy "team_members_delete"
  on "public"."team_members"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.teams t
  WHERE ((t.id = team_members.team_id) AND (( SELECT private.is_organization_admin(t.organization_id) AS is_organization_admin) OR ( SELECT private.is_team_leader(team_members.team_id) AS is_team_leader))))));



  create policy "team_members_insert"
  on "public"."team_members"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.teams t
  WHERE ((t.id = team_members.team_id) AND (( SELECT private.is_organization_admin(t.organization_id) AS is_organization_admin) OR ( SELECT private.is_team_leader(team_members.team_id) AS is_team_leader))))));



  create policy "team_members_select"
  on "public"."team_members"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.teams t
  WHERE ((t.id = team_members.team_id) AND ( SELECT private.is_organization_member(t.organization_id) AS is_organization_member)))));



  create policy "team_members_update"
  on "public"."team_members"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.teams t
  WHERE ((t.id = team_members.team_id) AND (( SELECT private.is_organization_admin(t.organization_id) AS is_organization_admin) OR ( SELECT private.is_team_leader(team_members.team_id) AS is_team_leader))))));



  create policy "teams_delete"
  on "public"."teams"
  as permissive
  for delete
  to authenticated
using (( SELECT private.is_organization_admin(teams.organization_id) AS is_organization_admin));



  create policy "teams_insert"
  on "public"."teams"
  as permissive
  for insert
  to authenticated
with check (( SELECT private.is_organization_admin(teams.organization_id) AS is_organization_admin));



  create policy "teams_select"
  on "public"."teams"
  as permissive
  for select
  to authenticated
using (( SELECT private.is_organization_member(teams.organization_id) AS is_organization_member));



  create policy "teams_update"
  on "public"."teams"
  as permissive
  for update
  to authenticated
using ((( SELECT private.is_organization_admin(teams.organization_id) AS is_organization_admin) OR ( SELECT private.is_team_leader(teams.id) AS is_team_leader)))
with check ((( SELECT private.is_organization_admin(teams.organization_id) AS is_organization_admin) OR ( SELECT private.is_team_leader(teams.id) AS is_team_leader)));



  create policy "todos_delete"
  on "public"."todos"
  as permissive
  for delete
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));



  create policy "todos_insert"
  on "public"."todos"
  as permissive
  for insert
  to authenticated
with check ((( SELECT private.has_blueprint_access(todos.blueprint_id) AS has_blueprint_access) AND (account_id = ( SELECT private.get_user_account_id() AS get_user_account_id))));



  create policy "todos_select"
  on "public"."todos"
  as permissive
  for select
  to authenticated
using ((( SELECT private.has_blueprint_access(todos.blueprint_id) AS has_blueprint_access) AND (account_id = ( SELECT private.get_user_account_id() AS get_user_account_id))));



  create policy "todos_update"
  on "public"."todos"
  as permissive
  for update
  to authenticated
using ((account_id = ( SELECT private.get_user_account_id() AS get_user_account_id)));


CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_blueprint_members_updated_at BEFORE UPDATE ON public.blueprint_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_blueprint_team_roles_updated_at BEFORE UPDATE ON public.blueprint_team_roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_blueprint_created AFTER INSERT ON public.blueprints FOR EACH ROW EXECUTE FUNCTION public.handle_new_blueprint();

CREATE TRIGGER update_blueprints_updated_at BEFORE UPDATE ON public.blueprints FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_checklist_items_updated_at BEFORE UPDATE ON public.checklist_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_checklists_updated_at BEFORE UPDATE ON public.checklists FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_diaries_updated_at BEFORE UPDATE ON public.diaries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_issue_comments_updated_at BEFORE UPDATE ON public.issue_comments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_issues_updated_at BEFORE UPDATE ON public.issues FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_organization_members_updated_at BEFORE UPDATE ON public.organization_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_organization_created AFTER INSERT ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.handle_new_organization();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_task_acceptances_updated_at BEFORE UPDATE ON public.task_acceptances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_team_members_updated_at BEFORE UPDATE ON public.team_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON public.todos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


