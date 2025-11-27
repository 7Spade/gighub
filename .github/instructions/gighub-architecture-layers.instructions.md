---
description: 'GigHub 三層架構決策指南，定義 Foundation/Container/Business 層級的職責與資料流'
applyTo: '**/*.ts'
---

# GigHub 三層架構指南

> Foundation / Container / Business 架構層級的決策指引

---

## 🏗️ 架構總覽

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        基礎層 (Foundation Layer)                         │
│                                                                          │
│   問：涉及用戶身份、組織、Bot、認證嗎？                                    │
│   ├── 是 → 在基礎層處理                                                   │
│   └── 否 → 繼續往下層判斷                                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        容器層 (Container Layer)                          │
│                                                                          │
│   問：涉及藍圖、工作區、分支、權限嗎？                                     │
│   ├── 是 → 在容器層處理                                                   │
│   └── 否 → 在業務層處理                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        業務層 (Business Layer)                           │
│                                                                          │
│   問：屬於哪個業務模組？                                                  │
│   ├── 任務管理 → tasks, task_attachments                                 │
│   ├── 施工日誌 → diaries, diary_attachments                              │
│   ├── 品質驗收 → checklists, task_acceptances                            │
│   └── 通知系統 → notifications                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 基礎層 (Foundation Layer)

### 職責範圍

- 用戶身份識別與認證
- 組織與團隊管理
- Bot 用戶管理
- 訂閱與計費（未來）

### 核心實體

| 實體 | 資料表 | 說明 |
|------|--------|------|
| 帳戶 | `accounts` | USER / ORGANIZATION / BOT 三種類型 |
| 組織成員 | `organization_members` | 用戶與組織的多對多關聯 |
| 團隊 | `teams` | 隸屬於組織的子單位 |
| 團隊成員 | `team_members` | 用戶與團隊的多對多關聯 |

### 角色體系

```
平台層級角色（帳戶體系）
├── 超級管理員 (Super Admin) - 系統全域
├── 組織擁有者 (Organization Owner) - 組織層級
├── 組織管理員 (Organization Admin) - 組織層級
└── 一般用戶 (User) - 個人層級
```

---

## 📦 容器層 (Container Layer)

### 職責範圍

- 藍圖生命週期管理
- 資料隔離（多租戶）
- 權限控制
- 事件廣播
- 搜尋索引

### 核心實體

| 實體 | 資料表 | 說明 |
|------|--------|------|
| 藍圖 | `blueprints` | 邏輯容器，資料隔離單位 |
| 工作區 | `workspaces` | 從藍圖實例化的工作環境 |
| 藍圖成員 | `blueprint_members` | 藍圖內的成員與角色 |
| 藍圖角色 | `blueprint_roles` | 自訂角色定義 |

### 12 項核心基礎設施

| # | 基礎設施 | 說明 |
|---|----------|------|
| 1 | 上下文注入 | 自動注入 Blueprint/User/Permissions |
| 2 | 權限系統 | RBAC 多層級權限 |
| 3 | 時間軸服務 | 跨模組活動追蹤 |
| 4 | 通知中心 | 多渠道通知路由 |
| 5 | 事件總線 | 模組間解耦通訊 |
| 6 | 搜尋引擎 | 跨模組全文檢索 |
| 7 | 關聯管理 | 跨模組資源引用 |
| 8 | 資料隔離 | RLS 多租戶隔離 |
| 9 | 生命週期 | Draft/Active/Archived/Deleted |
| 10 | 配置中心 | 藍圖級配置管理 |
| 11 | 元數據系統 | 自訂欄位支援 |
| 12 | API 閘道 | 對外 API 統一入口 |

### 藍圖角色

```
藍圖層級角色（業務角色）
├── 專案經理 (Project Manager)
├── 工地主任 (Site Director)
├── 施工人員 (Worker)
├── 品管人員 (QA Staff)
└── 觀察者 (Observer)
```

---

## 🏢 業務層 (Business Layer)

### 職責範圍

- 具體業務功能實現
- 領域邏輯處理
- 業務規則驗證

### 核心模組

