<!-- markdownlint-disable-file -->

# Task Research Notes: GigHub 系統架構與 PRD 完整研究報告

## 研究摘要

本報告基於完整閱讀以下兩份核心文件：
- `docs/architecture/system-architecture.md` (1,439 行)
- `docs/prd/construction-site-management.md` (2,973 行)

**研究目標**: 建立完整的系統架構研究報告，確保開發過程有充分的結構基礎，避免開發缺失。

---

## Research Executed

### File Analysis

- `/home/runner/work/gighub/gighub/docs/architecture/system-architecture.md`
  - 完整閱讀 1,439 行，涵蓋帳戶層級、藍圖容器層、12 項核心基礎設施、六大業務模組

- `/home/runner/work/gighub/gighub/docs/prd/construction-site-management.md`
  - 完整閱讀 2,973 行，涵蓋 PRD 全部章節（1-10 章 + 附錄 A-F）
  - 包含 40 個使用者故事、完整技術規範、資料庫設計、測試策略

### Project Conventions

- Standards referenced: Angular 20 開發規範、Supabase RLS 政策設計
- Instructions followed: `.github/instructions/` 中的架構與開發指引

---

## Key Discoveries

### 1. 三層架構設計

> **核心理念**: 藍圖是邏輯容器，任務是主核心模組，其他模組圍繞任務展開

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        基礎層 (Foundation Layer)                         │
│   問：涉及用戶身份、組織、Bot、認證嗎？                                    │
│   ├── 是 → 在基礎層處理                                                   │
│   └── 否 → 繼續往下層判斷                                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        容器層 (Container Layer)                          │
│   問：涉及藍圖、工作區、分支、權限嗎？                                     │
│   ├── 是 → 在容器層處理                                                   │
│   └── 否 → 在業務層處理                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        業務層 (Business Layer)                           │
│   問：屬於哪個業務模組？                                                  │
│   ├── 任務管理 → tasks, task_attachments                                 │
│   ├── 施工日誌 → diaries, diary_attachments                              │
│   ├── 品質驗收 → checklists, task_acceptances                            │
│   └── 通知系統 → notifications                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 1.1 基礎層 (Foundation Layer) - 帳戶體系

| 實體 | 資料表 | 說明 |
|------|--------|------|
| 帳戶 (Account) | `accounts` | USER / ORGANIZATION / BOT 三種類型 |
| 組織成員 | `organization_members` | 用戶與組織的多對多關聯 |
| 團隊 | `teams` | 隸屬於組織的子單位 |
| 團隊成員 | `team_members` | 用戶與團隊的多對多關聯 |
| 團隊機器人 | `team_bots` | 團隊與 Bot 的多對多關聯 |

**帳戶類型差異**:

| 類型 | 說明 | 建立方式 | 登入能力 |
|------|------|----------|----------|
| User (用戶) | 個人帳戶，可建立/加入組織 | Auth 註冊時自動建立 | ✅ 可登入 |
| Organization (組織) | 企業/團隊主體，擁有多成員 | 用戶手動建立 | ❌ 不可登入 |
| Bot | 自動化執行者，可指派任務 | 組織 Admin 建立 | ❌ 不可登入 (API Token) |

**平台角色體系**:

```
平台層級角色（帳戶體系）
├── 超級管理員 (Super Admin) - 系統全域最高權限
├── 組織擁有者 (Organization Owner) - 組織最高權限者
├── 組織管理員 (Organization Admin) - 組織管理者
└── 一般用戶 (User) - 個人層級使用者
```

**組織角色權限表**:

| 權限 | Owner | Admin | Member |
|------|-------|-------|--------|
| 刪除組織 | ✅ | ❌ | ❌ |
| 轉移擁有權 | ✅ | ❌ | ❌ |
| 管理成員 | ✅ | ✅ | ❌ |
| 建立藍圖 | ✅ | ✅ | ✅ |
| 管理團隊 | ✅ | ✅ | ❌ |
| 建立 Bot | ✅ | ✅ | ❌ |
| 檢視成員 | ✅ | ✅ | ✅ |

#### 1.2 容器層 (Container Layer) - 藍圖系統

| 實體 | 資料表 | 說明 |
|------|--------|------|
| 藍圖 | `blueprints` | 邏輯容器，資料隔離單位 |
| 工作區 | `workspaces` | 從藍圖實例化的工作環境 |
| 藍圖成員 | `blueprint_members` | 藍圖內的成員與角色 |
| 藍圖角色 | `blueprint_roles` | 自訂角色定義 |
| 藍圖分支 | `blueprint_branches` | Git-like 分支管理 |
| 合併請求 | `blueprint_pull_requests` | PR 機制 |

**藍圖擁有權規則**:
- 藍圖只能屬於 **個人 (User)** 或 **組織 (Organization)**
- 不可屬於團隊、BOT 或其他實體
- 組織藍圖由組織統一管理
- 個人藍圖可轉移至組織（不可逆）

**藍圖角色體系**:

| 角色 | 說明 | 權限範圍 |
|------|------|----------|
| Owner 擁有者 | 完全控制權 | 刪除藍圖、轉移擁有權、所有操作 |
| Admin 管理員 | 管理權限 | 成員管理、模組配置、設定工作流程 |
| Member 成員 | 協作權限 | 建立/編輯內容、上傳檔案、討論 |
| Viewer 檢視者 | 唯讀權限 | 查看內容、下載檔案、匯出報表 |

**藍圖層級角色（業務角色）**:

| 角色 | 說明 | 主要職責 |
|------|------|----------|
| 專案經理 (Project Manager) | 藍圖規劃與管理者 | 整體進度規劃、資源分配 |
| 工地主任 (Site Director) | 工地現場最高負責人 | 現場管理、品質控制 |
| 施工人員 (Worker) | 實際執行施工任務者 | 任務執行、進度回報 |
| 品管人員 (QA Staff) | 負責品質檢查者 | 驗收作業、問題開立 |
| 觀察者 (Observer) | 唯讀權限使用者 | 監督、報表檢視 |
| 協作者 (Collaborator) | 外部參與者 | 分包商、合作夥伴 |

#### 1.3 業務層 (Business Layer) - 核心模組

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

**六大業務模組**:

