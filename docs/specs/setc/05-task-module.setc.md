# 05-task-module.setc.md

## 1. 模組概述

### 業務價值
任務系統是 GigHub 的核心模組，作為工地施工進度追蹤的主要載體：
- **工項管理**：階層式任務結構對應工程項目
- **進度追蹤**：即時掌握各工項完成狀態
- **指派協作**：明確任務負責人與監工
- **品質驗收**：任務完成需經驗收流程

### 核心功能
1. **任務樹狀結構**：支援無限層級的父子任務關係
2. **任務狀態流程**：6 種狀態的完整生命週期
3. **任務指派與監工**：assignee（執行者）+ reviewer（監工）
4. **任務附件管理**：完工照片、參考資料等
5. **任務驗收機制**：透過檢查清單進行品質驗收

### 在系統中的定位
任務模組是業務層的主核心，其他模組（日誌、待辦、問題追蹤）皆以任務為依賴中心。

---

## 2. 功能需求

### 使用者故事列表

#### TASK-001: 任務樹狀結構管理
**作為** 專案經理
**我想要** 建立階層式的任務結構
**以便於** 對應實際工程的項目層級

**驗收標準**：
- [ ] 可建立根任務和子任務
- [ ] 支援無限層級嵌套
- [ ] 可拖曳調整任務順序
- [ ] 可拖曳調整父子關係
- [ ] 刪除父任務時子任務一併處理

#### TASK-002: 任務狀態流轉
**作為** 施工人員
**我想要** 更新任務執行狀態
**以便於** 反映實際施工進度

**驗收標準**：
- [ ] 支援 6 種狀態：pending, in_progress, in_review, completed, cancelled, blocked
- [ ] 狀態流轉遵循預定規則
- [ ] 狀態變更記錄時間軸
- [ ] completed 狀態需經驗收確認

#### TASK-003: 任務指派與監工
**作為** 工地主任
**我想要** 指派任務給施工人員
**以便於** 明確任務責任歸屬

**驗收標準**：
- [ ] 可指定任務 assignee（執行者）
- [ ] 可指定任務 reviewer（監工）
- [ ] 指派變更通知相關人員
- [ ] 可批次指派多個任務

#### TASK-004: 任務附件管理
**作為** 施工人員
**我想要** 上傳任務相關檔案
**以便於** 記錄施工過程和完工狀態

**驗收標準**：
- [ ] 支援多種檔案類型
- [ ] 可標記完工照片
- [ ] 附件顯示縮圖預覽
- [ ] 可下載和刪除附件

#### TASK-005: 任務進度計算
**作為** 專案經理
**我想要** 自動計算任務完成進度
**以便於** 掌握整體工程進度

**驗收標準**：
- [ ] 葉子任務手動設定進度
- [ ] 父任務自動彙總子任務進度
- [ ] 支援權重計算
- [ ] 進度變更即時更新

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 任務 CRUD | 藍圖系統 |
| P0 | 任務樹狀結構 | 任務 CRUD |
| P0 | 任務狀態管理 | 任務 CRUD |
| P1 | 任務指派 | 任務 CRUD、帳戶系統 |
| P1 | 任務附件 | 任務 CRUD、檔案系統 |
| P2 | 進度計算 | 任務樹狀結構 |
| P2 | 任務驗收 | 任務狀態、檢查清單 |

### 品質驗收機制

#### 驗收流程

```
任務完成 → 日誌可提報 → 提報後可 QA → QA 完成 → 驗收
  [DONE]     [REPORTED]    [QA_PENDING]  [QA_PASSED]  [ACCEPTED]
                                ↓
                          [QA_FAILED] → 問題開立
```

#### 驗收結果

| 結果 | 英文 | 狀態碼 | 說明 |
|------|------|--------|------|
| 待驗收 | Pending | `pending` | 等待驗收 |
| 通過 | Passed | `passed` | 驗收合格 |
| 不通過 | Failed | `failed` | 驗收不合格，需改善 |
| 有條件通過 | Conditional | `conditional` | 有附帶條件的通過 |

