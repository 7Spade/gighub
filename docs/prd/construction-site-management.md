---
title: 施工現場管理（Construction Site Management）
status: draft
created: 2025-11-27
owners: []
progress: 0
due: null
---

# 施工現場管理 — 產品需求概要 (PRD)

目的
-
本文件為 GigHub 工地施工進度追蹤系統（Construction Site Management）的產品需求說明（PRD）骨架，目標是逐步把商業需求、使用者故事、驗收標準與發展里程碑整理成可執行的開發任務。

背景與動機
-
- 工地管理涉及多方角色（工地主任、施工人員、品管、監工、業主等），需要即時的進度、照片、簽核與驗收流程。
- 本系統以 Supabase 作為後端、Angular/ng-alain 作為前端，目標提供可擴充、可審計的施工流程平台。

目標
-
- 提供日誌化的施工紀錄（施工日誌）與照片上傳。
- 支援任務/子任務與里程碑管理。
- 提供驗收清單與品質檢核流程（Checklists）。
- 支援權限與審核流程（多階段簽核）。

範圍（Scope）
-
- 首階段（MVP）範圍：
  - 建立/編輯/瀏覽施工日誌
  - 相片上傳與基本標記
  - 任務狀態（待處理、進行中、審核中、完成）
  - 基本使用者角色（Admin/PM/Worker/QA）與 RLS 保護
- 非包含：
  - 進階排程優化（Gantt、Critical Path）
  - 離線同步與衝突解決（預留後續擴充）

目標使用者與人物誌（Personas）
-
- 工地主任（Site Director）：記錄日常進度、簽核日誌
- 施工人員（Worker）：上傳現場照片、回報工時
- 品管（QA Staff）：填寫檢查清單、標註缺失
- 業主/觀察者（Observer）：查看已核准的日誌與驗收記錄

高階需求（High-level Requirements）
-
1. 使用者能建立每日施工日誌，包含文字描述、工時、施工人數、天氣與多張相片。
2. 照片支援標註（簡單的說明文字）並儲存 metadata（拍攝時間、上傳者）。
3. 任務必須支援狀態流轉與審核，並記錄審核歷史（audit trail）。
4. 系統應遵守 Row Level Security（RLS）原則，確保資料隔離與最小權限。

驗收標準（Acceptance Criteria）
-
- 範例：建立施工日誌
  - GIVEN 已登入的工地主任
  - WHEN 新增日誌並上傳至少一張照片
  - THEN 日誌儲存成功，照片可在日誌頁面檢視並顯示 metadata

非功能性需求（NFRs）
-
- 可用性：系統 UI 在行動裝置上可用且主要流程 < 3 次點擊完成
- 安全性：使用 Supabase Auth + RLS，敏感資料加密傳輸
- 可維護性：使用 Angular Signals、Repository 模式管理資料存取

里程碑與迭代計畫
-
- Iteration 1 (MVP, 2 weeks): 日誌 CRUD、照片上傳、基本角色
- Iteration 2 (2 weeks): 檢查清單、審核流程、RLS 深入測試
- Iteration 3 (2–4 weeks): 報表、匯出、照片標註強化

風險與假設
-
- 假設：使用者有行動網路連線；相片大小與上傳頻率受限於前端與 Supabase 儲存策略。
- 風險：影像儲存成本、離線情況下資料一致性問題。

後續步驟（Next Steps / Roadmap）
-
1. 與產品與使用者代表召開需求確認會議，補強使用案例與邊界條件。
2. 將高階需求拆解成具體 Jira / GitHub Issue。
3. 撰寫 API Contract（OpenAPI / Supabase schema）並建立 migration plan。
4. 設計 E2E 測試範例（Playwright）與 Accessibility checklist。

註記
-
- 此文件為骨架（living document），會隨需求討論與設計調整持續更新。請在每次 sprint planning 後更新本文件的進度區塊。

**完成判準（Definition of Done）**
-
- `status` 欄位更新為 `done`（由功能負責人或 reviewer 在確認所有條件後更新）。
- 所有 Acceptance Checklist 項目已通過（見下方範本）。
- 有關功能的 PR 已合併且 CI（lint、unit tests、E2E）全部綠燈。
- 相關文件（API contract / migrations / 操作說明）已更新並連結於本文件的「後續步驟」或 Issue 中。
- 如有 UI 變更，已提供畫面截圖或 Playwright 測試證明。

**Acceptance Checklist 範本（請複製到每個 Issue 或 PR）**

- [ ] 功能需求與使用案例已在 PRD 中確認
- [ ] Backend: 所需資料表 / 欄位 migration 已建立並 review
- [ ] API contract（OpenAPI 或 Postgres schema）已確認並有測試範例
- [ ] Frontend: UI 已實作且通過 manual QA
- [ ] Unit tests：覆蓋主要邏輯（Service / Repository）
- [ ] E2E tests：關鍵流程（建立日誌、上傳照片、審核）可通過
- [ ] RLS 與授權驗證（至少一個正向與一個負向測試）
- [ ] Accessibility：關鍵表單與檢視通過基本無障礙檢查（鍵盤操作 + 標籤）
- [ ] 運維/監控：需有基本監控指標或 log 設定（若有）
- [ ] 文件：更新 PRD、設計圖、使用說明或 release note

**進度欄位說明（Frontmatter usage）**
- `owners`: 指定負責人 (GitHub username)
- `progress`: 整數 0~100，或以 checklist/Issue 狀態來計算
- `due`: 可選，ISO 日期或 null

**驗證證據（Proof）**
- 對於每項被 tick 的項目，請在 PR/Issue 中提供一個連結或附件說明（例如：PR 編號、測試報表、截圖、Playwright run 的 URL）。

# PRD: 工地施工進度追蹤管理系統

## 1. 產品概述

### 1.1 文件標題與版本

- **PRD**: 工地施工進度追蹤管理系統 (Construction Site Management System)
- **版本**: 1.6.0
- **建立日期**: 2025-11-26
- **最後更新**: 2025-11-26
- **修訂說明**: 新增「開發者必讀：關鍵實作細節」章節，達到零認知開發水平

### 1.2 產品摘要

工地施工進度追蹤管理系統是一個專為台灣營造業設計的企業級應用程式，旨在解決工地現場管理的痛點。本系統整合了施工進度追蹤、品質驗收、每日施工日誌、任務管理等核心功能，透過視覺化的樹狀任務結構與即時狀態膠囊顯示，讓工地管理更加直覺且高效。

系統基於現代化的技術架構（Angular 20 + ng-alain + Supabase），採用 Git-like 的藍圖分支模式，支援多組織協作的承攬模式。

**🎯 開發理念（奧卡姆剃刀原則）：**
- **功能最小化**：每個功能只做必要的事，避免過度設計
- **企業標準**：雖然簡潔但符合企業級品質要求
- **易於擴展**：預留擴展接口但不預先實現
- **避免冗餘**：資料表只建立必要欄位，程式碼只寫必要邏輯

**🏗️ 核心架構理念：**
- **藍圖是邏輯容器**：提供資料隔離、上下文共享、多模組擴展的基礎架構
- **任務是主核心模組**：工地管理的一切操作都圍繞任務展開
- **其他模組依附任務**：進度追蹤、品質驗收、日誌、檔案等皆以任務為主體開發
- **上下文層層傳遞**：平台 → 藍圖 → 模組，避免重複查詢

**✅ 已完成的核心基礎設施：**
- **工作區上下文切換器**：支援個人、組織、團隊、Bot 工作區的無縫切換
- **藍圖邏輯容器框架**：提供資料隔離和上下文共享的多模組架構
- **任務系統框架**：包含樹狀圖、表格視圖、狀態管理
- **日誌系統框架**：支援列表、篩選架構
- **待辦系統框架**：基礎待辦事項管理

本 PRD 將聚焦於在現有基礎設施上實現工地管理的具體業務功能。

主要目標使用者包括：營造公司管理層、工地主任、施工人員、品管人員、以及業主。系統特別針對台灣工地環境進行優化，包括離線功能支援、在地化介面、以及符合台灣法規的文件管理。

### 1.3 現有基礎設施狀態

#### 1.3.1 工作區上下文切換器 ✅ 已完成

**實現檔案**: `src/app/core/facades/account/workspace-context.facade.ts`

```
WorkspaceContextFacade
├── 上下文類型支援
│   ├── USER (個人工作區)
│   ├── ORGANIZATION (組織工作區)
│   ├── TEAM (團隊工作區)
│   └── BOT (機器人工作區)
├── 核心 API
│   ├── switchToUser(userId, options)
│   ├── switchToOrganization(orgId, options)
│   ├── switchToTeam(teamId, options)
│   └── switchToBot(botId, options)
├── 狀態管理
│   ├── contextType (當前上下文類型)
│   ├── contextId (當前上下文 ID)
│   ├── contextLabel (上下文標籤)
│   └── contextIcon (上下文圖標)
└── 輔助功能
    ├── 菜單自動同步 (syncMenu)
    ├── 上下文持久化與恢復 (restoreContext)
    └── 組織/團隊資料載入
```

**路由結構**:
- 個人: `/account/user/:userId/*`
- 組織: `/account/org/:organizationId/*`
- 團隊: `/account/team/:teamId/*`

#### 1.3.2 藍圖邏輯容器框架 ✅ 已完成

**實現檔案**: `src/app/features/blueprint/`

```
Blueprint Feature (Vertical Slice Architecture)
├── shell/
│   └── BlueprintShellComponent (邏輯容器 - 資料隔離)
├── data-access/
│   ├── stores/
│   │   ├── BlueprintStore (藍圖 Facade)
│   │   ├── TaskStore (任務狀態)
│   │   ├── DiaryStore (日誌狀態)
│   │   └── TodoStore (待辦狀態)
│   ├── services/
│   │   ├── BlueprintService
│   │   └── WorkspaceService
│   └── repositories/
├── domain/
│   ├── models/ (BlueprintModel, TaskModel, etc.)
│   ├── enums/ (狀態、優先級、類型枚舉)
│   └── interfaces/ (過濾、排序、分頁介面)
├── ui/
│   ├── blueprint-list/
│   ├── task/ (task-list, task-tree, task-table)
│   ├── diary/ (diary-list)
│   └── todo/ (todo-list)
└── utils/ (export, canvas, validation)
```

**藍圖路由**:
- `/blueprint` - 藍圖 Shell
- `/blueprint/list` - 藍圖列表
- `/blueprint/task` - 任務管理
- `/blueprint/diary` - 日誌管理
- `/blueprint/todo` - 待辦事項

#### 1.3.3 任務系統 🔶 部分完成

**已完成**:
- ✅ 任務樹狀結構 (TaskTreeComponent) - 支援無限層級
- ✅ 任務表格視圖 (TaskTableComponent)
- ✅ 視圖切換 (tree/table)
- ✅ 任務搜尋與篩選
- ✅ 任務統計
- ✅ 狀態枚舉: `TODO, IN_PROGRESS, IN_REVIEW, DONE, CANCELLED`
- ✅ 優先級枚舉: `LOWEST, LOW, MEDIUM, HIGH, HIGHEST`
- ✅ 任務類型枚舉: `TASK, MILESTONE, BUG, FEATURE, IMPROVEMENT`

**待實現**:
- ⬜ 完工圖片顯示於樹狀圖旁
- ⬜ 膠囊狀態顯示（負責人頭像、截止日期、問題徽章）
- ⬜ 任務拖拉排序
- ⬜ 任務評論與討論
- ⬜ 任務時間記錄

#### 1.3.4 日誌系統 🔶 部分完成

**已完成**:
- ✅ 日誌列表框架 (DiaryListComponent)
- ✅ 按月份篩選
- ✅ 搜尋功能
- ✅ 天氣圖標映射（手動選擇）
- ✅ DiaryStore 狀態管理

**待實現**:
- ⬜ 日誌填寫表單
- ⬜ 照片批次上傳
- ⬜ 日誌匯出功能

#### 1.3.5 待辦系統 🔶 部分完成

**已完成**:
- ✅ TodoStore 狀態管理
- ✅ TodoListComponent 基礎框架

**待實現**:
- ⬜ 五狀態分類顯示
- ⬜ 與任務系統整合

---

## 2. 目標

### 2.1 商業目標

- 提升營造公司專案管理效率達 40% 以上
- 減少因溝通不良導致的施工錯誤與返工成本
- 建立可追溯的品質驗收記錄，降低法律糾紛風險
- 提供即時進度報告，提升業主信任度與滿意度
- 透過數據分析優化資源配置，降低專案成本
- 建立營造業數位轉型的標竿解決方案

### 2.2 使用者目標

- **專案經理**: 即時掌握所有專案進度，快速識別風險項目
- **工地主任**: 簡化每日報告流程，一鍵完成施工日誌
- **施工人員**: 清楚了解工作任務，快速回報完成狀態
- **品管人員**: 系統化品質檢查流程，降低人為疏失
- **業主**: 透明化專案進度，隨時查看施工狀況與品質報告
- **所有使用者**: 即使在網路不穩定的工地現場也能順利使用

### 2.3 非目標（初版範圍外）

- **初版不包含，但未來規劃**:
  - 財務系統（簡化版進度請款 - Phase 2）
  - 人力資源管理（極簡以任務為主體 - Phase 2）
  - Git-like 分支系統（Fork / PR - Phase 2）
  
- **不在產品規劃範圍**:
  - 完整財務會計功能（如成本會計、付款管理、發票開立）
  - 傳統人資管理功能（如薪資計算、出勤管理、績效評估）
  - 材料採購與庫存管理功能
  - BIM 模型整合功能（評估中）
  - Windows/macOS 桌面原生應用程式（僅 Web 應用）
  - 第一版不支援多語系（僅繁體中文）

---

## 3. 使用者角色與權限

### 3.0 角色體系架構

本系統採用**雙層角色體系**，區分平台層級與藍圖層級的角色：

```
角色體系架構
├── 平台層級角色（帳戶體系）
│   ├── 超級管理員 (Super Admin) - 系統全域
│   ├── 組織擁有者 (Organization Owner) - 組織層級
│   ├── 組織管理員 (Organization Admin) - 組織層級
│   └── 一般用戶 (User) - 個人層級
└── 藍圖層級角色（業務角色）
    ├── 專案經理 (Project Manager)
    ├── 工地主任 (Site Director)
    ├── 施工人員 (Worker)
    ├── 品管人員 (QA Staff)
    └── 觀察者 (Observer)
```

