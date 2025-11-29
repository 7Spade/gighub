# 📚 Supabase 文件總覽

> 本資料夾彙整與 Supabase 相關的專案文件與說明

---

## 🎯 目的

提供 GigHub 專案 Supabase 整合的完整文件索引，協助開發者理解資料庫架構、RLS 政策、遷移流程與測試規範。

---

## 📁 目錄結構

```
supabase/
├── docs/                    # 📚 文件與說明（本目錄）
│   ├── README.md           # 文件總覽（本文件）
│   ├── architecture.md     # 資料庫架構說明
│   ├── rls-patterns.md     # RLS 設計模式
│   ├── migration-guide.md  # 遷移操作指南
│   └── troubleshooting.md  # 疑難排解與 FAQ
│
├── migrations/              # 🔄 資料庫遷移檔
│   └── README.md           # 遷移檔命名規範與清單
│
├── policies/                # 🔐 RLS 政策參考檔
│   └── README.md           # 政策設計規範
│
├── seeds/                   # 🌱 種子資料
│   └── README.md           # 種子資料規範
│
├── tests/                   # 🧪 測試檔案
│   └── README.md           # 測試規範與執行指南
│
├── functions/               # ⚡ Edge Functions
│   └── README.md           # Edge Functions 開發指南
│
└── config.toml              # ⚙️ Supabase CLI 配置
```

---

## 📖 文件檔案清單

| 檔案 | 說明 | 狀態 |
|------|------|------|
| `architecture.md` | 資料庫架構、表關聯、ER 圖 | 📝 規劃中 |
| `rls-patterns.md` | RLS 政策設計模式與最佳實踐 | 📝 規劃中 |
| `migration-guide.md` | 遷移操作指南與回滾流程 | 📝 規劃中 |
| `troubleshooting.md` | 常見問題（42501 錯誤等）與解決方案 | 📝 規劃中 |
| `deployment.md` | 部署流程與環境配置 | 📝 規劃中 |
| `backup-restore.md` | 資料庫備份與還原指南 | 📝 規劃中 |

---

## 🔗 相關目錄

| 目錄 | 說明 | 連結 |
|------|------|------|
| `migrations/` | 資料庫結構遷移檔 | [migrations/README.md](../migrations/README.md) |
| `policies/` | RLS 政策參考檔 | [policies/README.md](../policies/README.md) |
| `seeds/` | 開發/測試種子資料 | [seeds/README.md](../seeds/README.md) |
| `tests/` | 資料庫測試檔案 | [tests/README.md](../tests/README.md) |

---

## 🚨 關於 42501 權限錯誤

### 問題背景

PostgreSQL 錯誤碼 `42501` (insufficient_privilege) 通常發生於：

1. **RLS 無限遞迴**：政策查詢受 RLS 保護的表
2. **權限不足**：角色缺少必要權限
3. **函數權限**：SECURITY DEFINER 設定不正確

### 解決方案架構

```
                    ┌─────────────────────────────────────┐
                    │         Helper Functions            │
                    │   (SECURITY DEFINER + row_security  │
                    │            = off)                   │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────┐
    │                      RLS Policies                         │
    │  使用 Helper Functions 而非直接查詢受保護的表              │
    └──────────────────────────────────────────────────────────┘
```

### 核心 Helper Functions

| 函數名稱 | 用途 | 回傳類型 |
|----------|------|----------|
| `get_user_account_id()` | 取得當前用戶的 account_id | UUID |
| `is_org_member(org_id)` | 檢查是否為組織成員 | BOOLEAN |
| `is_org_admin(org_id)` | 檢查是否為組織管理員 | BOOLEAN |
| `is_blueprint_member(bp_id)` | 檢查是否為藍圖成員 | BOOLEAN |
| `is_blueprint_admin(bp_id)` | 檢查是否為藍圖管理員 | BOOLEAN |
| `is_blueprint_owner(bp_id)` | 檢查是否為藍圖擁有者 | BOOLEAN |

---

## 📋 開發流程

### 1. 新增表格流程

```mermaid
graph LR
    A[設計表結構] --> B[建立 Migration]
    B --> C[啟用 RLS]
    C --> D[建立 Helper Functions]
    D --> E[建立 RLS Policies]
    E --> F[建立 Seeds]
    F --> G[撰寫測試]
```

### 2. 修改 RLS 流程

```mermaid
graph LR
    A[分析現有政策] --> B[建立新 Migration]
    B --> C[更新 Helper Functions]
    C --> D[測試權限]
    D --> E[驗證無遞迴]
```

---

## 🛠️ 常用指令

```bash
# 啟動本地 Supabase
pnpm supabase:start

# 重置資料庫（執行所有 migrations + seeds）
pnpm supabase:reset

# 建立新 migration
pnpm supabase migration new <migration_name>

# 生成 TypeScript 類型
pnpm supabase:gen-types

# 檢視資料庫狀態
supabase db status
```

---

## 📚 外部資源

- [Supabase 官方文件](https://supabase.com/docs)
- [Row Level Security 指南](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS 文件](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [GigHub Supabase 實踐指南](../../.github/instructions/gighub-supabase-practices.instructions.md)

---

## 🔄 維護規範

1. **同步更新**：修改資料庫結構時，同步更新相關文件
2. **版本標記**：重大變更需標註日期與負責人
3. **範例代碼**：提供可執行的範例 SQL
4. **測試驗證**：確保文件中的範例已通過測試

---

**最後更新**: 2025-11-29  
**維護者**: 開發團隊
