# 🔄 Supabase Migrations 遷移指南

> 資料庫遷移檔命名規範、執行流程與完整檔案規劃

---

## 🎯 目的

以有序、可追蹤的方式管理資料庫結構變更（DDL/DML），確保：
- 可重現的資料庫狀態
- 安全的版本控制
- 清晰的回滾策略

---

## 📁 遷移檔案規劃

### 完整檔案清單

```
supabase/migrations/
├── README.md                                           # 本文件
│
├── 00000000000000_initial_schema.sql                  # 🏗️ 初始 schema
│
│── Phase 1: 基礎設施 (Infrastructure)
├── 20251201000001_create_helper_functions.sql         # Helper Functions
├── 20251201000002_create_accounts_table.sql           # Accounts 表
├── 20251201000003_create_accounts_rls.sql             # Accounts RLS
├── 20251201000004_create_auth_trigger.sql             # Auth 觸發器
│
│── Phase 2: 組織與團隊 (Organization & Team)
├── 20251202000001_create_organizations_table.sql      # Organizations 表
├── 20251202000002_create_organization_members_table.sql # 組織成員表
├── 20251202000003_create_org_rls.sql                  # 組織 RLS
├── 20251202000004_create_org_triggers.sql             # 組織觸發器
├── 20251202000005_create_teams_table.sql              # Teams 表
├── 20251202000006_create_team_members_table.sql       # 團隊成員表
├── 20251202000007_create_team_rls.sql                 # 團隊 RLS
├── 20251202000008_create_team_triggers.sql            # 團隊觸發器
│
│── Phase 3: 藍圖系統 (Blueprint System)
├── 20251203000001_create_blueprints_table.sql         # Blueprints 表
├── 20251203000002_create_blueprint_members_table.sql  # 藍圖成員表
├── 20251203000003_create_blueprint_helper_functions.sql # 藍圖 Helper Functions
├── 20251203000004_create_blueprint_rls.sql            # 藍圖 RLS
├── 20251203000005_create_blueprint_triggers.sql       # 藍圖觸發器
│
│── Phase 4: 任務系統 (Task System)
├── 20251204000001_create_tasks_table.sql              # Tasks 表
├── 20251204000002_create_task_attachments_table.sql   # 任務附件表
├── 20251204000003_create_task_helper_functions.sql    # 任務 Helper Functions
├── 20251204000004_create_task_rls.sql                 # 任務 RLS
├── 20251204000005_create_checklists_table.sql         # Checklists 表
├── 20251204000006_create_checklist_items_table.sql    # Checklist Items 表
├── 20251204000007_create_checklist_rls.sql            # Checklist RLS
├── 20251204000008_create_task_acceptances_table.sql   # 任務驗收表
├── 20251204000009_create_task_acceptance_rls.sql      # 驗收 RLS
│
│── Phase 5: 施工日誌 (Diary System)
├── 20251205000001_create_diaries_table.sql            # Diaries 表
├── 20251205000002_create_diary_attachments_table.sql  # 日誌附件表
├── 20251205000003_create_diary_rls.sql                # 日誌 RLS
│
│── Phase 6: 待辦事項 (Todo System)
├── 20251206000001_create_todos_table.sql              # Todos 表
├── 20251206000002_create_todo_rls.sql                 # 待辦 RLS
│
│── Phase 7: 索引與優化 (Indexes & Optimization)
├── 20251207000001_create_indexes.sql                  # 索引建立
│
└── 後續增量遷移...
```

---

## 📋 命名規範

### 檔案命名格式

```
{timestamp}_{action}_{target}.sql
```

### 時間戳格式

```
YYYYMMDDHHMMSS
```

- `YYYY` - 年（4位）
- `MM` - 月（2位）
- `DD` - 日（2位）
- `HHMMSS` - 時分秒（建議使用 `000001`, `000002` 等序號）

### Action 動作詞

| Action | 說明 | 範例 |
|--------|------|------|
| `create` | 建立新物件 | `create_users_table` |
| `alter` | 修改既有物件 | `alter_users_add_phone` |
| `drop` | 刪除物件 | `drop_legacy_table` |
| `add` | 新增欄位/約束 | `add_email_unique_constraint` |
| `remove` | 移除欄位/約束 | `remove_deprecated_column` |
| `rename` | 重新命名 | `rename_user_to_account` |
| `update` | 更新政策/函數 | `update_user_rls_policy` |
| `fix` | 修復問題 | `fix_circular_dependency` |
| `migrate` | 資料遷移 | `migrate_legacy_data` |

### Target 目標物件

| Target | 說明 |
|--------|------|
| `{table}_table` | 資料表 |
| `{table}_rls` | RLS 政策 |
| `{name}_function` | 函數 |
| `{name}_trigger` | 觸發器 |
| `{table}_indexes` | 索引 |
| `helper_functions` | Helper Functions |

---

## 📄 遷移檔案結構

### 標準模板

```sql
-- =============================================================================
-- Migration: {migration_name}
-- Description: {簡述此遷移的目的}
-- Created: {YYYY-MM-DD}
-- Author: {author_name}
-- Phase: {phase_number} - {phase_name}
--
-- Dependencies:
--   - {previous_migration_file}
--
-- Rollback:
--   - {如何回滾此遷移}
-- =============================================================================

-- Transaction wrapper (Supabase 自動處理)
BEGIN;

-- =============================================================================
-- STEP 1: {步驟說明}
-- =============================================================================

-- SQL statements...

-- =============================================================================
-- STEP 2: {步驟說明}
-- =============================================================================

-- SQL statements...

-- =============================================================================
-- GRANTS
-- =============================================================================

GRANT ... TO authenticated;
GRANT ... TO service_role;

COMMIT;
```

