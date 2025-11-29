# 🔐 Supabase RLS 政策指南

> Row Level Security 政策設計規範與最佳實踐

---

## 🎯 目的

提供 RLS 政策的設計原則、命名規範與參考範例，確保：
- 防止 42501 權限錯誤
- 避免 RLS 無限遞迴
- 維護資料安全與存取控制

---

## 📁 目錄結構與檔案清單

```
supabase/policies/
├── README.md                           # 本文件
│
├── templates/                          # 📋 政策範本
│   ├── basic_crud.sql                 # 基本 CRUD 政策範本
│   ├── member_access.sql              # 成員存取政策範本
│   └── admin_only.sql                 # 管理員專用政策範本
│
├── helpers/                            # 🔧 Helper Functions
│   ├── get_user_account_id.sql        # 取得用戶 account_id
│   ├── is_org_member.sql              # 檢查組織成員
│   ├── is_org_admin.sql               # 檢查組織管理員
│   ├── is_blueprint_member.sql        # 檢查藍圖成員
│   ├── is_blueprint_admin.sql         # 檢查藍圖管理員
│   └── is_blueprint_owner.sql         # 檢查藍圖擁有者
│
├── references/                         # 📚 參考文件
│   ├── permission_matrix.md           # 權限矩陣
│   ├── role_definitions.md            # 角色定義
│   └── policy_naming.md               # 命名規範
│
└── examples/                           # 💡 範例
    ├── accounts_policies.sql          # Accounts 表政策範例
    ├── blueprints_policies.sql        # Blueprints 表政策範例
    └── tasks_policies.sql             # Tasks 表政策範例
```

---

## 📋 政策命名規範

### 命名格式

```
{主體}_{操作}_{對象}
```

### 範例

| 政策名稱 | 說明 |
|----------|------|
| `users_view_own_account` | 用戶查看自己的帳戶 |
| `org_admins_update_members` | 組織管理員更新成員 |
| `blueprint_members_view_tasks` | 藍圖成員查看任務 |
| `authenticated_create_blueprints` | 已認證用戶建立藍圖 |

### 命名規則

1. **主體** (WHO)：執行操作的角色
   - `users` - 一般用戶
   - `authenticated` - 已認證用戶
   - `org_members` - 組織成員
   - `org_admins` - 組織管理員
   - `blueprint_members` - 藍圖成員
   - `blueprint_admins` - 藍圖管理員
   - `blueprint_owners` - 藍圖擁有者

2. **操作** (ACTION)：執行的動作
   - `view` / `select` - 查詢
   - `create` / `insert` - 新增
   - `update` - 更新
   - `delete` - 刪除
   - `manage` - 完整 CRUD

3. **對象** (WHAT)：操作的目標
   - `own_*` - 自己的資料
   - `org_*` - 組織的資料
   - `blueprint_*` - 藍圖的資料

---

## 🔧 Helper Functions 設計

### 設計原則

為避免 42501 權限錯誤，所有 Helper Functions 必須：

1. **使用 SECURITY DEFINER**：以函數擁有者權限執行
2. **設定 row_security = off**：避免觸發 RLS 遞迴
3. **設定 search_path**：防止 schema 注入
4. **只回傳必要資訊**：僅回傳布林值或 UUID

### 標準模板

```sql
CREATE OR REPLACE FUNCTION public.{function_name}({parameters})
RETURNS {return_type}
LANGUAGE plpgsql
STABLE                          -- 函數不修改資料庫
SECURITY DEFINER                -- 使用函數擁有者權限
SET search_path = public        -- 固定 search_path
SET row_security = off          -- 停用 RLS（關鍵！）
AS $$
DECLARE
  -- 變數宣告
BEGIN
  -- 函數邏輯
  RETURN ...;
END;
$$;

-- 權限設定
GRANT EXECUTE ON FUNCTION public.{function_name}({param_types}) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.{function_name}({param_types}) FROM anon;
REVOKE EXECUTE ON FUNCTION public.{function_name}({param_types}) FROM public;
```

### 核心 Helper Functions

#### 1. get_user_account_id()

```sql
-- 取得當前用戶的 account_id
CREATE OR REPLACE FUNCTION public.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_account_id UUID;
BEGIN
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE auth_user_id = auth.uid()
    AND type = 'User'
    AND status != 'deleted'
  LIMIT 1;
  
  RETURN v_account_id;
END;
$$;
```

#### 2. is_org_member(org_id)

```sql
-- 檢查是否為組織成員
CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
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

#### 3. is_blueprint_member(bp_id)

```sql
-- 檢查是否為藍圖成員
CREATE OR REPLACE FUNCTION public.is_blueprint_member(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()
  );