| 模組 | 英文名稱 | 資料模型 | 狀態 |
|------|----------|----------|------|
| 任務 | Tasks | 樹狀結構、進度追蹤 | 🔴 核心模組 |
| 日誌 | Logs/Diaries | 每日記錄、批次照片 | 🔴 高優先 |
| 待辦 | Todos | 個人待辦清單 | 🟡 中優先 |
| 檔案 | Files | 版本控制、分享 | 🟡 中優先 |
| 連結 | Links | 外部資源管理 | 🟢 低優先 |
| 儀表板 | Dashboard | 數據聚合、視覺化 | 🟡 中優先 |

---

### 2. 容器層 12 項核心基礎設施

| # | 基礎設施 | 說明 | 實作方式 | 對應檔案/路徑 |
|---|----------|------|----------|---------------|
| 1 | 上下文注入 | 自動注入 Blueprint/User/Permissions | Angular DI + Signals | `shell/blueprint-shell/` |
| 2 | 權限系統 | RBAC 多層級權限 | RLS + Helper Functions | `guards/`, Helper Functions |
| 3 | 時間軸服務 | 跨模組活動追蹤 | Domain Events | `services/timeline.service.ts` |
| 4 | 通知中心 | 多渠道通知路由 | 站內通知 + Email | `services/notification.service.ts` |
| 5 | 事件總線 | 模組間解耦通訊 | Realtime Broadcast | `services/event-bus.service.ts` |
| 6 | 搜尋引擎 | 跨模組全文檢索 | PostgreSQL FTS | `services/search.service.ts` |
| 7 | 關聯管理 | 跨模組資源引用 | Foreign Key 關聯 | `repositories/relation.repository.ts` |
| 8 | 資料隔離 | RLS 多租戶隔離 | Supabase RLS | PostgreSQL RLS Policies |
| 9 | 生命週期 | Draft/Active/Archived/Deleted | 狀態機管理 | `domain/enums/` |
| 10 | 配置中心 | 藍圖級配置管理 | JSONB Settings | `blueprints.settings` 欄位 |
| 11 | 元數據系統 | 自訂欄位支援 | JSONB + Schema | `blueprints.metadata` 欄位 |
| 12 | API 閘道 | 對外 API 統一入口 | Supabase Functions | `services/api-gateway.service.ts` |

**各基礎設施詳細說明**:

#### 2.1 上下文注入 (Context Injection)

**實作方式**: Angular DI + Signals

```typescript
// BlueprintShellComponent 負責注入上下文
@Component({...})
export class BlueprintShellComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private blueprintStore = inject(BlueprintStore);
  
  ngOnInit() {
    // 從路由取得 blueprintId 並注入到 Store
    this.route.params.pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(params => {
      this.blueprintStore.loadBlueprint(params['id']);
    });
  }
}
```

#### 2.2 權限系統 (Permission System)

**前端快取策略**:
- 權限資料在登入/切換上下文時預載
- 使用 Signals 提供即時權限狀態
- 元件根據權限決定 UI 顯示

**後端強制檢查**:
- RLS Policy 作為最終權限守門員
- Helper Functions 封裝複雜權限邏輯
- 避免繞過前端直接存取 API

**權限檢查流程**:
```
用戶操作 → 前端權限判斷（快取）→ API 請求 → RLS 強制檢查 → 回傳結果
             ↓ 無權限                    ↓ 無權限
           顯示禁用/隱藏               返回 403 錯誤
```

#### 2.3 事件總線 (Event Bus)

**事件格式規範**:
```typescript
interface BroadcastEvent {
  type: string;        // 事件類型，如 'task:updated', 'member:joined'
  payload: object;     // 事件資料
  timestamp: string;   // ISO 8601 格式
  actor_id: string;    // 觸發者帳戶 ID
}
```

**訂閱者實作要點**:
1. 事件必須處理冪等性（重複收到同一事件不應產生副作用）
2. 使用 event.timestamp 判斷是否為過期事件
3. 本地觸發的事件應忽略（actor_id === currentUser.id）

#### 2.4 Realtime 訂閱規範

```typescript
// ✅ 正確：在 ngOnDestroy 中取消訂閱
private channel: RealtimeChannel | null = null;

ngOnInit() {
  this.channel = this.supabase.client
    .channel('tasks')
    .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'tasks' },
        payload => this.handleChange(payload))
    .subscribe();
}

ngOnDestroy() {
  this.channel?.unsubscribe();
}
```

---

### 3. 核心業務模組

#### 3.1 任務系統 (Task System) - 主核心模組

**任務狀態流程**:

```
pending → in_progress → review → completed
                ↓
             cancelled
                ↓
              blocked → in_progress
```

**任務狀態定義**:

| 狀態 | 英文 | 狀態碼 | 說明 |
|------|------|--------|------|
| 待處理 | Pending | `pending` | 任務已建立但未開始 |
| 進行中 | In Progress | `in_progress` | 任務正在執行中 |
| 審核中 | In Review | `in_review` | 等待審核確認 |
| 已完成 | Completed | `completed` | 任務已完成 |
| 已取消 | Cancelled | `cancelled` | 任務被取消 |
| 已阻塞 | Blocked | `blocked` | 任務因故暫停 |

**任務優先級**:

| 優先級 | 英文 | 等級碼 |
|--------|------|--------|
| 最低 | Lowest | `lowest` |
| 低 | Low | `low` |
| 中 | Medium | `medium` |
| 高 | High | `high` |
| 最高 | Highest | `highest` |

**任務類型**:

| 類型 | 英文 | 類型碼 |
|------|------|--------|
| 一般任務 | Task | `task` |
| 里程碑 | Milestone | `milestone` |
| 缺陷 | Bug | `bug` |
| 功能 | Feature | `feature` |
| 改進 | Improvement | `improvement` |

**完整資料表結構**:

```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES tasks(id) ON DELETE CASCADE,  -- 樹狀結構
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('lowest', 'low', 'medium', 'high', 'highest')),
  task_type TEXT DEFAULT 'task' CHECK (task_type IN ('task', 'milestone', 'bug', 'feature', 'improvement')),
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  assignee_id UUID REFERENCES accounts(id),
  reviewer_id UUID REFERENCES accounts(id),
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ  -- 軟刪除
);

-- 索引
CREATE INDEX idx_tasks_blueprint_id ON tasks(blueprint_id);
CREATE INDEX idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
```

**任務樹狀結構限制（PRD 8.11.1 規範）**:

