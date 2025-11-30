-- ============================================================================
-- Migration: Create Multi-Tenant SaaS Schema
-- Purpose: Complete database schema for multi-tenant SaaS with RBAC
-- Created: 2025-11-29
-- ============================================================================

-- ============================================================================
-- PART 1: ENUMS (Type Definitions)
-- ============================================================================

-- Account Types: user (個人用戶), org (組織), bot (自動化帳號/系統機器人)
CREATE TYPE account_type AS ENUM ('user', 'org', 'bot');

-- Account Status
CREATE TYPE account_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');

-- Organization Roles: owner (最高權限), admin (管理功能), member (一般使用者)
CREATE TYPE organization_role AS ENUM ('owner', 'admin', 'member');

-- Team Roles: leader (管理團隊成員與授權), member (被授權訪問資源)
CREATE TYPE team_role AS ENUM ('leader', 'member');

-- Blueprint (Workspace) Roles: viewer/contributor/maintainer
CREATE TYPE blueprint_role AS ENUM ('viewer', 'contributor', 'maintainer');

-- Blueprint Team Access Level: read/write/admin
CREATE TYPE blueprint_team_access AS ENUM ('read', 'write', 'admin');

-- Module Types
CREATE TYPE module_type AS ENUM ('tasks', 'diary', 'dashboard', 'bot_workflow', 'files', 'todos', 'checklists', 'issues');

-- Task Status
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked');

-- Task Priority
CREATE TYPE task_priority AS ENUM ('lowest', 'low', 'medium', 'high', 'highest');

-- Issue Severity
CREATE TYPE issue_severity AS ENUM ('low', 'medium', 'high', 'critical');

-- Issue Status
CREATE TYPE issue_status AS ENUM ('new', 'assigned', 'in_progress', 'pending_confirm', 'resolved', 'closed', 'reopened');

-- Acceptance Result
CREATE TYPE acceptance_result AS ENUM ('pending', 'passed', 'failed', 'conditional');

-- Weather Type
CREATE TYPE weather_type AS ENUM ('sunny', 'cloudy', 'rainy', 'stormy', 'snowy', 'foggy');

-- ============================================================================
-- PART 2: PRIVATE SCHEMA FOR HELPER FUNCTIONS
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS private;

-- ============================================================================
-- PART 3: CORE TABLES (Foundation Layer)
-- ============================================================================

-- Table: accounts (帳號)
-- Purpose: 認證與身分識別，依 type 區分權限邏輯
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID,
  type account_type NOT NULL DEFAULT 'user',
  status account_status NOT NULL DEFAULT 'active',
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  avatar_url TEXT,
  avatar TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT accounts_email_unique UNIQUE (email)
);

CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_status ON accounts(status);
CREATE INDEX idx_accounts_auth_user_id ON accounts(auth_user_id);

-- Partial unique index: Only enforces uniqueness of auth_user_id for user accounts.
-- Organization accounts can share the same auth_user_id (set to creator's auth.uid() for RLS)
-- but user accounts must have unique auth_user_id values.
CREATE UNIQUE INDEX accounts_auth_user_id_unique_user_only 
ON accounts (auth_user_id) 
WHERE type = 'user' AND auth_user_id IS NOT NULL;

-- Table: organizations (組織)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT organizations_account_id_unique UNIQUE (account_id)
);

CREATE INDEX idx_organizations_slug ON organizations(slug);

-- Table: organization_members (組織成員)
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  role organization_role NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT organization_members_unique UNIQUE (organization_id, account_id)
);

CREATE INDEX idx_organization_members_org ON organization_members(organization_id);
CREATE INDEX idx_organization_members_account ON organization_members(account_id);

-- Table: teams (團隊)
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT teams_name_unique UNIQUE (organization_id, name)
);

CREATE INDEX idx_teams_organization ON teams(organization_id);

-- Table: team_members (團隊成員)
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  role team_role NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT team_members_unique UNIQUE (team_id, account_id)
);

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_account ON team_members(account_id);

-- ============================================================================
-- PART 4: BLUEPRINT (WORKSPACE) TABLES (Container Layer)
-- ============================================================================

-- Table: blueprints (藍圖/工作區)
CREATE TABLE blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description TEXT,
  cover_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT false,
  status account_status NOT NULL DEFAULT 'active',
  metadata JSONB DEFAULT '{}'::jsonb,
  enabled_modules module_type[] DEFAULT ARRAY['tasks']::module_type[],
  created_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT blueprints_slug_unique UNIQUE (owner_id, slug)
);

CREATE INDEX idx_blueprints_owner ON blueprints(owner_id);
CREATE INDEX idx_blueprints_status ON blueprints(status);

