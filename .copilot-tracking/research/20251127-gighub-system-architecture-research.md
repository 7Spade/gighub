<!-- markdownlint-disable-file -->

# Task Research Notes: GigHub 系統架構與 PRD 完整研究報告

## 研究摘要

本報告基於完整閱讀以下兩份核心文件：
- `docs/architecture/system-architecture.md` (1,439 行)
- `docs/prd/construction-site-management.md` (2,973 行)

---

## Research Executed

### File Analysis

- `/home/runner/work/gighub/gighub/docs/architecture/system-architecture.md`
  - 完整閱讀 1,439 行，涵蓋帳戶層級、藍圖容器層、12 項核心基礎設施

- `/home/runner/work/gighub/gighub/docs/prd/construction-site-management.md`
  - 完整閱讀 2,973 行，涵蓋 PRD 全部章節（1-10 章 + 附錄 A-F）

### Project Conventions

- Standards referenced: Angular 20 開發規範、Supabase RLS 政策設計
- Instructions followed: `.github/instructions/` 中的架構與開發指引

---

## Key Discoveries

### 1. 三層架構設計

#### 1.1 基礎層 (Foundation Layer) - 帳戶體系

| 實體 | 資料表 | 說明 |
|------|--------|------|
| 帳戶 (Account) | `accounts` | USER / ORGANIZATION / BOT 三種類型 |
| 組織成員 | `organization_members` | 用戶與組織的多對多關聯 |
| 團隊 | `teams` | 隸屬於組織的子單位 |
| 團隊成員 | `team_members` | 用戶與團隊的多對多關聯 |

**帳戶類型差異**:

| 類型 | 說明 | 建立方式 |
|------|------|----------|
| User (用戶) | 個人帳戶，可建立/加入組織 | Auth 註冊時自動建立 |
| Organization (組織) | 企業/團隊主體，擁有多成員 | 用戶手動建立 |
| Bot | 自動化執行者，可指派任務 | 組織 Admin 建立 |

**平台角色體系**:

```
平台層級角色（帳戶體系）
├── 超級管理員 (Super Admin) - 系統全域最高權限
├── 組織擁有者 (Organization Owner) - 組織最高權限者
├── 組織管理員 (Organization Admin) - 組織管理者
└── 一般用戶 (User) - 個人層級使用者
```

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

---

### 2. 容器層 12 項核心基礎設施

| # | 基礎設施 | 說明 | 實作方式 |
|---|----------|------|----------|
| 1 | 上下文注入 | 自動注入 Blueprint/User/Permissions | Angular DI + Signals |
| 2 | 權限系統 | RBAC 多層級權限 | RLS + Helper Functions |
| 3 | 時間軸服務 | 跨模組活動追蹤 | Domain Events |
| 4 | 通知中心 | 多渠道通知路由 | 站內通知 + Email |
| 5 | 事件總線 | 模組間解耦通訊 | Realtime Broadcast |
| 6 | 搜尋引擎 | 跨模組全文檢索 | PostgreSQL FTS |
| 7 | 關聯管理 | 跨模組資源引用 | Foreign Key 關聯 |
| 8 | 資料隔離 | RLS 多租戶隔離 | Supabase RLS |
| 9 | 生命週期 | Draft/Active/Archived/Deleted | 狀態機管理 |
| 10 | 配置中心 | 藍圖級配置管理 | JSONB Settings |
| 11 | 元數據系統 | 自訂欄位支援 | JSONB + Schema |
| 12 | API 閘道 | 對外 API 統一入口 | Supabase Functions |

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

**資料表結構**:

```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES tasks(id) ON DELETE CASCADE,  -- 樹狀結構
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  task_type TEXT DEFAULT 'task',
  progress INTEGER DEFAULT 0,
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**任務樹狀結構限制**:

| 限制項目 | 數值 | 理由 |
|----------|------|------|
| 最大層級深度 | 10 層 | 效能考量 + UI 呈現 |
| 單一父節點下子任務數 | 1000 個 | 虛擬捲動效能 |
| 單一藍圖總任務數 | 50,000 個 | 資料庫效能 |
| 同時展開節點數 | 500 個 | 前端記憶體 |

#### 3.2 施工日誌系統 (Diary System)

**核心欄位**:
- 施工日期 (Work Date)
- 工作摘要 (Work Summary)
- 施工工時 (Work Hours)
- 施工人數 (Worker Count)
- 天氣狀況 (Weather)
- 施工照片 (Site Photos)

**天氣類型**: Sunny ☀️ | Cloudy ⛅ | Rainy 🌧️ | Stormy ⛈️ | Snowy ❄️ | Foggy 🌫️

#### 3.3 品質驗收系統 (Quality Acceptance)

**驗收狀態流程**:

```
任務完成 → 日誌可提報 → 提報後可 QA → QA 完成 → 驗收
  [DONE]     [REPORTED]    [QA_PENDING]  [QA_PASSED]  [ACCEPTED]