**所有權結構**：
- **組織**：必須有一位擁有者 (Owner)，可轉移擁有權
- **團隊**：隸屬於組織，由組織成員組成
- **Bot**：可隸屬於用戶、組織或藍圖（用於自動化工作流程）
- **藍圖**：擁有者只能是**個人用戶**或**組織**（團隊不可直接擁有藍圖）

### 3.1 平台層級角色（帳戶體系）

| 角色 | 說明 | 權限範圍 |
|------|------|----------|
| **超級管理員** | 系統最高權限者 | 管理所有組織、系統設定、全域數據監控 |
| **組織擁有者** | 組織的最高負責人 | 完全控制組織資源、轉移擁有權、刪除組織 |
| **組織管理員** | 組織的管理者 | 管理組織成員、團隊、組織設定（無法刪除組織） |
| **一般用戶** | 平台註冊用戶 | 管理個人資料、個人藍圖、加入組織/團隊 |

### 3.2 藍圖層級角色（業務角色）

這些角色適用於藍圖內的業務操作，**支援自訂角色權限存取矩陣**：

| 角色 | 說明 | 預設權限 |
|------|------|----------|
| **專案經理** | 藍圖的整體規劃與管理者 | 任務結構、里程碑、分配任務、審核 PR |
| **工地主任** | 工地現場最高負責人 | 每日日誌、進度更新、品質協調、問題回報 |
| **施工人員** | 實際執行施工任務 | 回報任務狀態、上傳照片、更新進度 |
| **品管人員** | 負責品質檢查與驗收 | 品質檢查、驗收照片、開立問題單 |
| **觀察者** | 唯讀權限使用者 | 查看進度、報表、照片（無法修改） |

### 3.3 自訂角色權限存取矩陣

系統支援**自訂角色**功能，藍圖擁有者可以：

1. **建立自訂角色**：基於預設角色模板或從頭建立
2. **設定權限矩陣**：針對各功能模組設定存取權限
3. **角色繼承**：自訂角色可繼承預設角色的基礎權限

**預設權限矩陣**（可自訂覆蓋）：

| 功能/角色 | 專案經理 | 工地主任 | 施工人員 | 品管人員 | 觀察者 |
|-----------|:--------:|:--------:|:--------:|:--------:|:------:|
| 建立藍圖 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 管理藍圖設定 | ✅ | 🔶 | ❌ | ❌ | ❌ |
| 建立/編輯任務 | ✅ | ✅ | ❌ | ❌ | ❌ |
| 更新任務進度 | ✅ | ✅ | ✅ | 🔶 | ❌ |
| 上傳任務照片 | ✅ | ✅ | ✅ | ✅ | ❌ |
| 提交每日日誌 | ✅ | ✅ | ✅ | ❌ | ❌ |
| 品質驗收 | ✅ | ✅ | ❌ | ✅ | ❌ |
| 最終驗收 | ✅ | 🔶 | ❌ | 🔶 | ❌ |
| 問題管理 | ✅ | ✅ | ✅ | ✅ | ❌ |
| 查看報表 | ✅ | ✅ | 🔶 | 🔶 | ✅ |
| 審核 PR | ✅ | ❌ | ❌ | ❌ | ❌ |
| Fork 分支 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 檔案管理 | ✅ | ✅ | 🔶 | 🔶 | ❌ |

說明：✅ 完整權限 | 🔶 有限權限 | ❌ 無權限

### 3.4 Bot 所屬關係

Bot（自動化工作流程）可設定以下所屬關係：

| 所屬類型 | 說明 | 使用場景 |
|----------|------|----------|
| **用戶所屬** | Bot 由個人用戶擁有 | 個人自動化任務、私人提醒 |
| **組織所屬** | Bot 由組織擁有 | 組織級自動化、跨藍圖同步 |
| **藍圖所屬** | Bot 綁定特定藍圖 | 藍圖內自動化、進度提醒、逾期警示 |

---

## 4. 功能需求

### 4.0 功能實現狀態摘要與優先級

**開發優先級原則**：
1. 帳戶體系 → 藍圖系統 → 任務系統（主核心）→ 其他模組
2. 每個模組需達到**企業標準+生產水平**後，才開始下一個模組
3. **任務是主核心模組**，其他模組都是圍繞任務開發

| 模組 | 狀態 | 完成度 | 優先級 | 前置依賴 |
|------|------|--------|--------|----------|
| 帳戶體系（工作區切換） | ✅ 基礎完成 | 80% | 🔴 最高 | 無 |
| 藍圖系統（邏輯容器） | ✅ 基礎完成 | 70% | 🔴 最高 | 帳戶體系達標 |
| **任務系統（主核心）** | 🔶 部分完成 | 60% | 🔴 最高 | 藍圖系統達標 |
| **檔案系統** | ⬜ 待實現 | 0% | 🔴 高 | 藍圖系統達標 |
| 施工進度追蹤 | ⬜ 待實現 | 0% | 🟡 高 | 任務系統達標 |
| 品質驗收系統 | ⬜ 待實現 | 0% | 🟡 高 | 任務系統 + 施工進度追蹤達標 |
| 每日施工日誌 | 🔶 部分完成 | 40% | 🟡 高 | 任務系統 + 藍圖系統 + 帳戶體系 |
| 問題追蹤系統 | ⬜ 待實現 | 0% | 🟢 中 | 任務系統達標 |
| 協作溝通模組 | 🔶 部分完成 | 30% | 🟢 中 | 任務系統達標 |
| 報表與分析 | ⬜ 待實現 | 0% | 🟢 中 | 多模組資料整合 |
| Git-like 分支系統 | ⬜ 待實現 | 0% | 🔵 未來 | 藍圖系統達標 |
| 財務系統（簡化） | ⬜ 待實現 | 0% | 🔵 最後 | 施工進度追蹤 + 任務系統 |
| 人力資源管理 | ⬜ 未來規劃 | 0% | 🔵 最後 | 任務系統 + 財務系統 |

### 4.1 帳戶體系與工作區切換 🔶 需強化（優先級：🔴 最高）

**目標**：上下文切換器需達到**企業標準+生產水平**

**現有實現**:

工作區上下文切換系統已完整實現，提供以下核心功能：

- **四種工作區類型支援**:
  - 個人工作區 (USER)：個人任務和藍圖管理
  - 組織工作區 (ORGANIZATION)：組織層級的資源管理
  - 團隊工作區 (TEAM)：團隊協作空間
  - 機器人工作區 (BOT)：自動化工作流程

- **核心功能**:
  - 無縫工作區切換（Header 快速切換）
  - 菜單自動同步（根據上下文動態調整）
  - 上下文持久化（記住上次選擇）
  - 組織與團隊資料自動載入
  - 上下文相關的路由導航

- **架構特點**:
  - 採用 Facade 模式整合多個底層服務
  - Angular Signals 響應式狀態管理
  - Effect 監聽認證狀態變化
  - 完善的錯誤處理和重載機制

**企業標準強化需求**:

- ⬜ **組織擁有權管理**:
  - 組織擁有者 (Owner) 角色實現
  - 擁有權轉移功能
  - 組織刪除保護機制

- ⬜ **效能與安全強化**:
  - 帳戶資料快取策略（Redis/LocalStorage）
  - 組織成員清單分頁載入（支援大型組織 1000+ 人）
  - Session 自動刷新機制
  - 操作審計日誌

- ⬜ **Bot 所屬關係**:
  - Bot 可設定所屬：用戶 / 組織 / 藍圖
  - Bot 權限邊界控制

### 4.2 藍圖系統 🔶 需強化（優先級：🔴 最高）

**目標**：與帳戶體系良好設計後，達到**企業標準+生產水平**

**前置依賴**：帳戶體系達到企業標準

**核心理念**：**藍圖是邏輯容器**，提供資料隔離、上下文共享、多模組擴展

**已完成功能**:

- ✅ **藍圖邏輯容器 (BlueprintShellComponent)**:
  - 資料隔離（每個藍圖獨立上下文）
  - 上下文共享（子模組共用狀態）
  - 路由嵌套支援
  
- ✅ **藍圖 CRUD (BlueprintStore + BlueprintService)**:
  - 藍圖建立、讀取、更新、刪除
  - 藍圖狀態管理（草稿、已發布、已封存）
  - 藍圖搜尋功能
  - 按擁有者載入藍圖
  - 公開藍圖載入（市集概念）

- ✅ **工作區系統 (WorkspaceService)**:
  - 從藍圖實例化工作區
  - 工作區 CRUD 操作
  - 按租戶載入工作區
  - 工作區狀態管理（活躍、已封存）

**企業標準強化需求**:

- ⬜ **藍圖擁有權規則強化**:
  - 藍圖擁有者只能是**個人用戶**或**組織**（不能是團隊）
  - 擁有權轉移功能
  - 藍圖權限邊界明確

- ⬜ **藍圖設定**:
  - 工作日曆（週休/假日）
  - 通知規則
  - 自訂欄位
  - 進度計算規則

**未來功能（Phase 2）**:

- ⬜ **Git-like 分支系統**:
  - 主分支（Main Branch）管理
  - Fork 給協作組織（1:1 承攬關係）
  - 組織分支建立與管理
  - Pull Request 提交與審核
  - PR 合併與衝突解決
  
- ⬜ **分支權限控制**:
  - 擁有者：完全控制任務結構
  - 協作組織：僅操作承攬欄位（進度、狀態、照片）
  - 觀察者：唯讀存取

### 4.3 任務系統 🔶 部分完成（優先級：🔴 最高）

**目標**：達到**企業標準+生產水平**

**前置依賴**：藍圖邏輯容器達到企業標準

**核心理念**：**任務是主核心模組**，工地管理的一切操作都圍繞任務展開

**已完成功能**:

- ✅ **樹狀任務結構 (TaskTreeComponent)**:
  - 無層級限制的階層結構（使用 NzTreeView）
  - 父子任務關聯（pre-built children map，O(1) 查詢）
  - 任務展開/收合
  - 視覺化縮排顯示
  - OnPush 變更偵測策略優化
  
- ✅ **表格視圖 (TaskTableComponent)**:
  - 任務列表表格顯示
  - 支援排序與篩選

- ✅ **視圖切換 (TaskListComponent)**:
  - 樹狀圖與表格視圖切換
  - 搜尋功能
  - 任務統計顯示

- ✅ **任務狀態系統**:
  - 狀態：待辦、進行中、審查中、完成、取消
  - 優先級：最低、低、中、高、最高
  - 類型：任務、里程碑、錯誤、功能、改進

**待實現功能**:

- ⬜ **任務膠囊狀態顯示增強**:
  - 負責人頭像（可多人）
  - 截止日期（過期標紅）
  - 問題數量徽章
  - 層級深度指示器
  
- ⬜ **完工圖片顯示**:
  - 任務卡片內嵌縮圖
  - 點擊放大檢視
  - 支援多張圖片輪播
  - 圖片上傳進度顯示
  - 圖片 EXIF 資訊顯示（拍攝時間、地點）

- ⬜ **任務排序與拖拉**:
  - 拖拉調整任務順序
  - 拖拉移動任務層級

- ⬜ **任務操作完善**:
  - 任務建立對話框
  - 任務編輯對話框
  - 任務刪除確認
  - 任務指派（個人/團隊/組織）
  - 任務評論與討論
  - 任務時間記錄

### 4.4 檔案系統 ⬜ 待實現（優先級：🔴 高）

**前置依賴**：藍圖邏輯容器達到企業標準

**說明**：藍圖內的檔案管理系統，用於存儲與任務相關的文件、圖紙、規格書等

- **檔案管理**:
  - 檔案上傳（支援多檔案批次）
  - 檔案分類與標籤
  - 資料夾結構管理
  - 檔案版本控制
  - 檔案預覽（圖片、PDF）
  
- **檔案關聯**:
  - 關聯至任務
  - 關聯至驗收記錄
  - 關聯至日誌
  - 關聯至問題單
  
- **檔案安全**:
  - 存取權限控制
  - 下載記錄追蹤
  - 檔案加密（選項）
  - 防止未授權分享

- **存儲整合**:
  - Supabase Storage 整合
  - CDN 加速
  - 自動縮圖生成
  - 大檔案分片上傳

### 4.5 施工進度追蹤 ⬜ 待實現（優先級：🟡 高）

**前置依賴**：任務系統（含任務樹）達到企業標準+生產水平

- **進度儀表板**:
  - 整體完成率顯示
  - 計劃 vs 實際進度曲線圖
  - 里程碑追蹤時間軸
  - 進度風險預警
  - 關鍵路徑標示
  
- **進度更新**:
  - 批次進度更新
  - 進度計算規則（加權/等權）
  - 自動進度彙總（子任務→父任務）
  - 進度歷史記錄
  
- **預警機制**:
  - 進度落後警示（黃燈/紅燈）
  - 任務逾期提醒
  - 里程碑逼近通知
  - 客製化警示規則

### 4.6 品質驗收系統 ⬜ 待實現（優先級：🟡 高）

**前置依賴**：任務系統 + 施工進度追蹤系統達到企業標準+生產水平

- **品質檢查清單**:
  - 清單模板管理
  - 自訂檢查項目
  - 檢查項目分類
  - 評分標準定義
  
- **驗收流程**:
  - 發起驗收申請
  - 品管人員指派
  - 檢查項目逐一確認
  - 評分與備註
  - 驗收結果判定（通過/不通過/有條件通過）
  
- **驗收照片**:
  - 前/中/後對比照片
  - 缺陷標記照片
  - 照片批次上傳
  - 照片分類標籤
  
- **串驗收功能**:
  - 多階段驗收流程定義
  - 驗收鏈追蹤
  - 階段性驗收結果記錄
  - 驗收簽核流程
  
- **最終驗收**:
  - 初步驗收
  - 最終驗收
  - 保固驗收
  - 責任切割記錄
  - 驗收報告產出

### 4.7 每日施工日誌 🔶 部分完成（優先級：🟡 高）

**前置依賴**：任務系統 + 藍圖系統 + 帳戶體系優化

**已完成功能**:

- ✅ **日誌列表框架 (DiaryListComponent)**:
  - 日誌清單檢視
  - 按月份篩選
  - 搜尋功能（標題、摘要、作者）
  - DiaryStore 狀態管理
  - DiaryViewModel 顯示模型
  - OnPush 變更偵測策略

- ✅ **天氣資料結構**:
  - 天氣圖標映射（晴天、多雲、雨天、暴風、雪天、霧天）
  - 天氣資料結構準備（手動輸入）

**待實現功能**:

- ⬜ **日誌填寫表單**:
  - 日期選擇（預設當日）
  - 工作摘要（文字描述）
  - 工作時數記錄
  - 工人數量統計
  - 材料使用記錄
  - 機具使用記錄
  - 天氣手動選擇
  
- ⬜ **照片管理**:
  - 批次照片上傳
  - 照片壓縮優化
  - 離線照片暫存
  - EXIF 資訊自動擷取
  - 照片分類標籤
  - 照片浮水印（選項）
  
- ⬜ **日誌匯出與簽核**:
  - 日誌匯出（PDF/Excel）
  - 日誌簽核流程

### 4.8 問題追蹤系統 ⬜ 待實現（優先級：🟢 中）

**前置依賴**：任務系統達到企業標準

- **問題開立**:
  - 手動開立問題
  - 驗收不合格自動開立
  - 系統檢測自動開立
  - 問題分類
  - 嚴重程度（低/中/高/緊急）
  
- **問題處理**:
  - 問題指派
  - 處理進度更新
  - 處理記錄追蹤
  - 問題照片上傳
  - 問題關閉確認
  
- **問題流程**:
  - 新建 → 指派 → 處理中 → 待確認 → 已解決 → 已關閉
  - 重新開啟功能
  - 轉移處理人
  - 升級問題嚴重度
  
- **跨分支同步**:
  - 問題即時同步至主分支
  - Realtime 訂閱更新
  - 問題狀態統一可見

### 4.9 協作溝通模組 🔶 部分完成（優先級：🟢 中）

**前置依賴**：任務系統達到企業標準

**已完成功能**:

- ✅ **待辦系統框架 (TodoStore + TodoListComponent)**:
  - TodoStore 狀態管理
  - TodoListComponent 基礎 UI

**待實現功能**:

- ⬜ **討論區**:
  - 實體關聯討論（任務/問題/PR/驗收）
  - 巢狀回覆
  - @提及通知
  - 附件支援
  - Realtime 即時更新
  
- **通知中心**:
  - 站內通知
  - Email 通知
  - 推播通知（未來版本）
  - 通知規則自訂
  - 批次已讀
  
- ⬜ **待辦中心增強**:
  - 個人待辦清單
  - 五狀態分類：
    - 🟦 待執行
    - 🟧 品管中
    - 🟥 驗收中
    - ⚠️ 問題追蹤
    - ✅ 已完成
  - 優先級排序
  - 截止日期提醒

### 4.10 報表與分析 ⬜ 待實現（優先級：🟢 中）

**前置依賴**：多模組資料整合（任務、進度、品質、日誌）

- **進度報表**:
  - 整體進度報表
  - 分區/分階段進度
  - 進度趨勢分析
  - 計劃 vs 實際對比
  
- **品質報表**:
  - 驗收統計報表
  - 缺陷率分析
  - 品質趨勢圖
  - 問題分類統計
  
- **工時報表**:
  - 人員工時統計
  - 任務工時分析
  - 工時趨勢圖
  - 效率指標計算
  
- **報表匯出**:
  - PDF 格式
  - Excel 格式
  - 報表排程（自動生成）
  - 報表訂閱

### 4.11 財務系統（簡化版）⬜ 待實現（優先級：🔵 最後）

**前置依賴**：施工進度追蹤 + 任務系統達到生產水平

**說明**：簡化版財務模組，專注於按進度請款，避免功能過度複雜。此模組將作為最後開發項目，以確保系統核心功能不被財務邏輯限制。

- **進度請款**:
  - 按任務/里程碑完成度請款
  - 多期請款管理
  - 請款單生成
  - 請款狀態追蹤（待審核/已核准/已請款/已收款）
  
- **簡單分析**:
  - 累計請款金額
  - 待請款金額
  - 請款進度曲線
  - 逾期應收提醒
  
- **匯出功能**:
  - 請款報表 PDF/Excel
  - 發票資料匯出

> ⚠️ **設計原則**：此模組採用最小化設計，預留擴展介面。核心功能不應依賴財務邏輯，確保即使無財務模組，系統仍可正常運作。

### 4.12 人力資源管理 ⬜ 未來規劃（優先級：🔵 最後）

**前置依賴**：任務系統 + 財務系統

**說明**：極簡化人力資源模組，以任務為主體進行開發。作為未來版本規劃，不納入初版範圍。

- **以任務為主體的人力管理**:
  - 人員指派至任務
  - 任務工時記錄
  - 人員技能標籤
  - 人員可用性查詢
  
- **基礎統計**:
  - 人員任務負載
  - 工時統計
  - 人員效率指標

> ⚠️ **設計原則**：人力管理功能圍繞任務展開，不實現複雜的薪資、出勤、績效等傳統 HR 功能。

---

## 5. 使用者體驗

### 5.1 進入點與首次使用者流程

- **註冊流程**:
  1. Email 註冊或 Google/GitHub OAuth
  2. 完成個人資料設定
  3. 選擇角色偏好
  4. 引導式功能介紹
  5. 建立/加入組織
  
- **首次登入**:
  1. 儀表板總覽
  2. 功能導覽教學
  3. 快速建立第一個藍圖（或加入現有藍圖）
  4. 設定通知偏好

### 5.2 核心體驗

- **儀表板首頁**:
  - 待辦事項快速存取
  - 進度摘要卡片
  - 最近活動時間軸
  - 快速操作按鈕
  - 確保載入時間 < 3 秒
  
- **任務樹狀圖**:
  - 流暢的展開/收合動畫
  - 拖拉排序即時反饋
  - 膠囊狀態一目瞭然
  - 側邊詳情面板
  - 確保大量任務（1000+）仍保持流暢
  
- **照片上傳**:
  - 批次選擇上傳
  - 上傳進度顯示
  - 背景上傳（不阻塞操作）
  - 壓縮優化（自動）
  - 離線暫存（網路恢復後同步）
  
- **即時協作**:
  - 多人同時編輯提示
  - 即時留言更新
  - 狀態變更即時反映
  - 衝突處理機制

### 5.3 進階功能與邊界情況

- **離線支援**:
  - Service Worker 快取
  - 離線資料讀取
  - 離線操作暫存
  - 同步衝突解決
  - 同步狀態指示
  
- **大量資料處理**:
  - 虛擬捲動（Virtual Scrolling）
  - 分頁載入
  - 懶載入圖片
  - 資料快取策略
  
- **錯誤處理**:
  - 友善錯誤訊息
  - 自動重試機制
  - 錯誤回報功能
  - 降級體驗

### 5.4 UI/UX 亮點

- **視覺設計**:
  - 符合 ng-zorro-antd 設計語言
  - 深色/淺色主題切換
  - 響應式設計（桌面/平板/手機）
  - 一致的圖示系統
  
- **互動設計**:
  - 骨架屏載入動畫
  - 操作成功/失敗反饋
  - 危險操作確認
  - 鍵盤快捷鍵支援
  
- **無障礙設計**:
  - ARIA 標籤
  - 螢幕閱讀器支援
  - 色盲友善配色
  - 字級調整

---

## 6. 敘事

小明是一家營造公司的工地主任，每天需要管理超過 50 項施工任務、協調 30 位工人、處理 3 家分包商的工作回報。過去，他使用 Excel 追蹤進度、LINE 群組溝通協調、紙本表單記錄品質檢查，工作繁瑣且容易出錯。

導入「工地施工進度追蹤管理系統」後，小明每天早上打開系統，就能在儀表板看到所有任務的即時進度。樹狀圖上的膠囊清楚顯示哪些任務延遲、哪些待驗收、哪些有問題需處理。

下午巡視工地時，小明使用手機 App 直接拍照上傳，系統自動記錄照片的時間與位置。完成任務後，他更新任務狀態並附上完工照片，系統即時同步更新進度。

品管人員老李收到驗收通知，按照系統的檢查清單逐項確認，發現一處缺陷後直接拍照標記，系統自動開立問題單並通知相關人員。所有問題都會同步更新，專案經理在辦公室就能即時掌握。

到了月底，財務部門需要進度報告，系統自動生成包含進度曲線、品質統計、工時記錄的完整報告，一鍵匯出 PDF 就能交付。

透過這套系統，小明每天節省 2 小時的文書作業時間，專案延遲率降低 30%，品質問題發現時間縮短 50%，業主滿意度大幅提升。

---

## 7. 成功指標

### 7.1 使用者指標

| 指標 | 目標值 | 衡量方式 |
|------|--------|----------|
| 日活躍使用者 (DAU) | 專案成員 80%+ | 系統登入統計 |
| 任務更新頻率 | 每日至少 1 次/人 | 任務操作記錄 |
| 日誌提交率 | 工作日 95%+ | 日誌提交統計 |
| 照片上傳量 | 每任務 3+ 張 | 照片上傳統計 |
| 功能使用率 | 核心功能 70%+ | 功能使用統計 |
| 使用者滿意度 (NPS) | > 50 | 定期問卷調查 |

### 7.2 商業指標

| 指標 | 目標值 | 衡量方式 |
|------|--------|----------|
| 專案延遲率降低 | 30%+ | 專案完成統計 |
| 文書作業時間節省 | 40%+ | 使用者回饋 |
| 品質問題發現時間 | 縮短 50% | 問題開立統計 |
| 返工率降低 | 20%+ | 品質報表 |
| 客戶滿意度 | 提升 25%+ | 客戶回饋 |
| 系統採用率 | 新專案 100% | 藍圖建立統計 |

### 7.3 技術指標

| 指標 | 目標值 | 衡量方式 |
|------|--------|----------|
| 頁面載入時間 | < 3 秒 | 效能監控 |
| API 回應時間 | < 500ms (P95) | API 監控 |
| 系統可用性 | 99.9% | 監控告警 |
| 錯誤率 | < 0.1% | 錯誤追蹤 |
| 離線同步成功率 | 99%+ | 同步日誌 |
| 照片上傳成功率 | 99.5%+ | 上傳統計 |

---

## 8. 技術考量

### 8.1 現有技術架構

專案已採用以下現代化技術模式：

**前端架構模式**:

- **Vertical Slice Architecture**: 功能按垂直切片組織（Blueprint Feature）
  ```
  features/blueprint/
  ├── shell/          # 邏輯容器
  ├── data-access/    # 狀態管理、服務、Repository
  ├── domain/         # 領域模型、枚舉、介面
  ├── ui/             # 展示元件
  └── utils/          # 工具函數
  ```

- **Facade Pattern**: Store 層作為統一 API 對外介面
  - `BlueprintStore`, `TaskStore`, `DiaryStore`, `TodoStore`
  - 隱藏內部服務複雜度
  - 提供高階 API

- **Angular Signals**: 響應式狀態管理
  - `signal()` 可寫狀態
  - `computed()` 衍生狀態
  - `effect()` 副作用處理

- **OnPush Change Detection**: 效能優化策略
  - 元件使用 `ChangeDetectionStrategy.OnPush`
  - 減少不必要的變更偵測

- **Standalone Components**: Angular 20 獨立元件
  - 無需 NgModule
  - 直接 import 相依

### 8.2 整合點

- **Supabase Auth**: 用戶認證、Session 管理、JWT Token
- **Supabase Database**: PostgreSQL 資料存儲、RLS 權限控制
- **Supabase Storage**: 照片與文件存儲、CDN 分發
- **Supabase Realtime**: 即時訂閱更新、協作同步
- **Supabase Edge Functions**: 複雜業務邏輯、第三方 API 整合
- **地圖服務**: Google Maps 或 OpenStreetMap（地點標記）
- **Email 服務**: Supabase 內建或 SendGrid（通知郵件）

### 8.3 資料存儲與隱私

- **資料分類**:
  - 敏感資料：用戶密碼（已 Hash）、認證 Token
  - 個人資料：姓名、Email、電話、頭像
  - 業務資料：任務、日誌、驗收記錄、照片
  - 系統資料：設定、日誌、快取
  
- **存儲策略**:
  - 照片：Supabase Storage + CDN，自動壓縮縮圖
  - 文件：Supabase Storage，版本控制
  - 快取：PostgreSQL analytics_cache 表 + 前端 IndexedDB
  
- **隱私保護**:
  - RLS 政策確保資料隔離
  - 照片 EXIF 敏感資訊處理（選擇性保留）
  - 軟刪除機制（30 天保留期）
  - 資料匯出功能（GDPR 合規）
  
- **備份策略**:
  - 每日自動備份
  - 跨區域備援
  - 30 天備份保留

### 8.4 擴展性與效能

- **前端效能**:
  - 懶載入路由與元件
  - 虛擬捲動處理大量資料
  - Service Worker 離線快取
  - 圖片懶載入與漸進式載入
  - Angular OnPush 變更偵測策略
  
- **後端效能**:
  - PostgreSQL 索引優化
  - Materialized Views 報表加速
  - RPC 函數批次操作
  - Edge Functions 邊緣運算
  
- **擴展性設計**:
  - 多租戶架構（RLS 隔離）
  - 資料分區策略（按時間/組織）
  - 讀寫分離（必要時）
  - CDN 靜態資源加速

### 8.5 潛在挑戰

| 挑戰 | 風險等級 | 應對策略 |
|------|----------|----------|
| 工地網路不穩定 | 高 | Service Worker 離線支援、背景同步、衝突解決機制 |
| 大量照片上傳 | 高 | 背景上傳、自動壓縮、分片上傳、斷點續傳 |
| 複雜權限邏輯 | 中 | 完善的 RLS 政策、前端權限快取、權限測試套件 |
| 即時同步效能 | 中 | Realtime 訂閱優化、訊息聚合、節流機制 |
| 報表生成效能 | 中 | Materialized Views、預計算快取、報表排程 |
| 多組織協作衝突 | 中 | PR 機制、衝突偵測、合併策略 |

### 8.6 上下文共享架構