-- Table: blueprint_members (藍圖成員)
CREATE TABLE blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  role blueprint_role NOT NULL DEFAULT 'viewer',
  is_external BOOLEAN NOT NULL DEFAULT false,
  invited_by UUID REFERENCES accounts(id),
  invited_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT blueprint_members_unique UNIQUE (blueprint_id, account_id)
);

CREATE INDEX idx_blueprint_members_blueprint ON blueprint_members(blueprint_id);
CREATE INDEX idx_blueprint_members_account ON blueprint_members(account_id);
CREATE INDEX idx_blueprint_members_role ON blueprint_members(role);

-- Table: blueprint_team_roles (團隊授權)
CREATE TABLE blueprint_team_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  access_level blueprint_team_access NOT NULL DEFAULT 'read',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT blueprint_team_roles_unique UNIQUE (blueprint_id, team_id)
);

CREATE INDEX idx_blueprint_team_roles_blueprint ON blueprint_team_roles(blueprint_id);
CREATE INDEX idx_blueprint_team_roles_team ON blueprint_team_roles(team_id);

-- ============================================================================
-- PART 5: MODULE TABLES (Business Layer)
-- ============================================================================

-- Table: tasks (任務)
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  status task_status NOT NULL DEFAULT 'pending',
  priority task_priority NOT NULL DEFAULT 'medium',
  assignee_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  reviewer_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  due_date DATE,
  start_date DATE,
  completion_rate INTEGER DEFAULT 0 CHECK (completion_rate >= 0 AND completion_rate <= 100),
  sort_order INTEGER NOT NULL DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_tasks_blueprint ON tasks(blueprint_id);