| 限制項目 | 數值 | 理由 |
|----------|------|------|
| 最大層級深度 | 10 層 | 效能考量 + UI 呈現 |
| 單一父節點下子任務數 | 1000 個 | 虛擬捲動效能 |
| 單一藍圖總任務數 | 50,000 個 | 資料庫效能 |
| 同時展開節點數 | 500 個 | 前端記憶體 |

**任務膠囊狀態（UI 顯示規範）**:

```
┌────────────────────────────────────────────────────────────┐
│ [層級] [優先級圖標] 任務名稱 [進度%] [狀態標籤] [👤] [📅] [🐛] │
└────────────────────────────────────────────────────────────┘

範例:
[L2] 🔴 基礎開挖作業 [75%] [進行中] [張三] [12/25] [2]
      │    │                │        │     │      │    └─ 關聯問題數量
      │    │                │        │     │      └────── 截止日期
      │    │                │        │     └───────────── 負責人
      │    │                │        └─────────────────── 狀態標籤
      │    │                └──────────────────────────── 完成百分比
      │    └───────────────────────────────────────────── 優先級 (🔴高 🟡中 🟢低)
      └────────────────────────────────────────────────── 層級 (L1~L10)
```

**任務完工圖片顯示規範**:

- 狀態為「已完成」時：任務名稱後顯示完工照片縮圖
- 縮圖尺寸：32x32 像素
- 點擊縮圖開啟燈箱檢視完整照片
- 多張照片時顯示第一張 + 數量標記（如「📷 +3」）

#### 3.2 施工日誌系統 (Diary System)

**核心欄位**:

| 欄位 | 說明 | 型別 |
|------|------|------|
| 施工日期 (Work Date) | 施工進行的日期 | DATE |
| 工作摘要 (Work Summary) | 當日工作概述 | TEXT |
| 施工工時 (Work Hours) | 實際施工時數 | DECIMAL |
| 施工人數 (Worker Count) | 當日施工人員數量 | INTEGER |
| 天氣狀況 (Weather) | 當日天氣記錄 | ENUM |
| 施工照片 (Site Photos) | 現場拍攝的照片 | 關聯 attachments |
| 日誌簽核 (Diary Approval) | 日誌審核狀態 | ENUM |

**天氣類型**:

| 天氣 | 英文 | 圖示 |
|------|------|------|
| 晴天 | Sunny | ☀️ |
| 多雲 | Cloudy | ⛅ |
| 雨天 | Rainy | 🌧️ |
| 暴風 | Stormy | ⛈️ |
| 雪天 | Snowy | ❄️ |
| 霧天 | Foggy | 🌫️ |

**日誌資料表結構**:

```sql
CREATE TABLE diaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  summary TEXT,
  work_hours DECIMAL(5,2),
  worker_count INTEGER,
  weather TEXT CHECK (weather IN ('sunny', 'cloudy', 'rainy', 'stormy', 'snowy', 'foggy')),
  notes TEXT,
  approval_status TEXT DEFAULT 'draft' CHECK (approval_status IN ('draft', 'submitted', 'approved', 'rejected')),
  created_by UUID NOT NULL REFERENCES accounts(id),
  approved_by UUID REFERENCES accounts(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (blueprint_id, work_date)  -- 每個藍圖每天一筆日誌
);

CREATE TABLE diary_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID NOT NULL REFERENCES diaries(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES files(id),
  caption TEXT,
  exif_data JSONB,  -- 照片 EXIF 資訊
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 3.3 品質驗收系統 (Quality Acceptance)

**驗收狀態流程**:

```
任務完成 → 日誌可提報 → 提報後可 QA → QA 完成 → 驗收
  [DONE]     [REPORTED]    [QA_PENDING]  [QA_PASSED]  [ACCEPTED]
                                ↓
                          [QA_FAILED] → 問題開立
