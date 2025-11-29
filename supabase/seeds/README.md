# 🌱 Supabase Seeds 種子資料指南

> 開發/測試環境的初始種子資料規範與執行說明

---

## 🎯 目的

提供可重複執行、具冪等性的種子資料，用於：
- 本地開發環境初始化
- 測試環境資料準備
- Demo 環境範例資料

---

## 📁 目錄結構與檔案清單

```
supabase/seeds/
├── README.md                    # 本文件
│
├── 00-reference.sql             # 🔢 參考資料/列舉值
│   └── 角色定義、狀態列舉、系統常數
│
├── 10-auth.sql                  # 👤 認證相關資料
│   └── 測試用戶、Auth 設定
│
├── 20-blueprints.sql            # 📐 藍圖資料
│   └── 範例藍圖、藍圖成員
│
├── 21-tasks.sql                 # 📋 任務資料
│   └── 範例任務、子任務、附件
│
├── 22-diary.sql                 # 📝 施工日誌
│   └── 範例日誌記錄
│
├── 23-todo.sql                  # ✅ 待辦事項
│   └── 範例待辦清單
│
└── 30-fixtures.sql              # 🔧 開發固定資料
    └── Mock 資料、測試場景
```

---

## 📋 檔案命名規範

### 命名格式

```
{序號}-{類別}.sql
```

### 序號規則

| 序號範圍 | 類別 | 說明 |
|----------|------|------|
| `00-09` | 參考/列舉 | 角色、狀態、系統常數 |
| `10-19` | 認證/用戶 | Auth 用戶、帳戶資料 |
| `20-29` | 核心業務 | 藍圖、任務、日誌等主要實體 |
| `30-39` | 固定資料 | Mock 資料、測試場景 |
| `90-99` | 清理腳本 | 資料清理（選用） |

### 為何使用序號？

1. **依賴順序**：確保外鍵依賴的表先有資料
2. **可預測性**：明確的執行順序
3. **模組化**：易於選擇性執行特定種子

---

## 📄 檔案內容規範

### 00-reference.sql - 參考資料

```sql
-- =============================================================================
-- Seeds: Reference Data
-- Description: 角色定義、狀態列舉、系統常數
-- Dependencies: None
-- =============================================================================

-- 此檔案用於建立參考資料
-- 若使用 PostgreSQL ENUM，則此檔案可能為空
-- 或用於插入 lookup tables 的資料

-- 範例：系統角色表（如果使用 lookup table 而非 ENUM）
-- INSERT INTO system_roles (code, name, description) VALUES
--   ('owner', '擁有者', '最高權限'),
--   ('admin', '管理員', '管理權限'),
--   ('member', '成員', '一般權限'),
--   ('viewer', '觀察者', '唯讀權限')
-- ON CONFLICT (code) DO NOTHING;
```

### 10-auth.sql - 認證資料

```sql
-- =============================================================================
-- Seeds: Auth & Accounts
-- Description: 測試用戶與帳戶資料
-- Dependencies: 00-reference.sql
-- =============================================================================

-- ⚠️ 重要：此檔案僅用於開發/測試環境
-- 生產環境不應執行此檔案

-- 測試用戶 1: 一般用戶
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at) VALUES
  ('user-001', 'dev1@example.com', crypt('password123', gen_salt('bf')), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.accounts (id, auth_user_id, type, name, email, status) VALUES
  ('account-001', 'user-001', 'User', '開發者小明', 'dev1@example.com', 'active')
ON CONFLICT (id) DO NOTHING;

-- 測試用戶 2: 組織管理員
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at) VALUES
  ('user-002', 'admin@example.com', crypt('password123', gen_salt('bf')), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.accounts (id, auth_user_id, type, name, email, status) VALUES
  ('account-002', 'user-002', 'User', '管理員小華', 'admin@example.com', 'active')
ON CONFLICT (id) DO NOTHING;

-- 測試組織
INSERT INTO public.accounts (id, type, name, email, status) VALUES
  ('org-001', 'Organization', '範例建設公司', 'org@example.com', 'active')
ON CONFLICT (id) DO NOTHING;

-- 組織成員關係
INSERT INTO public.organization_members (organization_id, account_id, role, auth_user_id) VALUES
  ('org-001', 'account-002', 'owner', 'user-002')
ON CONFLICT (organization_id, account_id) DO NOTHING;
```