CREATE INDEX idx_tasks_parent ON tasks(parent_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- Table: task_attachments (任務附件)
CREATE TABLE task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR(100),
  uploaded_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_attachments_task ON task_attachments(task_id);

-- Table: diaries (施工日誌)
CREATE TABLE diaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  weather weather_type,
  temperature_min INTEGER,
  temperature_max INTEGER,
  work_hours DECIMAL(4,2),
  worker_count INTEGER,
  summary TEXT,
  notes TEXT,
  status account_status NOT NULL DEFAULT 'active',
  created_by UUID REFERENCES accounts(id),
  approved_by UUID REFERENCES accounts(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT diaries_unique UNIQUE (blueprint_id, work_date)
);

CREATE INDEX idx_diaries_blueprint ON diaries(blueprint_id);
CREATE INDEX idx_diaries_work_date ON diaries(work_date);

-- Table: diary_attachments (日誌附件/施工照片)
CREATE TABLE diary_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID NOT NULL REFERENCES diaries(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR(100),
  caption TEXT,
  uploaded_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_diary_attachments_diary ON diary_attachments(diary_id);

-- Table: checklists (檢查清單)
CREATE TABLE checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_checklists_blueprint ON checklists(blueprint_id);

-- Table: checklist_items (檢查項目)
CREATE TABLE checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES checklists(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_checklist_items_checklist ON checklist_items(checklist_id);

-- Table: task_acceptances (品質驗收記錄)
CREATE TABLE task_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  checklist_id UUID REFERENCES checklists(id) ON DELETE SET NULL,
  result acceptance_result NOT NULL DEFAULT 'pending',
  notes TEXT,
  accepted_by UUID REFERENCES accounts(id),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_acceptances_task ON task_acceptances(task_id);
CREATE INDEX idx_task_acceptances_result ON task_acceptances(result);

-- Table: todos (待辦事項)
CREATE TABLE todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  due_date DATE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  related_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_todos_blueprint ON todos(blueprint_id);
CREATE INDEX idx_todos_account ON todos(account_id);
CREATE INDEX idx_todos_completed ON todos(is_completed);

-- Table: issues (問題追蹤)
CREATE TABLE issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  severity issue_severity NOT NULL DEFAULT 'medium',
  status issue_status NOT NULL DEFAULT 'new',
  reported_by UUID REFERENCES accounts(id),
  assigned_to UUID REFERENCES accounts(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_issues_blueprint ON issues(blueprint_id);
CREATE INDEX idx_issues_task ON issues(task_id);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_issues_severity ON issues(severity);

-- Table: issue_comments (問題評論)
CREATE TABLE issue_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_issue_comments_issue ON issue_comments(issue_id);

-- Table: notifications (通知)
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  blueprint_id UUID REFERENCES blueprints(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_account ON notifications(account_id);
CREATE INDEX idx_notifications_blueprint ON notifications(blueprint_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- ============================================================================
-- PART 6: HELPER FUNCTIONS (SECURITY DEFINER to avoid RLS recursion)
-- ============================================================================

-- Function: Get current user's account_id
CREATE OR REPLACE FUNCTION private.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
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
$$;

-- Function: Check if user owns an account
CREATE OR REPLACE FUNCTION private.is_account_owner(p_account_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.accounts
    WHERE id = p_account_id
    AND auth_user_id = auth.uid()
  );
END;
$$;

-- Function: Check if user is organization member
CREATE OR REPLACE FUNCTION private.is_organization_member(p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members om
    JOIN public.accounts a ON a.id = om.account_id
    WHERE om.organization_id = p_org_id
    AND a.auth_user_id = auth.uid()
  );
END;
$$;

-- Function: Get user's role in organization
CREATE OR REPLACE FUNCTION private.get_organization_role(p_org_id UUID)
RETURNS public.organization_role
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
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
$$;

-- Function: Check if user is organization owner/admin
CREATE OR REPLACE FUNCTION private.is_organization_admin(p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members om
    JOIN public.accounts a ON a.id = om.account_id
    WHERE om.organization_id = p_org_id
    AND a.auth_user_id = auth.uid()
    AND om.role IN ('owner', 'admin')
  );
END;
$$;

-- Function: Check if user is team member
CREATE OR REPLACE FUNCTION private.is_team_member(p_team_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.team_members tm
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE tm.team_id = p_team_id
    AND a.auth_user_id = auth.uid()
  );
END;
$$;

-- Function: Check if user is team leader
CREATE OR REPLACE FUNCTION private.is_team_leader(p_team_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.team_members tm
    JOIN public.accounts a ON a.id = tm.account_id
    WHERE tm.team_id = p_team_id
    AND a.auth_user_id = auth.uid()
    AND tm.role = 'leader'
  );
END;
$$;

-- Function: Check if user is blueprint owner
CREATE OR REPLACE FUNCTION private.is_blueprint_owner(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
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
$$;

-- Function: Check if user has access to blueprint
CREATE OR REPLACE FUNCTION private.has_blueprint_access(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
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
$$;

-- Function: Check if user can write to blueprint
CREATE OR REPLACE FUNCTION private.can_write_blueprint(p_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
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
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION private.get_user_account_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_account_owner(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_organization_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_organization_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_organization_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_team_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_team_leader(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_blueprint_owner(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_blueprint_access(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_write_blueprint(UUID) TO authenticated;

-- ============================================================================
-- PART 7: TRIGGERS (updated_at)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_organization_members_updated_at BEFORE UPDATE ON organization_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_team_members_updated_at BEFORE UPDATE ON team_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_blueprints_updated_at BEFORE UPDATE ON blueprints FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_blueprint_members_updated_at BEFORE UPDATE ON blueprint_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_blueprint_team_roles_updated_at BEFORE UPDATE ON blueprint_team_roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_diaries_updated_at BEFORE UPDATE ON diaries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_checklists_updated_at BEFORE UPDATE ON checklists FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_checklist_items_updated_at BEFORE UPDATE ON checklist_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_task_acceptances_updated_at BEFORE UPDATE ON task_acceptances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_issues_updated_at BEFORE UPDATE ON issues FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_issue_comments_updated_at BEFORE UPDATE ON issue_comments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================================
-- PART 8: ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE blueprint_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE blueprint_team_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies: accounts
CREATE POLICY "accounts_select_own" ON accounts FOR SELECT TO authenticated USING (auth_user_id = (SELECT auth.uid()));
-- NOTE: The following policy was removed because it performed a SELECT on the
-- `accounts` table inside its USING expression which caused Postgres RLS to
-- re-evaluate the policy recursively and produced "infinite recursion" errors
-- at runtime. The safer long-term fix is to implement a SECURITY DEFINER
-- helper owned by a role with BYPASSRLS or to refactor membership checks into
-- helper tables/views that don't trigger the same RLS evaluation path.
--
-- Original (removed) policy:
-- CREATE POLICY "accounts_select_related" ON accounts FOR SELECT TO authenticated USING (type IN ('org', 'bot') AND id IN (SELECT DISTINCT a.id FROM accounts a LEFT JOIN organizations o ON o.account_id = a.id LEFT JOIN organization_members om ON om.organization_id = o.id LEFT JOIN accounts member_account ON member_account.id = om.account_id WHERE member_account.auth_user_id = (SELECT auth.uid())));

-- Fallback: Only allow selecting own account by auth_user_id (already present
-- below). If additional cross-account selection is required (e.g., to view an
-- org account because the user is a member), add a helper SECURITY DEFINER
-- function that is owned by a role with BYPASSRLS and grant EXECUTE to
-- `authenticated`. Implementing that is left as a follow-up task.
CREATE POLICY "accounts_insert_own" ON accounts FOR INSERT TO authenticated WITH CHECK (auth_user_id = (SELECT auth.uid()) AND type = 'user');
-- Note: Organization accounts are created via SECURITY DEFINER function create_organization()
-- which bypasses RLS. This ensures atomic creation and allows auth_user_id = NULL for org accounts.
CREATE POLICY "accounts_update_own" ON accounts FOR UPDATE TO authenticated USING (auth_user_id = (SELECT auth.uid())) WITH CHECK (auth_user_id = (SELECT auth.uid()));
CREATE POLICY "accounts_delete_own" ON accounts FOR DELETE TO authenticated USING (auth_user_id = (SELECT auth.uid()));

-- RLS Policies: organizations
CREATE POLICY "organizations_select_member" ON organizations FOR SELECT TO authenticated USING ((SELECT private.is_organization_member(id)));
CREATE POLICY "organizations_insert" ON organizations FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "organizations_update_admin" ON organizations FOR UPDATE TO authenticated USING ((SELECT private.is_organization_admin(id))) WITH CHECK ((SELECT private.is_organization_admin(id)));
CREATE POLICY "organizations_delete_owner" ON organizations FOR DELETE TO authenticated USING ((SELECT private.get_organization_role(id)) = 'owner');

-- RLS Policies: organization_members
CREATE POLICY "organization_members_select" ON organization_members FOR SELECT TO authenticated USING ((SELECT private.is_organization_member(organization_id)));
CREATE POLICY "organization_members_insert" ON organization_members FOR INSERT TO authenticated WITH CHECK ((SELECT private.is_organization_admin(organization_id)));
CREATE POLICY "organization_members_update" ON organization_members FOR UPDATE TO authenticated USING ((SELECT private.is_organization_admin(organization_id))) WITH CHECK ((SELECT private.is_organization_admin(organization_id)) AND (role != 'owner' OR (SELECT private.get_organization_role(organization_id)) = 'owner'));
CREATE POLICY "organization_members_delete" ON organization_members FOR DELETE TO authenticated USING ((SELECT private.is_organization_admin(organization_id)) AND role != 'owner');

-- RLS Policies: teams
CREATE POLICY "teams_select" ON teams FOR SELECT TO authenticated USING ((SELECT private.is_organization_member(organization_id)));
-- Note: Teams are created via SECURITY DEFINER function create_team()
-- which bypasses RLS and ensures proper permission checks.
CREATE POLICY "teams_update" ON teams FOR UPDATE TO authenticated USING ((SELECT private.is_organization_admin(organization_id)) OR (SELECT private.is_team_leader(id))) WITH CHECK ((SELECT private.is_organization_admin(organization_id)) OR (SELECT private.is_team_leader(id)));
CREATE POLICY "teams_delete" ON teams FOR DELETE TO authenticated USING ((SELECT private.is_organization_admin(organization_id)));

-- RLS Policies: team_members
CREATE POLICY "team_members_select" ON team_members FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM teams t WHERE t.id = team_members.team_id AND (SELECT private.is_organization_member(t.organization_id))));
CREATE POLICY "team_members_insert" ON team_members FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM teams t WHERE t.id = team_members.team_id AND ((SELECT private.is_organization_admin(t.organization_id)) OR (SELECT private.is_team_leader(team_members.team_id)))));
CREATE POLICY "team_members_update" ON team_members FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM teams t WHERE t.id = team_members.team_id AND ((SELECT private.is_organization_admin(t.organization_id)) OR (SELECT private.is_team_leader(team_members.team_id)))));
CREATE POLICY "team_members_delete" ON team_members FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM teams t WHERE t.id = team_members.team_id AND ((SELECT private.is_organization_admin(t.organization_id)) OR (SELECT private.is_team_leader(team_members.team_id)))));

-- RLS Policies: blueprints
CREATE POLICY "blueprints_select" ON blueprints FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(id)));
CREATE POLICY "blueprints_select_public" ON blueprints FOR SELECT TO anon USING (is_public = true AND status = 'active');
-- Note: Blueprints are created via SECURITY DEFINER function create_blueprint()
-- which bypasses RLS and ensures proper permission checks.
CREATE POLICY "blueprints_update" ON blueprints FOR UPDATE TO authenticated USING ((SELECT private.is_blueprint_owner(id))) WITH CHECK ((SELECT private.is_blueprint_owner(id)));
CREATE POLICY "blueprints_delete" ON blueprints FOR DELETE TO authenticated USING ((SELECT private.is_blueprint_owner(id)));

-- RLS Policies: blueprint_members
CREATE POLICY "blueprint_members_select" ON blueprint_members FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "blueprint_members_insert" ON blueprint_members FOR INSERT TO authenticated WITH CHECK ((SELECT private.is_blueprint_owner(blueprint_id)) OR EXISTS (SELECT 1 FROM blueprint_members bm JOIN accounts a ON a.id = bm.account_id WHERE bm.blueprint_id = blueprint_members.blueprint_id AND a.auth_user_id = (SELECT auth.uid()) AND bm.role = 'maintainer'));
CREATE POLICY "blueprint_members_update" ON blueprint_members FOR UPDATE TO authenticated USING ((SELECT private.is_blueprint_owner(blueprint_id)) OR EXISTS (SELECT 1 FROM blueprint_members bm JOIN accounts a ON a.id = bm.account_id WHERE bm.blueprint_id = blueprint_members.blueprint_id AND a.auth_user_id = (SELECT auth.uid()) AND bm.role = 'maintainer'));
CREATE POLICY "blueprint_members_delete" ON blueprint_members FOR DELETE TO authenticated USING ((SELECT private.is_blueprint_owner(blueprint_id)) OR EXISTS (SELECT 1 FROM blueprint_members bm JOIN accounts a ON a.id = bm.account_id WHERE bm.blueprint_id = blueprint_members.blueprint_id AND a.auth_user_id = (SELECT auth.uid()) AND bm.role = 'maintainer'));

-- RLS Policies: blueprint_team_roles
CREATE POLICY "blueprint_team_roles_select" ON blueprint_team_roles FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "blueprint_team_roles_insert" ON blueprint_team_roles FOR INSERT TO authenticated WITH CHECK ((SELECT private.is_blueprint_owner(blueprint_id)));
CREATE POLICY "blueprint_team_roles_update" ON blueprint_team_roles FOR UPDATE TO authenticated USING ((SELECT private.is_blueprint_owner(blueprint_id)));
CREATE POLICY "blueprint_team_roles_delete" ON blueprint_team_roles FOR DELETE TO authenticated USING ((SELECT private.is_blueprint_owner(blueprint_id)));

-- RLS Policies: tasks
CREATE POLICY "tasks_select" ON tasks FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "tasks_insert" ON tasks FOR INSERT TO authenticated WITH CHECK ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "tasks_update" ON tasks FOR UPDATE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "tasks_delete" ON tasks FOR DELETE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));

-- RLS Policies: task_attachments
CREATE POLICY "task_attachments_select" ON task_attachments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_attachments.task_id AND (SELECT private.has_blueprint_access(t.blueprint_id))));
CREATE POLICY "task_attachments_insert" ON task_attachments FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_attachments.task_id AND (SELECT private.can_write_blueprint(t.blueprint_id))));
CREATE POLICY "task_attachments_delete" ON task_attachments FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_attachments.task_id AND (SELECT private.can_write_blueprint(t.blueprint_id))));