```

**驗收結果**:

| 結果 | 英文 | 狀態碼 | 說明 |
|------|------|--------|------|
| 待驗收 | Pending | `pending` | 等待驗收 |
| 通過 | Passed | `passed` | 驗收合格 |
| 不通過 | Failed | `failed` | 驗收不合格，需改善 |
| 有條件通過 | Conditional | `conditional` | 有附帶條件的通過 |

**驗收資料表結構**:

```sql
CREATE TABLE task_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  checklist_id UUID REFERENCES checklists(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'passed', 'failed', 'conditional')),
  inspector_id UUID NOT NULL REFERENCES accounts(id),
  inspection_date DATE NOT NULL,
  notes TEXT,
  conditions TEXT,  -- 有條件通過的附帶條件
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_template BOOLEAN DEFAULT false,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES checklists(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_required BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**串驗收流程（PRD 8.6 規範）**:

1. 可定義多階段驗收（如：初驗 → 複驗 → 終驗）
2. 可為每階段指定驗收人員
3. 前一階段通過才能進入下一階段
4. 可追蹤驗收鏈狀態
5. 所有階段通過才算最終完成

#### 3.4 問題追蹤系統 (Issue Tracking)

**嚴重程度**:

| 等級 | 英文 | 等級碼 | 說明 |
|------|------|--------|------|
| 低 | Low | `low` | 小問題，不影響進度 |
| 中 | Medium | `medium` | 一般問題，需處理 |
| 高 | High | `high` | 嚴重問題，需優先處理 |
| 緊急 | Critical | `critical` | 緊急問題，立即處理 |

**問題狀態**:

| 狀態 | 英文 | 狀態碼 |
|------|------|--------|
| 新建 | New | `new` |
| 已指派 | Assigned | `assigned` |
| 處理中 | In Progress | `in_progress` |
| 待確認 | Pending Confirm | `pending_confirm` |
| 已解決 | Resolved | `resolved` |
| 已關閉 | Closed | `closed` |
| 已重開 | Reopened | `reopened` |

**問題資料表結構**:

```sql
CREATE TABLE issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  task_id UUID REFERENCES tasks(id),
  title VARCHAR(500) NOT NULL,
  description TEXT,
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'assigned', 'in_progress', 'pending_confirm', 'resolved', 'closed', 'reopened')),
  assignee_id UUID REFERENCES accounts(id),
  reporter_id UUID NOT NULL REFERENCES accounts(id),
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
```

---

### 4. 技術架構

#### 4.1 技術棧

| 類別 | 技術 | 版本 | 說明 |
|------|------|------|------|
| 前端框架 | Angular | 20.3.x | 使用 Standalone Components |
| UI 框架 | ng-alain | 20.1.x | 企業級 Admin 框架 |
| UI 元件庫 | ng-zorro-antd | 20.3.x | Ant Design for Angular |
| 狀態管理 | Angular Signals | 內建 | 反應式狀態管理 |
| HTTP 客戶端 | HttpClient | 內建 | Angular HTTP 模組 |
| 後端服務 | Supabase | 2.84.x | BaaS 平台 |
| 資料庫 | PostgreSQL | 15.x | 關聯式資料庫 |
| 認證 | Supabase Auth | - | 身份認證 |
| 認證整合 | @delon/auth | - | ng-alain 認證模組 |
| 樣式 | LESS | - | CSS 預處理器 |

#### 4.2 Angular 20 核心特性應用

**Standalone 架構**:
- 完全採用 Standalone 元件架構
- 不使用 NgModule
- 使用 `bootstrapApplication` 啟動應用程式
- 使用 `provide*` APIs 設定

**Signals 狀態管理**:
- 使用 `signal()`, `computed()`, `effect()` 管理狀態
- Signal 用於同步反應式，Observable 用於非同步與時間序列
- 使用 `toSignal()` / `toObservable()` 進行轉換

**新控制流語法**:
```html
<!-- ✅ 使用新語法 -->
@if (loading()) {
  <nz-spin nzSimple></nz-spin>
} @else {
  <div>內容</div>
}

@for (task of tasks(); track task.id) {
  <app-task-card [task]="task" />
} @empty {
  <nz-empty nzNotFoundContent="暫無資料"></nz-empty>
}
```

**必須使用的 API**:
```typescript
@Component({
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TaskComponent {
  // 輸入 - 使用函數式 API
  task = input.required<Task>();
  isEditable = input(false);

  // 輸出 - 使用函數式 API
  taskSelected = output<Task>();

  // 依賴注入 - 使用 inject()
  private readonly store = inject(TaskStore);

  // 計算屬性
  protected readonly isOverdue = computed(() => {
    const task = this.task();
    return task.dueDate && new Date(task.dueDate) < new Date();
  });
}
```

#### 4.3 前端架構 - Feature 垂直切片結構

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

**完整 Angular 專案資料夾結構**:

```
src/app/
├── core/                           # 【基礎層】核心基礎設施
│   ├── facades/                    # Facade 模式統一 API
│   │   └── account/                # 帳戶上下文 Facade
│   │       └── workspace-context.facade.ts
│   ├── guards/                     # 路由守衛
│   ├── interceptors/               # HTTP 攔截器
│   └── services/                   # 全域服務
│       ├── auth/                   # 認證服務
│       ├── organization/           # 組織服務
│       └── billing/                # 計費服務
│
├── shared/                         # 【共享資源】跨模組共享
│   ├── components/                 # 共用元件
│   ├── directives/                 # 共用指令
│   ├── pipes/                      # 共用管道
│   ├── services/                   # 共用服務
│   ├── models/                     # 共用模型
│   └── utils/                      # 共用工具
│
├── layout/                         # 【版面配置】版面元件
│   ├── basic/                      # 基礎版面
│   ├── blank/                      # 空白版面
│   └── passport/                   # 登入版面
│
├── routes/                         # 【路由頁面】路由頁面
│   ├── account/                    # 帳戶頁面
│   ├── passport/                   # 登入頁面
│   └── exception/                  # 例外頁面
│
└── features/                       # 【容器層 + 業務模組層】功能模組
     └── blueprint/                 # 藍圖功能模組（垂直切片）
         ├── blueprint.routes.ts    # 路由配置
         ├── shell/                 # 【容器層】邏輯容器層
         │   ├── blueprint-shell/   # 藍圖外殼元件
         │   └── dialogs/           # 對話框元件
         ├── domain/                # 【容器層】領域層
         │   ├── enums/             # 枚舉定義
         │   ├── interfaces/        # 介面定義
         │   ├── models/            # 領域模型
         │   └── types/             # 類型定義
         ├── data-access/           # 【容器層】資料存取層
         │   ├── stores/            # 狀態管理 (Signal Store)
         │   │   ├── blueprint.store.ts
         │   │   ├── task.store.ts
         │   │   ├── diary.store.ts
         │   │   └── todo.store.ts
         │   ├── services/          # 業務服務
         │   └── repositories/      # 資料倉儲 (Supabase)
         └── ui/                    # 【業務模組層】展示層
             ├── task/              # 工項管理模組
             ├── diary/             # 施工日誌模組
             ├── todo/              # 待辦事項模組
             ├── file/              # 檔案管理模組
             ├── link/              # 連結管理模組
             └── progress/          # 進度模組
```

#### 4.4 上下文傳遞機制

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

**上下文傳遞規則**:

| 層級 | 提供者 | 消費者 | 方式 |
|------|--------|--------|------|
| 平台 → 藍圖 | WorkspaceContextFacade | BlueprintShellComponent | `inject()` DI |
| 藍圖 → 模組 | BlueprintStore | TaskStore, DiaryStore... | Route Params + inject() |
| 模組 → UI | XxxStore | XxxComponent | Angular Signals |

#### 4.5 Repository 模式規範

**核心原則**:
- Supabase Client 只能在 Repository 層使用
- 元件和服務不可直接呼叫 Supabase API
- Repository 封裝所有資料存取邏輯

**Repository 模板**:

```typescript
@Injectable({ providedIn: 'root' })
export class TaskRepository {
  private readonly supabase = inject(SupabaseService);
  private readonly TABLE = 'tasks';

  async findByBlueprint(blueprintId: string): Promise<Task[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .eq('blueprint_id', blueprintId)
      .order('sort_order', { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  async create(dto: CreateTaskDto): Promise<Task> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .insert(dto)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}
```

#### 4.6 Store 模式規範

**Store 模板**:

```typescript
@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly repository = inject(TaskRepository);

  // Private state
  private readonly _tasks = signal<Task[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly tasks = this._tasks.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed properties
  readonly pendingTasks = computed(() =>
    this._tasks().filter(t => t.status === 'pending')
  );

  // Update method - ✅ 使用 update
  async createTask(data: CreateTaskDto): Promise<Task | null> {
    const task = await this.repository.create(data);
    this._tasks.update(tasks => [...tasks, task]);
    return task;
  }
}
```

**Signal 操作規則**:
```typescript
// ❌ 禁止：直接修改 Signal 內部值
this._tasks().push(newTask);

// ✅ 正確：使用 update 方法
this._tasks.update(tasks => [...tasks, newTask]);
```

---

### 5. 資料庫設計

#### 5.1 既有資料表（已完成）

| 表名 | 用途 | 狀態 | 欄位數 |
|------|------|------|--------|
| `accounts` | 帳戶（含 USER/ORG/BOT 類型） | ✅ 完成 | 12 |
| `teams` | 團隊（屬於組織） | ✅ 完成 | 8 |
| `organization_members` | 組織成員關聯 | ✅ 完成 | 6 |
| `team_members` | 團隊成員關聯 | ✅ 完成 | 6 |
| `team_bots` | 團隊 Bot 關聯 | ✅ 完成 | 6 |

#### 5.2 待建立資料表

| 表名 | 用途 | 優先級 | 預估欄位數 |
|------|------|--------|------------|
| `blueprints` | 藍圖主表 | 🔴 高 | 15 |
| `blueprint_members` | 藍圖成員與角色 | 🔴 高 | 8 |
| `blueprint_roles` | 藍圖自訂角色定義 | 🔴 高 | 10 |
| `tasks` | 任務主表（樹狀結構） | 🔴 高 | 20 |
| `task_attachments` | 任務附件（含完工圖片） | 🔴 高 | 10 |
| `task_comments` | 任務討論 | 🟡 中 | 8 |
| `task_acceptances` | 任務驗收記錄 | 🔴 高 | 12 |
| `diaries` | 每日施工日誌 | 🔴 高 | 15 |
| `diary_attachments` | 日誌附件 | 🔴 高 | 8 |
| `files` | 檔案主表（含版本） | 🔴 高 | 15 |
| `file_versions` | 檔案版本歷史 | 🟡 中 | 10 |
| `checklists` | 品質檢查清單模板 | 🟡 中 | 8 |
| `checklist_items` | 檢查清單項目 | 🟡 中 | 8 |
| `issues` | 問題追蹤 | 🟡 中 | 15 |
| `notifications` | 通知中心 | 🟡 中 | 12 |
| `blueprint_branches` | Git-like 分支 | 🟡 中 | 10 |
| `blueprint_pull_requests` | 分支合併請求 | 🟡 中 | 12 |
| `timeline_events` | 時間軸事件 | 🟢 低 | 10 |
| `links` | 外部連結 | 🟢 低 | 8 |

#### 5.3 核心資料表完整 Schema

**blueprints 藍圖主表**:

```sql
CREATE TABLE blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES accounts(id),  -- 擁有者（User 或 Organization）
  name VARCHAR(255) NOT NULL,
  description TEXT,
  slug VARCHAR(100),  -- URL 友善名稱
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'internal', 'public')),
  settings JSONB DEFAULT '{}',  -- 藍圖級配置
  metadata JSONB DEFAULT '{}',  -- 自訂元數據
  cover_image_url TEXT,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (owner_id, slug)
);

CREATE INDEX idx_blueprints_owner_id ON blueprints(owner_id);
CREATE INDEX idx_blueprints_status ON blueprints(status);
CREATE INDEX idx_blueprints_slug ON blueprints(slug);
```

**blueprint_members 藍圖成員**:

```sql
CREATE TABLE blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  business_role TEXT,  -- 業務角色：project_manager, site_director, worker, qa_staff, observer
  joined_at TIMESTAMPTZ DEFAULT now(),
  invited_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (blueprint_id, account_id)
);

CREATE INDEX idx_blueprint_members_blueprint_id ON blueprint_members(blueprint_id);
CREATE INDEX idx_blueprint_members_account_id ON blueprint_members(account_id);
```

**files 檔案主表**:

```sql
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  size_bytes BIGINT NOT NULL,
  storage_path TEXT NOT NULL,  -- Supabase Storage 路徑
  thumbnail_path TEXT,
  file_type TEXT CHECK (file_type IN ('image', 'document', 'spreadsheet', 'cad_drawing', 'video', 'other')),
  parent_folder_id UUID REFERENCES files(id),
  is_folder BOOLEAN DEFAULT false,
  current_version INTEGER DEFAULT 1,
  uploaded_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_files_blueprint_id ON files(blueprint_id);
CREATE INDEX idx_files_parent_folder_id ON files(parent_folder_id);
CREATE INDEX idx_files_uploaded_by ON files(uploaded_by);
```

**task_attachments 任務附件**:

```sql
CREATE TABLE task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES files(id),
  attachment_type TEXT DEFAULT 'general' CHECK (attachment_type IN ('general', 'completion_photo', 'reference', 'issue_evidence')),
  caption TEXT,
  is_completion_photo BOOLEAN DEFAULT false,  -- 是否為完工照片
  sort_order INTEGER DEFAULT 0,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_task_attachments_task_id ON task_attachments(task_id);
CREATE INDEX idx_task_attachments_file_id ON task_attachments(file_id);
```

**notifications 通知**:

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES accounts(id),
  blueprint_id UUID REFERENCES blueprints(id),
  notification_type TEXT NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ
);

CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

#### 5.4 RLS Helper Functions

**既有 Helper Functions**:

| 函數名稱 | 用途 | 狀態 |
|----------|------|------|
| `get_user_account_id()` | 取得當前用戶帳戶 ID | ✅ 完成 |
| `is_org_member(org_id)` | 檢查是否為組織成員 | ✅ 完成 |
| `is_team_member(team_id)` | 檢查是否為團隊成員 | ✅ 完成 |
| `get_user_role_in_org(org_id)` | 取得用戶在組織的角色 | ✅ 完成 |

**待建立 Helper Functions**:

```sql
-- 1. 檢查是否為藍圖成員
CREATE OR REPLACE FUNCTION is_blueprint_member(p_blueprint_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = get_user_account_id()
  );
END;
$$;

-- 2. 取得用戶在藍圖的角色
CREATE OR REPLACE FUNCTION get_user_role_in_blueprint(p_blueprint_id uuid)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_role TEXT;
BEGIN
  SELECT role INTO v_role
  FROM blueprint_members
  WHERE blueprint_id = p_blueprint_id
  AND account_id = get_user_account_id();
  
  RETURN COALESCE(v_role, 'none');
END;
$$;

-- 3. 檢查任務存取權限（通過藍圖成員資格）
CREATE OR REPLACE FUNCTION can_access_task(p_task_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_blueprint_id uuid;
BEGIN
  SELECT blueprint_id INTO v_blueprint_id
  FROM tasks
  WHERE id = p_task_id;
  
  IF v_blueprint_id IS NULL THEN
    RETURN false;
  END IF;
  
  RETURN is_blueprint_member(v_blueprint_id);
END;
$$;

-- 4. 遞迴計算任務進度
CREATE OR REPLACE FUNCTION calculate_task_progress(p_task_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_has_children boolean;
  v_avg_progress integer;
BEGIN
  -- 檢查是否有子任務
  SELECT EXISTS(
    SELECT 1 FROM tasks WHERE parent_id = p_task_id AND deleted_at IS NULL
  ) INTO v_has_children;
  
  IF NOT v_has_children THEN
    -- 沒有子任務，返回自身進度
    SELECT progress INTO v_avg_progress FROM tasks WHERE id = p_task_id;
    RETURN COALESCE(v_avg_progress, 0);
  END IF;
  
  -- 有子任務，計算子任務平均進度
  SELECT COALESCE(AVG(calculate_task_progress(id)), 0)::integer INTO v_avg_progress
  FROM tasks
  WHERE parent_id = p_task_id AND deleted_at IS NULL;
  
  RETURN v_avg_progress;
END;
$$;

-- 5. 檢查是否可編輯任務
CREATE OR REPLACE FUNCTION can_edit_task(p_task_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_blueprint_id uuid;
  v_role TEXT;
BEGIN
  SELECT blueprint_id INTO v_blueprint_id
  FROM tasks WHERE id = p_task_id;
  
  v_role := get_user_role_in_blueprint(v_blueprint_id);
  
  RETURN v_role IN ('owner', 'admin', 'member');
END;
$$;
```