#### 驗收使用者故事

**TASK-006: 任務驗收**  
**作為** 品管人員  
**我想要** 對已完成任務進行驗收  
**以便於** 確認工項品質符合規範

**驗收標準**：
- [ ] 可對 completed 狀態任務發起驗收
- [ ] 可選擇驗收檢查清單
- [ ] 可記錄驗收結果與備註
- [ ] 驗收不通過可開立問題
- [ ] 驗收歷史可追蹤

---

## 3. 技術設計

### 資料模型

**tasks（任務主表）**:
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked'
  )),
  priority TEXT DEFAULT 'medium' CHECK (priority IN (
    'lowest', 'low', 'medium', 'high', 'highest'
  )),
  task_type TEXT DEFAULT 'task' CHECK (task_type IN (
    'task', 'milestone', 'bug', 'feature', 'improvement'
  )),
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  start_date DATE,
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  weight DECIMAL(5,2) DEFAULT 1.0,
  assignee_id UUID REFERENCES accounts(id),
  reviewer_id UUID REFERENCES accounts(id),
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_tasks_blueprint_id ON tasks(blueprint_id);
CREATE INDEX idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_sort_order ON tasks(blueprint_id, parent_id, sort_order);
```

**task_attachments（任務附件）**:
```sql
CREATE TABLE task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES files(id),
  attachment_type TEXT DEFAULT 'general' CHECK (attachment_type IN (
    'general', 'completion_photo', 'reference', 'issue_evidence'
  )),
  caption TEXT,
  is_completion_photo BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_task_attachments_task_id ON task_attachments(task_id);
CREATE INDEX idx_task_attachments_file_id ON task_attachments(file_id);
```

**task_acceptances（任務驗收）**:
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

CREATE INDEX idx_task_acceptances_task_id ON task_acceptances(task_id);
CREATE INDEX idx_task_acceptances_status ON task_acceptances(status);
```

**checklists（檢查清單模板）**:
```sql
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
  sort_order INTEGER DEFAULT 0,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### API 設計

**任務 Repository**:
```typescript
@Injectable({ providedIn: 'root' })
export class TaskRepository {
  private readonly supabase = inject(SupabaseService);
  private readonly TABLE = 'tasks';