> **奧卡姆剃刀原則**：上下文設計以「最小必要共享」為原則，避免過度耦合

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        平台層級（Platform Context）                       │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  WorkspaceContextFacade                                             │ │
│  │  • currentContext: Signal<WorkspaceContext>                        │ │
│  │  • contextType: USER | ORGANIZATION | TEAM | BOT                   │ │
│  │  • contextId: string (account_id)                                   │ │
│  │  • permissions: Signal<string[]>                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      藍圖層級（Blueprint Context）                        │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  BlueprintShellComponent (邏輯容器)                                  │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │  BlueprintStore (Facade)                                       │  │ │
│  │  │  • blueprintId: Signal<string>                                 │  │ │
│  │  │  • workspaceId: Signal<string>                                 │  │ │
│  │  │  • ownerContext: inherited from Platform                       │  │ │
│  │  │  • blueprintRole: Signal<BlueprintRole>                        │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│   模組層級           │ │   模組層級           │ │   模組層級           │
│   TaskStore         │ │   DiaryStore        │ │   TodoStore         │
│   • 繼承藍圖上下文    │ │   • 繼承藍圖上下文    │ │   • 繼承藍圖上下文    │
│   • blueprintId     │ │   • blueprintId     │ │   • blueprintId     │
│   • ownerContext    │ │   • ownerContext    │ │   • ownerContext    │
└─────────────────────┘ └─────────────────────┘ └─────────────────────┘
```

**上下文傳遞規則**：

| 層級 | 提供者 | 消費者 | 傳遞方式 |
|------|--------|--------|----------|
| 平台 → 藍圖 | WorkspaceContextFacade | BlueprintShellComponent | `inject()` DI |
| 藍圖 → 模組 | BlueprintStore | TaskStore, DiaryStore... | Route Params + inject() |
| 模組 → UI | XxxStore | XxxComponent | Angular Signals |

**已完成標記**：
- ✅ `WorkspaceContextFacade` - 平台層上下文切換
- ✅ `BlueprintShellComponent` - 藍圖邏輯容器
- ✅ `BlueprintStore` - 藍圖狀態管理
- ✅ 模組層 Store 基礎結構（Task, Diary, Todo）

### 8.7 專案資料夾結構規範

> **奧卡姆剃刀原則**：每個資料夾職責單一、命名清晰、結構扁平

```
src/app/
├── core/                           # ✅ 已完成
│   ├── facades/                    # Facade 模式統一 API
│   │   └── account/
│   │       └── workspace-context.facade.ts  ✅
│   ├── guards/                     # 路由守衛
│   ├── interceptors/               # HTTP 攔截器
│   └── services/                   # 全域服務
│
├── shared/                         # 🔶 部分完成
│   ├── components/                 # 共用元件
│   ├── directives/                 # 共用指令
│   ├── pipes/                      # 共用管道
│   └── utils/                      # 共用工具
│
└── features/                       # 功能模組（Vertical Slice）
    ├── blueprint/                  # ✅ 核心功能區
    │   ├── blueprint.routes.ts     # 路由配置
    │   │
    │   ├── shell/                  # 邏輯容器層
    │   │   ├── blueprint-shell/    # ✅ 藍圖外殼元件
    │   │   └── dialogs/            # 對話框元件
    │   │
    │   ├── domain/                 # 領域層
    │   │   ├── enums/              # ✅ 枚舉定義
    │   │   ├── interfaces/         # ✅ 介面定義
    │   │   ├── models/             # ✅ 領域模型
    │   │   └── types/              # ✅ 類型定義
    │   │
    │   ├── data-access/            # 資料存取層
    │   │   ├── stores/             # ✅ 狀態管理 (Facade)
    │   │   │   ├── blueprint.store.ts
    │   │   │   ├── task.store.ts
    │   │   │   ├── diary.store.ts
    │   │   │   └── todo.store.ts
    │   │   ├── services/           # ✅ 業務服務
    │   │   └── repositories/       # 資料倉儲 (Supabase)
    │   │
    │   ├── ui/                     # 展示層
    │   │   ├── task/               # 🔶 任務模組
    │   │   │   ├── task-tree/      # ✅ 樹狀圖
    │   │   │   ├── task-table/     # ✅ 表格
    │   │   │   └── shared/         # 共用元件
    │   │   ├── diary/              # 🔶 日誌模組
    │   │   │   └── diary-list/     # ✅ 列表
    │   │   ├── todo/               # 🔶 待辦模組
    │   │   │   └── todo-list/      # ✅ 列表
    │   │   ├── file/               # ⬜ 檔案模組（待建立）
    │   │   ├── progress/           # ⬜ 進度模組（待建立）
    │   │   └── quality/            # ⬜ 品質模組（待建立）
    │   │
    │   ├── guards/                 # 功能守衛
    │   ├── pipes/                  # 功能管道
    │   └── utils/                  # ✅ 工具函數
    │
    └── dashboard/                  # ⬜ 儀表板（待建立）
```

### 8.8 命名規範

> **奧卡姆剃刀原則**：命名簡潔、語意明確、一致性優先

#### 8.8.1 檔案命名（kebab-case）

| 類型 | 命名格式 | 範例 | 狀態 |
|------|----------|------|------|
| Component | `{name}.component.ts` | `task-tree.component.ts` | ✅ |
| Store | `{name}.store.ts` | `blueprint.store.ts` | ✅ |
| Service | `{name}.service.ts` | `workspace.service.ts` | ✅ |
| Interface | `{name}.interface.ts` | `task.interface.ts` | ✅ |
| Model | `{name}.model.ts` | `blueprint.model.ts` | ✅ |
| Enum | `{name}.enum.ts` | `task-status.enum.ts` | ✅ |
| Guard | `{name}.guard.ts` | `blueprint-access.guard.ts` | ✅ |
| Pipe | `{name}.pipe.ts` | `duration-format.pipe.ts` | ✅ |
| Utils | `{name}.utils.ts` | `date-calculator.ts` | ✅ |
| Validator | `{name}.validators.ts` | `task.validators.ts` | ✅ |

#### 8.8.2 函數前綴規範

| 前綴 | 用途 | 範例 |
|------|------|------|
| `load` | 載入資料 | `loadBlueprintsByOwner()` |
| `create` | 建立資源 | `createBlueprint()` |
| `update` | 更新資源 | `updateTask()` |
| `delete` | 刪除資源 | `deleteTask()` |
| `get` | 取得單一值 | `getUserAccountId()` |
| `find` | 查詢多筆 | `findTasksByStatus()` |
| `is` | 布林判斷 | `isOrgAdmin()` |
| `has` | 存在判斷 | `hasPermission()` |
| `can` | 權限判斷 | `canEditBlueprint()` |
| `on` | 事件處理 | `onTaskSelect()` |
| `handle` | 處理器 | `handleError()` |
| `switch` | 切換狀態 | `switchToOrganization()` |

#### 8.8.3 資料表命名（snake_case）

| 命名規則 | 範例 | 說明 |
|----------|------|------|
| 主表 | `accounts`, `tasks`, `blueprints` | 複數名詞 |
| 關聯表 | `organization_members`, `team_bots` | `{parent}_{children}` |
| 中間表 | `task_assignees`, `blueprint_tags` | `{entity}_{relation}` |

**資料表狀態**：

| 表名 | 用途 | 狀態 |
|------|------|------|
| `accounts` | 帳戶（User/Organization/Bot） | ✅ 已完成 |
| `organization_members` | 組織成員關聯 | ✅ 已完成 |
| `teams` | 團隊 | ✅ 已完成 |
| `team_members` | 團隊成員關聯 | ✅ 已完成 |
| `team_bots` | 團隊機器人關聯 | ✅ 已完成 |
| `blueprints` | 藍圖 | ⬜ 待建立 |
| `workspaces` | 工作區 | ⬜ 待建立 |
| `tasks` | 任務 | ⬜ 待建立 |
| `task_attachments` | 任務附件 | ⬜ 待建立 |
| `diaries` | 日誌 | ⬜ 待建立 |
| `diary_photos` | 日誌照片 | ⬜ 待建立 |

#### 8.8.4 欄位命名規範（最小必要欄位）

> **奧卡姆剃刀原則**：只建立必要欄位，避免「以防萬一」的冗餘

**通用欄位**：
```sql
-- 必要欄位（所有表）
id            UUID PRIMARY KEY DEFAULT gen_random_uuid()
created_at    TIMESTAMPTZ DEFAULT now() NOT NULL
updated_at    TIMESTAMPTZ DEFAULT now() NOT NULL

-- 關聯欄位（按需）
{parent}_id   UUID REFERENCES {parent}(id) ON DELETE CASCADE

-- 擁有權欄位（按需）
owner_id      UUID REFERENCES accounts(id)
owner_type    TEXT CHECK (owner_type IN ('User', 'Organization'))

-- 狀態欄位（按需，限制選項）
status        TEXT CHECK (status IN ('active', 'archived', 'deleted'))
```

**避免的反模式**：
- ❌ 預留未使用欄位（如 `reserved_1`, `extra_data`）
- ❌ 過度細分的時間戳（如 `viewed_at`, `touched_at`）
- ❌ 冗餘的計數欄位（應使用 `COUNT()` 查詢）
- ❌ 過長的 JSON 欄位（應正規化為關聯表）

### 8.9 RLS 與觸發器設計規範

> **設計原則**：安全第一、效能優化、避免遞迴

#### 8.9.1 RLS 政策架構

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           RLS 政策層級架構                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Layer 1: Helper Functions (SECURITY DEFINER)                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  get_user_account_id()     → 取得當前用戶 account_id           │   │
│  │  is_org_member(org_id)     → 檢查是否為組織成員                 │   │
│  │  is_org_admin(org_id)      → 檢查是否為組織管理員               │   │
│  │  is_team_member(team_id)   → 檢查是否為團隊成員                 │   │
│  │  is_team_leader(team_id)   → 檢查是否為團隊領導                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  Layer 2: RLS Policies (調用 Helper Functions)                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  accounts_select_policy    → 可查看自己、所屬組織、所屬團隊     │   │
│  │  accounts_insert_policy    → 僅可建立自己的帳戶                 │   │
│  │  accounts_update_policy    → 僅可更新自己的資料                 │   │
│  │  organizations_policy      → 組織成員可查看、管理員可編輯       │   │
│  │  teams_policy              → 團隊成員可查看、領導可編輯         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**已完成的 RLS Helper Functions**：

| 函數名 | 用途 | 狀態 |
|--------|------|------|
| `get_user_account_id()` | 取得當前用戶 account_id（防遞迴） | ✅ |
| `is_org_member(org_id)` | 檢查組織成員身份 | ✅ |
| `is_org_admin(org_id)` | 檢查組織管理員身份 | ✅ |
| `is_team_member(team_id)` | 檢查團隊成員身份 | ✅ |
| `is_team_leader(team_id)` | 檢查團隊領導身份 | ✅ |

**RLS 設計要點**：

1. **避免無限遞迴**
   ```sql
   -- ✅ 正確：使用 SECURITY DEFINER + row_security = off
   CREATE FUNCTION get_user_account_id() RETURNS UUID
   LANGUAGE plpgsql SECURITY DEFINER SET row_security = off
   AS $$ ... $$;
   
   -- ❌ 錯誤：在 RLS 政策中直接查詢受保護的表
   CREATE POLICY "..." ON accounts
   USING (id IN (SELECT account_id FROM organization_members WHERE ...));
   ```

2. **使用 Helper Function 封裝複雜邏輯**
   ```sql
   -- ✅ 正確：調用預定義函數
   CREATE POLICY "org_members_select" ON organizations
   FOR SELECT USING (is_org_member(id));
   
   -- ❌ 錯誤：內聯複雜查詢
   CREATE POLICY "..." ON organizations
   FOR SELECT USING (EXISTS (SELECT 1 FROM ... WHERE ...));
   ```

#### 8.9.2 觸發器設計

**已完成的觸發器**：

| 觸發器 | 表 | 事件 | 用途 | 狀態 |
|--------|-----|------|------|------|
| `handle_new_user` | `auth.users` | INSERT | 自動建立 accounts 記錄 | ✅ |
| `add_creator_as_org_owner` | `accounts` | INSERT | 組織建立者自動成為 owner | ✅ |
| `auto_add_team_creator` | `teams` | INSERT | 團隊建立者自動成為 leader | ✅ |

**待建立的觸發器**：

| 觸發器 | 表 | 事件 | 用途 | 狀態 |
|--------|-----|------|------|------|
| `update_task_progress` | `tasks` | UPDATE | 子任務完成時更新父任務進度 | ⬜ |
| `auto_create_activity_log` | `*` | INSERT/UPDATE/DELETE | 自動記錄操作日誌 | ⬜ |
| `notify_task_assignee` | `task_assignees` | INSERT | 任務指派時發送通知 | ⬜ |

**觸發器設計原則**：

1. **單一職責**：一個觸發器只做一件事
2. **效能考量**：避免在觸發器中執行耗時操作
3. **錯誤處理**：使用 `BEGIN ... EXCEPTION ... END` 包裹
4. **日誌記錄**：重要操作記錄到審計日誌

#### 8.9.3 藍圖相關資料表設計（待建立）

```sql
-- blueprints: 藍圖主表
CREATE TABLE blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  owner_id UUID NOT NULL REFERENCES accounts(id),
  owner_type TEXT NOT NULL CHECK (owner_type IN ('User', 'Organization')),
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  settings JSONB DEFAULT '{}',  -- 工作日曆、通知規則等
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 藍圖 RLS: 擁有者可完全操作，公開藍圖可被所有人查看
CREATE POLICY "blueprints_select" ON blueprints FOR SELECT
USING (
  owner_id = get_user_account_id()
  OR status = 'published'
  OR is_org_member(owner_id)
);

