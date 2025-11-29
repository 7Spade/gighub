# PostgreSQL 42501 錯誤防範指南

本文檔提供完整的 PostgreSQL 42501 (權限拒絕) 錯誤防範策略，特別針對 Supabase RLS 政策設計。

## 目錄

1. [42501 錯誤概述](#42501-錯誤概述)
2. [常見原因](#常見原因)
3. [核心解決模式](#核心解決模式)
4. [最佳實踐](#最佳實踐)
5. [檢查清單](#檢查清單)
6. [範例程式碼](#範例程式碼)
7. [故障排除流程](#故障排除流程)

---

## 42501 錯誤概述

### 錯誤代碼說明

| 錯誤碼 | 名稱 | 說明 |
|--------|------|------|
| 42501 | INSUFFICIENT_PRIVILEGE | 權限不足，無法執行請求的操作 |

### 在 Supabase 中的表現

```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"tablename\"",
  "details": null,
  "hint": null
}
```

### 常見觸發場景

1. **INSERT 操作被拒** - 新行不符合 RLS INSERT 政策
2. **UPDATE 操作被拒** - 現有行或更新後的行不符合 RLS 政策
3. **DELETE 操作被拒** - 行不符合 RLS DELETE 政策
4. **SELECT 返回空** - 雖然數據存在，但 RLS 過濾了結果

---

## 常見原因

### 1. RLS 無限遞迴 (Infinite Recursion)

```sql
-- ❌ 錯誤示例：在 RLS 中查詢自身受保護的表
CREATE POLICY "members_view" ON accounts
FOR SELECT USING (
  id IN (SELECT account_id FROM organization_members WHERE ...)  -- ← 如果 organization_members 也有 RLS，可能導致遞迴
);
```

### 2. 缺少 SECURITY DEFINER 函數

```sql
-- ❌ 錯誤示例：直接在 RLS 中查詢受保護的表
CREATE POLICY "..." ON tasks
USING (
  blueprint_id IN (
    SELECT blueprint_id FROM blueprint_members  -- ← 觸發 blueprint_members 的 RLS
    WHERE account_id = get_user_account_id()
  )
);
```

### 3. WITH CHECK 條件不一致

```sql
-- ❌ 錯誤示例：USING 和 WITH CHECK 不一致
CREATE POLICY "..." ON tasks
FOR UPDATE
USING (created_by = get_user_account_id())
WITH CHECK (status != 'deleted');  -- ← 即使符合 USING，也可能因 WITH CHECK 失敗
```

### 4. auth.uid() 為 NULL

```sql
-- ❌ 問題：匿名用戶嘗試操作
CREATE POLICY "..." ON tasks
FOR INSERT WITH CHECK (
  created_by = get_user_account_id()  -- ← 如果用戶未登入，返回 NULL，條件永遠為 false
);
```

### 5. 觸發器與 RLS 衝突

```sql
-- ❌ 觸發器可能插入用戶無權訪問的數據
CREATE TRIGGER auto_add_member
AFTER INSERT ON blueprints
FOR EACH ROW
EXECUTE FUNCTION add_blueprint_creator_as_owner();  -- ← 如果函數沒有 SECURITY DEFINER，可能被 RLS 阻擋
```

---

## 核心解決模式

### 模式 1：SECURITY DEFINER 輔助函數

**原則**: 使用 `SECURITY DEFINER` 函數繞過 RLS 檢查，打破遞迴鏈。

```sql
-- ✅ 正確示例：創建 SECURITY DEFINER 函數
CREATE OR REPLACE FUNCTION public.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER            -- ← 以函數所有者權限執行
SET row_security = off      -- ← 禁用 RLS 檢查
STABLE
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

-- 授權給認證用戶
GRANT EXECUTE ON FUNCTION public.get_user_account_id() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_account_id() FROM anon, public;
```

### 模式 2：成員資格檢查函數

```sql
-- ✅ 檢查藍圖成員資格
CREATE OR REPLACE FUNCTION public.is_blueprint_member(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()  -- ← 使用 auth_user_id 而非 account_id
  );
END;
$$;
```

### 模式 3：在表中存儲 auth_user_id

**原則**: 在需要 RLS 檢查的表中添加 `auth_user_id` 列，避免跨表查詢。

```sql
-- ✅ 表設計：包含 auth_user_id 列
CREATE TABLE blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id),
  account_id UUID REFERENCES accounts(id),
  auth_user_id UUID,           -- ← 直接存儲 auth.uid()
  role TEXT NOT NULL,
  -- ...
);

-- RLS 可以直接檢查 auth_user_id
CREATE POLICY "..." ON blueprint_members
FOR SELECT USING (
  auth_user_id = auth.uid()    -- ← 無需跨表查詢
);
```

### 模式 4：觸發器使用 SECURITY DEFINER

```sql
-- ✅ 觸發器函數使用 SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.add_blueprint_creator_as_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER              -- ← 重要！避免被 RLS 阻擋
SET row_security = off
AS $$
BEGIN
  INSERT INTO public.blueprint_members (
    blueprint_id,
    account_id,
    auth_user_id,
    role
  ) VALUES (
    NEW.id,
    get_user_account_id(),
    auth.uid(),
    'owner'
  );
  RETURN NEW;
END;
$$;
```

---

## 最佳實踐

### 1. 建表時立即啟用 RLS

```sql
-- ✅ 建表後立即啟用 RLS
CREATE TABLE tasks (...);
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 創建至少一個政策
CREATE POLICY "default_deny" ON tasks
FOR ALL USING (false);  -- 默認拒絕所有操作
```

### 2. 使用層級化權限檢查

```
用戶認證 (auth.uid())
    │
    ▼
帳戶系統 (get_user_account_id())
    │
    ▼
藍圖成員 (is_blueprint_member())
    │
    ▼
任務訪問 (can_access_task())
```

### 3. 分離 USING 和 WITH CHECK 邏輯

```sql
-- ✅ USING: 讀取前檢查
-- ✅ WITH CHECK: 寫入後驗證
CREATE POLICY "tasks_update" ON tasks
FOR UPDATE
USING (
  deleted_at IS NULL
  AND is_blueprint_member(blueprint_id)  -- 可以更新哪些行
)
WITH CHECK (
  is_blueprint_member(blueprint_id)       -- 更新後的行仍然有效
);
```

### 4. 處理 NULL 值

```sql
-- ✅ 安全處理可能為 NULL 的情況
CREATE POLICY "..." ON tasks
FOR INSERT WITH CHECK (
  blueprint_id IS NOT NULL
  AND COALESCE(is_blueprint_member(blueprint_id), false)
);
```

### 5. 使用 EXISTS 替代 IN

```sql
-- ✅ EXISTS 通常比 IN 更高效
CREATE POLICY "..." ON tasks
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = tasks.blueprint_id
      AND auth_user_id = auth.uid()
  )
);
```

---

## 檢查清單

### 新建表時

- [ ] 表已啟用 RLS (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`)
- [ ] 至少有一個 SELECT 政策
- [ ] INSERT 政策有 WITH CHECK 子句
- [ ] UPDATE 政策有 USING 和 WITH CHECK
- [ ] DELETE 政策有 USING 子句
- [ ] 所有政策都有註釋說明

### 創建 RLS 政策時

- [ ] 政策不會導致無限遞迴
- [ ] 使用 SECURITY DEFINER 函數處理跨表檢查
- [ ] 處理了 NULL 值情況
- [ ] 已測試匿名用戶場景
- [ ] 已測試新用戶（無帳戶）場景

### 創建觸發器時

- [ ] 觸發器函數使用 SECURITY DEFINER
- [ ] 觸發器函數設置 `SET row_security = off`
- [ ] 觸發器函數有明確的 search_path

### 部署前

- [ ] 在開發環境測試所有 CRUD 操作
- [ ] 測試不同角色的權限
- [ ] 檢查觸發器與 RLS 的交互
- [ ] 驗證錯誤消息對用戶友好

---

## 範例程式碼

### 完整的藍圖 RLS 設置

```sql
-- 1. 創建輔助函數
CREATE OR REPLACE FUNCTION public.is_blueprint_member(target_blueprint_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER SET row_security = off
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blueprint_members
    WHERE blueprint_id = target_blueprint_id
      AND auth_user_id = auth.uid()
  );
END;
$$;

-- 2. 啟用 RLS
ALTER TABLE blueprints ENABLE ROW LEVEL SECURITY;

-- 3. SELECT 政策
CREATE POLICY "blueprint_members_can_view" ON blueprints
FOR SELECT TO authenticated
USING (
  status != 'deleted'
  AND (
    is_blueprint_member(id)
    OR visibility = 'public'
  )
);

-- 4. INSERT 政策
CREATE POLICY "authenticated_users_create_blueprints" ON blueprints
FOR INSERT TO authenticated
WITH CHECK (
  status != 'deleted'
  AND get_user_account_id() IS NOT NULL
);

-- 5. UPDATE 政策
CREATE POLICY "blueprint_admins_update" ON blueprints
FOR UPDATE TO authenticated
USING (status != 'deleted' AND is_blueprint_admin(id))
WITH CHECK (status != 'deleted' AND is_blueprint_admin(id));

-- 6. 自動添加創建者為擁有者
CREATE OR REPLACE FUNCTION add_blueprint_creator_as_owner()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET row_security = off
AS $$
BEGIN
  INSERT INTO blueprint_members (blueprint_id, account_id, auth_user_id, role)
  VALUES (NEW.id, get_user_account_id(), auth.uid(), 'owner');
  RETURN NEW;
END;
$$;

CREATE TRIGGER add_blueprint_creator_trigger
AFTER INSERT ON blueprints FOR EACH ROW
EXECUTE FUNCTION add_blueprint_creator_as_owner();
```

---

## 故障排除流程

### 遇到 42501 錯誤時

```
1. 確認錯誤來源
   ├── 是哪個表？
   ├── 是什麼操作（SELECT/INSERT/UPDATE/DELETE）？
   └── 當前用戶是誰？(auth.uid())

2. 檢查 RLS 政策
   SELECT * FROM pg_policies WHERE tablename = 'your_table';

3. 測試政策條件
   SELECT is_blueprint_member('blueprint-id');
   SELECT get_user_account_id();

4. 檢查輔助函數
   \df+ is_blueprint_member
   \df+ get_user_account_id

5. 模擬執行
   SET ROLE authenticated;
   SET request.jwt.claim.sub = 'user-uuid';
   SELECT * FROM your_table;

6. 檢查觸發器
   SELECT * FROM information_schema.triggers 
   WHERE event_object_table = 'your_table';
```

### 常見修復方法

| 問題 | 解決方案 |
|------|----------|
| 遞迴 RLS | 創建 SECURITY DEFINER 函數 |
| 觸發器被阻擋 | 觸發器函數添加 SECURITY DEFINER |
| NULL 值問題 | 使用 COALESCE 或 IS NOT NULL 檢查 |
| 政策條件不一致 | 確保 USING 和 WITH CHECK 邏輯一致 |

---

## 相關文檔

- [postgresql-42501-analysis.md](./postgresql-42501-analysis.md) - 詳細分析文檔
- [rls-best-practices.md](./rls-best-practices.md) - RLS 最佳實踐
- [Supabase RLS 官方文檔](https://supabase.com/docs/guides/auth/row-level-security)

---

**最後更新**: 2025-11-29
**維護者**: GigHub 開發團隊
