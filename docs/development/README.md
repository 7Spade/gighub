# 🛠️ 開發環境

> **目的**: 提供本地開發環境設置指南

---

## 📋 系統需求

| 需求 | 最低版本 | 建議版本 |
|------|----------|----------|
| Node.js | 20.x | 20.x LTS |
| pnpm | 8.x | 9.x |
| Docker | 24.x | 最新版 |
| Git | 2.x | 最新版 |

---

## 🚀 快速開始

### 1. 克隆專案

```bash
git clone https://github.com/your-org/gighub.git
cd gighub
```

### 2. 安裝依賴

```bash
pnpm install
```

### 3. 啟動 Supabase

```bash
pnpm supabase:start
```

### 4. 設定環境變數

```bash
cp .env.example .env.local
# 編輯 .env.local 填入 Supabase 資訊
```

### 5. 啟動開發伺服器

```bash
pnpm start
```

### 6. 開啟瀏覽器

http://localhost:4200

---

## 📁 專案結構

```
src/app/
├── core/               # 核心服務
│   ├── auth/           # 認證
│   ├── guards/         # 路由守衛
│   ├── interceptors/   # HTTP 攔截器
│   ├── facades/        # Facade 層
│   └── services/       # 全域服務
├── shared/             # 共用組件
│   ├── components/     # 組件
│   ├── directives/     # 指令
│   ├── pipes/          # 管道
│   └── utils/          # 工具函數
├── features/           # 功能模組
│   └── blueprint/      # 藍圖功能
│       ├── shell/      # 邏輯容器
│       ├── data-access/# 資料存取
│       ├── domain/     # 領域模型
│       ├── ui/         # UI 元件
│       └── utils/      # 工具函數
└── routes/             # 頁面路由
```

---

## 🔧 常用命令

### 開發

```bash
pnpm start              # 啟動開發伺服器
pnpm build              # 建構生產版本
pnpm build:analyze      # 分析 bundle 大小
```

### 測試

```bash
pnpm test               # 執行單元測試
pnpm test:watch         # 監聽模式測試
pnpm e2e                # 執行 E2E 測試
```

### 程式碼品質

```bash
pnpm lint               # ESLint 檢查
pnpm lint:fix           # 自動修復
pnpm format             # Prettier 格式化
```

### Supabase

```bash
pnpm supabase:start     # 啟動本地 Supabase
pnpm supabase:stop      # 停止 Supabase
pnpm supabase:reset     # 重置資料庫
pnpm supabase:gen-types # 生成 TypeScript 類型
```

---

## 🔐 環境變數

| 變數 | 說明 | 範例 |
|------|------|------|
| `SUPABASE_URL` | Supabase API URL | `http://localhost:54321` |
| `SUPABASE_ANON_KEY` | Supabase 匿名金鑰 | `eyJ...` |
| `NG_APP_API_URL` | API 基礎路徑 | `http://localhost:54321` |

---

## 🐛 常見問題

### Supabase 無法啟動

```bash
# 確認 Docker 正在運行
docker info

# 重置 Supabase
pnpm supabase stop
pnpm supabase start
```

### 類型定義過時

```bash
# 重新生成類型
pnpm supabase:gen-types
```

### 依賴衝突

```bash
# 清除快取並重新安裝
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

---

## 📚 相關文檔

- [技術規範](../specs/README.md)
- [Supabase 整合](../supabase/README.md)
- [Agent 開發指南](../agent/README.md)

---

**最後更新**: 2025-11-27  
**維護者**: 開發團隊
