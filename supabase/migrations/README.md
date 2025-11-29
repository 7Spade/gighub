# Supabase Migrations

> 此目錄包含資料庫遷移檔（migrations），以有序、可追蹤的方式變更資料庫結構與資料。

---

## 📁 目錄結構

```
supabase/migrations/
├── README.md                                                  # 本文件
│
├── # ===== Phase 1: Core Schema (基礎架構) =====
├── 20251201000001_create_extensions.sql                      # 啟用必要擴展 (uuid-ossp, pgcrypto)
├── 20251201000002_create_enums.sql                           # 建立列舉類型
├── 20251201000003_create_accounts_table.sql                  # 帳戶表 (User/Organization/Bot)
├── 20251201000004_create_organization_members_table.sql      # 組織成員表
├── 20251201000005_create_teams_table.sql                     # 團隊表
├── 20251201000006_create_team_members_table.sql              # 團隊成員表
├── 20251201000007_create_team_bots_table.sql                 # 團隊 Bot 表
│
├── # ===== Phase 2: Helper Functions (輔助函式) =====
├── 20251202000001_create_get_user_account_id_function.sql    # 取得使用者帳戶 ID
├── 20251202000002_create_is_org_member_function.sql          # 檢查組織成員
├── 20251202000003_create_is_org_admin_function.sql           # 檢查組織管理員
├── 20251202000004_create_is_team_member_function.sql         # 檢查團隊成員
├── 20251202000005_create_is_team_leader_function.sql         # 檢查團隊領導
│
├── # ===== Phase 3: RLS Policies - Core (核心 RLS) =====
├── 20251203000001_enable_rls_core_tables.sql                 # 啟用核心表 RLS
├── 20251203000002_create_user_rls_policies.sql               # User 帳戶 RLS
├── 20251203000003_create_organization_rls_policies.sql       # Organization RLS
├── 20251203000004_create_bot_rls_policies.sql                # Bot 帳戶 RLS
├── 20251203000005_create_org_members_rls_policies.sql        # 組織成員 RLS
├── 20251203000006_create_teams_rls_policies.sql              # 團隊 RLS
├── 20251203000007_create_team_members_rls_policies.sql       # 團隊成員 RLS
│
├── # ===== Phase 4: Triggers (觸發器) =====
├── 20251204000001_create_handle_new_user_trigger.sql         # 新使用者自動建立帳戶
├── 20251204000002_create_add_creator_as_org_owner_trigger.sql # 組織建立者自動成為擁有者
├── 20251204000003_create_add_creator_as_team_leader_trigger.sql # 團隊建立者自動成為領導
├── 20251204000004_create_updated_at_trigger.sql              # 自動更新 updated_at
│
├── # ===== Phase 5: Blueprint System (藍圖系統) =====
├── 20251205000001_create_blueprints_table.sql                # 藍圖表
├── 20251205000002_create_blueprint_members_table.sql         # 藍圖成員表
├── 20251205000003_create_blueprint_helper_functions.sql      # 藍圖輔助函式
├── 20251205000004_create_blueprint_rls_policies.sql          # 藍圖 RLS
├── 20251205000005_create_blueprint_triggers.sql              # 藍圖觸發器
│
├── # ===== Phase 6: Task System (任務系統) =====
├── 20251206000001_create_tasks_table.sql                     # 任務表
├── 20251206000002_create_task_attachments_table.sql          # 任務附件表
├── 20251206000003_create_checklists_table.sql                # 檢查清單表
├── 20251206000004_create_checklist_items_table.sql           # 檢查項目表
├── 20251206000005_create_task_acceptances_table.sql          # 任務驗收表
├── 20251206000006_create_task_helper_functions.sql           # 任務輔助函式
├── 20251206000007_create_task_rls_policies.sql               # 任務 RLS
│
├── # ===== Phase 7: Additional Features (附加功能) =====
├── 20251207000001_create_notifications_table.sql             # 通知表
├── 20251207000002_create_activity_logs_table.sql             # 活動日誌表
└── 20251207000003_create_feature_rls_policies.sql            # 附加功能 RLS
```

