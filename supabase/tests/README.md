# Supabase Tests

> 這個資料夾包含與 Supabase 有關的測試資源：單元測試、整合測試、RLS 政策測試與測試工具。

---

## 📁 目錄結構

```
supabase/tests/
├── README.md                          # 本文件 - 測試說明
│
├── unit/                              # 單元測試
│   ├── functions/                     # SQL 函式測試
│   │   ├── get_user_account_id.test.sql
│   │   ├── is_org_member.test.sql
│   │   ├── is_org_admin.test.sql
│   │   └── is_blueprint_member.test.sql
│   └── triggers/                      # 觸發器測試
│       ├── handle_new_user.test.sql
│       └── add_creator_as_owner.test.sql
│
├── integration/                       # 整合測試
│   ├── auth-flow.test.sql             # 認證流程測試
│   ├── blueprint-lifecycle.test.sql   # 藍圖生命週期測試
│   └── task-workflow.test.sql         # 任務工作流程測試
│
├── rls/                               # RLS 政策測試
│   ├── accounts.rls.test.sql          # 帳戶表 RLS 測試
│   ├── organizations.rls.test.sql     # 組織 RLS 測試
│   ├── teams.rls.test.sql             # 團隊 RLS 測試
│   ├── blueprints.rls.test.sql        # 藍圖 RLS 測試
│   └── tasks.rls.test.sql             # 任務 RLS 測試
│
├── fixtures/                          # 測試資料
│   ├── users.sql                      # 測試使用者資料
│   ├── organizations.sql              # 測試組織資料
│   └── blueprints.sql                 # 測試藍圖資料
│
└── helpers/                           # 測試輔助工具
    ├── setup.sql                      # 測試環境設置
    ├── teardown.sql                   # 測試環境清理
    ├── assert.sql                     # 斷言函式
    └── mock-auth.sql                  # 模擬認證函式
```

---

## 📋 規劃檔案清單

### 單元測試 (`unit/`)

#### 函式測試 (`unit/functions/`)

| 檔案名稱 | 測試目標 | 測試案例數 | 狀態 |
|---------|---------|-----------|------|
| `get_user_account_id.test.sql` | `get_user_account_id()` | 3 | 待建立 |
| `is_org_member.test.sql` | `is_org_member()` | 4 | 待建立 |
| `is_org_admin.test.sql` | `is_org_admin()` | 4 | 待建立 |
| `is_blueprint_member.test.sql` | `is_blueprint_member()` | 4 | 待建立 |
| `is_blueprint_admin.test.sql` | `is_blueprint_admin()` | 4 | 待建立 |
| `can_access_task.test.sql` | `can_access_task()` | 5 | 待建立 |

#### 觸發器測試 (`unit/triggers/`)

| 檔案名稱 | 測試目標 | 測試案例數 | 狀態 |
|---------|---------|-----------|------|
| `handle_new_user.test.sql` | 新使用者觸發器 | 2 | 待建立 |
| `add_creator_as_owner.test.sql` | 組織建立者觸發器 | 3 | 待建立 |
| `add_blueprint_creator.test.sql` | 藍圖建立者觸發器 | 3 | 待建立 |

### 整合測試 (`integration/`)

| 檔案名稱 | 測試範圍 | 測試案例數 | 狀態 |
|---------|---------|-----------|------|
| `auth-flow.test.sql` | 完整認證流程 | 5 | 待建立 |
| `blueprint-lifecycle.test.sql` | 藍圖建立→成員管理→刪除 | 6 | 待建立 |
| `task-workflow.test.sql` | 任務建立→更新→驗收 | 8 | 待建立 |
| `team-management.test.sql` | 團隊管理完整流程 | 5 | 待建立 |

### RLS 政策測試 (`rls/`)

| 檔案名稱 | 測試表格 | 測試案例數 | 狀態 |
|---------|---------|-----------|------|
| `accounts.rls.test.sql` | `accounts` | 6 | 待建立 |
| `organizations.rls.test.sql` | `accounts` (Organization) | 6 | 待建立 |
| `org-members.rls.test.sql` | `organization_members` | 8 | 待建立 |
| `teams.rls.test.sql` | `teams` | 6 | 待建立 |
| `team-members.rls.test.sql` | `team_members` | 8 | 待建立 |
| `blueprints.rls.test.sql` | `blueprints` | 8 | 待建立 |
| `blueprint-members.rls.test.sql` | `blueprint_members` | 8 | 待建立 |
| `tasks.rls.test.sql` | `tasks` | 8 | 待建立 |

### 測試輔助 (`helpers/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `setup.sql` | 建立測試環境、載入 fixtures | 待建立 |
| `teardown.sql` | 清理測試資料、重設狀態 | 待建立 |
| `assert.sql` | 斷言函式（assert_equals, assert_true 等） | 待建立 |
| `mock-auth.sql` | 模擬不同使用者的認證狀態 | 待建立 |

