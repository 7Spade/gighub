# Supabase Seeds

> 此資料夾存放用於開發/測試環境的初始種子資料（seed data），包含測試用的使用者、範例資料與測試表格內容。

---

## 📁 目錄結構

```
supabase/seeds/
├── README.md                          # 本文件 - Seeds 說明
│
├── # ===== 依序載入的種子檔案 =====
├── 00-reference.sql                   # 參考資料：列舉值、角色定義
├── 10-auth.sql                        # 認證資料：測試使用者帳戶
├── 20-blueprints.sql                  # 藍圖資料：測試藍圖與成員
├── 21-tasks.sql                       # 任務資料：測試任務與附件
├── 22-diary.sql                       # 日誌資料：施工日誌範例
├── 23-todo.sql                        # 待辦資料：待辦事項範例
├── 30-fixtures.sql                    # 開發用假資料與測試情境
│
└── utils/                             # 種子工具
    ├── reset-sequences.sql            # 重設序列計數器
    └── cleanup.sql                    # 清理測試資料
```

---

## 📋 規劃檔案清單

### 主要種子檔案

| 檔案名稱 | 說明 | 載入順序 | 狀態 |
|---------|------|---------|------|
| `00-reference.sql` | 參考/查找資料（列舉、角色、狀態定義） | 1 | 待建立 |
| `10-auth.sql` | 測試使用者與認證資料 | 2 | 待建立 |
| `20-blueprints.sql` | 藍圖、藍圖成員範例資料 | 3 | 待建立 |
| `21-tasks.sql` | 任務、附件、檢查清單範例資料 | 4 | 待建立 |
| `22-diary.sql` | 施工日誌範例資料 | 5 | 待建立 |
| `23-todo.sql` | 待辦事項範例資料 | 6 | 待建立 |
| `30-fixtures.sql` | 開發環境的完整假資料集 | 7 | 待建立 |

### 工具腳本 (`utils/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `reset-sequences.sql` | 重設所有序列計數器到正確值 | 待建立 |
| `cleanup.sql` | 清理所有測試資料（用於重新播種） | 待建立 |

---

## 📝 種子檔案規範

### 命名慣例

```
##-<category>.sql
```

- **序號前綴**：兩位數字，控制載入順序
  - `00-09`: 參考/查找資料
  - `10-19`: 認證/使用者資料
  - `20-29`: 核心業務資料
  - `30-39`: 開發用假資料/測試情境

### 檔案結構範本

```sql
-- ============================================================================
-- Seed: 20-blueprints.sql
-- Description: 藍圖與藍圖成員的測試資料
-- Dependencies: 10-auth.sql (需要測試使用者)
-- ============================================================================

-- 使用 DO 區塊確保冪等性
DO $$
DECLARE
  v_user_id UUID;
  v_blueprint_id UUID;
BEGIN
  -- 取得測試使用者
  SELECT id INTO v_user_id FROM accounts WHERE email = 'test@example.com';
  
  -- 插入或更新資料（冪等）
  INSERT INTO blueprints (id, name, description, created_by)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '測試藍圖',
    '用於開發測試的藍圖',
    v_user_id
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;
    
END $$;
```

### 冪等性要求

種子腳本必須可重複執行：

```sql
-- ✅ 正確：使用 ON CONFLICT
INSERT INTO table_name (id, name)
VALUES ('uuid', 'name')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- ✅ 正確：使用 DO 區塊檢查
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM table_name WHERE id = 'uuid') THEN
    INSERT INTO table_name (id, name) VALUES ('uuid', 'name');
  END IF;
END $$;

-- ❌ 錯誤：可能重複插入
INSERT INTO table_name (id, name) VALUES ('uuid', 'name');
```

---

## 🔧 使用方式

### 設定載入順序

在 `supabase/config.toml` 中已配置：

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

### 執行種子

```bash
# 重置資料庫並載入種子
supabase db reset

# 僅重新載入種子（需要先清理）
psql -f supabase/seeds/utils/cleanup.sql
supabase db reset --no-migrations
```

### 手動載入單一種子

```bash
psql $DATABASE_URL -f supabase/seeds/20-blueprints.sql
```

---

## 🧪 測試使用者

種子資料包含以下測試使用者：

| 電子郵件 | 密碼 | 角色 | 說明 |
|---------|------|------|------|
| `admin@test.com` | `test1234` | 系統管理員 | 具有所有權限 |
| `owner@test.com` | `test1234` | 組織擁有者 | 測試組織的擁有者 |
| `member@test.com` | `test1234` | 一般成員 | 基本成員權限 |
| `viewer@test.com` | `test1234` | 觀察者 | 僅查看權限 |

> ⚠️ **注意**：這些測試帳戶僅用於開發環境，切勿在生產環境使用

---

## ⚠️ 最佳實踐

1. **冪等性**：種子腳本應可重複執行而不產生錯誤
2. **相依順序**：確保種子按正確順序載入
3. **無敏感資料**：不在種子中包含真實密碼或 API 金鑰
4. **文件化**：每個種子檔案應包含說明註解
5. **最小資料集**：僅包含必要的測試資料

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../docs/`](../docs/README.md) | 文件與指南 |
| [`../migrations/`](../migrations/README.md) | 資料庫遷移 |
| [`../tests/`](../tests/README.md) | 測試檔案 |

---

**最後更新**: 2025-11-29
