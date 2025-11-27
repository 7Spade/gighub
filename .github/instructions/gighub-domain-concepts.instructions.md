---
description: 'GigHub 工地領域概念與業務規則，定義任務系統、施工日誌、品質驗收等核心業務領域'
applyTo: '**'
---

# GigHub 領域概念指南

> 工地施工進度追蹤管理系統的核心業務領域概念

---

## 🎯 系統核心概念

### 藍圖系統 (Blueprint System)

| 概念 | 說明 |
|------|------|
| 藍圖 (Blueprint) | 邏輯容器，提供資料隔離的工作空間 |
| 工作區 (Workspace) | 從藍圖實例化的工作環境 |
| 藍圖分支 (Blueprint Branch) | Git-like 的分支管理 |
| 合併請求 (Pull Request) | 分支合併請求 |
| Fork | 複製藍圖給協作組織 |
| 主分支 (Main Branch) | 原始藍圖的主線 |

### 帳戶體系 (Account System)

| 概念 | 說明 |
|------|------|
| 帳戶 (Account) | 系統身份單位（用戶/組織/Bot） |
| 用戶 (User) | 個人帳戶 |
| 組織 (Organization) | 企業/團隊主體 |
| 團隊 (Team) | 組織下的子單位 |
| Bot 用戶 (Bot User) | 自動化執行者帳戶 |
| 工作區上下文 (Workspace Context) | 當前操作的環境（個人/組織/團隊） |

---

## 👥 角色與權限

### 平台層級角色

| 角色 | 說明 |
|------|------|
| 超級管理員 (Super Admin) | 系統全域最高權限 |
| 組織擁有者 (Organization Owner) | 組織最高權限者 |
| 組織管理員 (Organization Admin) | 組織管理者 |
| 一般用戶 (User) | 個人層級使用者 |

### 藍圖層級角色

| 角色 | 說明 |
|------|------|
| 專案經理 (Project Manager) | 藍圖規劃與管理者 |
| 工地主任 (Site Director) | 工地現場最高負責人 |
| 施工人員 (Worker) | 實際執行施工任務者 |
| 品管人員 (QA Staff) | 負責品質檢查者 |
| 觀察者 (Observer) | 唯讀權限使用者 |
| 協作者 (Collaborator) | 外部參與者 |

---

## 🏗️ 任務系統 (Task System)

### 基本概念

| 概念 | 說明 |
|------|------|
| 任務 (Task) | 施工工作項目 |
| 子任務 (Sub-task) | 任務的子項目 |
| 任務樹 (Task Tree) | 階層式任務結構 |
| 里程碑 (Milestone) | 重要時間節點 |
| 負責人 (Assignee) | 任務執行者 |
| 監工 (Reviewer) | 任務審核者 |

### 任務狀態

| 狀態 | 英文 | 狀態碼 |
|------|------|--------|
| 待處理 | Pending | `pending` |
| 進行中 | In Progress | `in_progress` |
| 審核中 | In Review | `in_review` |
| 已完成 | Completed | `completed` |
| 已取消 | Cancelled | `cancelled` |
| 已阻塞 | Blocked | `blocked` |

### 任務優先級

| 優先級 | 英文 | 等級碼 |
|--------|------|--------|
| 最低 | Lowest | `lowest` |
| 低 | Low | `low` |
| 中 | Medium | `medium` |
| 高 | High | `high` |
| 最高 | Highest | `highest` |

### 任務類型

| 類型 | 英文 | 類型碼 |
|------|------|--------|
| 一般任務 | Task | `task` |
| 里程碑 | Milestone | `milestone` |
| 缺陷 | Bug | `bug` |
| 功能 | Feature | `feature` |
| 改進 | Improvement | `improvement` |

---

## 📝 施工日誌 (Construction Diary)

| 概念 | 說明 |
|------|------|
| 施工日誌 (Construction Diary) | 每日施工記錄 |
| 施工日期 (Work Date) | 施工進行的日期 |
| 工作摘要 (Work Summary) | 當日工作概述 |
| 施工工時 (Work Hours) | 實際施工時數 |
| 施工人數 (Worker Count) | 當日施工人員數量 |
| 天氣狀況 (Weather) | 當日天氣記錄 |
| 施工照片 (Site Photos) | 現場拍攝的照片 |
| 日誌簽核 (Diary Approval) | 日誌審核流程 |

### 天氣類型

| 天氣 | 英文 | 圖示 |
|------|------|------|
| 晴天 | Sunny | ☀️ |
| 多雲 | Cloudy | ⛅ |
| 雨天 | Rainy | 🌧️ |
| 暴風 | Stormy | ⛈️ |
| 雪天 | Snowy | ❄️ |
| 霧天 | Foggy | 🌫️ |