#### 5.5 RLS 政策設計

**設計原則**:
- 每張表必須有 RLS 政策
- 使用 Helper Functions 封裝權限檢查
- 避免在 RLS 中直接查詢受保護的表（防止遞迴）

**blueprints 表 RLS**:

```sql
ALTER TABLE blueprints ENABLE ROW LEVEL SECURITY;

-- SELECT: 成員可查看
CREATE POLICY "blueprint_members_can_view" ON blueprints FOR SELECT
USING (is_blueprint_member(id) OR owner_id = get_user_account_id());

-- INSERT: 任何登入用戶可建立
CREATE POLICY "authenticated_users_can_create" ON blueprints FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: 只有 owner 和 admin 可修改
CREATE POLICY "blueprint_admins_can_update" ON blueprints FOR UPDATE
USING (get_user_role_in_blueprint(id) IN ('owner', 'admin'));

-- DELETE: 只有 owner 可刪除
CREATE POLICY "blueprint_owner_can_delete" ON blueprints FOR DELETE
USING (get_user_role_in_blueprint(id) = 'owner');
```

**tasks 表 RLS**:

```sql
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- SELECT: 藍圖成員可查看
CREATE POLICY "blueprint_members_can_view_tasks" ON tasks FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- INSERT: member 以上可建立
CREATE POLICY "blueprint_members_can_create_tasks" ON tasks FOR INSERT
WITH CHECK (
  is_blueprint_member(blueprint_id) AND
  get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin', 'member')
);

-- UPDATE: member 以上可修改
CREATE POLICY "blueprint_members_can_update_tasks" ON tasks FOR UPDATE
USING (
  is_blueprint_member(blueprint_id) AND
  get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin', 'member')
);

-- DELETE: admin 以上可刪除
CREATE POLICY "blueprint_admins_can_delete_tasks" ON tasks FOR DELETE
USING (get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin'));
```

---

### 6. 安全與權限設計

#### 6.1 RLS 政策設計原則

- 每張表必須有 RLS 政策
- 使用 Helper Functions 封裝權限檢查
- 避免在 RLS 中直接查詢受保護的表（防止遞迴）
- 使用 SECURITY DEFINER 函數避免權限提升問題

**正確範例**:

```sql
-- ✅ 使用 SECURITY DEFINER 函數避免遞迴
CREATE OR REPLACE FUNCTION is_blueprint_member(p_blueprint_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = get_user_account_id()
  );
END;
$$;

CREATE POLICY "users_can_view_own_tasks" ON tasks FOR SELECT
USING (is_blueprint_member(blueprint_id));
```

**錯誤範例**:

```sql
-- ❌ 在 RLS 中直接查詢受保護的表（會導致無限遞迴）
CREATE POLICY "..." ON accounts
USING (id IN (SELECT account_id FROM organization_members WHERE ...));
```

#### 6.2 權限檢查流程

```
用戶操作 → 前端權限判斷（快取） → API 請求 → RLS 強制檢查 → 回傳結果
             ↓ 無權限                    ↓ 無權限
           顯示禁用/隱藏               返回 403 錯誤
```

**前端權限快取**:
- 權限資料在登入/切換上下文時預載
- 使用 Signals 提供即時權限狀態
- 元件根據權限決定 UI 顯示

**後端強制檢查**:
- RLS Policy 作為最終權限守門員
- Helper Functions 封裝複雜權限邏輯
- 避免繞過前端直接存取 API

#### 6.3 XSS 防護

```typescript
// ❌ 禁止：直接使用 innerHTML
element.innerHTML = userInput;

// ✅ 正確：使用 Angular 的內建綁定（自動清理）
@Component({ template: `<div [textContent]="userContent"></div>` })
class MyComponent {
  userContent = userInput; // Angular 自動轉義
}

// ⚠️ 需要 HTML 渲染時，使用 DomSanitizer.sanitize()
@Component({ template: `<div [innerHTML]="trustedHtml"></div>` })
class MyComponent {
  private readonly sanitizer = inject(DomSanitizer);
  sanitizedContent = this.sanitizer.sanitize(SecurityContext.HTML, untrustedContent);
}
```

#### 6.4 敏感資料處理