---

## 📝 測試規範

### 測試命名

```
<target>_<scenario>_<expected_result>
```

範例：
- `is_org_member_when_member_should_return_true`
- `accounts_rls_user_can_view_own_account`
- `blueprint_lifecycle_create_and_add_member`

### 測試檔案結構

```sql
-- ============================================================================
-- Test: get_user_account_id.test.sql
-- Description: 測試 get_user_account_id() 函式
-- ============================================================================

-- Setup
\i helpers/setup.sql
\i helpers/mock-auth.sql

-- Test 1: 已認證使用者應返回正確的 account_id
DO $$
DECLARE
  v_result UUID;
  v_expected UUID := '550e8400-e29b-41d4-a716-446655440001';
BEGIN
  -- Arrange: 模擬使用者認證
  PERFORM mock_auth_uid('auth-user-id-1');
  
  -- Act: 執行函式
  SELECT get_user_account_id() INTO v_result;
  
  -- Assert: 驗證結果
  IF v_result != v_expected THEN
    RAISE EXCEPTION 'Test failed: Expected %, got %', v_expected, v_result;
  END IF;
  
  RAISE NOTICE 'PASS: get_user_account_id returns correct account_id';
END $$;

-- Test 2: 未認證使用者應返回 NULL
DO $$
DECLARE
  v_result UUID;
BEGIN
  -- Arrange: 清除認證
  PERFORM mock_auth_uid(NULL);
  
  -- Act
  SELECT get_user_account_id() INTO v_result;
  
  -- Assert
  IF v_result IS NOT NULL THEN
    RAISE EXCEPTION 'Test failed: Expected NULL, got %', v_result;
  END IF;
  
  RAISE NOTICE 'PASS: get_user_account_id returns NULL for unauthenticated user';
END $$;

-- Teardown
\i helpers/teardown.sql
```

### RLS 測試結構

```sql
-- ============================================================================
-- Test: accounts.rls.test.sql
-- Description: 測試 accounts 表的 RLS 政策
-- ============================================================================

\i helpers/setup.sql
\i helpers/mock-auth.sql

-- Test: User 可以查看自己的帳戶
DO $$
DECLARE
  v_count INT;
BEGIN
  -- Arrange: 以 user1 身份登入
  PERFORM mock_auth_uid('user1-auth-id');
  
  -- Act: 嘗試查詢
  SELECT COUNT(*) INTO v_count 
  FROM accounts 
  WHERE auth_user_id = 'user1-auth-id';
  
  -- Assert: 應該看到 1 筆
  PERFORM assert_equals(v_count, 1, 'User should see own account');
END $$;

-- Test: User 不能查看其他人的帳戶
DO $$
DECLARE
  v_count INT;
BEGIN
  -- Arrange: 以 user1 身份登入
  PERFORM mock_auth_uid('user1-auth-id');
  
  -- Act: 嘗試查詢其他使用者
  SELECT COUNT(*) INTO v_count 
  FROM accounts 
  WHERE auth_user_id = 'user2-auth-id';
  
  -- Assert: 應該看到 0 筆
  PERFORM assert_equals(v_count, 0, 'User should not see other accounts');
END $$;

\i helpers/teardown.sql
```

---

## 🔧 執行測試

### 使用 psql 執行

```bash
# 執行單一測試
psql $DATABASE_URL -f supabase/tests/unit/functions/get_user_account_id.test.sql

# 執行所有單元測試
for f in supabase/tests/unit/**/*.test.sql; do
  psql $DATABASE_URL -f "$f"
done

# 執行所有 RLS 測試
for f in supabase/tests/rls/*.test.sql; do
  psql $DATABASE_URL -f "$f"
done
```

### 使用 npm 腳本

```bash
# 在 package.json 中設定
npm run test:db           # 執行所有資料庫測試
npm run test:db:unit      # 僅執行單元測試
npm run test:db:rls       # 僅執行 RLS 測試
npm run test:db:integration # 僅執行整合測試
```

### CI/CD 整合

```yaml
# .github/workflows/test.yml
jobs:
  db-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: supabase db reset
      - run: npm run test:db
```

---

## 📊 測試覆蓋率目標

| 類型 | 目標 | 說明 |
|------|------|------|
| Helper Functions | 100% | 所有 helper function 都需測試 |
| Triggers | 100% | 所有觸發器都需測試 |
| RLS Policies | 100% | 每個政策至少 2 個測試案例 |
| Integration | 80%+ | 主要業務流程需覆蓋 |

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../docs/`](../docs/README.md) | 文件與指南 |
| [`../migrations/`](../migrations/README.md) | 資料庫遷移 |
| [`../policies/`](../policies/README.md) | RLS 政策 |
| [`../seeds/`](../seeds/README.md) | 種子資料 |

---

**最後更新**: 2025-11-29