-- tasks: 任務主表（藍圖內）
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'review', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('lowest', 'low', 'medium', 'high', 'highest')),
  task_type TEXT DEFAULT 'task' CHECK (task_type IN ('task', 'milestone', 'bug', 'feature', 'improvement')),
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 任務 RLS: 繼承藍圖權限
CREATE POLICY "tasks_select" ON tasks FOR SELECT
USING (
  blueprint_id IN (
    SELECT id FROM blueprints 
    WHERE owner_id = get_user_account_id()
      OR status = 'published'
      OR is_org_member(owner_id)
  )
);
```

### 8.10 補充技術設計規範

> **設計原則**：極簡方向、明確重點、避免過度設計

#### 8.10.1 完工圖片架構設計

**方向**：獨立表設計，避免效能瓶頸

```sql
-- task_attachments: 任務附件獨立表（支援大量圖片 + 進階查詢）
CREATE TABLE task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,          -- Supabase Storage 路徑
  file_type TEXT NOT NULL,          -- image/jpeg, image/png, etc.
  thumbnail_path TEXT,              -- 縮圖路徑（自動生成）
  file_size INTEGER,                -- bytes
  exif_taken_at TIMESTAMPTZ,        -- EXIF 拍攝時間
  exif_location POINT,              -- EXIF 經緯度
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES accounts(id)
);
CREATE INDEX idx_task_attachments_task ON task_attachments(task_id);
```

**縮圖顯示策略**：任務卡片顯示前 3 張縮圖 + 數量徽章（+N）

---

#### 8.10.2 膠囊狀態顯示與虛擬捲動

**ng-zorro-antd/tree-view 現代化設計方向**：

```typescript
// 使用 nz-tree-virtual-scroll-view 處理大量任務
import { NzTreeViewModule } from 'ng-zorro-antd/tree-view';
import { CdkVirtualScrollViewport } from '@angular/cdk/scrolling';

// 膠囊狀態顯示設計
interface TaskCapsule {
  avatar: string[];           // 負責人頭像（最多3個 + "+N"）
  dueStatus: 'normal'|'warning'|'overdue';  // 截止日狀態
  issueCount: number;         // 問題徽章數
  progress: number;           // 進度百分比
  priority: PriorityLevel;    // 優先級圖標
}

// 虛擬捲動設定（itemSize = 每行高度 px）
<nz-tree-virtual-scroll-view [nzDataSource]="tasks" [itemSize]="48">
  <nz-tree-node *nzTreeNodeDef="let node" [nzTreeNode]="node">
    <app-task-capsule [task]="node.data"></app-task-capsule>
  </nz-tree-node>
</nz-tree-virtual-scroll-view>
```

**效能要點**：itemSize 固定、OnPush 策略、TrackBy 函數

---

#### 8.10.3 離線同步與衝突解決

**策略**：Last-Write-Wins + 手動解決重要衝突

```
離線操作流程:
1. 離線時操作 → IndexedDB 暫存 (帶 localTimestamp)
2. 恢復連線 → 批次提交至 Supabase
3. 衝突偵測 → 比較 updated_at vs localTimestamp
4. 自動解決 → 一般欄位採 Last-Write-Wins
5. 手動解決 → 狀態/進度等關鍵欄位提示用戶選擇
```

**衝突類型處理**：
| 欄位類型 | 解決策略 |
|----------|----------|
| 描述/備註 | Last-Write-Wins |
| 狀態/進度 | 提示用戶選擇 |
| 照片附件 | 全部保留（合併） |

---

#### 8.10.4 多人協作應對

**Realtime 訂閱 + 樂觀更新**：

```typescript
// 即時訂閱任務變更
supabase.channel('tasks')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'tasks' }, 
    (payload) => handleRealtimeUpdate(payload))
  .subscribe();

// 樂觀更新策略
1. UI 立即反映變更
2. 背景發送 API 請求
3. 失敗時回滾 + 提示
```

**多人編輯提示**：任務詳情頁顯示「XXX 正在編輯...」

---

#### 8.10.5 Git-like 分支系統核心邏輯

**資料表設計**（不使用 Edge Function，純 RLS + 觸發器）：

```sql
-- blueprint_branches: 藍圖分支表
CREATE TABLE blueprint_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  branch_type TEXT DEFAULT 'feature' CHECK (branch_type IN ('main', 'feature', 'fork')),
  source_branch_id UUID REFERENCES blueprint_branches(id),  -- Fork 來源
  forked_to_org_id UUID REFERENCES accounts(id),           -- Fork 給哪個組織
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'merged', 'closed')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- blueprint_pull_requests: PR 表
CREATE TABLE blueprint_pull_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id),
  source_branch_id UUID NOT NULL REFERENCES blueprint_branches(id),
  target_branch_id UUID NOT NULL REFERENCES blueprint_branches(id),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'merged', 'closed')),
  created_by UUID REFERENCES accounts(id),
  reviewed_by UUID REFERENCES accounts(id),
  merged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**合併策略**：手動審核 + 覆蓋承攬欄位（進度/狀態/照片）

---

#### 8.10.6 檔案系統存取控制

**權限對應**：檔案權限繼承藍圖角色權限

```sql
-- file_permissions: 檔案權限表（細粒度控制）
CREATE TABLE file_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  grantee_id UUID NOT NULL REFERENCES accounts(id),  -- 授權對象
  permission TEXT NOT NULL CHECK (permission IN ('view', 'download', 'edit', 'delete')),
  expires_at TIMESTAMPTZ,  -- 時效性（NULL = 永久）
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**分享機制**：
- **內部分享**：授權給特定帳戶/組織
- **公開連結**：生成帶簽名的時效性 URL（Supabase Storage signed URL）

**軟刪除**：`deleted_at TIMESTAMPTZ` + 30 天自動清理 Job

**版本控制**：同名上傳時建立新版本，保留歷史（`file_versions` 表）

---

#### 8.10.7 財務系統最小化設計

**進度計算規則**：從樹狀最後一層往上遞迴彙總

```sql
-- 遞迴計算進度：子節點加權平均 → 父節點
WITH RECURSIVE task_progress AS (
  -- 葉子節點（無子任務）直接取 progress
  SELECT id, parent_id, progress, amount
  FROM tasks WHERE id NOT IN (SELECT DISTINCT parent_id FROM tasks WHERE parent_id IS NOT NULL)
  UNION ALL
  -- 父節點進度 = 子節點進度加權平均
  SELECT t.id, t.parent_id, 
         COALESCE(AVG(tp.progress), t.progress) as progress,
         t.amount
  FROM tasks t JOIN task_progress tp ON t.id = tp.parent_id
  GROUP BY t.id, t.parent_id, t.progress, t.amount
)
SELECT * FROM task_progress;
```

**金額綁定邏輯**：

```
規則：子節點金額總和 ≤ 父節點金額
驗證：INSERT/UPDATE 時觸發器檢查
      IF SUM(children.amount) > parent.amount THEN RAISE EXCEPTION
```

**請款邏輯**：`請款金額 = 任務金額 × 進度%`

---

#### 8.10.8 Realtime 訂閱設計

**訂閱範圍**：按藍圖 ID 訂閱，避免全局廣播

```typescript
// 進入藍圖時建立訂閱
const channel = supabase.channel(`blueprint:${blueprintId}`)
  .on('postgres_changes', { 
    event: '*', 
    schema: 'public', 
    table: 'tasks',
    filter: `blueprint_id=eq.${blueprintId}` 
  }, handleTaskChange)
  .on('postgres_changes', { 
    event: '*', 
    schema: 'public', 
    table: 'diaries',
    filter: `blueprint_id=eq.${blueprintId}` 
  }, handleDiaryChange)
  .subscribe();

// 離開藍圖時取消訂閱
channel.unsubscribe();
```

**效能要點**：
- 使用 filter 縮小訂閱範圍
- 離開頁面時必須 unsubscribe
- 批次更新使用 debounce（300ms）

---

#### 8.10.9 權限檢查設計

**檢查流程圖**：

```
用戶操作 → 前端權限判斷（快取） → API 請求 → RLS 強制檢查 → 回傳結果
             ↓ 無權限                    ↓ 無權限
           顯示禁用/隱藏               返回 403 錯誤
```

**按功能的權限檢查時機**：

| 功能 | 前端檢查 | 後端檢查 |
|------|----------|----------|
| 按鈕顯示 | 載入時 | - |
| 表單提交 | 提交前 | RLS Policy |
| 資料查詢 | - | RLS Policy |
| 檔案存取 | 點擊時 | Storage Policy |

**權限快取策略**：
```typescript
// 使用 Angular Signal 快取權限
permissions = signal<string[]>([]);

// 切換上下文時重新載入
effect(() => {
  const ctx = workspaceContext();
  loadPermissions(ctx.contextType, ctx.contextId);
});

// 快取有效期：Session 內有效，登出清除
```

**權限變更同步**：Realtime 訂閱 `role_assignments` 表變更 → 刷新權限快取

---

#### 8.10.10 QA 測試策略與驗收流程

**狀態流程**：

```
任務完成 → 日誌可提報 → 提報後可 QA → QA 完成 → 驗收
  [DONE]     [REPORTED]    [QA_PENDING]  [QA_PASSED]  [ACCEPTED]
     ↓           ↓              ↓            ↓
  只能更新   觸發日誌      指派品管      通過/不通過    最終確認
  進度照片   建立關聯      人員檢查      自動開問題     結案歸檔
```

**狀態機驗證**：

```typescript
// 狀態轉換規則（前端 + 後端雙重驗證）
const VALID_TRANSITIONS = {
  'DONE': ['REPORTED'],
  'REPORTED': ['QA_PENDING'],
  'QA_PENDING': ['QA_PASSED', 'QA_FAILED'],
  'QA_FAILED': ['QA_PENDING'],  // 重新提交
  'QA_PASSED': ['ACCEPTED'],
};

function canTransition(from: string, to: string): boolean {
  return VALID_TRANSITIONS[from]?.includes(to) ?? false;
}
```

**驗收表設計**：

```sql
CREATE TABLE task_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id),
  stage TEXT NOT NULL,  -- 'qa', 'final'
  status TEXT NOT NULL CHECK (status IN ('pending', 'passed', 'failed', 'conditional')),
  checklist_id UUID REFERENCES checklists(id),
  checked_by UUID REFERENCES accounts(id),
  checked_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

---

### 8.11 開發者必讀：關鍵實作細節

> **目的**：本章節整理所有開發時容易出錯、需要特別注意的規則與限制，確保協作者能達到「零認知開發」——無需額外溝通即可正確實作。

---

#### 8.11.1 協作者管理規則

**邀請機制**：

| 規則 | 數值/邏輯 |
|------|----------|
| 邀請連結有效期 | 7 天 |
| 同一 Email 發送頻率限制 | 24 小時內最多 3 次，超過時顯示錯誤「請於 {剩餘時間} 後重試」 |
| 被邀請者已是成員時 | 顯示提示「該用戶已是成員」，不發送邀請 |
| 邀請狀態流程 | `pending` → `accepted` / `expired` / `revoked` |

**權限變更生效規則**：

| 變更類型 | 生效時機 | 前端行為 |
|----------|----------|----------|
| 角色提升（如 Member → Admin） | 立即生效 | 自動刷新權限快取，UI 更新 |
| 角色降級（如 Admin → Member） | 下次頁面載入時生效 | 當前頁面維持原權限 |
| 移除成員 | 立即生效 | 強制登出該成員所有工作階段 |

**成員退出後資料處理**：

| 情境 | 任務/日誌處理 | 關聯欄位處理 |
|------|--------------|-------------|
| 個人主動離開組織 | 保留記錄，不刪除 | `assignee_id` / `created_by` 設為 `null` |
| 被組織移除 | 同上 | 同上 |
| 組織刪除 | 軟刪除，30 天後永久刪除 | CASCADE 關聯刪除 |

**擁有權轉移流程**：

```
1. 只有 Owner 可發起轉移
2. 新 Owner 必須是現有成員
3. 系統顯示二次確認對話框
4. 確認後：
   - 新 Owner 角色更新為 owner
   - 原 Owner 自動降級為 admin
   - 操作記錄寫入 audit_log
5. 轉移操作不可撤銷
```

---

#### 8.11.2 任務樹操作限制

**結構限制**：

| 限制項目 | 預設值 | 可調整範圍 | 說明 |
|----------|--------|-----------|------|
| 最大層級深度 | 10 層 | 5-20（藍圖設定） | 超過時禁止建立子任務 |
| 單一父節點最大子節點數 | 200 | - | 建議 50 以內維持效能 |
| 單一藍圖最大任務數 | 10,000 | - | 超過需升級方案 |

**循環檢測邏輯**（移動任務前必須執行）：

```sql
-- 檢查 new_parent_id 是否為 task_id 的子孫節點
-- 注意：遞迴最大深度設為 20 層（與系統限制一致），防止資料損壞時的無限迴圈
-- 若遞迴達到深度限制，視為異常並記錄警告日誌
WITH RECURSIVE descendants AS (
  SELECT id, 1 AS depth FROM tasks WHERE parent_id = :task_id
  UNION ALL
  SELECT t.id, d.depth + 1 FROM tasks t 
  JOIN descendants d ON t.parent_id = d.id
  WHERE d.depth < 20  -- 防止無限遞迴
)
SELECT EXISTS (SELECT 1 FROM descendants WHERE id = :new_parent_id) AS is_circular;
-- 若 is_circular = true，禁止移動並顯示錯誤 TASK552
```

**批次操作限制**：

| 操作類型 | 單次最大數量 | 超過時行為 |
|----------|-------------|-----------|
| 拖拉移動 | 50 個任務 | 顯示警告，要求分批操作 |
| 批次刪除 | 100 個任務 | 顯示影響的子任務數量警告 |
| 批次狀態更新 | 200 個任務 | 自動分批處理，顯示進度 |

---

#### 8.11.3 檔案系統限制

**檔案大小與格式**：

| 檔案類型 | 單檔大小限制 | 允許格式 |
|----------|-------------|---------|
| 圖片 | 10 MB | `.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`* |
| 文件 | 50 MB | `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx` |
| 工程圖檔 | 100 MB | `.dwg`, `.dxf` |

> *HEIC 相容性說明：HEIC 格式（iPhone 拍攝）瀏覽器支援有限，上傳後由伺服器自動轉換為 JPEG 格式儲存，確保網頁顯示相容性。原始 HEIC 檔案不保留。

**命名規則**：

| 限制 | 規則 |
|------|------|
| 最大長度 | 100 字元（含副檔名） |
| 禁止字元 | `/ \ : * ? " < > |` |
| 自動處理 | 重複檔名自動加後綴 `(1)`, `(2)`... |

**批次與儲存限制**：