```typescript
// ❌ 禁止：在日誌中輸出敏感資料
console.log('User token:', token);
console.log('Password:', password);

// ✅ 正確：只記錄必要資訊
console.log('User authenticated:', userId);
```

```typescript
// ❌ 禁止：在 URL 中傳遞敏感資料
router.navigate(['/api'], { queryParams: { token: authToken } });

// ✅ 正確：使用 Header
this.http.post('/api', data, { headers: { Authorization: `Bearer ${token}` } });
```

#### 6.5 SQL 注入防護

```typescript
// ❌ 禁止：字串拼接 SQL
const query = `SELECT * FROM tasks WHERE name = '${userInput}'`;

// ✅ 正確：使用參數化查詢（Supabase 自動處理）
const { data } = await this.supabase.client
  .from('tasks')
  .select('*')
  .eq('name', userInput);
```

---

### 7. 離線同步與衝突解決

#### 7.1 離線同步策略

```
離線操作流程:
1. 離線時操作 → IndexedDB 暫存 (帶 localTimestamp)
2. 恢復連線 → 批次提交至 Supabase
3. 衝突偵測 → 比較 updated_at vs localTimestamp
4. 自動解決 → 一般欄位採 Last-Write-Wins
5. 手動解決 → 狀態/進度等關鍵欄位提示用戶選擇
```

#### 7.2 衝突類型處理

| 欄位類型 | 解決策略 |
|----------|----------|
| 描述/備註 | Last-Write-Wins |
| 狀態/進度 | 提示用戶選擇 |
| 照片附件 | 全部保留（合併） |

---

### 8. 效能基準

#### 8.1 前端效能目標

| 指標 | 目標值 |
|------|--------|
| 首次內容繪製 (FCP) | < 1.5s |
| 最大內容繪製 (LCP) | < 2.5s |
| 互動至下一次繪製 (INP) | < 200ms |
| 累積佈局偏移 (CLS) | < 0.1 |
| 任務樹渲染 (1000 節點) | < 500ms |

#### 8.2 後端效能目標

| 指標 | 目標值 |
|------|--------|
| API 回應時間 (P50) | < 200ms |
| API 回應時間 (P95) | < 500ms |
| API 回應時間 (P99) | < 1s |
| 資料庫查詢 (P95) | < 100ms |

---

### 9. 測試策略

#### 9.1 覆蓋率目標

| 層級 | 目標 | 測試重點 |
|------|------|----------|
| Store 層 | 100% | 狀態變更、computed signals |
| Service 層 | 80%+ | API 呼叫、錯誤處理 |
| Component 層 | 60%+ | 關鍵交互、表單提交 |
| Utils | 100% | 純函數、邊界條件 |

#### 9.2 測試命名規範

```typescript
// 格式：MethodName_Condition_ExpectedResult
it('loadTasks_whenBlueprintIdValid_shouldReturnTasks', () => { ... });
it('updateStatus_whenNoPermission_shouldThrowError', () => { ... });
```

---

### 10. 開發里程碑

#### 10.1 專案規模

- **規模**: 中大型專案
- **預估時程**: 12-16 週
- **團隊規模**: 4-6 人

#### 10.2 階段規劃

| 階段 | 週次 | 目標 |
|------|------|------|
| 第零階段 | 1-2 週 | 基礎設施強化（帳戶體系 + 藍圖系統） |
| 第一階段 | 3-5 週 | 任務系統達到生產水平 |
| 第一點五階段 | 6-7 週 | 檔案系統 |
| 第二階段 | 8-9 週 | 日誌系統 |
| 第三階段 | 10-11 週 | 進度追蹤儀表板 |
| 第四階段 | 12-13 週 | 品質驗收系統 |
| 第五階段 | 14-16 週 | 協作、報表與上線 |

#### 10.3 現有已完成功能

| 功能 | 實現狀態 | 核心檔案 |
|------|----------|----------|
| 工作區上下文切換 | ✅ 100% | `workspace-context.facade.ts` |
| 藍圖邏輯容器 | ✅ 100% | `blueprint-shell.component.ts` |
| 任務樹狀結構 | ✅ 90% | `task-tree.component.ts` |
| 任務表格視圖 | ✅ 90% | `task-table.component.ts` |
| 日誌列表框架 | ✅ 60% | `diary-list.component.ts` |
| 待辦列表框架 | ✅ 40% | `todo-list.component.ts` |

---

### 11. 使用者故事索引

PRD 定義了 40 個完整使用者故事，分為以下類別：

| 類別 | 故事數量 | ID 範圍 | 優先級 |
|------|----------|---------|--------|
| 帳戶與認證 | 4 | GH-001 ~ GH-004 | 🔴 高 |
| 組織與團隊 | 4 | GH-005 ~ GH-008 | 🔴 高 |
| 藍圖管理 | 4 | GH-009 ~ GH-012 | 🔴 高 |
| 任務管理 | 5 | GH-013 ~ GH-017 | 🔴 高 |
| 施工日誌 | 4 | GH-018 ~ GH-021 | 🔴 高 |
| 品質驗收 | 4 | GH-022 ~ GH-025 | 🟡 中 |
| 問題追蹤 | 3 | GH-026 ~ GH-028 | 🟡 中 |
| 協作溝通 | 3 | GH-029 ~ GH-031 | 🟡 中 |
| 報表分析 | 3 | GH-032 ~ GH-034 | 🟡 中 |
| 離線與同步 | 3 | GH-035 ~ GH-037 | 🟢 低 |
| 系統管理 | 3 | GH-038 ~ GH-040 | 🟢 低 |

#### 11.1 使用者故事完整列表

**帳戶與認證 (GH-001 ~ GH-004)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-001 | 用戶註冊 | P0 | 作為新用戶，我想要註冊帳號以使用系統 |
| GH-002 | 用戶登入 | P0 | 作為已註冊用戶，我想要登入系統以存取我的資料 |
| GH-003 | 密碼重設 | P1 | 作為忘記密碼的用戶，我想要重設密碼 |
| GH-004 | 個人資料管理 | P2 | 作為用戶，我想要管理我的個人資料 |

**組織與團隊 (GH-005 ~ GH-008)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-005 | 建立組織 | P0 | 作為用戶，我想要建立組織以管理團隊和專案 |
| GH-006 | 邀請成員加入組織 | P0 | 作為組織管理員，我想要邀請成員加入 |
| GH-007 | 建立團隊 | P1 | 作為組織管理員，我想要建立團隊以分組管理 |
| GH-008 | 管理組織成員權限 | P1 | 作為組織管理員，我想要設定成員權限 |