-- RLS Policies: diaries
CREATE POLICY "diaries_select" ON diaries FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "diaries_insert" ON diaries FOR INSERT TO authenticated WITH CHECK ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "diaries_update" ON diaries FOR UPDATE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "diaries_delete" ON diaries FOR DELETE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));

-- RLS Policies: diary_attachments
CREATE POLICY "diary_attachments_select" ON diary_attachments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM diaries d WHERE d.id = diary_attachments.diary_id AND (SELECT private.has_blueprint_access(d.blueprint_id))));
CREATE POLICY "diary_attachments_insert" ON diary_attachments FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM diaries d WHERE d.id = diary_attachments.diary_id AND (SELECT private.can_write_blueprint(d.blueprint_id))));
CREATE POLICY "diary_attachments_delete" ON diary_attachments FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM diaries d WHERE d.id = diary_attachments.diary_id AND (SELECT private.can_write_blueprint(d.blueprint_id))));

-- RLS Policies: checklists
CREATE POLICY "checklists_select" ON checklists FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "checklists_insert" ON checklists FOR INSERT TO authenticated WITH CHECK ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "checklists_update" ON checklists FOR UPDATE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "checklists_delete" ON checklists FOR DELETE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));

-- RLS Policies: checklist_items
CREATE POLICY "checklist_items_select" ON checklist_items FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM checklists c WHERE c.id = checklist_items.checklist_id AND (SELECT private.has_blueprint_access(c.blueprint_id))));
CREATE POLICY "checklist_items_insert" ON checklist_items FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM checklists c WHERE c.id = checklist_items.checklist_id AND (SELECT private.can_write_blueprint(c.blueprint_id))));
CREATE POLICY "checklist_items_update" ON checklist_items FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM checklists c WHERE c.id = checklist_items.checklist_id AND (SELECT private.can_write_blueprint(c.blueprint_id))));
CREATE POLICY "checklist_items_delete" ON checklist_items FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM checklists c WHERE c.id = checklist_items.checklist_id AND (SELECT private.can_write_blueprint(c.blueprint_id))));