```

**驗收結果**: pending | passed | failed | conditional

#### 3.4 問題追蹤系統 (Issue Tracking)

**嚴重程度**: low | medium | high | critical

**問題狀態**: new → assigned → in_progress → pending_confirm → resolved → closed

---

### 4. 技術架構

#### 4.1 技術棧

| 類別 | 技術 | 版本 |
|------|------|------|
| 前端框架 | Angular | 20.3.x |
| UI 框架 | ng-alain | 20.1.x |
| UI 元件庫 | ng-zorro-antd | 20.3.x |
| 狀態管理 | Angular Signals | 內建 |
| 後端服務 | Supabase | 2.84.x |
| 資料庫 | PostgreSQL | 15.x |
| 認證 | Supabase Auth + @delon/auth | - |

#### 4.2 前端架構 - Feature 垂直切片結構

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

#### 4.3 上下文傳遞機制

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

---

### 5. 資料庫設計

#### 5.1 既有資料表（已完成）

| 表名 | 用途 | 狀態 |
|------|------|------|
| `accounts` | 帳戶（含 USER/ORG/BOT 類型） | ✅ 完成 |
| `teams` | 團隊（屬於組織） | ✅ 完成 |
| `organization_members` | 組織成員關聯 | ✅ 完成 |
| `team_members` | 團隊成員關聯 | ✅ 完成 |
| `team_bots` | 團隊 Bot 關聯 | ✅ 完成 |

#### 5.2 待建立資料表

| 表名 | 用途 | 優先級 |
|------|------|--------|
| `blueprints` | 藍圖主表 | 🔴 高 |
| `blueprint_members` | 藍圖成員與角色 | 🔴 高 |
| `blueprint_roles` | 藍圖自訂角色定義 | 🔴 高 |
| `tasks` | 任務主表（樹狀結構） | 🔴 高 |
| `task_attachments` | 任務附件（含完工圖片） | 🔴 高 |
| `diaries` | 每日施工日誌 | 🔴 高 |
| `diary_attachments` | 日誌附件 | 🔴 高 |
| `files` | 檔案主表（含版本） | 🔴 高 |
| `blueprint_branches` | Git-like 分支 | 🟡 中 |
| `blueprint_pull_requests` | 分支合併請求 | 🟡 中 |
| `task_comments` | 任務討論 | 🟡 中 |
| `task_acceptances` | 任務驗收記錄 | 🔴 高 |
| `checklists` | 品質檢查清單模板 | 🟡 中 |
| `issues` | 問題追蹤 | 🟡 中 |
| `notifications` | 通知中心 | 🟡 中 |

#### 5.3 RLS Helper Functions

**既有**:
- `get_user_account_id()` - 取得當前用戶帳戶 ID
- `is_org_member(org_id)` - 檢查是否為組織成員
- `is_team_member(team_id)` - 檢查是否為團隊成員
- `get_user_role_in_org(org_id)` - 取得用戶在組織的角色

**待建立**:
- `is_blueprint_member(blueprint_id)` - 檢查是否為藍圖成員
- `get_user_role_in_blueprint(blueprint_id)` - 取得用戶在藍圖的角色
- `can_access_task(task_id)` - 檢查任務存取權限
- `calculate_task_progress(task_id)` - 遞迴計算任務進度

---

### 6. 安全與權限設計

#### 6.1 RLS 政策設計原則

- 每張表必須有 RLS 政策
- 使用 Helper Functions 封裝權限檢查
- 避免在 RLS 中直接查詢受保護的表（防止遞迴）

**正確範例**:

```sql
-- ✅ 使用 SECURITY DEFINER 函數避免遞迴
CREATE OR REPLACE FUNCTION is_blueprint_member(p_blueprint_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = auth.uid()
  );
END;
$$;

CREATE POLICY "users_can_view_own_tasks" ON tasks FOR SELECT
USING (is_blueprint_member(blueprint_id));
```

#### 6.2 權限檢查流程

```
用戶操作 → 前端權限判斷（快取） → API 請求 → RLS 強制檢查 → 回傳結果
             ↓ 無權限                    ↓ 無權限
           顯示禁用/隱藏               返回 403 錯誤
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

| 類別 | 故事數量 | ID 範圍 |
|------|----------|---------|
| 帳戶與認證 | 4 | GH-001 ~ GH-004 |
| 組織與團隊 | 4 | GH-005 ~ GH-008 |
| 藍圖管理 | 4 | GH-009 ~ GH-012 |
| 任務管理 | 5 | GH-013 ~ GH-017 |
| 施工日誌 | 4 | GH-018 ~ GH-021 |
| 品質驗收 | 4 | GH-022 ~ GH-025 |
| 問題追蹤 | 3 | GH-026 ~ GH-028 |
| 協作溝通 | 3 | GH-029 ~ GH-031 |
| 報表分析 | 3 | GH-032 ~ GH-034 |
| 離線與同步 | 3 | GH-035 ~ GH-037 |
| 系統管理 | 3 | GH-038 ~ GH-040 |

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
