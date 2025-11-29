# Supabase RLS Policies

> 此資料夾保存 Supabase 的 Row Level Security (RLS) 與相關存取控制政策定義與範例。

---

## 📁 目錄結構

```
supabase/policies/
├── README.md                          # 本文件 - RLS 政策說明
├── templates/                         # 政策範本
│   ├── basic-crud.sql                 # 基本 CRUD 政策範本
│   ├── membership-based.sql           # 成員資格基礎政策範本
│   └── hierarchical.sql               # 階層式權限政策範本
├── core/                              # 核心表格政策
│   ├── accounts.policies.sql          # 帳戶表政策定義
│   ├── organization-members.policies.sql # 組織成員政策
│   ├── teams.policies.sql             # 團隊政策
│   └── team-members.policies.sql      # 團隊成員政策
├── blueprint/                         # 藍圖系統政策
│   ├── blueprints.policies.sql        # 藍圖表政策
│   └── blueprint-members.policies.sql # 藍圖成員政策
├── task/                              # 任務系統政策
│   ├── tasks.policies.sql             # 任務表政策
│   ├── task-attachments.policies.sql  # 任務附件政策
│   ├── checklists.policies.sql        # 檢查清單政策
│   └── task-acceptances.policies.sql  # 任務驗收政策
└── examples/                          # 範例與說明
    ├── avoid-recursion.md             # 避免 RLS 遞迴的範例
    └── security-definer-pattern.md    # SECURITY DEFINER 模式說明
```

---

## 📋 規劃檔案清單

### 政策範本 (`templates/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `basic-crud.sql` | 基本 SELECT/INSERT/UPDATE/DELETE 政策範本 | 待建立 |
| `membership-based.sql` | 基於成員資格的政策範本 | 待建立 |
| `hierarchical.sql` | 階層式權限（owner > admin > member）範本 | 待建立 |

### 核心表格政策 (`core/`)

| 檔案名稱 | 對應表格 | 政策數量 | 狀態 |
|---------|---------|---------|------|
| `accounts.policies.sql` | `accounts` | 3 (SELECT/INSERT/UPDATE) | 待建立 |
| `organization-members.policies.sql` | `organization_members` | 4 (CRUD) | 待建立 |
| `teams.policies.sql` | `teams` | 4 (CRUD) | 待建立 |
| `team-members.policies.sql` | `team_members` | 4 (CRUD) | 待建立 |

### 藍圖系統政策 (`blueprint/`)

| 檔案名稱 | 對應表格 | 政策數量 | 狀態 |
|---------|---------|---------|------|
| `blueprints.policies.sql` | `blueprints` | 4 (CRUD) | 待建立 |
| `blueprint-members.policies.sql` | `blueprint_members` | 4 (CRUD) | 待建立 |

### 任務系統政策 (`task/`)

| 檔案名稱 | 對應表格 | 政策數量 | 狀態 |
|---------|---------|---------|------|
| `tasks.policies.sql` | `tasks` | 4 (CRUD) | 待建立 |
| `task-attachments.policies.sql` | `task_attachments` | 3 (SELECT/INSERT/DELETE) | 待建立 |
| `checklists.policies.sql` | `checklists` | 4 (CRUD) | 待建立 |
| `task-acceptances.policies.sql` | `task_acceptances` | 4 (CRUD) | 待建立 |

### 範例與說明 (`examples/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `avoid-recursion.md` | 如何避免 RLS 政策的無限遞迴 | 待建立 |
| `security-definer-pattern.md` | SECURITY DEFINER 函式的使用模式 | 待建立 |

---

## 📝 RLS 政策設計原則

### 1. 避免 42501 權限錯誤（無限遞迴）

**問題**：RLS 政策中直接查詢受 RLS 保護的表會導致無限遞迴

```sql
-- ❌ 錯誤：會導致無限遞迴
CREATE POLICY "view_org_accounts" ON accounts
USING (
  id IN (SELECT account_id FROM organization_members WHERE organization_id = ...)
);
```

**解決方案**：使用 SECURITY DEFINER 函式

```sql
-- ✅ 正確：使用 helper function
CREATE POLICY "view_org_accounts" ON accounts
USING (
  public.is_org_member(id) = TRUE
);

-- Helper function 定義
CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET row_security = off  -- 關閉 RLS 避免遞迴
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = target_org_id
      AND auth_user_id = auth.uid()
  );
END;
$$;
```

### 2. 政策命名規範

```
<role>_<action>_<target>
```

| 組成 | 說明 | 範例 |
|------|------|------|
| role | 適用角色 | `users`, `members`, `admins`, `owners` |
| action | 操作類型 | `view`, `create`, `update`, `delete` |
| target | 目標物件 | `own_account`, `team_members`, `tasks` |

範例：
- `users_view_own_user_account`
- `blueprint_members_can_view`
- `blueprint_admins_update`

### 3. 分層權限設計

```
Owner (擁有者)
  └── 完全控制權
Admin (管理員)
  └── 管理成員、設定
Member (成員)
  └── 讀取、基本操作
Viewer (觀察者)
  └── 僅讀取
```

### 4. 軟刪除支援

所有 SELECT 政策應排除已刪除的記錄：

```sql
CREATE POLICY "..." ON table_name
FOR SELECT
USING (
  status != 'deleted'  -- 或 deleted_at IS NULL
  AND ...其他條件
);
```

---

## 🔧 常用 Helper Functions

| 函式名稱 | 用途 | 回傳值 |
|---------|------|--------|
| `get_user_account_id()` | 取得當前使用者的帳戶 ID | UUID |
| `is_org_member(org_id)` | 檢查是否為組織成員 | BOOLEAN |
| `is_org_admin(org_id)` | 檢查是否為組織管理員 | BOOLEAN |
| `is_team_member(team_id)` | 檢查是否為團隊成員 | BOOLEAN |
| `is_team_leader(team_id)` | 檢查是否為團隊領導 | BOOLEAN |
| `is_blueprint_member(blueprint_id)` | 檢查是否為藍圖成員 | BOOLEAN |
| `is_blueprint_admin(blueprint_id)` | 檢查是否為藍圖管理員 | BOOLEAN |
| `is_blueprint_owner(blueprint_id)` | 檢查是否為藍圖擁有者 | BOOLEAN |
| `can_access_task(task_id)` | 檢查是否可存取任務 | BOOLEAN |

---

## ⚠️ 安全注意事項

1. **政策為安全關鍵設定**：變更需經過審查
2. **不存放機密**：不在此處放置憑證或敏感資料
3. **測試驗證**：變更政策需提供測試案例
4. **透過 migration 部署**：生產政策變更應透過遷移檔案

---

## 📋 政策審查檢查清單

變更 RLS 政策時，請確認：

- [ ] 政策名稱遵循命名規範
- [ ] 不會導致 RLS 遞迴
- [ ] 使用 helper function 而非直接查詢受保護表
- [ ] 包含軟刪除條件檢查
- [ ] 已建立對應的測試案例
- [ ] 已在開發環境測試通過
- [ ] PR 說明包含權限影響評估

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../docs/`](../docs/README.md) | 文件與指南 |
| [`../migrations/`](../migrations/README.md) | 資料庫遷移（政策部署） |
| [`../tests/`](../tests/README.md) | 測試檔案 |

---

**最後更新**: 2025-11-29
