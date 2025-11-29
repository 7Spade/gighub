# 故障排除指南

本目錄包含 GigHub 專案的故障排除文檔，幫助開發團隊快速識別和解決常見問題。

## 目錄

### PostgreSQL / Supabase

| 文檔 | 說明 |
|------|------|
| [rls-42501-prevention-guide.md](./rls-42501-prevention-guide.md) | 42501 權限錯誤防範指南 |
| [postgresql-42501-analysis.md](./postgresql-42501-analysis.md) | 42501 錯誤詳細分析 |
| [rls-best-practices.md](./rls-best-practices.md) | RLS 最佳實踐 |

---

## 快速參考

### 常見錯誤代碼

| 錯誤碼 | 名稱 | 說明 | 參考文檔 |
|--------|------|------|----------|
| 42501 | INSUFFICIENT_PRIVILEGE | RLS 權限不足 | [rls-42501-prevention-guide.md](./rls-42501-prevention-guide.md) |
| PGRST116 | No rows returned | 查詢無結果 | 檢查 RLS SELECT 政策 |
| 23503 | FOREIGN_KEY_VIOLATION | 外鍵約束違反 | 檢查參照完整性 |
| 23505 | UNIQUE_VIOLATION | 唯一約束違反 | 檢查重複數據 |

### RLS 故障排除流程

```
1. 確認用戶身份
   SELECT auth.uid();
   SELECT get_user_account_id();

2. 檢查 RLS 政策
   SELECT * FROM pg_policies WHERE tablename = 'your_table';

3. 測試輔助函數
   SELECT is_blueprint_member('uuid');
   SELECT is_blueprint_admin('uuid');

4. 檢查觸發器
   SELECT * FROM information_schema.triggers 
   WHERE event_object_table = 'your_table';

5. 驗證數據
   SET ROLE service_role;  -- 繞過 RLS
   SELECT * FROM your_table;
```

---

## 問題回報

如果遇到未記錄的問題：

1. 收集完整錯誤信息（錯誤碼、消息、堆棧）
2. 記錄重現步驟
3. 在 GitHub Issues 中提交問題
4. 標記相關標籤：`bug`, `database`, `rls`

---

**最後更新**: 2025-11-29