-- RLS Policies: task_acceptances
CREATE POLICY "task_acceptances_select" ON task_acceptances FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_acceptances.task_id AND (SELECT private.has_blueprint_access(t.blueprint_id))));
CREATE POLICY "task_acceptances_insert" ON task_acceptances FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_acceptances.task_id AND (SELECT private.can_write_blueprint(t.blueprint_id))));
CREATE POLICY "task_acceptances_update" ON task_acceptances FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM tasks t WHERE t.id = task_acceptances.task_id AND (SELECT private.can_write_blueprint(t.blueprint_id))));

-- RLS Policies: todos
CREATE POLICY "todos_select" ON todos FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)) AND account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "todos_insert" ON todos FOR INSERT TO authenticated WITH CHECK ((SELECT private.has_blueprint_access(blueprint_id)) AND account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "todos_update" ON todos FOR UPDATE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "todos_delete" ON todos FOR DELETE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));

-- RLS Policies: issues
CREATE POLICY "issues_select" ON issues FOR SELECT TO authenticated USING ((SELECT private.has_blueprint_access(blueprint_id)));
CREATE POLICY "issues_insert" ON issues FOR INSERT TO authenticated WITH CHECK ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "issues_update" ON issues FOR UPDATE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));
CREATE POLICY "issues_delete" ON issues FOR DELETE TO authenticated USING ((SELECT private.can_write_blueprint(blueprint_id)));