### 20-blueprints.sql - 藍圖資料

```sql
-- =============================================================================
-- Seeds: Blueprints
-- Description: 範例藍圖與藍圖成員
-- Dependencies: 10-auth.sql
-- =============================================================================

-- 範例藍圖 1: 私人專案
INSERT INTO public.blueprints (id, name, description, visibility, status, created_by) VALUES
  ('blueprint-001', '台北101大樓維修專案', '大樓外牆維修工程', 'private', 'active', 'account-001')
ON CONFLICT (id) DO NOTHING;

-- 藍圖成員
INSERT INTO public.blueprint_members (blueprint_id, account_id, auth_user_id, role, invited_by) VALUES
  ('blueprint-001', 'account-001', 'user-001', 'owner', 'account-001'),
  ('blueprint-001', 'account-002', 'user-002', 'admin', 'account-001')
ON CONFLICT (blueprint_id, account_id) DO NOTHING;

-- 範例藍圖 2: 公開專案
INSERT INTO public.blueprints (id, name, description, visibility, status, created_by) VALUES
  ('blueprint-002', '社區公園整建', '社區公園景觀改造工程', 'public', 'active', 'account-002')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.blueprint_members (blueprint_id, account_id, auth_user_id, role, invited_by) VALUES
  ('blueprint-002', 'account-002', 'user-002', 'owner', 'account-002')
ON CONFLICT (blueprint_id, account_id) DO NOTHING;
```

### 21-tasks.sql - 任務資料

```sql
-- =============================================================================
-- Seeds: Tasks
-- Description: 範例任務資料
-- Dependencies: 20-blueprints.sql
-- =============================================================================

-- 藍圖 1 的任務
INSERT INTO public.tasks (id, blueprint_id, title, description, status, priority, created_by) VALUES
  ('task-001', 'blueprint-001', '外牆清洗', '高壓水柱清洗外牆', 'in_progress', 'high', 'account-001'),
  ('task-002', 'blueprint-001', '防水塗料施作', '塗刷防水漆', 'pending', 'medium', 'account-001'),
  ('task-003', 'blueprint-001', '品質驗收', '完工品質檢查', 'pending', 'high', 'account-001')
ON CONFLICT (id) DO NOTHING;

-- 藍圖 2 的任務
INSERT INTO public.tasks (id, blueprint_id, title, description, status, priority, created_by) VALUES
  ('task-004', 'blueprint-002', '草皮整理', '修剪草坪與施肥', 'completed', 'low', 'account-002'),
  ('task-005', 'blueprint-002', '步道鋪設', '新增碎石步道', 'in_progress', 'medium', 'account-002')
ON CONFLICT (id) DO NOTHING;
```

### 22-diary.sql - 施工日誌

```sql
-- =============================================================================
-- Seeds: Diary Entries
-- Description: 範例施工日誌
-- Dependencies: 20-blueprints.sql
-- =============================================================================

-- 施工日誌範例（依實際表結構調整）
-- INSERT INTO public.diary_entries (...) VALUES (...)
-- ON CONFLICT (...) DO NOTHING;
```

### 23-todo.sql - 待辦事項

```sql
-- =============================================================================
-- Seeds: Todo Items
-- Description: 範例待辦事項
-- Dependencies: 10-auth.sql
-- =============================================================================

-- 待辦事項範例（依實際表結構調整）
-- INSERT INTO public.todos (...) VALUES (...)
-- ON CONFLICT (...) DO NOTHING;
```

### 30-fixtures.sql - 開發固定資料