  async findByBlueprint(blueprintId: string): Promise<Task[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select(`
        *,
        assignee:assignee_id(id, display_name, avatar_url),
        reviewer:reviewer_id(id, display_name, avatar_url),
        attachments:task_attachments(
          id,
          file:file_id(id, name, thumbnail_path),
          attachment_type,
          is_completion_photo
        )
      `)
      .eq('blueprint_id', blueprintId)
      .is('deleted_at', null)
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

  async updateStatus(id: string, status: TaskStatus): Promise<Task> {
    const updates: Partial<Task> = { status };
    if (status === 'completed') {
      updates.completed_at = new Date().toISOString();
      updates.progress = 100;
    }

    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async reorder(blueprintId: string, taskId: string, newParentId: string | null, newIndex: number): Promise<void> {
    // 使用 RPC 呼叫處理複雜的重排序邏輯
    const { error } = await this.supabase.client
      .rpc('reorder_task', {
        p_blueprint_id: blueprintId,
        p_task_id: taskId,
        p_new_parent_id: newParentId,
        p_new_index: newIndex
      });

    if (error) throw error;
  }
}
```

### 前端元件結構

```
features/blueprint/ui/task/
├── task-tree/                      # 任務樹元件
│   ├── task-tree.component.ts
│   ├── task-tree.component.html
│   └── task-tree.component.less
├── task-card/                      # 任務卡片
│   ├── task-card.component.ts
│   └── task-card.component.html
├── task-detail/                    # 任務詳情
│   ├── task-detail.component.ts
│   ├── task-detail.component.html
│   └── task-detail-tabs/
│       ├── task-info-tab.component.ts
│       ├── task-attachments-tab.component.ts
│       └── task-timeline-tab.component.ts
├── task-form/                      # 任務表單
│   ├── task-form.component.ts
│   └── task-form.component.html
└── task-status-badge/              # 狀態徽章
    └── task-status-badge.component.ts
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly repository = inject(TaskRepository);
  private readonly blueprintStore = inject(BlueprintStore);

  // State
  private readonly _tasks = signal<Task[]>([]);
  private readonly _selectedTaskId = signal<string | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly tasks = this._tasks.asReadonly();
  readonly selectedTaskId = this._selectedTaskId.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed - 任務樹結構
  readonly taskTree = computed(() => {
    const tasks = this._tasks();
    return this.buildTree(tasks);
  });

  // Computed - 選中的任務
  readonly selectedTask = computed(() => {
    const id = this._selectedTaskId();
    return id ? this._tasks().find(t => t.id === id) : null;
  });

  // Computed - 各狀態任務數量
  readonly statusCounts = computed(() => {
    const tasks = this._tasks();
    return {
      pending: tasks.filter(t => t.status === 'pending').length,
      in_progress: tasks.filter(t => t.status === 'in_progress').length,
      in_review: tasks.filter(t => t.status === 'in_review').length,
      completed: tasks.filter(t => t.status === 'completed').length,
      blocked: tasks.filter(t => t.status === 'blocked').length,
    };
  });

  // Computed - 整體進度
  readonly overallProgress = computed(() => {
    const tasks = this._tasks().filter(t => !t.parent_id); // 只計算根任務
    if (tasks.length === 0) return 0;
    const total = tasks.reduce((sum, t) => sum + (t.progress ?? 0), 0);
    return Math.round(total / tasks.length);
  });

  // Actions
  async loadTasks(): Promise<void> {
    const blueprintId = this.blueprintStore.blueprintId();
    if (!blueprintId) return;

    this._loading.set(true);
    this._error.set(null);

    try {
      const tasks = await this.repository.findByBlueprint(blueprintId);
      this._tasks.set(tasks);
    } catch (error) {
      this._error.set('載入任務失敗');
      console.error('[TaskStore] loadTasks error:', error);
    } finally {
      this._loading.set(false);
    }
  }

  async createTask(dto: CreateTaskDto): Promise<Task | null> {
    try {
      const task = await this.repository.create({
        ...dto,
        blueprint_id: this.blueprintStore.blueprintId()!,
      });
      this._tasks.update(tasks => [...tasks, task]);
      return task;
    } catch (error) {
      this._error.set('建立任務失敗');
      return null;
    }
  }

  async updateStatus(taskId: string, status: TaskStatus): Promise<void> {
    try {
      const updated = await this.repository.updateStatus(taskId, status);
      this._tasks.update(tasks =>
        tasks.map(t => t.id === taskId ? updated : t)
      );
    } catch (error) {
      this._error.set('更新狀態失敗');
    }
  }

  selectTask(taskId: string | null): void {
    this._selectedTaskId.set(taskId);
  }

  private buildTree(tasks: Task[]): TaskTreeNode[] {
    const map = new Map<string, TaskTreeNode>();
    const roots: TaskTreeNode[] = [];

    // 建立節點 map
    tasks.forEach(task => {
      map.set(task.id, { ...task, children: [] });
    });

    // 建立樹結構
    tasks.forEach(task => {
      const node = map.get(task.id)!;
      if (task.parent_id && map.has(task.parent_id)) {
        map.get(task.parent_id)!.children.push(node);
      } else {
        roots.push(node);
      }
    });

    return roots;
  }
}
```

---

## 4. 安全與權限

### RLS 政策

```sql
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- SELECT: 藍圖成員可讀
CREATE POLICY "tasks_select" ON tasks
  FOR SELECT USING (is_blueprint_member(blueprint_id));

-- INSERT: 藍圖成員可建立
CREATE POLICY "tasks_insert" ON tasks
  FOR INSERT WITH CHECK (is_blueprint_member(blueprint_id));

-- UPDATE: 成員可更新（限定條件）
CREATE POLICY "tasks_update" ON tasks
  FOR UPDATE USING (
    is_blueprint_member(blueprint_id) AND (
      is_blueprint_admin(blueprint_id) OR
      assignee_id = get_user_account_id() OR
      created_by = get_user_account_id()
    )
  );

-- DELETE: 軟刪除由管理員執行
CREATE POLICY "tasks_delete" ON tasks
  FOR UPDATE USING (is_blueprint_admin(blueprint_id))
  WITH CHECK (deleted_at IS NOT NULL);
```

### 權限檢查點

1. **建立任務**：藍圖成員權限
2. **編輯任務**：任務建立者、指派者或管理員
3. **刪除任務**：藍圖管理員
4. **指派任務**：藍圖管理員或工地主任

### 資料隔離策略

- 所有任務透過 `blueprint_id` 隔離
- RLS 強制檢查藍圖成員資格
- 軟刪除保留歷史紀錄

---

## 5. 測試規範

### 單元測試清單

| 測試項目 | 測試內容 | 優先級 |
|----------|----------|--------|
| TaskStore.loadTasks | 載入任務列表 | P0 |
| TaskStore.createTask | 建立新任務 | P0 |
| TaskStore.updateStatus | 狀態流轉正確 | P0 |
| TaskStore.taskTree | 樹結構建立正確 | P0 |
| TaskStore.overallProgress | 進度計算正確 | P1 |
| TaskRepository | API 呼叫正確 | P0 |

### 整合測試場景

1. **任務樹操作**：建立→移動→刪除
2. **狀態流轉**：pending→in_progress→completed
3. **附件上傳**：上傳→預覽→刪除
4. **進度更新**：子任務完成→父任務進度更新

### E2E 測試案例

1. 完整的任務建立流程
2. 拖曳調整任務順序
3. 任務狀態變更與通知
4. 任務附件上傳與預覽

---

## 6. 效能考量

### 效能目標

| 指標 | 目標值 | 說明 |
|------|--------|------|
| 任務樹渲染 | < 500ms | 1000 節點 |
| 任務載入 | < 200ms | 單一藍圖 |
| 狀態更新 | < 100ms | 樂觀更新 |
| 拖曳反饋 | < 16ms | 60fps |

### 優化策略

1. **虛擬捲動**：大量任務使用虛擬列表
2. **樂觀更新**：先更新 UI 再同步後端
3. **批次載入**：分批載入深層子任務
4. **快取策略**：任務資料適當快取

### 監控指標

- 任務樹渲染時間
- API 回應時間
- 記憶體使用量
- 用戶操作回應時間

---

## 7. 實作檢查清單

### 階段一：基礎功能（P0）
- [ ] tasks 資料表建立
- [ ] task_attachments 資料表建立
- [ ] RLS 政策設定
- [ ] TaskRepository 實作
- [ ] TaskStore 實作
- [ ] 任務樹元件開發

### 階段二：核心功能（P1）
- [ ] 任務建立表單
- [ ] 任務詳情頁面
- [ ] 狀態變更功能
- [ ] 指派功能
- [ ] 附件上傳功能

### 階段三：進階功能（P2）
- [ ] 拖曳排序
- [ ] 進度自動計算
- [ ] 批次操作
- [ ] 篩選與搜尋

### 階段四：驗收整合（P2）
- [ ] checklists 資料表建立
- [ ] task_acceptances 資料表建立
- [ ] 驗收 RLS 政策設定
- [ ] AcceptanceRepository 實作
- [ ] AcceptanceStore 實作
- [ ] 驗收表單元件開發
- [ ] 驗收歷史檢視

### 階段五：模組整合（P3）
- [ ] 任務驗收流程
- [ ] 與日誌模組整合
- [ ] 與待辦模組整合
- [ ] 與問題追蹤整合
- [ ] 時間軸整合

---

**文件版本**: v1.1
**最後更新**: 2025-11-28
**維護者**: 模組負責人