END;
$$;
```

---

## 📊 權限矩陣

### 帳戶與組織層級

| 操作 | User (自己) | Org Member | Org Admin | Org Owner |
|------|:-----------:|:----------:|:---------:|:---------:|
| 查看自己的帳戶 | ✅ | - | - | - |
| 更新自己的帳戶 | ✅ | - | - | - |
| 查看組織帳戶 | - | ✅ | ✅ | ✅ |
| 更新組織設定 | - | ❌ | ✅ | ✅ |
| 刪除組織 | - | ❌ | ❌ | ✅ |
| 查看組織成員 | - | ✅ | ✅ | ✅ |
| 新增組織成員 | - | ❌ | ✅ | ✅ |
| 移除組織成員 | - | ❌ | ✅ | ✅ |

### 藍圖層級

| 操作 | Member | Admin | Owner |
|------|:------:|:-----:|:-----:|
| 查看藍圖 | ✅ | ✅ | ✅ |
| 更新藍圖設定 | ❌ | ✅ | ✅ |
| 刪除藍圖 | ❌ | ❌ | ✅ |
| 查看成員 | ✅ | ✅ | ✅ |
| 新增成員 | ❌ | ✅ | ✅ |
| 變更成員角色 | ❌ | ✅ | ✅ |
| 移除成員 | ❌ | ✅ | ✅ |
| 查看任務 | ✅ | ✅ | ✅ |
| 建立任務 | ✅ | ✅ | ✅ |
| 更新任務 | ✅ | ✅ | ✅ |
| 刪除任務 | ❌ | ✅ | ✅ |

---

## 🚨 42501 錯誤避免指南

### 問題根源

```
42501 insufficient_privilege
```

此錯誤通常發生於 RLS 政策形成無限遞迴：

```sql
-- ❌ 錯誤範例：RLS 政策直接查詢受保護的表
CREATE POLICY "..." ON accounts
USING (
  id IN (
    SELECT account_id FROM organization_members  -- 此表也有 RLS！
    WHERE organization_id = ...
  )
);
```

### 解決方案

```sql
-- ✅ 正確做法：使用 Helper Function
CREATE POLICY "..." ON accounts
USING (public.is_org_member(id));  -- Helper 繞過 RLS
```

### 檢查清單

在建立新政策前，確認：

1. [ ] 政策 USING/WITH CHECK 中沒有直接查詢受 RLS 保護的表
2. [ ] 所有跨表查詢都使用 Helper Function
3. [ ] Helper Function 設定了 `SECURITY DEFINER` 和 `row_security = off`
4. [ ] 在開發環境測試了各種用戶角色

---

## 📄 政策範本

### 基本 CRUD 政策

```sql
-- =============================================================================
-- Table: {table_name}
-- =============================================================================

ALTER TABLE public.{table_name} ENABLE ROW LEVEL SECURITY;

-- SELECT: 誰可以查看
CREATE POLICY "{role}_view_{table}" ON public.{table_name}
FOR SELECT TO authenticated
USING (
  -- 條件
);

-- INSERT: 誰可以新增
CREATE POLICY "{role}_create_{table}" ON public.{table_name}
FOR INSERT TO authenticated
WITH CHECK (
  -- 條件
);

-- UPDATE: 誰可以更新
CREATE POLICY "{role}_update_{table}" ON public.{table_name}
FOR UPDATE TO authenticated
USING (
  -- USING: 可以更新哪些列
)
WITH CHECK (
  -- WITH CHECK: 更新後的值必須符合
);

-- DELETE: 誰可以刪除
CREATE POLICY "{role}_delete_{table}" ON public.{table_name}
FOR DELETE TO authenticated
USING (
  -- 條件
);
```

### 藍圖成員存取政策

```sql
-- =============================================================================
-- Table: {table_name} (藍圖關聯表)
-- =============================================================================

-- SELECT: 藍圖成員可查看
CREATE POLICY "blueprint_members_view_{table}" ON public.{table_name}
FOR SELECT TO authenticated
USING (
  public.is_blueprint_member(blueprint_id)
);

-- INSERT: 藍圖成員可新增
CREATE POLICY "blueprint_members_create_{table}" ON public.{table_name}
FOR INSERT TO authenticated
WITH CHECK (
  public.is_blueprint_member(blueprint_id)
);

-- UPDATE: 藍圖成員可更新
CREATE POLICY "blueprint_members_update_{table}" ON public.{table_name}
FOR UPDATE TO authenticated
USING (public.is_blueprint_member(blueprint_id))
WITH CHECK (public.is_blueprint_member(blueprint_id));

-- DELETE: 僅藍圖管理員可刪除
CREATE POLICY "blueprint_admins_delete_{table}" ON public.{table_name}
FOR DELETE TO authenticated
USING (
  public.is_blueprint_admin(blueprint_id)
);
```

---

## 🧪 政策測試

### 測試腳本範例

```sql
-- 測試政策是否正確運作
BEGIN;

-- 設定測試用戶 context
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub": "test-user-id"}';

-- 測試 SELECT 政策
SELECT lives_ok(
  'SELECT * FROM blueprints WHERE id = ''test-blueprint-id''',
  'Member should be able to view blueprint'
);

-- 測試 INSERT 政策
SELECT throws_ok(
  'INSERT INTO blueprints (name) VALUES (''test'')',
  '42501',
  'Non-member should not be able to create blueprint'
);

ROLLBACK;
```

---

## 📚 參考資源

- [Supabase RLS 文件](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS 文件](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [GigHub Supabase 實踐指南](../../.github/instructions/gighub-supabase-practices.instructions.md)

---

**最後更新**: 2025-11-29  
**維護者**: 開發團隊
