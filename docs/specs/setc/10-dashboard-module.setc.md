# 10-dashboard-module.setc.md

## 1. 模組概述

### 業務價值
儀表板模組提供數據視覺化與進度追蹤：
- **數據聚合**：匯整各模組關鍵指標
- **視覺化圖表**：直觀呈現專案狀態
- **進度追蹤**：即時掌握工程進度
- **報表匯出**：生成專業報表

### 核心功能
1. **數據聚合**：跨模組數據整合
2. **視覺化圖表**：進度曲線、甘特圖、圓餅圖等
3. **關鍵指標看板**：KPI 即時顯示
4. **進度曲線**：S 曲線進度追蹤
5. **報表匯出**：PDF/Excel 報表生成

### 在系統中的定位
儀表板是藍圖的資訊中心，提供宏觀視角的專案狀態總覽。

---

## 2. 功能需求

### 使用者故事列表

#### DASH-001: 專案總覽看板
**作為** 專案經理
**我想要** 查看專案關鍵指標
**以便於** 快速掌握專案狀態

**驗收標準**：
- [ ] 顯示任務完成率
- [ ] 顯示進行中任務數
- [ ] 顯示逾期任務數
- [ ] 顯示本週新增日誌數
- [ ] 顯示待處理問題數

#### DASH-002: 進度曲線圖
**作為** 專案經理
**我想要** 查看進度曲線
**以便於** 比較計畫與實際進度

**驗收標準**：
- [ ] 顯示計劃進度曲線
- [ ] 顯示實際進度曲線
- [ ] 支援日期範圍選擇
- [ ] 支援縮放與平移
- [ ] 顯示里程碑標記

#### DASH-003: 任務分布圖
**作為** 專案經理
**我想要** 查看任務狀態分布
**以便於** 了解各狀態任務比例

**驗收標準**：
- [ ] 圓餅圖顯示狀態分布
- [ ] 顯示各狀態數量與百分比
- [ ] 點擊可跳轉至對應任務列表
- [ ] 支援依負責人篩選

#### DASH-004: 工時統計
**作為** 專案經理
**我想要** 查看工時統計
**以便於** 分析資源投入

**驗收標準**：
- [ ] 顯示總工時統計
- [ ] 顯示週/月工時趨勢
- [ ] 顯示各任務工時分布
- [ ] 顯示各人員工時統計

#### DASH-005: 報表匯出
**作為** 專案經理
**我想要** 匯出專案報表
**以便於** 向上級報告

**驗收標準**：
- [ ] 支援 PDF 格式匯出
- [ ] 支援 Excel 格式匯出
- [ ] 可選擇報表內容範圍
- [ ] 包含圖表與數據表格
- [ ] 支援自訂報表標題

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 總覽看板 | 任務系統 |
| P1 | 進度曲線 | 任務系統 |
| P1 | 任務分布圖 | 任務系統 |
| P2 | 工時統計 | 日誌系統 |
| P2 | 報表匯出 | 以上全部 |

---

## 3. 技術設計

### 資料來源

儀表板不需獨立資料表，從以下表聚合數據：

| 數據來源 | 指標 |
|----------|------|
| tasks | 任務完成率、狀態分布、逾期統計 |
| diaries | 工時統計、工作天數 |
| issues | 問題數量、解決率 |
| task_acceptances | 驗收通過率 |

### API 設計

**儀表板 API**:
```typescript
// 取得總覽統計
GET /api/blueprints/{blueprint_id}/dashboard/overview
Response: {
  task_completion_rate: number,
  tasks_in_progress: number,
  tasks_overdue: number,
  diaries_this_week: number,
  open_issues: number
}

// 取得進度曲線數據
GET /api/blueprints/{blueprint_id}/dashboard/progress
Query: { start_date: string, end_date: string }
Response: {
  planned: { date: string, progress: number }[],
  actual: { date: string, progress: number }[],
  milestones: { date: string, name: string }[]
}

// 取得任務分布
GET /api/blueprints/{blueprint_id}/dashboard/task-distribution
Response: {
  by_status: { status: string, count: number }[],
  by_priority: { priority: string, count: number }[],
  by_assignee: { assignee_id: string, name: string, count: number }[]
}

// 取得工時統計
GET /api/blueprints/{blueprint_id}/dashboard/work-hours
Query: { start_date: string, end_date: string }
Response: {
  total_hours: number,
  by_date: { date: string, hours: number }[],
  by_task: { task_id: string, name: string, hours: number }[],
  by_worker: { worker_id: string, name: string, hours: number }[]
}

// 生成報表
POST /api/blueprints/{blueprint_id}/reports
Body: { 
  type: 'progress' | 'summary' | 'detailed',
  format: 'pdf' | 'excel',
  date_range: { start: string, end: string }
}
Response: { download_url: string }
```

