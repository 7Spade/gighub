# 07-todo-module.setc.md

## 1. 模組概述

### 業務價值
待辦模組提供個人化的工作管理介面：
- **工作彙整**：跨藍圖彙整個人待辦事項
- **五狀態分類**：清晰呈現工作進度
- **優先排序**：依優先級與截止日排序
- **快速導航**：一鍵跳轉至對應功能

### 核心功能
1. **個人待辦清單**：彙整指派給自己的任務
2. **五狀態分類**：pending、in_progress、in_review、completed、cancelled
3. **跨藍圖彙整**：統一檢視所有藍圖的待辦事項
4. **優先級排序**：依緊急程度排列
5. **截止日提醒**：即將到期、已過期標示

### 在系統中的定位
待辦模組是用戶工作台的核心視圖，從任務系統抽取與當前用戶相關的任務進行展示。

---

## 2. 功能需求

### 使用者故事列表

#### TODO-001: 個人待辦清單
**作為** 使用者
**我想要** 查看指派給我的所有待辦事項
**以便於** 掌握我的工作內容

**驗收標準**：
- [ ] 顯示所有指派給我的任務
- [ ] 支援跨藍圖彙整
- [ ] 顯示任務所屬藍圖名稱
- [ ] 點擊可跳轉至任務詳情

#### TODO-002: 五狀態分類顯示
**作為** 使用者
**我想要** 依狀態分類檢視待辦事項
**以便於** 了解各階段的工作量

**驗收標準**：
- [ ] 支援五種狀態分類顯示
- [ ] 顯示各狀態任務數量
- [ ] 支援切換顯示模式（列表/看板）
- [ ] 支援篩選特定狀態

#### TODO-003: 優先級排序
**作為** 使用者
**我想要** 依優先級排序待辦事項
**以便於** 優先處理重要工作

**驗收標準**：
- [ ] 預設依優先級+截止日排序
- [ ] 支援自訂排序方式
- [ ] 高優先級任務視覺突顯
- [ ] 支援多欄位組合排序

#### TODO-004: 截止日提醒
**作為** 使用者
**我想要** 收到任務截止提醒
**以便於** 避免逾期

**驗收標準**：
- [ ] 即將到期任務（3天內）標示
- [ ] 已過期任務紅色警示
- [ ] 今日到期任務特別標示
- [ ] 無截止日任務單獨分組

#### TODO-005: 快速操作
**作為** 使用者
**我想要** 快速更新任務狀態
**以便於** 高效處理工作

**驗收標準**：
- [ ] 支援拖曳更新狀態（看板模式）
- [ ] 支援快速標記完成
- [ ] 支援批次操作
- [ ] 狀態更新即時同步

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 待辦清單顯示 | 任務系統 |
| P0 | 狀態分類 | 待辦清單 |
| P1 | 優先級排序 | 待辦清單 |
| P1 | 截止日提醒 | 待辦清單 |
| P2 | 快速操作 | 待辦清單、任務系統 |

---

## 3. 技術設計

### 資料模型

待辦模組不需獨立資料表，直接從 tasks 表查詢：

**查詢邏輯**:
```sql
-- 取得使用者待辦事項
SELECT t.*, b.name as blueprint_name
FROM tasks t
JOIN blueprints b ON t.blueprint_id = b.id
WHERE t.assignee_id = :current_user_id
  AND t.deleted_at IS NULL
  AND t.status != 'cancelled'
ORDER BY 
  CASE t.priority
    WHEN 'highest' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
    WHEN 'lowest' THEN 5
  END,
  t.due_date ASC NULLS LAST;
```

### API 設計

**待辦 API**:
```typescript
// 取得個人待辦列表
GET /api/todos
Query: { 
  status?: string[], 
  priority?: string[], 
  blueprint_id?: string,
  due_before?: string,
  due_after?: string
}
Response: { data: Todo[], total: number }

// 取得待辦統計
GET /api/todos/stats
Response: { 
  by_status: { pending: number, in_progress: number, ... },
  by_priority: { highest: number, high: number, ... },
  overdue: number,
  due_today: number,
  due_this_week: number
}

// 批次更新狀態
PATCH /api/todos/batch
Body: { task_ids: string[], status: string }
Response: { updated: number }
```

### 前端元件結構