| 限制項目 | 數值 |
|----------|------|
| 單次批次上傳 | 最多 20 個檔案 |
| 藍圖總儲存空間 | 10 GB（可升級） |
| 縮圖生成 | 圖片自動生成 200x200 縮圖 |

---

#### 8.11.4 API 限制與分頁規範

**速率限制**：

| 請求類型 | 限制 | 超過時回應 |
|----------|------|-----------|
| 匿名請求 | 60 req/min | HTTP 429 + `Retry-After` header |
| 認證用戶 | 300 req/min | HTTP 429 + `Retry-After` header |
| 批次操作（如批次更新） | 10 req/min | HTTP 429 + 建議分批提示 |

**分頁規範**：

| 參數 | 預設值 | 最大值 | 說明 |
|------|--------|--------|------|
| `pageSize` | 20 | 100 | 超過 100 自動降為 100 |
| `page` | 1 | - | 從 1 開始 |
| 無限捲動閾值 | - | - | 距離底部 200px 時自動載入下一頁 |

---

#### 8.11.5 錯誤碼規範

**格式**：`{模組代碼}{錯誤類型}{序號}`

**模組代碼**：

| 代碼 | 模組 |
|------|------|
| 10 | AUTH（認證） |
| 20 | ACCOUNT（帳戶） |
| 30 | BLUEPRINT（藍圖） |
| 40 | TASK（任務） |
| 50 | FILE（檔案） |
| 60 | DIARY（日誌） |
| 70 | QA（品質驗收） |

**錯誤類型**：

| 類型碼 | 說明 |
|--------|------|
| 1 | 驗證錯誤（格式、必填） |
| 2 | 權限錯誤 |
| 3 | 資源不存在 |
| 4 | 狀態衝突 |
| 5 | 超過限制 |
| 9 | 系統錯誤 |

**常見錯誤碼與前端處理**：

| 錯誤碼 | 說明 | 前端處理 |
|--------|------|----------|
| `AUTH101` | 登入失敗：密碼錯誤 | 顯示提示，連續 3 次顯示「忘記密碼」連結 |
| `AUTH102` | Session 過期 | 儲存當前頁面路徑，導向登入頁 |
| `AUTH105` | 帳號鎖定（連續 5 次失敗） | 顯示鎖定時間與解鎖方式 |
| `ACCOUNT201` | 無權存取此組織 | 顯示無權限頁面，提供返回按鈕 |
| `ACCOUNT202` | 非藍圖成員 | 顯示申請加入按鈕或返回列表 |
| `BLUEPRINT301` | 藍圖不存在 | 導向藍圖列表，顯示提示 |
| `BLUEPRINT302` | 藍圖已封存 | 提示聯繫管理員解除封存 |
| `TASK401` | 任務狀態衝突 | 刷新頁面，顯示最新狀態 |
| `TASK403` | 任務已被他人鎖定 | 顯示鎖定者資訊與預估解鎖時間 |
| `TASK551` | 超過任務層級限制 | 顯示當前深度與限制，禁止操作 |
| `TASK552` | 超過子節點數量限制 | 建議拆分任務結構 |
| `FILE501` | 檔案大小超過限制 | 顯示壓縮建議或禁止上傳 |
| `FILE502` | 不支援的檔案格式 | 顯示支援格式列表 |
| `FILE503` | 儲存空間不足 | 顯示升級方案或刪除建議 |

---

#### 8.11.6 前端狀態管理規範

**Signal 重置時機**：

| 觸發情境 | 重置範圍 | 說明 |
|----------|----------|------|
| 登出 | 所有 Store Signal | 清除所有快取狀態 |
| 切換組織 | `BlueprintStore`, `TaskStore`, `DiaryStore`, `TodoStore` | 保留 `AccountStore` |
| 切換藍圖 | `TaskStore`, `DiaryStore`, `TodoStore` | 保留 `BlueprintStore` 列表 |
| 進入藍圖 | 僅載入，不重置 | 保留快取，背景驗證 |

**快取失效策略**：

| 資料類型 | 策略 | 有效期 |
|----------|------|--------|
| 藍圖列表 | 切換組織時失效 | Session 內有效 |
| 任務樹 | Stale-While-Revalidate | 5 分鐘 |
| 用戶權限 | 切換上下文時重新載入 | 手動失效 |
| 檔案列表 | 上傳/刪除後失效 | 手動失效 |

**Subscription 清理規範**：

```typescript
// ✅ 正確：使用 takeUntilDestroyed
@Component({...})
export class TaskListComponent {
  private destroyRef = inject(DestroyRef);
  
  ngOnInit() {
    this.taskStore.tasks$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(tasks => {...});
  }
}

// ✅ 正確：手動管理 Realtime Channel
ngOnDestroy() {
  this.realtimeChannel?.unsubscribe();
}

// ❌ 錯誤：未清理 Subscription（造成 Memory Leak）
// 原因：Component 銷毀後 Subscription 仍持續運行，
//       持有對 Component 的引用導致無法被 GC 回收，
//       可能導致重複執行回調、效能下降、記憶體持續增長
ngOnInit() {
  this.taskStore.tasks$.subscribe(tasks => {...}); // Memory Leak!
}
```

---

#### 8.11.7 離線同步衝突欄位詳細清單

**自動合併欄位（Last-Write-Wins）**：

| 表 | 欄位 | 說明 |
|-----|------|------|
| `tasks` | `description`, `name` | 文字類欄位直接覆蓋 |
| `diaries` | `summary`, `notes` | 同上 |
| `*` | `updated_at` | 時間戳記自動更新 |

**手動解決欄位（提示用戶選擇）**：

| 表 | 欄位 | 衝突 UI |
|-----|------|---------|
| `tasks` | `status`, `progress` | 顯示本機版本 vs 伺服器版本，用戶選擇 |
| `tasks` | `assignee_id` | 顯示兩個指派人，用戶選擇或保留兩者 |
| `task_acceptances` | `status` | 顯示衝突詳情，通知相關人員 |

**自動合併欄位（全部保留）**：

| 表 | 欄位 | 說明 |
|-----|------|------|
| `task_attachments` | 新增記錄 | 離線上傳的照片全部保留 |
| `task_comments` | 新增記錄 | 離線評論全部保留，按時間排序 |

---

#### 8.11.8 擴展性設計約定

**新增模組接入規範**：

```
1. 建立資料夾結構：
   src/app/features/blueprint/ui/{module}/
   ├── {module}-list/
   │   └── {module}-list.component.ts
   └── shared/

2. 建立 Store：
   src/app/features/blueprint/data-access/stores/{module}.store.ts
   - 繼承 BlueprintStore 的上下文（blueprintId, ownerContext）
   - 實作標準介面：load(), create(), update(), delete()

3. 建立領域模型：
   src/app/features/blueprint/domain/models/{module}.model.ts

4. 新增路由：
   // blueprint.routes.ts
   { path: '{module}', loadComponent: () => import('./ui/{module}/...') }

5. 新增 RLS 政策：
   CREATE POLICY "{module}_blueprint_access" ON {table}
   USING (blueprint_id IN (SELECT ...藍圖成員查詢...));
```

**預留 Hook 點列表**（尚未實作，預留擴展）：

| Hook 名稱 | 觸發時機 | 預期用途 |
|----------|----------|----------|
| `onTaskStatusChange` | 任務狀態變更後 | Webhook 通知（如 Slack、LINE） |
| `onBlueprintComplete` | 藍圖進度達 100% | 自動報表生成、財務系統觸發 |
| `onFileUpload` | 檔案上傳成功後 | 病毒掃描、AI 自動分類 |
| `onQAFailed` | 品質驗收失敗 | 自動開立問題單、通知負責人 |
| `onMilestoneReached` | 里程碑完成 | 進度請款觸發 |

**事件廣播規範**（Realtime Broadcast）：

```typescript
// 事件格式
interface BroadcastEvent {
  type: string;        // 事件類型，如 'task:updated', 'member:joined'
  payload: object;     // 事件資料
  timestamp: string;   // ISO 8601 格式
  actor_id: string;    // 觸發者帳戶 ID
}

// 訂閱者實作要點
// 1. 事件必須處理冪等性（重複收到同一事件不應產生副作用）
// 2. 使用 event.timestamp 判斷是否為過期事件
// 3. 本地觸發的事件應忽略（actor_id === currentUser.id）
```

---

#### 8.11.9 測試策略

**單元測試覆蓋率要求**：

| 層級 | 覆蓋率目標 | 測試重點 |
|------|-----------|----------|
| Store 層 | 100% | 狀態變更、computed signals、side effects |
| Service 層 | 80%+ | API 呼叫、錯誤處理、資料轉換 |
| Component 層 | 60%+ | 關鍵交互（按鈕點擊、表單提交） |
| Utils | 100% | 純函數、邊界條件 |

**整合測試重點場景**：

| 場景 | 測試內容 |
|------|----------|
| 上下文切換流程 | 組織→藍圖→任務的完整切換鏈 |
| 權限檢查鏈 | 前端快取 → API 請求 → RLS 攔截 |
| 離線同步 | 離線修改 → 恢復連線 → 衝突偵測 → 解決 |
| Realtime 同步 | A 用戶修改 → B 用戶即時更新 |

**E2E 測試場景（Playwright）**：

| 場景名稱 | 測試流程 |
|----------|----------|
| 完整使用者旅程 | 註冊 → 建立組織 → 邀請成員 → 建立藍圖 → 建立任務 → 完成任務 → 品質驗收 |
| 多人協作衝突 | A 開始編輯任務 → B 同時編輯相同任務 → 衝突提示顯示 → 選擇解決方案 |
| 離線上線同步 | 模擬離線 → 執行操作 → 恢復連線 → 驗證同步結果 |
| 大量資料效能 | 載入 1000+ 任務樹 → 驗證虛擬捲動 → 操作響應時間 < 200ms |

**測試資料管理**：

```typescript
// 測試前準備
beforeEach(async () => {
  // 使用獨立的測試藍圖，避免測試間干擾
  testBlueprint = await createTestBlueprint({ name: `test-${Date.now()}` });
});

// 測試後清理
afterEach(async () => {
  // 清理測試資料（使用 CASCADE 刪除）
  await deleteTestBlueprint(testBlueprint.id);
});
```

---

#### 8.11.10 效能基準與監控

**前端效能基準**：

| 指標 | 目標值 | 測量方式 |
|------|--------|----------|
| 首次內容繪製 (FCP) | < 1.5s | Lighthouse |
| 最大內容繪製 (LCP) | < 2.5s | Lighthouse |
| 互動至下一次繪製 (INP) | < 200ms | Web Vitals |
| 累積佈局偏移 (CLS) | < 0.1 | Web Vitals |
| 任務樹渲染 (1000 節點) | < 500ms | 自定義計時 |
| 虛擬捲動滾動 | 60fps | Chrome DevTools |

> 注意：INP (Interaction to Next Paint) 於 2024 年 3 月取代 FID 成為 Core Web Vitals 正式指標。

**後端效能基準**：

| 指標 | 目標值 | 告警閾值 |
|------|--------|----------|
| API 回應時間 (P50) | < 200ms | > 500ms |
| API 回應時間 (P95) | < 500ms | > 1s |
| API 回應時間 (P99) | < 1s | > 2s |
| 資料庫查詢 (P95) | < 100ms | > 300ms |
| 檔案上傳 (10MB) | < 5s | > 10s |

**監控告警規則**：

| 告警名稱 | 觸發條件 | 通知方式 |
|----------|----------|----------|
| API 高延遲 | P95 > 1s 持續 5 分鐘 | Email + Slack |
| 錯誤率上升 | 5xx 錯誤率 > 1% | Email + Slack |
| 資料庫連線池耗盡 | 可用連線 < 10 | Email + PagerDuty |
| 儲存空間不足 | 使用率 > 80% | Email |

---

## 9. 里程碑與排程

### 9.1 專案規模估計

- **規模**: 中大型專案（基礎設施已完成，聚焦業務功能開發）
- **預估時程**: 12-16 週
- **團隊規模**: 4-6 人

### 9.2 團隊組成

- **前端開發**: 2 人（Angular 專家）
- **後端開發**: 1 人（Supabase/PostgreSQL 專家）
- **UI/UX 設計**: 1 人
- **QA 測試**: 1 人
- **產品經理**: 1 人（兼任 Scrum Master）

### 9.3 現有基礎設施（已完成）

以下功能已在專案中實現，可直接使用：

| 模組 | 實現狀態 | 核心檔案 |
|------|----------|----------|
| 工作區上下文切換 | ✅ 100% | `workspace-context.facade.ts` |
| 藍圖邏輯容器 | ✅ 100% | `blueprint-shell.component.ts`, `blueprint.store.ts` |
| 任務樹狀結構 | ✅ 90% | `task-tree.component.ts`, `task.store.ts` |
| 任務表格視圖 | ✅ 90% | `task-table.component.ts` |
| 日誌列表框架 | ✅ 60% | `diary-list.component.ts`, `diary.store.ts` |
| 待辦列表框架 | ✅ 40% | `todo-list.component.ts`, `todo.store.ts` |

### 9.4 階段規劃（依賴驅動增量開發）

> **開發原則**：每個模組需達到**企業標準+生產水平**後，才開始下一個模組。
> **核心理念**：藍圖是邏輯容器，任務是主核心模組，其他模組圍繞任務展開。

#### 第零階段：基礎設施強化（第 1-2 週）

**目標**: 帳戶體系 + 藍圖系統達到企業標準+生產水平

**交付項目**:
- [ ] 組織擁有權管理（Owner 角色、擁有權轉移）
- [ ] Bot 所屬關係實現（用戶/組織/藍圖）
- [ ] 藍圖擁有權規則強化（只能是個人/組織）
- [ ] 自訂角色權限存取矩陣
- [ ] 帳戶資料快取策略

**依賴**: 現有 WorkspaceContextFacade, BlueprintStore

#### 第一階段：任務系統達到生產水平（第 3-5 週）

**目標**: 任務系統（主核心）達到企業標準+生產水平

**交付項目**:
- [ ] 任務建立/編輯對話框
- [ ] 任務膠囊狀態增強（負責人、截止日、問題徽章）
- [ ] 任務拖拉排序
- [ ] 完工圖片上傳與顯示
- [ ] 任務指派與討論

