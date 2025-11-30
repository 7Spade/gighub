# 資料庫同步指南 / Database Sync Instructions

## 問題說明
42501 權限錯誤是因為資料庫中缺少以下內容：
1. `blueprints` 和 `blueprint_members` 資料表
2. `tasks`, `task_attachments`, `checklists`, `checklist_items`, `task_acceptances` 資料表
3. RLS 輔助函數：`is_blueprint_member()`, `is_blueprint_admin()`, `is_blueprint_owner()`

## 修復內容
已修復的遷移檔案：
- `supabase/migrations/20251129000001_create_blueprints_table.sql` - 重新排序，表格先於函數建立
- `supabase/migrations/20251129000002_create_tasks_table.sql` - 新增冪等性 (DROP IF EXISTS)

## 同步步驟

### 方法 1：使用 Supabase Dashboard SQL Editor
1. 登入 Supabase Dashboard: https://app.supabase.com
2. 選擇您的專案
3. 前往 SQL Editor
4. 執行以下 SQL 檔案（按順序）：
   - 先執行 `supabase/migrations/20251129000001_create_blueprints_table.sql`
   - 再執行 `supabase/migrations/20251129000002_create_tasks_table.sql`

### 方法 2：使用 Supabase CLI
```bash
# 安裝 Supabase CLI
# macOS
brew install supabase/tap/supabase

# 或 Linux
curl -sSL https://cli.supabase.io | bash

# 連結到專案
supabase link --project-ref nvxhnmkmwekuhzhprfqo

# 執行遷移
supabase db push
```

### 方法 3：使用 Supabase MCP
如果您有 Supabase MCP 工具，可以直接執行：
```
執行 SQL: supabase/migrations/20251129000001_create_blueprints_table.sql
執行 SQL: supabase/migrations/20251129000002_create_tasks_table.sql
```

## 驗證同步
執行以下 SQL 查詢驗證資料庫與遷移是否一致：

```sql
-- 檢查表格是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 檢查輔助函數是否存在
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 檢查 RLS 政策是否存在
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

預期結果應包含：
- 表格：`accounts`, `blueprints`, `blueprint_members`, `checklists`, `checklist_items`, `organization_members`, `task_acceptances`, `task_attachments`, `tasks`, `team_bots`, `team_members`, `teams`
- 函數：`is_blueprint_member`, `is_blueprint_admin`, `is_blueprint_owner`, `can_access_task`, `can_access_checklist`, `is_checklist_admin` 等