---

## 📋 規劃檔案清單

### Phase 1: Core Schema (基礎架構)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251201000001_create_extensions.sql` | uuid-ossp, pgcrypto 擴展 | 無 | 待建立 |
| `20251201000002_create_enums.sql` | account_type, status, role 等列舉 | 001 | 待建立 |
| `20251201000003_create_accounts_table.sql` | accounts 表結構 | 002 | 待建立 |
| `20251201000004_create_organization_members_table.sql` | organization_members 表 | 003 | 待建立 |
| `20251201000005_create_teams_table.sql` | teams 表結構 | 003 | 待建立 |
| `20251201000006_create_team_members_table.sql` | team_members 表 | 005 | 待建立 |
| `20251201000007_create_team_bots_table.sql` | team_bots 表 | 005 | 待建立 |

### Phase 2: Helper Functions (輔助函式)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251202000001_create_get_user_account_id_function.sql` | 取得當前使用者帳戶 ID，避免 RLS 遞迴 | Phase 1 | 待建立 |
| `20251202000002_create_is_org_member_function.sql` | 檢查是否為組織成員 | Phase 1 | 待建立 |
| `20251202000003_create_is_org_admin_function.sql` | 檢查是否為組織管理員 | Phase 1 | 待建立 |
| `20251202000004_create_is_team_member_function.sql` | 檢查是否為團隊成員 | Phase 1 | 待建立 |
| `20251202000005_create_is_team_leader_function.sql` | 檢查是否為團隊領導 | Phase 1 | 待建立 |

### Phase 3: RLS Policies - Core (核心 RLS)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251203000001_enable_rls_core_tables.sql` | 啟用所有核心表的 RLS | Phase 1 | 待建立 |
| `20251203000002_create_user_rls_policies.sql` | User 類型帳戶的 RLS 政策 | Phase 2 | 待建立 |
| `20251203000003_create_organization_rls_policies.sql` | Organization 帳戶的 RLS | Phase 2 | 待建立 |
| `20251203000004_create_bot_rls_policies.sql` | Bot 帳戶的 RLS | Phase 2 | 待建立 |
| `20251203000005_create_org_members_rls_policies.sql` | 組織成員表的 RLS | Phase 2 | 待建立 |
| `20251203000006_create_teams_rls_policies.sql` | 團隊表的 RLS | Phase 2 | 待建立 |
| `20251203000007_create_team_members_rls_policies.sql` | 團隊成員表的 RLS | Phase 2 | 待建立 |

### Phase 4: Triggers (觸發器)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251204000001_create_handle_new_user_trigger.sql` | auth.users 新增時自動建立 account | Phase 1 | 待建立 |
| `20251204000002_create_add_creator_as_org_owner_trigger.sql` | 建立組織時自動加入 owner | Phase 3 | 待建立 |
| `20251204000003_create_add_creator_as_team_leader_trigger.sql` | 建立團隊時自動加入 leader | Phase 3 | 待建立 |
| `20251204000004_create_updated_at_trigger.sql` | 通用 updated_at 自動更新 | Phase 1 | 待建立 |

### Phase 5: Blueprint System (藍圖系統)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251205000001_create_blueprints_table.sql` | 藍圖主表結構 | Phase 4 | 待建立 |
| `20251205000002_create_blueprint_members_table.sql` | 藍圖成員表 | 001 | 待建立 |
| `20251205000003_create_blueprint_helper_functions.sql` | is_blueprint_member/admin/owner | 002 | 待建立 |
| `20251205000004_create_blueprint_rls_policies.sql` | 藍圖相關 RLS | 003 | 待建立 |
| `20251205000005_create_blueprint_triggers.sql` | 藍圖建立者自動成為 owner | 004 | 待建立 |