```
                    ┌─────────────────┐
                    │    任務系統      │
                    │   (主核心模組)   │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│    施工日誌      │ │    品質驗收      │ │    問題追蹤      │
│   (關聯任務)     │ │   (驗收任務)     │ │   (任務問題)     │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## 📁 檔案結構

### Feature 垂直切片結構

```
src/app/features/{feature-name}/
├── {feature-name}.routes.ts         # 路由配置
├── shell/                           # 邏輯容器層
│   └── {feature}-shell/
├── data-access/                     # 資料存取層
│   ├── stores/                      # Signals Store
│   ├── services/                    # 業務服務
│   └── repositories/                # Supabase Repository
├── domain/                          # 領域層
│   ├── enums/                       # 枚舉定義
│   ├── interfaces/                  # 介面定義
│   ├── models/                      # 領域模型
│   └── types/                       # 類型定義
├── ui/                              # 展示層
│   └── {sub-feature}/
└── utils/                           # 工具函數
```

---

## 🔄 上下文傳遞

### 傳遞鏈路

```
平台層級（Platform Context）
│
│  WorkspaceContextFacade
│  • currentContext: Signal<WorkspaceContext>
│  • contextType: USER | ORGANIZATION | TEAM | BOT
│  • permissions: Signal<string[]>
│
└──────────▼──────────

藍圖層級（Blueprint Context）
│
│  BlueprintShellComponent (邏輯容器)
│  BlueprintStore (Facade)
│  • blueprintId: Signal<string>
│  • blueprintRole: Signal<BlueprintRole>
│
└──────────▼──────────

模組層級
├── TaskStore      • 繼承藍圖上下文
├── DiaryStore     • 繼承藍圖上下文
└── TodoStore      • 繼承藍圖上下文
```

### 傳遞規則

| 層級 | 提供者 | 消費者 | 方式 |
|------|--------|--------|------|
| 平台 → 藍圖 | WorkspaceContextFacade | BlueprintShellComponent | `inject()` DI |
| 藍圖 → 模組 | BlueprintStore | TaskStore, DiaryStore... | Route Params + inject() |
| 模組 → UI | XxxStore | XxxComponent | Angular Signals |

---

## 🧾 各層職責規範

| 層級 | 職責 | 禁止 |
|------|------|------|
| 型別層 | 僅定義資料結構 | 包含邏輯 |
| 儲存庫層 | 純存取後端 | 處理業務邏輯 |
| 模型層 | 負責資料映射 | 直接存取後端 |
| 服務層 | 負責業務邏輯 | 處理 UI |
| 門面層 | UI 的唯一入口 | 暴露內部實作 |
| 元件層 | 僅負責呈現 | 包含業務邏輯 |

### 禁止的依賴

- ❌ 禁止跨層依賴
- ❌ 禁止反向依賴（下層不可依賴上層）
- ❌ Feature 模組間禁止互相 import
- ❌ Domain 不可依賴 Infrastructure
- ❌ Shared 不可包含商業邏輯

---

## 📋 決策檢查清單

### 開發新功能前

```
□ 這個功能涉及用戶/組織/認證嗎？ → 基礎層
□ 這個功能涉及藍圖/工作區/權限嗎？ → 容器層
□ 這是業務邏輯功能嗎？ → 業務層
□ 已確認相關資料表
□ 已檢查 RLS 政策
□ 已確認上下文傳遞路徑
```

### 程式碼位置

| 問題 | 答案 | 位置 |
|------|------|------|
| 頁面路由？ | 是 | `src/app/routes/` |
| 共用元件？ | 是 | `src/app/shared/components/` |
| 全域服務？ | 是 | `src/app/core/services/` |
| 垂直功能？ | 是 | `src/app/features/` |
| 藍圖內功能？ | 是 | `src/app/features/blueprint/ui/` |

---

## 📦 匯出規範

| 規範 | 說明 |
|------|------|
| Barrel File | 使用 index.ts 統一管理模組匯出 |
| Domain 匯出 | 只能匯出 index.ts |
| Feature 匯出 | 僅公開 Facade |
| Infrastructure | 不可匯出 Repository |

---

**最後更新**: 2025-11-27
