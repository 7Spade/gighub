# 🧪 Supabase 測試指南

> 資料庫測試資源、規範與執行指南

---

## 🎯 目的

確保資料庫遷移、RLS 政策、觸發器與函數的正確性與安全性，防止權限錯誤（如 42501）與資料完整性問題。

---

## 📁 目錄結構

```
supabase/tests/
├── README.md                           # 本文件
│
├── unit/                               # 單元測試
│   ├── functions/                      # Helper Functions 測試
│   │   ├── get_user_account_id.test.sql
│   │   ├── is_org_member.test.sql
│   │   ├── is_org_admin.test.sql
│   │   ├── is_blueprint_member.test.sql
│   │   ├── is_blueprint_admin.test.sql
│   │   └── is_blueprint_owner.test.sql
│   │
│   └── triggers/                       # 觸發器測試
│       ├── add_creator_as_org_owner.test.sql
│       └── add_blueprint_creator_as_owner.test.sql
│
├── integration/                        # 整合測試
│   ├── rls/                           # RLS 政策測試
│   │   ├── accounts_rls.test.sql
│   │   ├── organizations_rls.test.sql
│   │   ├── teams_rls.test.sql
│   │   ├── blueprints_rls.test.sql
│   │   ├── blueprint_members_rls.test.sql
│   │   ├── tasks_rls.test.sql
│   │   └── task_attachments_rls.test.sql
│   │
│   └── permissions/                   # 權限矩陣測試
│       ├── user_permissions.test.sql
│       ├── org_admin_permissions.test.sql
│       └── blueprint_admin_permissions.test.sql
│
├── regression/                        # 回歸測試
│   ├── 42501_recursion.test.sql      # 權限遞迴測試
│   └── data_integrity.test.sql       # 資料完整性測試
│
└── fixtures/                          # 測試資料
    ├── test_users.sql
    ├── test_organizations.sql
    ├── test_blueprints.sql
    └── cleanup.sql
```

---

## 📋 測試檔案命名規範

### 命名格式

```
{test_type}/{category}/{target_name}.test.sql
```

### 範例

| 檔案名稱 | 說明 |
|----------|------|
| `unit/functions/get_user_account_id.test.sql` | Helper function 單元測試 |
| `integration/rls/accounts_rls.test.sql` | Accounts 表 RLS 整合測試 |
| `regression/42501_recursion.test.sql` | 42501 權限遞迴回歸測試 |

---

## 🧪 測試類型

### 1. 單元測試 (Unit Tests)

測試單一函數或觸發器的行為。

**測試範圍**：
- Helper Functions 回傳值
- 觸發器執行結果
- 邊界條件處理

**範例**：`get_user_account_id.test.sql`
```sql
-- Test: get_user_account_id returns correct account_id for authenticated user
BEGIN;

-- Setup: Create test user and account
INSERT INTO auth.users (id, email) VALUES 
  ('test-user-1', 'test1@example.com');
INSERT INTO public.accounts (id, auth_user_id, type, name, email, status) VALUES
  ('account-1', 'test-user-1', 'User', 'Test User', 'test1@example.com', 'active');

-- Set current user context
SET LOCAL "request.jwt.claims" TO '{"sub": "test-user-1"}';

-- Test
SELECT is(
  public.get_user_account_id()::TEXT,
  'account-1',
  'get_user_account_id should return correct account_id'
);

ROLLBACK;
```

### 2. 整合測試 (Integration Tests)

測試 RLS 政策與多表互動。

**測試範圍**：
- RLS SELECT/INSERT/UPDATE/DELETE 政策
- 跨表權限檢查
- 角色權限矩陣

**範例**：`blueprints_rls.test.sql`
```sql
-- Test: Blueprint members can view their blueprints
BEGIN;

-- Setup test data...

-- Test as blueprint member
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "member-user-id"}';

SELECT results_eq(
  'SELECT id FROM blueprints WHERE id = ''blueprint-1''',
  ARRAY['blueprint-1'::UUID],
  'Blueprint member should be able to view their blueprint'
);

-- Test as non-member
SET LOCAL "request.jwt.claims" TO '{"sub": "non-member-user-id"}';

SELECT is_empty(
  'SELECT id FROM blueprints WHERE id = ''blueprint-1'' AND visibility = ''private''',
  'Non-member should not see private blueprint'
);

ROLLBACK;
```

