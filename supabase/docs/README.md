# Supabase 文件目錄 (Documentation)

> 本資料夾彙整與 Supabase 相關的專案文件與說明，包含部署指引、架構說明、操作手冊與最佳實踐。

---

## 📁 目錄結構

```
supabase/docs/
├── README.md                          # 本文件 - 文件目錄索引
├── architecture/                      # 系統架構文件
│   ├── database-schema.md             # 資料庫架構設計說明
│   ├── rls-strategy.md                # Row Level Security 策略說明
│   └── naming-conventions.md          # 命名規範與慣例
├── guides/                            # 操作指南
│   ├── local-development.md           # 本地開發環境設置
│   ├── migration-workflow.md          # 遷移工作流程
│   ├── deployment-checklist.md        # 部署檢查清單
│   └── troubleshooting.md             # 常見問題排解 (含 42501 權限錯誤)
├── references/                        # 參考資料
│   ├── helper-functions.md            # Helper Functions 參考
│   ├── rls-policies-reference.md      # RLS 政策參考
│   └── error-codes.md                 # 錯誤碼對照表
└── adr/                               # 架構決策記錄 (Architecture Decision Records)
    ├── 001-use-security-definer.md    # ADR: 使用 SECURITY DEFINER 避免 RLS 遞迴
    ├── 002-soft-delete-strategy.md    # ADR: 軟刪除策略
    └── 003-auth-user-id-pattern.md    # ADR: auth_user_id 欄位模式
```

---

## 📋 規劃檔案清單

### 架構文件 (`architecture/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `database-schema.md` | 完整資料庫架構，包含 ER Diagram、表格關聯 | 待建立 |
| `rls-strategy.md` | RLS 設計原則、避免 42501 錯誤的策略 | 待建立 |
| `naming-conventions.md` | 表格、欄位、函式、政策的命名規範 | 待建立 |

### 操作指南 (`guides/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `local-development.md` | 本地 Supabase 開發環境設置步驟 | 待建立 |
| `migration-workflow.md` | 遷移檔案建立、測試、部署的完整流程 | 待建立 |
| `deployment-checklist.md` | 生產環境部署前的檢查項目 | 待建立 |
| `troubleshooting.md` | 常見錯誤排解，特別是 42501 權限錯誤 | 待建立 |

### 參考資料 (`references/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `helper-functions.md` | 所有 Helper Functions 的使用說明 | 待建立 |
| `rls-policies-reference.md` | 現有 RLS 政策的完整參考 | 待建立 |
| `error-codes.md` | PostgreSQL/Supabase 錯誤碼對照 | 待建立 |

### 架構決策記錄 (`adr/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `001-use-security-definer.md` | 為何使用 SECURITY DEFINER 函式 | 待建立 |
| `002-soft-delete-strategy.md` | 軟刪除 vs 硬刪除的決策 | 待建立 |
| `003-auth-user-id-pattern.md` | auth_user_id 欄位設計決策 | 待建立 |

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../migrations/`](../migrations/README.md) | 資料庫遷移檔案 |
| [`../policies/`](../policies/README.md) | RLS 政策定義 |
| [`../functions/`](../functions/README.md) | Edge Functions |
| [`../seeds/`](../seeds/README.md) | 種子資料 |
| [`../tests/`](../tests/README.md) | 測試檔案 |

---

## 📝 維護指引

1. **保持同步**：更新基礎結構（遷移、政策、函式）時，同步更新相關文件
2. **版本追蹤**：重大變更需記錄更新日期與作者
3. **ADR 記錄**：重要架構決策需建立 ADR 文件
4. **清晰簡潔**：文件應易於閱讀，避免冗長敘述

---

**最後更新**: 2025-11-29