### Phase 6: Task System (任務系統)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251206000001_create_tasks_table.sql` | 任務主表 | Phase 5 | 待建立 |
| `20251206000002_create_task_attachments_table.sql` | 任務附件表 | 001 | 待建立 |
| `20251206000003_create_checklists_table.sql` | 檢查清單表 | Phase 5 | 待建立 |
| `20251206000004_create_checklist_items_table.sql` | 檢查項目表 | 003 | 待建立 |
| `20251206000005_create_task_acceptances_table.sql` | 任務驗收表 | 001, 003 | 待建立 |
| `20251206000006_create_task_helper_functions.sql` | can_access_task 等輔助函式 | 001-005 | 待建立 |
| `20251206000007_create_task_rls_policies.sql` | 任務系統 RLS | 006 | 待建立 |

### Phase 7: Additional Features (附加功能)

| 檔案名稱 | 說明 | 相依 | 狀態 |
|---------|------|------|------|
| `20251207000001_create_notifications_table.sql` | 通知表結構 | Phase 4 | 待建立 |
| `20251207000002_create_activity_logs_table.sql` | 活動日誌表 | Phase 4 | 待建立 |
| `20251207000003_create_feature_rls_policies.sql` | 通知與日誌的 RLS | 001, 002 | 待建立 |

---

## 📝 命名規範

### 檔案命名

```
YYYYMMDD######_<action>_<target>_<detail>.sql
```

- **時間戳**: `YYYYMMDD` + 6 位序號（如 `000001`）
- **動作**: `create`, `alter`, `drop`, `add`, `remove`, `fix`
- **目標**: 表名、函式名、政策名
- **細節**: 選填，進一步說明

範例：
- `20251201000001_create_extensions.sql`
- `20251203000002_create_user_rls_policies.sql`
- `20251204000001_create_handle_new_user_trigger.sql`

### 物件命名

| 類型 | 命名規則 | 範例 |
|------|---------|------|
| 表格 | 複數名詞，snake_case | `accounts`, `team_members` |
| 欄位 | snake_case | `auth_user_id`, `created_at` |
| 函式 | 動詞開頭，snake_case | `get_user_account_id()`, `is_org_admin()` |
| 觸發器 | `<action>_<target>_trigger` | `handle_new_user_trigger` |
| RLS 政策 | `<role>_<action>_<target>` | `users_view_own_user_account` |

---

## 🔧 使用方式

### 建立新遷移

```bash
# 使用 Supabase CLI 建立
supabase migration new <migration_name>

# 或手動建立（依照命名規範）
touch supabase/migrations/20251201000001_create_example.sql
```

### 套用遷移

```bash
# 本地開發
supabase db push

# 或重置並套用
supabase db reset
```

### 檢視遷移狀態

```bash
supabase migration list
```

---

## ⚠️ 重要注意事項

### 避免 42501 權限錯誤

1. **使用 SECURITY DEFINER 函式**：查詢受 RLS 保護的表時，使用 helper functions
2. **設定 `row_security = off`**：在 SECURITY DEFINER 函式內關閉 RLS
3. **避免循環依賴**：RLS 政策不應直接查詢受保護的表

```sql
-- ✅ 正確：使用 helper function
CREATE POLICY "..." ON accounts
USING (id = public.get_user_account_id());

-- ❌ 錯誤：直接在 RLS 中查詢會導致遞迴
CREATE POLICY "..." ON accounts
USING (id IN (SELECT account_id FROM organization_members WHERE ...));
```

### 遷移檔案規則

1. **不修改已部署的遷移**：需要變更時，建立新的遷移檔案
2. **包含回滾邏輯**：重要變更應記錄回滾步驟
3. **測試再部署**：先在本地/staging 環境測試
4. **記錄相依性**：在檔案註解中說明相依關係

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../docs/`](../docs/README.md) | 文件與指南 |
| [`../policies/`](../policies/README.md) | RLS 政策詳細說明 |
| [`../seeds/`](../seeds/README.md) | 種子資料 |
| [`../tests/`](../tests/README.md) | 測試檔案 |

---

**最後更新**: 2025-11-29