**藍圖管理 (GH-009 ~ GH-012)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-009 | 建立藍圖 | P0 | 作為用戶，我想要建立藍圖以規劃施工項目 |
| GH-010 | 藍圖成員管理 | P0 | 作為藍圖管理員，我想要管理藍圖成員 |
| GH-011 | 藍圖設定 | P1 | 作為藍圖管理員，我想要設定藍圖參數 |
| GH-012 | 藍圖分支管理 | P2 | 作為藍圖管理員，我想要使用分支管理變更 |

**任務管理 (GH-013 ~ GH-017)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-013 | 建立任務 | P0 | 作為施工人員，我想要建立任務以追蹤工作項目 |
| GH-014 | 任務樹狀結構 | P0 | 作為專案經理，我想要以樹狀結構組織任務 |
| GH-015 | 任務狀態管理 | P0 | 作為施工人員，我想要更新任務狀態 |
| GH-016 | 任務指派 | P1 | 作為工地主任，我想要將任務指派給施工人員 |
| GH-017 | 任務附件管理 | P1 | 作為施工人員，我想要上傳任務相關附件 |

**施工日誌 (GH-018 ~ GH-021)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-018 | 建立施工日誌 | P0 | 作為施工人員，我想要記錄每日施工情況 |
| GH-019 | 日誌照片上傳 | P0 | 作為施工人員，我想要上傳現場照片 |
| GH-020 | 日誌審核 | P1 | 作為工地主任，我想要審核施工日誌 |
| GH-021 | 日誌報表 | P2 | 作為專案經理，我想要查看日誌報表 |

**品質驗收 (GH-022 ~ GH-025)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-022 | 建立檢查清單 | P1 | 作為品管人員，我想要建立品質檢查清單 |
| GH-023 | 執行驗收 | P1 | 作為品管人員，我想要對任務進行驗收 |
| GH-024 | 驗收記錄 | P1 | 作為品管人員，我想要記錄驗收結果 |
| GH-025 | 串驗收流程 | P2 | 作為品管人員，我想要設定多階段驗收流程 |

**問題追蹤 (GH-026 ~ GH-028)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-026 | 開立問題 | P1 | 作為品管人員，我想要開立問題單 |
| GH-027 | 問題指派 | P1 | 作為工地主任，我想要指派問題處理人員 |
| GH-028 | 問題解決追蹤 | P1 | 作為專案經理，我想要追蹤問題解決進度 |

**協作溝通 (GH-029 ~ GH-031)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-029 | 任務討論 | P2 | 作為施工人員，我想要在任務中討論問題 |
| GH-030 | @提及通知 | P2 | 作為用戶，我想要 @提及其他成員 |
| GH-031 | 通知中心 | P2 | 作為用戶，我想要接收系統通知 |

**報表分析 (GH-032 ~ GH-034)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-032 | 進度儀表板 | P2 | 作為專案經理，我想要查看整體進度 |
| GH-033 | 進度曲線圖 | P2 | 作為專案經理，我想要查看 S 曲線進度 |
| GH-034 | 匯出報表 | P2 | 作為專案經理，我想要匯出報表 |

**離線與同步 (GH-035 ~ GH-037)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-035 | 離線操作 | P2 | 作為施工人員，我想要在離線時繼續操作 |
| GH-036 | 自動同步 | P2 | 作為施工人員，我想要恢復連線時自動同步 |
| GH-037 | 衝突解決 | P3 | 作為施工人員，我想要處理同步衝突 |

**系統管理 (GH-038 ~ GH-040)**:

| ID | 故事名稱 | 優先級 | 說明 |
|----|----------|--------|------|
| GH-038 | 系統設定 | P3 | 作為系統管理員，我想要管理系統設定 |
| GH-039 | 用戶管理 | P3 | 作為系統管理員，我想要管理所有用戶 |
| GH-040 | 系統日誌 | P3 | 作為系統管理員，我想要查看系統日誌 |

---

## Recommended Approach

### 實作優先順序

1. **第一優先 - 基礎設施**
   - 完成 `blueprints` 表與 RLS 政策
   - 實作 `is_blueprint_member()` Helper Function
   - 建立 Blueprint 成員管理機制

2. **第二優先 - 任務系統核心**
   - 完成 `tasks` 表與樹狀結構
   - 實作任務 CRUD 與狀態流轉
   - 完成任務附件上傳功能

3. **第三優先 - 日誌與驗收**
   - 實作施工日誌功能
   - 建立品質驗收流程
   - 整合問題追蹤

### 技術實作重點

- 嚴格遵循 Repository 模式（Supabase Client 只能在 Repository 層使用）
- 使用 Angular Signals 進行狀態管理
- 所有元件使用 `ChangeDetectionStrategy.OnPush`
- 使用 `takeUntilDestroyed` 管理 RxJS 訂閱

---

## Implementation Guidance

- **Objectives**: 建構完整的工地施工進度追蹤管理系統，涵蓋任務管理、施工日誌、品質驗收、問題追蹤等核心功能
- **Key Tasks**: 按階段實作基礎設施、任務系統、日誌系統、驗收系統、協作功能
- **Dependencies**: Angular 20、ng-alain 20、ng-zorro-antd 20、Supabase、PostgreSQL 15
- **Success Criteria**: 
  - 所有模組達到企業標準+生產水平
  - 測試覆蓋率達到規定目標
  - 效能指標符合基準要求
  - 完整的離線同步支援

---

## 相關文件索引

| 文件 | 路徑 | 說明 |
|------|------|------|
| 系統架構 | `docs/architecture/system-architecture.md` | 三層架構設計 |
| PRD | `docs/prd/construction-site-management.md` | 完整產品需求 |
| ER 圖 | `docs/architecture/06-entity-relationship-diagram.mermaid.md` | 資料模型 |
| RLS 矩陣 | `docs/architecture/09-security-rls-permission-matrix.md` | 權限設計 |
| 架構層原子化 | `docs/architecture/22-architecture-layers-atomization-design.md` | 架構指引 |

---

**研究完成時間**: 2025-11-27
**研究者**: Task Researcher Agent
**文件狀態**: 完成