-- RLS Policies: issue_comments
CREATE POLICY "issue_comments_select" ON issue_comments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM issues i WHERE i.id = issue_comments.issue_id AND (SELECT private.has_blueprint_access(i.blueprint_id))));
CREATE POLICY "issue_comments_insert" ON issue_comments FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM issues i WHERE i.id = issue_comments.issue_id AND (SELECT private.has_blueprint_access(i.blueprint_id))) AND account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "issue_comments_update" ON issue_comments FOR UPDATE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "issue_comments_delete" ON issue_comments FOR DELETE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));

-- RLS Policies: notifications
CREATE POLICY "notifications_select" ON notifications FOR SELECT TO authenticated USING (account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "notifications_insert" ON notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "notifications_update" ON notifications FOR UPDATE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));
CREATE POLICY "notifications_delete" ON notifications FOR DELETE TO authenticated USING (account_id = (SELECT private.get_user_account_id()));

-- ============================================================================
-- PART 9: AUTO-CREATE ACCOUNT ON AUTH USER
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- CREATE ORGANIZATION FUNCTION (SECURITY DEFINER)
-- Creates an organization account and organization record in a single transaction.
-- This function bypasses RLS policies to ensure atomic creation.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_organization(
  p_name VARCHAR(255),
  p_email VARCHAR(255) DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL,
  p_slug VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
  account_id UUID,
  organization_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_account_id UUID;
  v_org_account_id UUID;
  v_organization_id UUID;
  v_slug VARCHAR(100);
  v_auth_user_id UUID;
BEGIN
  -- 1. Get current user's auth_user_id
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- 2. Get user's account_id
  SELECT id INTO v_user_account_id
  FROM public.accounts
  WHERE auth_user_id = v_auth_user_id
    AND type = 'user'
    AND status != 'deleted'
  LIMIT 1;

  IF v_user_account_id IS NULL THEN
    RAISE EXCEPTION 'User account not found';
  END IF;

  -- 3. Generate slug if not provided
  IF p_slug IS NULL OR p_slug = '' THEN
    v_slug := lower(regexp_replace(p_name, '[^a-zA-Z0-9]+', '-', 'g'));
    v_slug := trim(both '-' from v_slug);
    -- Ensure slug is unique
    WHILE EXISTS (SELECT 1 FROM public.organizations WHERE slug = v_slug) LOOP
      v_slug := v_slug || '-' || substr(gen_random_uuid()::text, 1, 8);
    END LOOP;
  ELSE
    v_slug := p_slug;
  END IF;

  -- 4. Create organization account (auth_user_id = NULL for org accounts)
  INSERT INTO public.accounts (
    auth_user_id,
    type,
    name,
    email,
    avatar_url,
    status
  )
  VALUES (
    NULL,  -- Organization accounts don't need auth_user_id
    'org',
    p_name,
    p_email,
    p_avatar_url,
    'active'
  )
  RETURNING id INTO v_org_account_id;

  -- 5. Create organization record
  INSERT INTO public.organizations (
    account_id,
    name,
    slug,
    description,
    logo_url,
    created_by
  )
  VALUES (
    v_org_account_id,
    p_name,
    v_slug,
    NULL,
    p_avatar_url,
    v_user_account_id
  )
  RETURNING id INTO v_organization_id;

  -- 6. Add creator as owner (trigger will handle this, but we do it explicitly for clarity)
  INSERT INTO public.organization_members (organization_id, account_id, role)
  VALUES (v_organization_id, v_user_account_id, 'owner')
  ON CONFLICT (organization_id, account_id) DO NOTHING;

  -- 7. Return created IDs
  RETURN QUERY SELECT v_org_account_id, v_organization_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_organization(VARCHAR, VARCHAR, TEXT, VARCHAR) TO authenticated;

-- ============================================================================
-- AUTO-ADD ORGANIZATION CREATOR AS OWNER MEMBER
-- When an organization is created, automatically add the creator (created_by)
-- to organization_members with role = 'owner'
-- ============================================================================

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

CREATE OR REPLACE TRIGGER on_organization_created
  AFTER INSERT ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_organization();

-- ============================================================================
-- CREATE TEAM FUNCTION (SECURITY DEFINER)
-- Creates a team in an organization with proper permission checks.
-- This function bypasses RLS policies to ensure atomic creation.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_team(
  p_organization_id UUID,
  p_name VARCHAR(255),
  p_description TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE (
  team_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_account_id UUID;
  v_team_id UUID;
  v_auth_user_id UUID;
BEGIN
  -- 1. Get current user's auth_user_id
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- 2. Get user's account_id
  SELECT id INTO v_user_account_id
  FROM public.accounts
  WHERE auth_user_id = v_auth_user_id
    AND type = 'user'
    AND status != 'deleted'
  LIMIT 1;

  IF v_user_account_id IS NULL THEN
    RAISE EXCEPTION 'User account not found';
  END IF;

  -- 3. Verify user is organization admin/owner
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members om
    JOIN public.accounts a ON a.id = om.account_id
    WHERE om.organization_id = p_organization_id
    AND a.auth_user_id = v_auth_user_id
    AND om.role IN ('owner', 'admin')
  ) THEN
    RAISE EXCEPTION 'User is not an admin or owner of the organization';
  END IF;

  -- 4. Check if team name already exists in organization
  IF EXISTS (
    SELECT 1 FROM public.teams
    WHERE organization_id = p_organization_id
    AND name = p_name
    AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Team name already exists in this organization';
  END IF;

  -- 5. Create team
  INSERT INTO public.teams (
    organization_id,
    name,
    description,
    metadata
  )
  VALUES (
    p_organization_id,
    p_name,
    p_description,
    p_metadata
  )
  RETURNING id INTO v_team_id;

  -- 6. Return created team ID
  RETURN QUERY SELECT v_team_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_team(UUID, VARCHAR, TEXT, JSONB) TO authenticated;

-- ============================================================================
-- CREATE BLUEPRINT FUNCTION (SECURITY DEFINER)
-- Creates a blueprint (workspace) with proper permission checks.
-- This function bypasses RLS policies to ensure atomic creation.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_blueprint(
  p_owner_id UUID,
  p_name VARCHAR(255),
  p_slug VARCHAR(100) DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_cover_url TEXT DEFAULT NULL,
  p_is_public BOOLEAN DEFAULT false,
  p_enabled_modules module_type[] DEFAULT ARRAY['tasks']::module_type[]
)
RETURNS TABLE (
  blueprint_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_account_id UUID;
  v_blueprint_id UUID;
  v_slug VARCHAR(100);
  v_auth_user_id UUID;
  v_owner_type public.account_type;
BEGIN
  -- 1. Get current user's auth_user_id
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- 2. Get user's account_id
  SELECT id INTO v_user_account_id
  FROM public.accounts
  WHERE auth_user_id = v_auth_user_id
    AND type = 'user'
    AND status != 'deleted'
  LIMIT 1;

  IF v_user_account_id IS NULL THEN
    RAISE EXCEPTION 'User account not found';
  END IF;

  -- 3. Get owner account type and verify permissions
  SELECT type INTO v_owner_type
  FROM public.accounts
  WHERE id = p_owner_id
    AND status != 'deleted';

  IF v_owner_type IS NULL THEN
    RAISE EXCEPTION 'Owner account not found';
  END IF;

  -- 4. Verify user has permission to create blueprint for owner
  IF v_owner_type = 'user' THEN
    -- For user accounts, owner must be the current user
    IF p_owner_id != v_user_account_id THEN
      RAISE EXCEPTION 'User can only create blueprints for their own account';
    END IF;
  ELSIF v_owner_type = 'org' THEN
    -- For organization accounts, user must be admin/owner
    IF NOT EXISTS (
      SELECT 1 FROM public.organizations o
      JOIN public.organization_members om ON om.organization_id = o.id
      JOIN public.accounts a ON a.id = om.account_id
      WHERE o.account_id = p_owner_id
      AND a.auth_user_id = v_auth_user_id
      AND om.role IN ('owner', 'admin')
    ) THEN
      RAISE EXCEPTION 'User is not an admin or owner of the organization';
    END IF;
  ELSE
    RAISE EXCEPTION 'Invalid owner account type';
  END IF;

  -- 5. Generate slug if not provided
  IF p_slug IS NULL OR p_slug = '' THEN
    v_slug := lower(regexp_replace(p_name, '[^a-zA-Z0-9]+', '-', 'g'));
    v_slug := trim(both '-' from v_slug);
    -- Ensure slug is unique for the owner
    WHILE EXISTS (
      SELECT 1 FROM public.blueprints
      WHERE owner_id = p_owner_id
      AND slug = v_slug
      AND deleted_at IS NULL
    ) LOOP
      v_slug := v_slug || '-' || substr(gen_random_uuid()::text, 1, 8);
    END LOOP;
  ELSE
    v_slug := p_slug;
    -- Check if slug already exists for owner
    IF EXISTS (
      SELECT 1 FROM public.blueprints
      WHERE owner_id = p_owner_id
      AND slug = v_slug
      AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Blueprint slug already exists for this owner';
    END IF;
  END IF;

  -- 6. Create blueprint
  INSERT INTO public.blueprints (
    owner_id,
    name,
    slug,
    description,
    cover_url,
    is_public,
    status,
    enabled_modules,
    created_by
  )
  VALUES (
    p_owner_id,
    p_name,
    v_slug,
    p_description,
    p_cover_url,
    p_is_public,
    'active',
    p_enabled_modules,
    v_user_account_id
  )
  RETURNING id INTO v_blueprint_id;

  -- 7. Add creator as maintainer (trigger will also handle this, but we do it explicitly)
  INSERT INTO public.blueprint_members (blueprint_id, account_id, role, is_external)
  VALUES (v_blueprint_id, v_user_account_id, 'maintainer', false)
  ON CONFLICT (blueprint_id, account_id) DO NOTHING;

  -- 8. Return created blueprint ID
  RETURN QUERY SELECT v_blueprint_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_blueprint(UUID, VARCHAR, VARCHAR, TEXT, TEXT, BOOLEAN, module_type[]) TO authenticated;

-- ============================================================================
-- AUTO-ADD BLUEPRINT CREATOR AS MAINTAINER MEMBER
-- When a blueprint is created:
-- - If owner is a User (personal blueprint): creator is automatically maintainer
-- - If owner is an Organization: creator is automatically maintainer
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_blueprint()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

CREATE OR REPLACE TRIGGER on_blueprint_created
  AFTER INSERT ON blueprints
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_blueprint();

-- ============================================================================
-- PART 10: COMMENTS/DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE accounts IS '帳號 - 認證與身分識別 (user/org/bot)';
COMMENT ON TABLE organizations IS '組織 - 組織層級管理';
COMMENT ON TABLE organization_members IS '組織成員 - 用戶與組織的多對多關聯';
COMMENT ON TABLE teams IS '團隊 - 組織內群組，用於授權和權限分發 (不是資產所有者)';
COMMENT ON TABLE team_members IS '團隊成員 - 用戶與團隊的多對多關聯';
COMMENT ON TABLE blueprints IS '藍圖/工作區 - 資產容器，Owner = User or Organization';
COMMENT ON TABLE blueprint_members IS '藍圖成員 - Blueprint-level access control (Members + Collaborators)';
COMMENT ON TABLE blueprint_team_roles IS '藍圖團隊授權 - Team permission injection (not ownership)';
COMMENT ON TABLE tasks IS '任務 - 施工工作項目';
COMMENT ON TABLE task_attachments IS '任務附件';
COMMENT ON TABLE diaries IS '施工日誌 - 每日施工記錄';
COMMENT ON TABLE diary_attachments IS '日誌附件/施工照片';
COMMENT ON TABLE checklists IS '檢查清單 - 驗收檢查項目列表';
COMMENT ON TABLE checklist_items IS '檢查項目 - 單一驗收項目';
COMMENT ON TABLE task_acceptances IS '品質驗收記錄';
COMMENT ON TABLE todos IS '待辦事項 - 個人待辦清單';
COMMENT ON TABLE issues IS '問題追蹤';
COMMENT ON TABLE issue_comments IS '問題評論';
COMMENT ON TABLE notifications IS '通知';

COMMENT ON FUNCTION private.get_user_account_id() IS 'Get current user account_id (SECURITY DEFINER to avoid RLS recursion)';
COMMENT ON FUNCTION private.is_account_owner(UUID) IS 'Check if current user owns the account';
COMMENT ON FUNCTION private.is_organization_member(UUID) IS 'Check if current user is member of organization';
COMMENT ON FUNCTION private.is_organization_admin(UUID) IS 'Check if current user is owner/admin of organization';
COMMENT ON FUNCTION private.is_team_member(UUID) IS 'Check if current user is member of team';
COMMENT ON FUNCTION private.is_team_leader(UUID) IS 'Check if current user is leader of team';
COMMENT ON FUNCTION private.is_blueprint_owner(UUID) IS 'Check if current user owns the blueprint (directly or via org)';
COMMENT ON FUNCTION private.has_blueprint_access(UUID) IS 'Check if current user has any access to blueprint';
COMMENT ON FUNCTION private.can_write_blueprint(UUID) IS 'Check if current user can write to blueprint';
COMMENT ON FUNCTION public.handle_new_organization() IS 'Auto-add organization creator to organization_members with role=owner';
COMMENT ON FUNCTION public.handle_new_blueprint() IS 'Auto-add blueprint creator to blueprint_members with role=maintainer';
