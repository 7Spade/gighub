# RLS 最佳實踐

## 原則

### 1. 默認拒絕 (Deny by Default)

```sql
-- 啟用 RLS 後，沒有政策 = 拒絕所有訪問
ALTER TABLE tablename ENABLE ROW LEVEL SECURITY;
```

### 2. 最小權限原則

- 每個政策只授予必要的最小權限
- 避免使用 `FOR ALL` 政策
- 分別定義 SELECT, INSERT, UPDATE, DELETE 政策

### 3. 使用輔助函數

```sql
-- 使用 SECURITY DEFINER 函數避免遞迴
CREATE OR REPLACE FUNCTION check_access(...)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$ ... $$;
```

### 4. 存儲直接引用

```sql
-- 在表中存儲 auth_user_id 避免跨表查詢
CREATE TABLE blueprint_members (
  auth_user_id UUID,  -- 直接存儲
  ...
);
```

### 5. 完整的政策覆蓋

每個啟用 RLS 的表應該有：
- SELECT 政策（或明確拒絕）
- INSERT 政策（帶 WITH CHECK）
- UPDATE 政策（USING + WITH CHECK）
- DELETE 政策（或禁止硬刪除）

### 6. 觸發器安全

```sql
-- 觸發器函數必須使用 SECURITY DEFINER
CREATE OR REPLACE FUNCTION trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$ ... $$;
```

## 反模式

### ❌ 直接查詢受保護的表

```sql
-- 錯誤：在 RLS 中直接查詢受保護的表
CREATE POLICY "..." ON tasks
USING (
  blueprint_id IN (SELECT blueprint_id FROM blueprint_members WHERE ...)
);
```

### ❌ 忽略 NULL 值

```sql
-- 錯誤：沒有處理 NULL 情況
CREATE POLICY "..." ON tasks
USING (created_by = get_user_account_id());  -- 如果函數返回 NULL，永遠為 false
```

### ❌ USING 和 WITH CHECK 不一致

```sql
-- 錯誤：UPDATE 後可能無法再次訪問
CREATE POLICY "..." ON tasks
FOR UPDATE
USING (status = 'active')
WITH CHECK (true);  -- 可以更新為任何狀態，但之後可能無法訪問
```

## 測試策略

1. **正向測試**：驗證授權用戶可以訪問
2. **負向測試**：驗證未授權用戶無法訪問
3. **邊界測試**：測試 NULL、空字符串、特殊字符
4. **性能測試**：確保 RLS 不會嚴重影響性能

---

**最後更新**: 2025-11-29
