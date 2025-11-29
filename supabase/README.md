# GigHub Supabase 架構

> GigHub 專案的 Supabase 後端服務架構，包含資料庫遷移、RLS 政策、Edge Functions、種子資料與測試。

---

## 🎯 專案目標

本專案旨在建立現代化的 Supabase 架構，以避免常見的 **42501 權限錯誤**（RLS 無限遞迴），並確保：

- ✅ 正確的資料隔離與權限控制
- ✅ 可維護的遷移檔案結構
- ✅ 完整的測試覆蓋
- ✅ 清晰的文件與命名規範

---

## 📁 目錄結構總覽

```
supabase/
├── README.md                    # 本文件 - Supabase 架構總覽
├── config.toml                  # Supabase 本地設定
│
├── docs/                        # 📚 文件與指南
│   ├── README.md                # 文件目錄索引
│   ├── architecture/            # 系統架構文件
│   ├── guides/                  # 操作指南
│   ├── references/              # 參考資料
│   └── adr/                     # 架構決策記錄
│
├── functions/                   # ⚡ Edge Functions
│   ├── README.md                # Functions 說明
│   ├── _shared/                 # 共用程式碼
│   └── <function-name>/         # 各函式目錄
│
├── migrations/                  # 🔄 資料庫遷移
│   ├── README.md                # 遷移檔案規劃與命名規範
│   └── YYYYMMDD######_*.sql     # 時間戳記命名的遷移檔
│
├── policies/                    # 🔐 RLS 政策
│   ├── README.md                # RLS 政策說明與範本
│   ├── templates/               # 政策範本
│   ├── core/                    # 核心表格政策
│   ├── blueprint/               # 藍圖系統政策
│   └── task/                    # 任務系統政策
│
├── seeds/                       # 🌱 種子資料
│   ├── README.md                # 種子資料說明
│   ├── 00-reference.sql         # 參考資料
│   ├── 10-auth.sql              # 認證資料
│   ├── 20-blueprints.sql        # 藍圖資料
│   ├── 21-tasks.sql             # 任務資料
│   ├── 22-diary.sql             # 日誌資料
│   ├── 23-todo.sql              # 待辦資料
│   └── 30-fixtures.sql          # 假資料
│
├── tests/                       # 🧪 測試
│   ├── README.md                # 測試說明
│   ├── unit/                    # 單元測試
│   ├── integration/             # 整合測試
│   ├── rls/                     # RLS 政策測試
│   ├── fixtures/                # 測試資料
│   └── helpers/                 # 測試輔助工具
│
└── migrations-old/              # 📦 舊遷移檔（僅供參考）
    └── *.sql                    # 舊版遷移檔案
```

---

## 🚀 快速開始

### 前置需求

- [Supabase CLI](https://supabase.com/docs/guides/cli) >= 1.0
- [Docker](https://www.docker.com/) (用於本地開發)
- [Node.js](https://nodejs.org/) >= 18 (用於 Edge Functions 開發)

### 初始化本地環境

```bash
# 1. 啟動本地 Supabase
supabase start

# 2. 套用遷移與種子資料
supabase db reset

# 3. 開啟 Studio (資料庫管理介面)
# 預設網址: http://localhost:54323
```

### 常用指令

```bash
# 資料庫操作
supabase db reset          # 重置資料庫（套用遷移+種子）
supabase db push           # 推送遷移到遠端
supabase migration list    # 列出遷移狀態

# 建立新遷移
supabase migration new <name>

# Edge Functions
supabase functions serve   # 本地開發
supabase functions deploy  # 部署到遠端

# 停止服務
supabase stop
```

---

## 📋 各目錄詳細說明

### [📚 docs/](./docs/README.md)

文件與指南，包含：
- 系統架構文件
- 操作指南（本地開發、部署）
- 參考資料（helper functions、錯誤碼）
- 架構決策記錄 (ADR)

### [⚡ functions/](./functions/README.md)

Supabase Edge Functions：
- Deno Runtime 無伺服器函式
- 共用程式碼與工具
- 部署與測試指南

### [🔄 migrations/](./migrations/README.md)

資料庫遷移檔：
- 分階段的遷移規劃（Phase 1-7）
- 命名規範與相依關係
- 避免 42501 錯誤的最佳實踐

### [🔐 policies/](./policies/README.md)

Row Level Security 政策：
- 政策範本與模式
- Helper Functions 使用說明
- 避免 RLS 遞迴的策略

### [🌱 seeds/](./seeds/README.md)

開發/測試用種子資料：
- 依序載入的種子檔案
- 測試使用者帳戶
- 冪等性播種規範

### [🧪 tests/](./tests/README.md)

資料庫測試：
- 單元測試（函式、觸發器）
- 整合測試（業務流程）
- RLS 政策測試

---

## ⚠️ 關鍵設計決策

### 避免 42501 權限錯誤

**問題**：RLS 政策中直接查詢受保護的表會導致無限遞迴

**解決方案**：使用 SECURITY DEFINER 函式

```sql
-- ✅ 正確做法
CREATE OR REPLACE FUNCTION public.get_user_account_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET row_security = off  -- 關鍵：關閉 RLS
AS $$
BEGIN
  RETURN (SELECT id FROM accounts WHERE auth_user_id = auth.uid());
END;
$$;

-- 在 RLS 政策中使用
CREATE POLICY "users_view_own_account" ON accounts
FOR SELECT USING (id = public.get_user_account_id());
```

### 遷移檔案分階段

遷移檔案按邏輯分為 7 個階段：

1. **Phase 1**: Core Schema - 基礎表格
2. **Phase 2**: Helper Functions - 輔助函式
3. **Phase 3**: RLS Policies - 核心 RLS 政策
4. **Phase 4**: Triggers - 觸發器
5. **Phase 5**: Blueprint System - 藍圖系統
6. **Phase 6**: Task System - 任務系統
7. **Phase 7**: Additional Features - 附加功能

---

## 🔗 參考資源

- [Supabase 官方文件](https://supabase.com/docs)
- [PostgreSQL RLS 文件](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Supabase CLI 參考](https://supabase.com/docs/reference/cli)

---

## 📝 貢獻指南

1. **遷移檔案**：遵循 `migrations/README.md` 的命名規範
2. **RLS 政策**：使用 `policies/` 中的範本
3. **測試**：新增功能需附帶測試
4. **文件**：更新相關 README 檔案

---

**最後更新**: 2025-11-29