### 表格建立範例

```sql
-- =============================================================================
-- Migration: create_blueprints_table
-- Description: 建立 blueprints 表，作為專案/工程的容器
-- Created: 2025-12-03
-- Author: Dev Team
-- Phase: 3 - Blueprint System
-- =============================================================================

BEGIN;

-- =============================================================================
-- TABLE: blueprints
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.blueprints (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core Fields
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Status & Visibility
  status VARCHAR(50) NOT NULL DEFAULT 'active'
    CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility VARCHAR(50) NOT NULL DEFAULT 'private'
    CHECK (visibility IN ('private', 'internal', 'public')),
  
  -- Ownership
  created_by UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE public.blueprints IS '藍圖表：專案/工程的邏輯容器';
COMMENT ON COLUMN public.blueprints.status IS '狀態：draft, active, archived, deleted';
COMMENT ON COLUMN public.blueprints.visibility IS '可見性：private, internal, public';

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_blueprints_created_by 
  ON public.blueprints(created_by);
CREATE INDEX IF NOT EXISTS idx_blueprints_status 
  ON public.blueprints(status) WHERE status != 'deleted';

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_blueprints_updated_at ON public.blueprints;
CREATE TRIGGER update_blueprints_updated_at
  BEFORE UPDATE ON public.blueprints
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- GRANTS
-- =============================================================================

GRANT ALL ON TABLE public.blueprints TO authenticated;
GRANT ALL ON TABLE public.blueprints TO service_role;

COMMIT;
```

---

## 🏃 執行流程

### 開發環境

```bash
# 建立新 migration
pnpm supabase migration new create_xxx_table

# 重置資料庫（執行所有 migrations + seeds）
pnpm supabase:reset

# 僅執行 migrations（不重置）
supabase db push

# 檢視 migration 狀態
supabase migration list
```

### 生產環境

```bash
# 1. 備份資料庫
pg_dump -h $DB_HOST -U postgres -d postgres > backup_$(date +%Y%m%d).sql

# 2. 在 staging 測試
supabase db push --db-url $STAGING_DB_URL

# 3. 推送到生產
supabase db push --db-url $PRODUCTION_DB_URL
```

---

## 🔙 回滾策略

### 回滾原則

1. **新增 migration 而非修改**：永遠不要修改已套用的 migration
2. **明確的回滾 SQL**：每個 migration 都應記錄回滾方式
3. **測試回滾**：在開發環境測試回滾程序

### 回滾範例

```sql
-- =============================================================================
-- Migration: drop_blueprints_deprecated_column
-- Rollback Migration for: add_blueprints_deprecated_column
-- =============================================================================

BEGIN;

-- 移除欄位
ALTER TABLE public.blueprints DROP COLUMN IF EXISTS deprecated_field;

COMMIT;
```

### 緊急回滾

```bash
# 回滾最後一個 migration
supabase migration repair --status reverted {migration_version}

# 手動執行回滾 SQL
psql -h localhost -p 54322 -U postgres -d postgres \
  -f migrations/rollback/xxx_rollback.sql
```

---

## ⚠️ 重要注意事項

### 禁止事項

1. ❌ **不要修改已套用的 migration 檔案**
2. ❌ **不要在 migration 中使用 `DROP TABLE` 而不備份**
3. ❌ **不要在 migration 中硬編碼敏感資料**
4. ❌ **不要跳過 migration 序號**

### 最佳實踐

1. ✅ **小步快跑**：每個 migration 只做一件事
2. ✅ **先測試**：在開發環境完整測試後才推送
3. ✅ **寫回滾**：記錄每個 migration 的回滾方式
4. ✅ **加註解**：說明 migration 的目的和影響

### RLS 相關遷移注意事項

```sql
-- ⚠️ 建立表後必須立即啟用 RLS
ALTER TABLE public.new_table ENABLE ROW LEVEL SECURITY;

-- ⚠️ Helper Functions 必須先於 RLS 政策建立
-- 順序：
-- 1. 建立表
-- 2. 建立 Helper Functions
-- 3. 啟用 RLS
-- 4. 建立 RLS Policies
```

---

## 📊 Phase 規劃說明

| Phase | 名稱 | 內容 | 依賴 |
|-------|------|------|------|
| 0 | Initial | 初始 schema 設定 | - |
| 1 | Infrastructure | Helper Functions, Accounts | Phase 0 |
| 2 | Organization | 組織與團隊系統 | Phase 1 |
| 3 | Blueprint | 藍圖系統 | Phase 1, 2 |
| 4 | Task | 任務系統 | Phase 3 |
| 5 | Diary | 施工日誌系統 | Phase 3 |
| 6 | Todo | 待辦事項系統 | Phase 1 |
| 7 | Optimization | 索引與效能優化 | Phase 1-6 |

---

## 🔗 相關資源

- [Supabase Migrations 文件](https://supabase.com/docs/guides/cli/managing-migrations)
- [PostgreSQL DDL 文件](https://www.postgresql.org/docs/current/ddl.html)
- [policies/README.md](../policies/README.md) - RLS 政策指南
- [seeds/README.md](../seeds/README.md) - 種子資料指南

---

**最後更新**: 2025-11-29  
**維護者**: 開發團隊