### 3. 回歸測試 (Regression Tests)

防止已修復的問題再次發生。

**測試範圍**：
- 42501 權限遞迴問題
- 無限迴圈檢測
- 資料完整性約束

**範例**：`42501_recursion.test.sql`
```sql
-- Test: RLS policies do not cause infinite recursion
BEGIN;

-- Setup test user
-- ...

-- Test: Selecting from accounts should not cause 42501 error
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "test-user-id"}';

SELECT lives_ok(
  'SELECT * FROM accounts LIMIT 1',
  'Accounts SELECT should not cause recursion error'
);

SELECT lives_ok(
  'SELECT * FROM organization_members LIMIT 1',
  'Organization_members SELECT should not cause recursion error'
);

SELECT lives_ok(
  'SELECT * FROM blueprints LIMIT 1',
  'Blueprints SELECT should not cause recursion error'
);

ROLLBACK;
```

---

## 🏃 執行測試

### 前置需求

1. 安裝 [pgTAP](https://pgtap.org/) 測試框架
2. 本地 Supabase 環境已啟動

### 執行指令

```bash
# 執行所有測試
pnpm supabase:test

# 執行特定測試檔
pg_prove -d postgres -h localhost -p 54322 -U postgres \
  supabase/tests/unit/functions/get_user_account_id.test.sql

# 執行目錄下所有測試
pg_prove -d postgres -h localhost -p 54322 -U postgres \
  supabase/tests/integration/rls/*.test.sql

# 產生測試報告
pg_prove --verbose --color \
  supabase/tests/**/*.test.sql > test-report.txt
```

### CI/CD 整合

```yaml
# .github/workflows/db-tests.yml
- name: Run database tests
  run: |
    supabase start
    pg_prove -d postgres -h localhost -p 54322 \
      supabase/tests/**/*.test.sql
```

---

## 📊 測試覆蓋率目標

| 測試類型 | 目標覆蓋率 | 優先級 |
|----------|------------|--------|
| Helper Functions | 100% | P0 |
| 觸發器 | 100% | P0 |
| RLS 政策 | 100% | P0 |
| 權限矩陣 | 90%+ | P1 |
| 回歸測試 | 關鍵路徑 | P0 |

---

## ✅ 測試規範

### 必要原則

1. **隔離性**：每個測試使用 `BEGIN...ROLLBACK` 確保隔離
2. **可重複**：測試應可重複執行，結果一致
3. **明確性**：測試名稱清楚說明測試目的
4. **獨立性**：測試之間不應有依賴關係

### 測試結構模板

```sql
-- =============================================================================
-- Test: [測試目的簡述]
-- Table: [目標表名]
-- Policy: [政策名稱]
-- =============================================================================

BEGIN;

-- Setup
-- [建立測試資料]

-- Exercise
-- [執行測試操作]

-- Verify
-- [驗證結果]

-- Teardown (由 ROLLBACK 自動處理)

ROLLBACK;
```

---

## 🔧 疑難排解

### 測試失敗常見原因

| 錯誤 | 原因 | 解決方案 |
|------|------|----------|
| `42501` | RLS 權限不足 | 檢查 Helper Function 設定 |
| `23505` | 違反唯一約束 | 使用 `ON CONFLICT` 或清理資料 |
| `23503` | 外鍵約束失敗 | 確保依賴資料存在 |
| `P0001` | 自訂觸發器錯誤 | 檢查觸發器邏輯 |

### 除錯技巧

```sql
-- 1. 檢查當前用戶 context
SELECT auth.uid();

-- 2. 暫時停用 RLS 進行比對
SET row_security = off;
SELECT * FROM target_table;
SET row_security = on;

-- 3. 檢查政策定義
SELECT * FROM pg_policies WHERE tablename = 'target_table';

-- 4. 追蹤查詢執行計畫
EXPLAIN ANALYZE SELECT * FROM target_table;
```

---

## 📚 參考資源

- [pgTAP 官方文件](https://pgtap.org/documentation.html)
- [Supabase 測試指南](https://supabase.com/docs/guides/database/testing)
- [PostgreSQL 測試最佳實踐](https://www.postgresql.org/docs/current/regress.html)

---

**最後更新**: 2025-11-29  
**維護者**: 開發團隊