---

## ✅ 品質驗收 (Quality Acceptance)

| 概念 | 說明 |
|------|------|
| 品質驗收 (Quality Acceptance) | 品質檢查與驗收程序 |
| 檢查清單 (Checklist) | 驗收檢查項目列表 |
| 檢查項目 (Check Item) | 單一驗收項目 |
| 驗收記錄 (Acceptance Record) | 驗收結果記錄 |
| 串驗收 (Sequential Acceptance) | 多階段連續驗收 |

### 驗收結果

| 結果 | 英文 | 狀態碼 |
|------|------|--------|
| 待驗收 | Pending | `pending` |
| 通過 | Passed | `passed` |
| 不通過 | Failed | `failed` |
| 有條件通過 | Conditional | `conditional` |

---

## 🐛 問題追蹤 (Issue Tracking)

### 嚴重程度

| 等級 | 英文 | 等級碼 |
|------|------|--------|
| 低 | Low | `low` |
| 中 | Medium | `medium` |
| 高 | High | `high` |
| 緊急 | Critical | `critical` |

### 問題狀態

| 狀態 | 英文 | 狀態碼 |
|------|------|--------|
| 新建 | New | `new` |
| 已指派 | Assigned | `assigned` |
| 處理中 | In Progress | `in_progress` |
| 待確認 | Pending Confirm | `pending_confirm` |
| 已解決 | Resolved | `resolved` |
| 已關閉 | Closed | `closed` |
| 已重開 | Reopened | `reopened` |

---

## 📁 檔案系統

### 檔案類型

| 類型 | 英文 | 副檔名 |
|------|------|--------|
| 圖片 | Image | `.jpg`, `.png`, `.webp` |
| 文件 | Document | `.pdf`, `.doc`, `.docx` |
| 試算表 | Spreadsheet | `.xls`, `.xlsx` |
| 工程圖檔 | CAD Drawing | `.dwg`, `.dxf` |

### 使用者上傳禁止的檔案類型

> 注意：此限制僅適用於使用者上傳功能，不影響開發用的設定檔或建置腳本

```
❌ 使用者上傳禁止：
- .exe, .bat, .cmd, .com  （執行檔）
- .vbs, .ps1              （系統腳本）
- .dll, .sys              （系統檔）
```

### 檔案大小限制

| 類型 | 限制 |
|------|------|
| 圖片 | 最大 10 MB |
| 文件 | 最大 50 MB |
| 工程圖 | 最大 100 MB |

---

## 📊 進度追蹤

| 概念 | 說明 |
|------|------|
| 完成率 (Completion Rate) | 任務完成百分比 |
| 計劃進度 (Planned Progress) | 預定應完成進度 |
| 實際進度 (Actual Progress) | 實際完成進度 |
| 進度曲線 (Progress Curve) | S 曲線進度圖 |
| 進度落後 (Schedule Delay) | 落後計劃的狀態 |
| 關鍵路徑 (Critical Path) | 影響專案工期的關鍵任務鏈 |

---

## 🔔 通知系統

| 類型 | 說明 |
|------|------|
| 站內通知 (In-app Notification) | 應用程式內通知 |
| 電子郵件通知 (Email Notification) | 郵件通知 |
| 推播通知 (Push Notification) | 裝置推播 |
| 提及 (@Mention) | @某人的提及通知 |
| 待辦事項 (Todo) | 個人待辦清單 |

---

## 🔄 工作流程

### 任務生命週期

```
建立 → 待處理 → 進行中 → 審核中 → 已完成
                    │
                    └── 已阻塞 ──→ 進行中
```

### 驗收流程

```
驗收申請 → 待驗收 → 驗收判定 → 通過/不通過/有條件通過
```

### 48 小時可撤回規則

任務完成後進入暫存區，48 小時內可撤回修改

---

## 📚 技術術語

| 中文 | 英文 | 說明 |
|------|------|------|
| 行級安全 | Row Level Security (RLS) | Supabase 資料權限控制 |
| 軟刪除 | Soft Delete | 標記刪除而非實際刪除 |
| 樂觀鎖 | Optimistic Lock | 並發更新控制機制 |
| 離線同步 | Offline Sync | 離線操作同步機制 |
| 即時訂閱 | Realtime Subscription | 資料即時更新訂閱 |
| 虛擬捲動 | Virtual Scrolling | 大量資料渲染優化 |

---

**最後更新**: 2025-11-27