**前置依賴**: 第零階段完成（帳戶體系 + 藍圖系統達標）

#### 第一點五階段：檔案系統（第 6-7 週）

**目標**: 完成藍圖內檔案管理系統

**交付項目**:
- [ ] 檔案上傳與管理
- [ ] 檔案關聯至任務/日誌/驗收
- [ ] 檔案版本控制
- [ ] 存取權限控制

**前置依賴**: 第一階段完成（任務系統達標）

#### 第二階段：日誌系統（第 8-9 週）

**目標**: 完成每日施工日誌功能

**交付項目**:
- [ ] 日誌填寫表單
- [ ] 批次照片上傳（含壓縮、離線暫存）
- [ ] EXIF 資訊提取
- [ ] 天氣手動選擇
- [ ] 日誌匯出（PDF/Excel）

**前置依賴**: 第一點五階段完成（檔案系統）

#### 第三階段：進度追蹤儀表板（第 10-11 週）

**目標**: 完成施工進度視覺化儀表板

**交付項目**:
- [ ] 進度儀表板主頁
- [ ] 計劃 vs 實際進度曲線（Chart.js 或 ECharts）
- [ ] 里程碑時間軸
- [ ] 進度風險預警
- [ ] 進度更新與自動彙總

**前置依賴**: 第一階段完成（任務系統達標）

#### 第四階段：品質驗收系統（第 12-13 週）

**目標**: 完成品質檢查與驗收流程

**交付項目**:
- [ ] 檢查清單模板管理
- [ ] 驗收流程實作（發起→檢查→判定）
- [ ] 驗收照片（前/中/後對比）
- [ ] 串驗收功能
- [ ] 驗收不合格自動開立問題

**前置依賴**: 第三階段完成（施工進度追蹤達標）

#### 第五階段：協作、報表與上線（第 14-16 週）

**目標**: 完成協作溝通、報表系統，整體優化準備上線

**交付項目**:
- [ ] 討論區功能（任務/問題關聯）
- [ ] 通知中心（站內 + Email）
- [ ] 待辦中心增強
- [ ] 進度/品質/工時報表
- [ ] 效能優化（虛擬捲動、懶載入）
- [ ] UAT 測試
- [ ] 文件完善

**前置依賴**: 第四階段完成

### 9.5 未來規劃（Phase 2）

以下功能規劃在初版上線後的後續版本：

**中期規劃**：
- Git-like 分支系統（Fork / Pull Request）
- 多組織協作與權限控制
- 問題追蹤系統完整實現
- 移動端 PWA 優化

**長期規劃**：
- 財務系統（簡化版 - 按進度請款）
- 人力資源管理（極簡 - 以任務為主體）
- BIM 模型整合（評估中）

> ⚠️ **設計原則**：財務與人資模組採用最小化設計，預留擴展介面。核心功能不應依賴這些模組，確保系統獨立運作。

---

## 10. 使用者故事

### 10.1 帳戶與認證

#### GH-001: 使用者註冊

- **ID**: GH-001
- **描述**: 作為一個新使用者，我希望能夠註冊帳號，以便使用系統功能。
- **驗收標準**:
  - 可使用 Email 註冊
  - 可使用 Google OAuth 註冊
  - 註冊時需填寫姓名
  - 密碼需符合複雜度要求（8 字元以上，包含大小寫與數字）
  - 註冊後需驗證 Email
  - 驗證完成後自動導向首頁

#### GH-002: 使用者登入

- **ID**: GH-002
- **描述**: 作為一個已註冊使用者，我希望能夠登入系統，以便存取我的資料。
- **驗收標準**:
  - 可使用 Email/密碼登入
  - 可使用 Google OAuth 登入
  - 登入錯誤需顯示友善提示
  - 連續 5 次登入失敗需暫時鎖定
  - 支援「記住我」功能
  - 登入後導向上次瀏覽頁面或儀表板

#### GH-003: 密碼重設

- **ID**: GH-003
- **描述**: 作為一個忘記密碼的使用者，我希望能夠重設密碼。
- **驗收標準**:
  - 可透過 Email 發送重設連結
  - 重設連結 24 小時內有效
  - 重設密碼需符合複雜度要求
  - 重設成功後自動登入

#### GH-004: 個人資料管理

- **ID**: GH-004
- **描述**: 作為一個使用者，我希望能夠管理我的個人資料。
- **驗收標準**:
  - 可修改姓名、電話、頭像
  - 頭像支援圖片上傳與裁剪
  - 可變更 Email（需重新驗證）
  - 可變更密碼（需輸入原密碼）
  - 可設定通知偏好
  - 可設定介面偏好（主題、語言）

### 10.2 組織與團隊

#### GH-005: 建立組織

- **ID**: GH-005
- **描述**: 作為一個使用者，我希望能夠建立組織，以便管理公司專案。
- **驗收標準**:
  - 可輸入組織名稱、描述、Logo
  - 建立者自動成為組織擁有者
  - 可設定組織基本資訊（地址、統編）
  - 組織建立後可邀請成員

#### GH-006: 邀請組織成員

- **ID**: GH-006
- **描述**: 作為組織管理員，我希望能夠邀請成員加入組織。
- **驗收標準**:
  - 可透過 Email 發送邀請
  - 可設定邀請者的角色
  - 邀請連結 7 天內有效
  - 被邀請者需確認加入
  - 可查看待處理的邀請清單
  - 可撤銷未接受的邀請

#### GH-007: 建立團隊

- **ID**: GH-007
- **描述**: 作為組織管理員，我希望能夠建立團隊，以便分組管理成員。
- **驗收標準**:
  - 可輸入團隊名稱、描述
  - 可指定團隊負責人
  - 可將組織成員加入團隊
  - 團隊可指派至特定藍圖
  - 成員可同時屬於多個團隊

#### GH-008: 切換工作環境

- **ID**: GH-008
- **描述**: 作為一個同時屬於多個組織的使用者，我希望能夠切換工作環境。
- **驗收標準**:
  - Header 顯示當前組織/團隊
  - 可快速切換組織
  - 切換後顯示該組織的藍圖與資料
  - 記住上次選擇的環境

### 10.3 藍圖管理

#### GH-009: 建立藍圖

- **ID**: GH-009
- **描述**: 作為專案經理，我希望能夠建立藍圖，以便管理新專案。
- **驗收標準**:
  - 可輸入藍圖名稱、描述
  - 可設定開始/結束日期
  - 可設定藍圖擁有者
  - 可設定藍圖狀態（規劃中/進行中/暫停/完成/封存）
  - 建立後自動導向藍圖詳情頁

#### GH-010: 藍圖設定

- **ID**: GH-010
- **描述**: 作為藍圖擁有者，我希望能夠設定藍圖參數。
- **驗收標準**:
  - 可設定工作日曆（週休/假日）
  - 可設定通知規則
  - 可新增自訂欄位
  - 可管理藍圖成員與權限
  - 可設定進度計算規則

#### GH-011: Fork 藍圖給協作組織

- **ID**: GH-011
- **描述**: 作為藍圖擁有者，我希望能夠 Fork 藍圖給協作組織，以便分包施工。
- **驗收標準**:
  - 可選擇要 Fork 的任務範圍
  - 可選擇協作組織
  - 協作組織收到邀請通知
  - 協作組織接受後建立分支
  - 分支權限限制為僅操作承攬欄位

#### GH-012: 提交 Pull Request

- **ID**: GH-012
- **描述**: 作為協作組織成員，我希望能夠提交 PR，以便回報執行進度。
- **驗收標準**:
  - 可選擇要提交的變更內容
  - 可輸入 PR 說明
  - PR 建立後通知藍圖擁有者
  - 可在 PR 中進行討論
  - 藍圖擁有者可審核/合併/拒絕

### 10.4 任務管理

#### GH-013: 建立任務

- **ID**: GH-013
- **描述**: 作為專案經理，我希望能夠建立任務，以便規劃施工項目。
- **驗收標準**:
  - 可輸入任務名稱、描述
  - 可設定父任務（建立階層關係）
  - 可設定優先級（低/中/高/緊急）
  - 可設定開始/截止日期
  - 可設定預估工時
  - 可指派負責人

#### GH-014: 檢視任務樹狀圖

- **ID**: GH-014
- **描述**: 作為使用者，我希望能夠以樹狀圖檢視任務，以便了解任務結構。
- **驗收標準**:
  - 以階層縮排顯示任務
  - 可展開/收合子任務
  - 顯示任務膠囊（層級/優先/進度/狀態/負責人/截止日）
  - 已完成任務顯示完工照片縮圖
  - 可拖拉調整任務順序
  - 支援任務搜尋與篩選

#### GH-015: 更新任務狀態

- **ID**: GH-015
- **描述**: 作為施工人員，我希望能夠更新任務狀態，以便回報進度。
- **驗收標準**:
  - 可變更任務狀態（待處理 → 進行中 → 已完成 → ...）
  - 狀態變更需確認
  - 變更後即時更新 UI
  - 變更記錄在活動日誌
  - 相關人員收到通知

#### GH-016: 更新任務進度

- **ID**: GH-016
- **描述**: 作為施工人員，我希望能夠更新任務進度並上傳完工證明。
- **驗收標準**:
  - 完成任務後可更新進度百分比
  - 可上傳完工照片
  - 進度更新即時同步
  - 自動更新父任務進度
  - 相關人員收到通知

#### GH-017: 上傳任務完工照片

- **ID**: GH-017
- **描述**: 作為施工人員，我希望能夠上傳完工照片，以便記錄施工結果。
- **驗收標準**:
  - 可選擇多張照片上傳
  - 顯示上傳進度
  - 自動壓縮優化
  - 保留 EXIF 資訊（時間、地點）
  - 照片縮圖顯示在任務卡片
  - 點擊可放大檢視

### 10.5 每日日誌

#### GH-018: 填寫每日施工日誌

- **ID**: GH-018
- **描述**: 作為工地主任，我希望能夠填寫每日施工日誌。
- **驗收標準**:
  - 可選擇日期（預設當日）
  - 可輸入工作摘要
  - 可記錄工作時數
  - 可記錄工人數量
  - 可上傳施工照片
  - 可手動選擇天氣狀況

#### GH-019: 管理日誌照片

- **ID**: GH-019
- **描述**: 作為工地主任，我希望能夠管理日誌照片。
- **驗收標準**:
  - 可批次上傳照片
  - 可為照片新增說明
  - 可分類標籤照片
  - 可刪除照片
  - 照片自動壓縮

#### GH-020: 檢視歷史日誌

- **ID**: GH-020
- **描述**: 作為使用者，我希望能夠檢視歷史日誌。
- **驗收標準**:
  - 可按日期範圍篩選
  - 可按人員篩選
  - 可按任務篩選
  - 日誌清單顯示摘要
  - 點擊可檢視詳情

### 10.6 品質驗收

#### GH-021: 管理檢查清單模板

- **ID**: GH-021
- **描述**: 作為品管人員，我希望能夠管理檢查清單模板。
- **驗收標準**:
  - 可建立清單模板
  - 可新增/編輯/刪除檢查項目
  - 可設定評分標準
  - 可分類檢查項目
  - 模板可複製

#### GH-022: 發起品質驗收

- **ID**: GH-022
- **描述**: 作為工地主任，我希望能夠發起品質驗收。
- **驗收標準**:
  - 可選擇要驗收的任務
  - 可選擇檢查清單模板
  - 可指派品管人員
  - 發起後通知品管人員
  - 任務狀態變為「品管中」

#### GH-023: 執行品質檢查

- **ID**: GH-023
- **描述**: 作為品管人員，我希望能夠執行品質檢查。
- **驗收標準**:
  - 可逐項確認檢查項目
  - 可為每項評分
  - 可新增備註
  - 可上傳缺陷照片
  - 可拍攝前/中/後對比照

#### GH-024: 完成驗收判定

- **ID**: GH-024
- **描述**: 作為品管人員，我希望能夠完成驗收判定。
- **驗收標準**:
  - 可判定為通過/不通過/有條件通過
  - 不通過需填寫原因
  - 不通過自動開立問題單
  - 相關人員收到通知
  - 任務狀態更新

#### GH-025: 串驗收流程

- **ID**: GH-025
- **描述**: 作為專案經理，我希望能夠設定串驗收流程。
- **驗收標準**:
  - 可定義多階段驗收
  - 可為每階段指定驗收人員
  - 前一階段通過才能進入下一階段
  - 可追蹤驗收鏈狀態
  - 所有階段通過才算完成

### 10.7 問題追蹤

#### GH-026: 手動開立問題

- **ID**: GH-026
- **描述**: 作為使用者，我希望能夠手動開立問題。
- **驗收標準**:
  - 可輸入問題標題、描述
  - 可選擇關聯任務
  - 可設定嚴重程度
  - 可上傳問題照片
  - 可指派處理人員

#### GH-027: 處理問題

- **ID**: GH-027
- **描述**: 作為被指派者，我希望能夠處理問題。
- **驗收標準**:
  - 可更新處理進度
  - 可新增處理記錄
  - 可上傳處理後照片
  - 處理完成後可申請關閉
  - 問題開立者確認後關閉

#### GH-028: 問題跨分支同步

- **ID**: GH-028
- **描述**: 作為藍圖擁有者，我希望能夠看到所有分支的問題。
- **驗收標準**:
  - 分支問題即時同步至主分支
  - 主分支可看到所有問題
  - 問題狀態即時更新
  - 可篩選顯示特定分支問題

### 10.8 協作溝通

#### GH-029: 任務討論

- **ID**: GH-029
- **描述**: 作為使用者，我希望能夠在任務中進行討論。
- **驗收標準**:
  - 可在任務詳情頁留言
  - 支援巢狀回覆
  - 支援 @提及
  - 被提及者收到通知
  - 即時更新留言

#### GH-030: 通知管理

- **ID**: GH-030
- **描述**: 作為使用者，我希望能夠管理通知。
- **驗收標準**:
  - 可檢視所有通知
  - 可標記已讀/未讀
  - 可批次刪除
  - 可設定通知偏好
  - 支援通知分類顯示

#### GH-031: 待辦中心