### 前端元件結構

```
src/app/features/dashboard/
├── dashboard.routes.ts
├── shell/
│   └── dashboard-shell/
│       └── dashboard-shell.component.ts
├── data-access/
│   ├── stores/
│   │   └── dashboard.store.ts
│   └── services/
│       ├── dashboard.service.ts
│       └── report.service.ts
├── domain/
│   └── interfaces/
│       └── dashboard.interface.ts
└── ui/
    ├── overview-cards/
    │   └── overview-cards.component.ts
    ├── progress-chart/
    │   └── progress-chart.component.ts
    ├── task-distribution/
    │   └── task-distribution.component.ts
    ├── work-hours-chart/
    │   └── work-hours-chart.component.ts
    └── report-generator/
        └── report-generator.component.ts
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class DashboardStore {
  private readonly service = inject(DashboardService);

  // Private state
  private readonly _overview = signal<DashboardOverview | null>(null);
  private readonly _progressData = signal<ProgressData | null>(null);
  private readonly _taskDistribution = signal<TaskDistribution | null>(null);
  private readonly _workHours = signal<WorkHoursData | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly overview = this._overview.asReadonly();
  readonly progressData = this._progressData.asReadonly();
  readonly taskDistribution = this._taskDistribution.asReadonly();
  readonly workHours = this._workHours.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed properties
  readonly completionPercentage = computed(() => 
    this._overview()?.task_completion_rate ?? 0
  );

  readonly hasOverdueTasks = computed(() =>
    (this._overview()?.tasks_overdue ?? 0) > 0
  );

  // Methods
  async loadOverview(blueprintId: string): Promise<void>;
  async loadProgressData(blueprintId: string, dateRange: DateRange): Promise<void>;
  async loadTaskDistribution(blueprintId: string): Promise<void>;
  async loadWorkHours(blueprintId: string, dateRange: DateRange): Promise<void>;
  async generateReport(blueprintId: string, options: ReportOptions): Promise<string>;
}
```

---

## 4. 安全與權限

### 權限檢查點

| 操作 | 所需權限 | 額外條件 |
|------|----------|----------|
| 查看儀表板 | 藍圖成員 | - |
| 生成報表 | member 以上 | - |
| 匯出數據 | admin 以上 | - |

---

## 5. 測試規範

### 單元測試清單

```typescript
describe('DashboardStore', () => {
  it('loadOverview_shouldReturnStatistics');
  it('loadProgressData_shouldReturnCurveData');
  it('loadTaskDistribution_shouldGroupByStatus');
  it('loadWorkHours_shouldAggregateFromDiaries');
  it('generateReport_shouldReturnDownloadUrl');
});
```

### E2E 測試案例

```typescript
describe('Dashboard Module E2E', () => {
  it('should display overview cards');
  it('should render progress chart');
  it('should filter by date range');
  it('should generate PDF report');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 載入總覽 | < 200ms |
| 載入進度曲線 | < 300ms |
| 生成報表 | < 5s |

### 優化策略

1. **預計算統計**：定時任務預計算統計數據
2. **快取機制**：短時間內相同查詢返回快取
3. **增量更新**：只更新變化的數據
4. **報表佇列**：大型報表使用背景任務生成

---

## 7. 實作檢查清單

- [ ] 實作統計 API
- [ ] 實作進度曲線 API
- [ ] 實作任務分布 API
- [ ] 實作工時統計 API
- [ ] 實作報表生成 API
- [ ] 實作 DashboardStore
- [ ] 實作 overview-cards 元件
- [ ] 實作 progress-chart 元件（使用 ng2-charts 或 ECharts）
- [ ] 實作 task-distribution 元件
- [ ] 實作 work-hours-chart 元件
- [ ] 實作 report-generator 元件
- [ ] 撰寫測試

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