```sql
-- =============================================================================
-- Seeds: Development Fixtures
-- Description: 開發環境專用的 Mock 資料與測試場景
-- Dependencies: 21-tasks.sql
-- =============================================================================

-- ⚠️ 此檔案僅用於開發環境
-- 包含大量測試用假資料

-- 批量產生測試任務
-- DO $$
-- DECLARE
--   i INTEGER;
-- BEGIN
--   FOR i IN 1..100 LOOP
--     INSERT INTO public.tasks (blueprint_id, title, status, priority, created_by)
--     VALUES ('blueprint-001', '測試任務 ' || i, 'pending', 'medium', 'account-001')
--     ON CONFLICT DO NOTHING;
--   END LOOP;
-- END $$;
```

---

## 🏃 執行方式

### 使用 Supabase CLI

```bash
# 重置資料庫並執行所有 seeds
pnpm supabase:reset

# 僅執行 seeds（不重置）
supabase db seed
```

### 手動執行特定 seed

```bash
# 執行單一 seed 檔
psql -h localhost -p 54322 -U postgres -d postgres \
  -f supabase/seeds/10-auth.sql
```

### config.toml 配置

```toml
[db.seed]
enabled = true
sql_paths = [
  "./seeds/00-reference.sql",
  "./seeds/10-auth.sql",
  "./seeds/20-blueprints.sql",
  "./seeds/21-tasks.sql",
  "./seeds/22-diary.sql",
  "./seeds/23-todo.sql",
  "./seeds/30-fixtures.sql"
]
```

---

## ✅ 最佳實踐

### 1. 冪等性 (Idempotency)

所有 seed 必須可重複執行：

```sql
-- ✅ 使用 ON CONFLICT
INSERT INTO accounts (...) VALUES (...)
ON CONFLICT (id) DO NOTHING;

-- ✅ 使用 INSERT ... SELECT ... WHERE NOT EXISTS
INSERT INTO accounts (...)
SELECT ... WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE id = ...);

-- ❌ 避免無條件 INSERT
INSERT INTO accounts (...) VALUES (...);
```

### 2. 使用固定 UUID

開發/測試資料使用可預測的 UUID：

```sql
-- ✅ 使用有意義的固定 ID
INSERT INTO accounts (id, ...) VALUES
  ('11111111-1111-1111-1111-000000000001', ...);

-- ❌ 避免隨機 UUID（難以在測試中引用）
INSERT INTO accounts (id, ...) VALUES
  (gen_random_uuid(), ...);
```

### 3. 安全注意事項

```sql
-- ⚠️ 永遠不要在 seeds 中包含：
-- - 真實用戶資料
-- - 生產環境密碼
-- - API Keys 或 Secrets
-- - 敏感個資

-- ✅ 使用明確的測試資料標記
INSERT INTO accounts (name, email) VALUES
  ('測試用戶 [DEV]', 'test-dev@example.com');
```

### 4. 環境區分

```sql
-- 在 seed 開頭加入環境檢查（選用）
DO $$
BEGIN
  IF current_setting('app.environment', true) = 'production' THEN
    RAISE EXCEPTION 'Seeds should not run in production!';
  END IF;
END $$;
```

---

## 🔧 疑難排解

### 常見錯誤

| 錯誤 | 原因 | 解決方案 |
|------|------|----------|
| `23505` unique_violation | 資料已存在 | 使用 `ON CONFLICT` |
| `23503` foreign_key_violation | 依賴資料不存在 | 檢查 seed 執行順序 |
| `42501` insufficient_privilege | RLS 阻擋 | 使用 service_role 執行 |

### 除錯技巧

```bash
# 以 service_role 執行 seed（繞過 RLS）
PGPASSWORD=service_role_secret psql \
  -h localhost -p 54322 \
  -U service_role \
  -d postgres \
  -f supabase/seeds/10-auth.sql
```

---

## 📚 參考資源

- [Supabase Seeds 文件](https://supabase.com/docs/guides/cli/seeding-your-database)
- [PostgreSQL ON CONFLICT](https://www.postgresql.org/docs/current/sql-insert.html#SQL-ON-CONFLICT)

---

**最後更新**: 2025-11-29  
**維護者**: 開發團隊