- **ID**: GH-031
- **描述**: 作為使用者，我希望能夠使用待辦中心管理工作。
- **驗收標準**:
  - 顯示我的待辦事項
  - 按五狀態分類顯示
  - 可依優先級排序
  - 顯示截止日期
  - 點擊可跳轉至對應功能

### 10.9 報表分析

#### GH-032: 檢視進度報表

- **ID**: GH-032
- **描述**: 作為專案經理，我希望能夠檢視進度報表。
- **驗收標準**:
  - 顯示整體完成率
  - 顯示計劃 vs 實際曲線
  - 顯示里程碑狀態
  - 可選擇時間範圍
  - 可匯出 PDF/Excel

#### GH-033: 檢視品質報表

- **ID**: GH-033
- **描述**: 作為品管人員，我希望能夠檢視品質報表。
- **驗收標準**:
  - 顯示驗收統計
  - 顯示缺陷率趨勢
  - 顯示問題分類統計
  - 可選擇時間範圍
  - 可匯出 PDF/Excel

#### GH-034: 檢視工時報表

- **ID**: GH-034
- **描述**: 作為專案經理，我希望能夠檢視工時報表。
- **驗收標準**:
  - 顯示人員工時統計
  - 顯示任務工時分析
  - 顯示工時趨勢圖
  - 可選擇時間範圍
  - 可匯出 PDF/Excel

### 10.10 離線與同步

#### GH-035: 離線瀏覽

- **ID**: GH-035
- **描述**: 作為工地使用者，我希望在離線時也能瀏覽資料。
- **驗收標準**:
  - 離線時可瀏覽已快取的資料
  - 顯示離線狀態指示
  - 離線時核心功能可用
  - 離線資料自動更新

#### GH-036: 離線操作

- **ID**: GH-036
- **描述**: 作為工地使用者，我希望在離線時也能執行操作。
- **驗收標準**:
  - 離線時可更新任務狀態
  - 離線時可填寫日誌
  - 離線時可上傳照片（暫存）
  - 操作暫存於本機
  - 恢復連線後自動同步

#### GH-037: 同步衝突解決

- **ID**: GH-037
- **描述**: 作為使用者，當發生同步衝突時，我希望能夠解決。
- **驗收標準**:
  - 偵測同步衝突
  - 顯示衝突提示
  - 提供衝突解決選項
  - 可選擇保留本機或伺服器版本
  - 解決後繼續同步

### 10.11 系統管理

#### GH-038: 系統設定管理

- **ID**: GH-038
- **描述**: 作為超級管理員，我希望能夠管理系統設定。
- **驗收標準**:
  - 可設定全域參數
  - 可管理功能開關
  - 可查看系統日誌
  - 可管理 API 金鑰
  - 可設定備份排程

#### GH-039: 功能開關管理

- **ID**: GH-039
- **描述**: 作為超級管理員，我希望能夠管理功能開關。
- **驗收標準**:
  - 可啟用/停用特定功能
  - 可設定目標使用者/組織
  - 可設定灰度發布比例
  - 開關即時生效
  - 可查看功能使用統計

#### GH-040: 活動日誌查詢

- **ID**: GH-040
- **描述**: 作為管理員，我希望能夠查詢活動日誌。
- **驗收標準**:
  - 可按時間範圍查詢
  - 可按使用者查詢
  - 可按操作類型查詢
  - 可按實體查詢
  - 可匯出日誌

---

## 附錄

### A. 資料模型參考

現有資料模型已設計完成，詳見：
- `docs/architecture/06-entity-relationship-diagram.mermaid.md`
- `database_export_20251124_133450.sql`

### B. 技術棧

| 類別 | 技術 | 版本 |
|------|------|------|
| 前端框架 | Angular | 20.3.x |
| UI 框架 | ng-alain | 20.1.x |
| UI 元件庫 | ng-zorro-antd | 20.3.x |
| 狀態管理 | Angular Signals | - |
| 後端服務 | Supabase | 2.84.x |
| 資料庫 | PostgreSQL | 15.x |
| 認證 | Supabase Auth + @delon/auth | - |

### C. 已完成功能代碼參考

| 功能 | 檔案路徑 |
|------|----------|
| 工作區上下文切換 | `src/app/core/facades/account/workspace-context.facade.ts` |
| 藍圖邏輯容器 | `src/app/features/blueprint/shell/blueprint-shell/` |
| 藍圖狀態管理 | `src/app/features/blueprint/data-access/stores/blueprint.store.ts` |
| 任務樹狀圖 | `src/app/features/blueprint/ui/task/task-tree/task-tree.component.ts` |
| 任務表格視圖 | `src/app/features/blueprint/ui/task/task-table/task-table.component.ts` |
| 任務列表容器 | `src/app/features/blueprint/ui/task/task-list/task-list.component.ts` |
| 任務狀態管理 | `src/app/features/blueprint/data-access/stores/task.store.ts` |
| 日誌列表 | `src/app/features/blueprint/ui/diary/diary-list/diary-list.component.ts` |
| 日誌狀態管理 | `src/app/features/blueprint/data-access/stores/diary.store.ts` |
| 待辦列表 | `src/app/features/blueprint/ui/todo/todo-list/todo-list.component.ts` |
| 待辦狀態管理 | `src/app/features/blueprint/data-access/stores/todo.store.ts` |
| 任務領域模型 | `src/app/features/blueprint/domain/models/task.model.ts` |
| 任務狀態枚舉 | `src/app/features/blueprint/domain/enums/task.enums.ts` |
| 藍圖狀態枚舉 | `src/app/features/blueprint/domain/enums/blueprint.enums.ts` |
| 個人工作區路由 | `src/app/routes/account/user/routes.ts` |
| 組織工作區路由 | `src/app/routes/account/org/routes.ts` |
| 團隊工作區路由 | `src/app/routes/account/team/routes.ts` |
| 藍圖功能路由 | `src/app/features/blueprint/blueprint.routes.ts` |

### D. 相關文件

- 系統架構圖：`docs/architecture/01-system-architecture-mindmap.mermaid.md`
- 帳戶層流程圖：`docs/architecture/05-account-layer-flowchart.mermaid.md`
- RLS 權限矩陣：`docs/architecture/09-security-rls-permission-matrix.md`
- 專案分析報告：`docs/PROJECT-ANALYSIS-REPORT.md`
- 架構層原子化設計：`docs/architecture/22-architecture-layers-atomization-design.md`

### E. 變更記錄

| 版本 | 日期 | 變更內容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2025-11-26 | 初版建立 | GitHub Copilot |
| 1.1.0 | 2025-11-26 | 更新以反映專案現有基礎設施實現狀態 | GitHub Copilot |
| 1.2.0 | 2025-11-26 | 調整角色體系、優先級依賴關係、新增檔案/財務/人資模組 | GitHub Copilot |
| 1.3.0 | 2025-11-26 | 新增上下文架構圖、資料夾結構、命名規範、RLS/觸發器設計 | GitHub Copilot |
| 1.4.0 | 2025-11-26 | 新增技術設計補充（圖片架構、膠囊狀態、離線同步、Git-like 分支、檔案系統、財務邏輯、Realtime、權限、QA流程） | GitHub Copilot |
| 1.5.0 | 2025-11-26 | 新增完整資料表、RLS 政策、觸發器清單 | GitHub Copilot |
| 1.6.0 | 2025-11-26 | 新增「開發者必讀：關鍵實作細節」章節，涵蓋協作者管理、任務樹限制、檔案系統、API 限制、錯誤碼、狀態管理、擴展性、測試策略、效能監控，達到零認知開發水平 | GitHub Copilot |

---

## 附錄 F. 資料庫物件清單

### F.1 資料表清單

#### 既有資料表（✅ 已完成）

| 表名 | 用途 | 狀態 |
|------|------|------|
| `accounts` | 帳戶（含 USER/ORG/BOT 類型） | ✅ 完成 |
| `teams` | 團隊（屬於組織） | ✅ 完成 |
| `organization_members` | 組織成員關聯 | ✅ 完成 |
| `team_members` | 團隊成員關聯 | ✅ 完成 |
| `team_bots` | 團隊 Bot 關聯 | ✅ 完成 |

#### 待建立資料表（⬜ 規劃中）

| 表名 | 用途 | 優先級 |
|------|------|--------|
| `blueprints` | 藍圖主表 | 🔴 高 |
| `blueprint_members` | 藍圖成員與角色 | 🔴 高 |
| `blueprint_roles` | 藍圖自訂角色定義 | 🔴 高 |
| `blueprint_branches` | Git-like 分支 | 🟡 中 |
| `blueprint_pull_requests` | 分支合併請求 | 🟡 中 |
| `tasks` | 任務主表（樹狀結構） | 🔴 高 |
| `task_attachments` | 任務附件（含完工圖片） | 🔴 高 |
| `task_comments` | 任務討論 | 🟡 中 |
| `task_acceptances` | 任務驗收記錄 | 🔴 高 |
| `task_budget` | 任務預算金額 | 🟡 中 |
| `diaries` | 每日施工日誌 | 🔴 高 |
| `diary_attachments` | 日誌附件 | 🔴 高 |
| `files` | 檔案主表（含版本） | 🔴 高 |
| `file_shares` | 檔案分享連結 | 🟡 中 |
| `checklists` | 品質檢查清單模板 | 🟡 中 |
| `checklist_items` | 檢查項目 | 🟡 中 |
| `issues` | 問題追蹤 | 🟡 中 |
| `notifications` | 通知中心 | 🟡 中 |
| `payment_requests` | 請款申請（財務簡化版） | 🟢 低 |

### F.2 RLS 政策清單

#### 既有 RLS 政策（✅ 已完成）

| 政策名稱 | 表 | 操作 |
|----------|-----|------|
| `users_view_own_user_account` | accounts | SELECT |
| `users_update_own_user_account` | accounts | UPDATE |
| `users_insert_own_user_account` | accounts | INSERT |
| `users_view_organizations_they_belong_to` | accounts | SELECT |
| `org_owners_update_organizations` | accounts | UPDATE |
| `org_owners_delete_organizations` | accounts | DELETE |
| `authenticated_users_create_organizations` | accounts | INSERT |
| `users_view_bots_they_created` | accounts | SELECT |
| `users_view_bots_in_their_teams` | accounts | SELECT |
| `bot_creators_update_bots` | accounts | UPDATE |
| `bot_creators_delete_bots` | accounts | DELETE |
| `authenticated_users_create_bots` | accounts | INSERT |
| `users_view_teams_in_their_organizations` | teams | SELECT |
| `org_owners_create_teams` | teams | INSERT |
| `org_owners_update_teams` | teams | UPDATE |
| `org_owners_delete_teams` | teams | DELETE |
| `Users can view organization members` | organization_members | SELECT |
| `Allow initial organization owner on creation` | organization_members | INSERT |
| `Organization owners can add members` | organization_members | INSERT |
| `Organization admins can update member roles` | organization_members | UPDATE |
| `Users can leave organizations` | organization_members | DELETE |
| `Organization owners can remove members` | organization_members | DELETE |
| `Users can view team members in their teams` | team_members | SELECT |
| `Allow initial team leader` | team_members | INSERT |
| `Team leaders can add members` | team_members | INSERT |
| `Team leaders can update member roles` | team_members | UPDATE |
| `Users can remove themselves from teams` | team_members | DELETE |
| `Team leaders can remove members` | team_members | DELETE |
| `users_view_team_bots_for_their_teams` | team_bots | SELECT |
| `team_owners_manage_team_bots` | team_bots | ALL |

#### 待建立 RLS 政策（⬜ 規劃命名）

| 政策名稱 | 表 | 用途 |
|----------|-----|------|
| `blueprint_members_view` | blueprints | 藍圖成員可查看 |
| `blueprint_owner_manage` | blueprints | 擁有者可管理 |
| `tasks_blueprint_member_view` | tasks | 藍圖成員可查看任務 |
| `tasks_assignee_update` | tasks | 被指派者可更新 |
| `attachments_task_access` | task_attachments | 任務存取權限繼承 |
| `files_blueprint_access` | files | 檔案權限繼承藍圖 |
| `diaries_blueprint_member_view` | diaries | 藍圖成員可查看日誌 |

### F.3 觸發器清單

#### 既有觸發器（✅ 已完成）

| 觸發器名稱 | 表 | 事件 | 用途 |
|------------|-----|------|------|
| `add_creator_as_org_owner` | accounts | AFTER INSERT | 建立組織時自動加入擁有者 |
| `add_team_creator_as_leader_trigger` | teams | AFTER INSERT | 建立團隊時自動加入領導者 |

#### 待建立觸發器（⬜ 規劃命名）

| 觸發器名稱 | 表 | 事件 | 用途 |
|------------|-----|------|------|
| `add_blueprint_creator_as_owner` | blueprints | AFTER INSERT | 藍圖建立者自動為擁有者 |
| `update_parent_task_progress` | tasks | AFTER UPDATE | 子任務完成時更新父進度 |
| `validate_task_budget` | task_budget | BEFORE INSERT/UPDATE | 子金額 ≤ 父金額驗證 |
| `auto_thumbnail_attachment` | task_attachments | AFTER INSERT | 自動生成縮圖（需 Edge Function） |
| `soft_delete_file` | files | BEFORE DELETE | 軟刪除設定 deleted_at |

### F.4 Helper Functions（✅ 既有）

| 函數名稱 | 用途 |
|----------|------|
| `get_user_account_id()` | 取得當前用戶帳戶 ID |
| `is_org_member(org_id)` | 檢查是否為組織成員 |
| `is_team_member(team_id)` | 檢查是否為團隊成員 |
| `get_user_role_in_org(org_id)` | 取得用戶在組織的角色 |

### F.5 待建立 Helper Functions（⬜ 規劃命名）

| 函數名稱 | 用途 |
|----------|------|
| `is_blueprint_member(blueprint_id)` | 檢查是否為藍圖成員 |
| `get_user_role_in_blueprint(blueprint_id)` | 取得用戶在藍圖的角色 |
| `can_access_task(task_id)` | 檢查任務存取權限 |
| `calculate_task_progress(task_id)` | 遞迴計算任務進度 |
| `get_task_ancestors(task_id)` | 取得任務所有祖先節點 |

---

**文件狀態**: 草稿  
**審核狀態**: 待審核  
**下一步**: 與利害關係人確認需求後，進入開發階段