```
src/app/features/todo/
├── todo.routes.ts
├── shell/
│   └── todo-shell/
│       └── todo-shell.component.ts
├── data-access/
│   ├── stores/
│   │   └── todo.store.ts
│   └── services/
│       └── todo.service.ts
├── domain/
│   └── interfaces/
│       └── todo.interface.ts
└── ui/
    ├── todo-list/
    │   └── todo-list.component.ts
    ├── todo-board/
    │   └── todo-board.component.ts
    ├── todo-stats/
    │   └── todo-stats.component.ts
    └── todo-filters/
        └── todo-filters.component.ts
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class TodoStore {
  private readonly taskRepository = inject(TaskRepository);

  // Private state
  private readonly _todos = signal<Todo[]>([]);
  private readonly _stats = signal<TodoStats | null>(null);
  private readonly _filters = signal<TodoFilters>({});
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly todos = this._todos.asReadonly();
  readonly stats = this._stats.asReadonly();
  readonly filters = this._filters.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed properties
  readonly filteredTodos = computed(() => {
    const todos = this._todos();
    const filters = this._filters();
    return this.applyFilters(todos, filters);
  });

  readonly todosByStatus = computed(() => {
    const todos = this.filteredTodos();
    return {
      pending: todos.filter(t => t.status === 'pending'),
      in_progress: todos.filter(t => t.status === 'in_progress'),
      in_review: todos.filter(t => t.status === 'in_review'),
      completed: todos.filter(t => t.status === 'completed'),
      cancelled: todos.filter(t => t.status === 'cancelled'),
    };
  });

  readonly overdueTodos = computed(() =>
    this._todos().filter(t => t.due_date && new Date(t.due_date) < new Date())
  );

  readonly dueTodayTodos = computed(() => {
    const today = new Date().toDateString();
    return this._todos().filter(t => 
      t.due_date && new Date(t.due_date).toDateString() === today
    );
  });

  // Methods
  async loadTodos(): Promise<void>;
  async loadStats(): Promise<void>;
  setFilters(filters: TodoFilters): void;
  async updateTodoStatus(taskId: string, status: string): Promise<void>;
  async batchUpdateStatus(taskIds: string[], status: string): Promise<void>;
}
```

---

## 4. 安全與權限

### RLS 政策

待辦模組使用 tasks 表的 RLS 政策，額外過濾 `assignee_id`：

```sql
-- 使用者只能看到指派給自己的待辦
-- 透過 API 層過濾，RLS 保證基本存取權限
```

### 權限檢查點

| 操作 | 所需權限 | 額外條件 |
|------|----------|----------|
| 查看待辦 | 藍圖成員 | assignee_id = 當前用戶 |
| 更新狀態 | 藍圖成員 | assignee_id = 當前用戶 或 admin |
| 批次操作 | 藍圖成員 | 只能操作自己的任務 |

### 資料隔離策略
- 待辦清單只顯示指派給當前用戶的任務
- 跨藍圖查詢時，RLS 確保只返回有權限的藍圖資料

---

## 5. 測試規範

### 單元測試清單

**TodoStore 測試**:
```typescript
describe('TodoStore', () => {
  it('loadTodos_shouldReturnUserAssignedTasks');
  it('filteredTodos_whenStatusFilter_shouldFilterCorrectly');
  it('filteredTodos_whenPriorityFilter_shouldFilterCorrectly');
  it('todosByStatus_shouldGroupCorrectly');
  it('overdueTodos_shouldReturnOverdueOnly');
  it('dueTodayTodos_shouldReturnTodayOnly');
  it('updateTodoStatus_shouldUpdateAndReload');
  it('batchUpdateStatus_shouldUpdateMultiple');
});
```

**TodoFilters 測試**:
```typescript
describe('TodoFilters', () => {
  it('applyFilters_withStatusFilter_shouldFilter');
  it('applyFilters_withPriorityFilter_shouldFilter');
  it('applyFilters_withDateRange_shouldFilter');
  it('applyFilters_withMultipleFilters_shouldCombine');
});
```

### 整合測試場景

1. **待辦載入**：載入用戶待辦 → 驗證只顯示指派任務
2. **狀態更新**：拖曳更新狀態 → 驗證同步回任務系統
3. **跨藍圖**：切換組織 → 驗證待辦清單更新

### E2E 測試案例

```typescript
describe('Todo Module E2E', () => {
  it('should display user assigned tasks');
  it('should filter by status');
  it('should sort by priority');
  it('should update status via drag and drop');
  it('should navigate to task detail');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 載入待辦列表 | < 150ms |
| 載入統計數據 | < 100ms |
| 狀態更新 | < 200ms |
| 篩選切換 | < 50ms |

### 優化策略

1. **索引優化**：`assignee_id + status` 複合索引
2. **分頁載入**：大量待辦使用虛擬捲動
3. **本地快取**：統計數據本地快取
4. **即時同步**：使用 Realtime 保持同步

### 監控指標

- 待辦列表載入時間
- 狀態更新成功率
- 跨藍圖查詢效能

---

## 7. 實作檢查清單

### 資料庫
- [ ] 確認 tasks 表索引（assignee_id）
- [ ] 建立待辦查詢視圖（選用）

### 後端
- [ ] 實作待辦查詢 API
- [ ] 實作統計 API
- [ ] 實作批次更新 API

### 前端
- [ ] 實作 TodoStore
- [ ] 實作 todo-list 元件
- [ ] 實作 todo-board 元件（看板視圖）
- [ ] 實作 todo-stats 元件
- [ ] 實作 todo-filters 元件

### 測試
- [ ] TodoStore 單元測試
- [ ] 整合測試
- [ ] E2E 測試

### 文件
- [ ] API 文件更新
- [ ] 使用者指南更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
