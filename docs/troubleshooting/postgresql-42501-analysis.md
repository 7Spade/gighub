# PostgreSQL 42501 錯誤詳細分析

## 概述

PostgreSQL 錯誤代碼 42501 (INSUFFICIENT_PRIVILEGE) 表示當前用戶沒有足夠的權限執行請求的操作。在 Supabase 環境中，這通常與行級安全 (RLS) 政策相關。

## 錯誤分類

### 類型 1：INSERT 權限不足

**症狀**：
```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"tablename\""
}
```

**原因**：
- 缺少 INSERT 政策
- INSERT 政策的 WITH CHECK 條件不滿足
- 觸發器嘗試插入受保護的表

**解決方案**：
1. 檢查是否存在 INSERT 政策
2. 驗證 WITH CHECK 條件
3. 確保觸發器函數使用 SECURITY DEFINER

### 類型 2：UPDATE 權限不足

**症狀**：
```json
{
  "code": "42501", 
  "message": "new row violates row-level security policy (USING expression)"
}
```

**原因**：
- 現有行不符合 USING 條件
- 更新後的行不符合 WITH CHECK 條件

**解決方案**：
1. 分別檢查 USING 和 WITH CHECK
2. 確保兩者邏輯一致

### 類型 3：DELETE 權限不足

**症狀**：
```json
{
  "code": "42501",
  "message": "permission denied for table tablename"
}
```

**原因**：
- 缺少 DELETE 政策
- DELETE USING 條件不滿足

### 類型 4：RLS 遞迴

**症狀**：
- 查詢超時
- 堆棧溢出錯誤

**原因**：
- RLS 政策中的子查詢觸發其他表的 RLS 檢查
- 形成循環依賴

**解決方案**：
- 使用 SECURITY DEFINER 函數打破遞迴鏈

## 診斷工具

### 查看表的 RLS 狀態

```sql
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'your_table';
```

### 查看 RLS 政策

```sql
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'your_table';
```

### 測試 SECURITY DEFINER 函數

```sql
-- 檢查函數屬性
SELECT 
  proname,
  prosecdef,
  proconfig
FROM pg_proc
WHERE proname = 'your_function';
```

## 預防措施

參見 [rls-42501-prevention-guide.md](./rls-42501-prevention-guide.md)

---

**最後更新**: 2025-11-29
