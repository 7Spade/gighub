# 04-angular-project-structure.setc.md

## 1. 模組概述

### 業務價值
定義 Angular 20 專案的標準結構，確保：
- **一致性**：團隊遵循統一的程式碼組織方式
- **可維護性**：清晰的模組邊界與職責劃分
- **可擴展性**：支援業務功能的靈活擴展
- **開發效率**：減少決策成本，加速開發

### 核心功能
1. **Feature 垂直切片**：按功能領域組織程式碼
2. **Repository 模式**：封裝 Supabase 資料存取
3. **Store 模式**：使用 Signals 管理狀態
4. **上下文傳遞機制**：層層傳遞上下文資訊

### 在系統中的定位
本文件定義前端專案結構標準，是所有前端開發的基礎參考。

---

## 2. 功能需求

### 專案結構總覽

```
src/app/
├── core/                   # 【基礎層】核心基礎設施
│   ├── facades/           # Facade 模式統一 API
│   │   └── account/
│   │       └── workspace-context.facade.ts
│   ├── guards/            # 路由守衛
│   │   └── auth.guard.ts
│   ├── i18n/              # 國際化
│   ├── infra/             # 基礎設施
│   │   └── supabase.service.ts
│   ├── interceptors/      # HTTP 攔截器
│   ├── net/               # 網路服務
│   └── startup/           # 應用啟動
│
├── shared/                 # 【共享資源】跨模組共享
│   ├── components/        # 共用元件
│   ├── directives/        # 共用指令
│   ├── pipes/             # 共用管道
│   ├── services/          # 共用服務
│   └── index.ts           # Barrel exports
│
├── layout/                 # 【版面配置】版面元件
│   ├── basic/             # 基本版面
│   └── blank/             # 空白版面
│
├── routes/                 # 【路由頁面】路由頁面
│   ├── passport/          # 登入相關
│   │   ├── login/
│   │   └── register/
│   ├── exception/         # 例外頁面
│   └── dashboard/         # 儀表板
│
└── features/               # 【容器層 + 業務模組層】功能模組
    └── blueprint/         # 藍圖功能模組
        ├── blueprint.routes.ts
        ├── shell/         # 邏輯容器層
        ├── domain/        # 領域層
        ├── data-access/   # 資料存取層
        └── ui/            # 展示層
```

### Feature 垂直切片結構

```
src/app/features/{feature-name}/
├── {feature-name}.routes.ts         # 路由配置
├── shell/                           # 邏輯容器層
│   └── {feature}-shell/
│       ├── {feature}-shell.component.ts
│       ├── {feature}-shell.component.html
│       └── {feature}-shell.component.less
├── data-access/                     # 資料存取層
│   ├── stores/                      # Signals Store
│   │   └── {feature}.store.ts
│   ├── services/                    # 業務服務
│   │   └── {feature}.service.ts
│   └── repositories/                # Supabase Repository
│       └── {feature}.repository.ts
├── domain/                          # 領域層
│   ├── enums/                       # 枚舉定義
│   │   └── {feature}-status.enum.ts
│   ├── interfaces/                  # 介面定義
│   │   └── {feature}.interface.ts
│   ├── models/                      # 領域模型
│   │   └── {feature}.model.ts
│   └── types/                       # 類型定義
│       └── {feature}.types.ts
├── ui/                              # 展示層
│   └── {sub-feature}/
│       ├── {sub-feature}.component.ts
│       ├── {sub-feature}.component.html
│       └── {sub-feature}.component.less
└── utils/                           # 工具函數
    └── {feature}.utils.ts
```

### 各層職責規範

| 層級 | 職責 | 禁止 |
|------|------|------|
| 型別層 (domain) | 僅定義資料結構 | 包含邏輯 |
| 儲存庫層 (repository) | 純存取後端 | 處理業務邏輯 |
| 模型層 (model) | 負責資料映射 | 直接存取後端 |
| 服務層 (service) | 負責業務邏輯 | 處理 UI |
| Store 層 | 狀態管理 | 直接呼叫 Supabase |
| 元件層 (component) | 僅負責呈現 | 包含業務邏輯 |

---

## 3. 技術設計

### Repository 模式規範

```typescript
// ✅ 正確：透過 Repository 封裝 Supabase 呼叫
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

  async findById(id: string): Promise<Task | null> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
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

  async update(id: string, dto: UpdateTaskDto): Promise<Task> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .update({ ...dto, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.client
      .from(this.TABLE)
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}
```

### 禁止的模式

```typescript
// ❌ 禁止：在元件中直接呼叫 Supabase
@Component({ ... })
export class TaskComponent {
  private readonly supabase = inject(SupabaseService);

  async loadTasks() {
    // 這是錯誤的！應透過 Repository 呼叫
    const { data } = await this.supabase.client
      .from('tasks')
      .select('*');
  }
}

// ✅ 正確：透過 Store 存取資料
@Component({ ... })
export class TaskComponent {
  private readonly store = inject(TaskStore);
  readonly tasks = this.store.tasks;
}
```

### Store 模式規範

```typescript
@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly repository = inject(TaskRepository);

  // ==================== Private State ====================
  private readonly _tasks = signal<Task[]>([]);
  private readonly _selectedTask = signal<Task | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // ==================== Public Readonly State ====================
  readonly tasks = this._tasks.asReadonly();
  readonly selectedTask = this._selectedTask.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // ==================== Computed Properties ====================
  readonly pendingTasks = computed(() =>
    this._tasks().filter(t => t.status === 'pending')
  );

  readonly completedTasks = computed(() =>
    this._tasks().filter(t => t.status === 'completed')
  );

  readonly taskCount = computed(() => this._tasks().length);

  // ==================== Actions ====================
  async loadTasks(blueprintId: string): Promise<void> {
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
      const task = await this.repository.create(dto);
      this._tasks.update(tasks => [...tasks, task]);
      return task;
    } catch (error) {
      this._error.set('建立任務失敗');
      return null;
    }
  }

  selectTask(task: Task | null): void {
    this._selectedTask.set(task);
  }

  reset(): void {
    this._tasks.set([]);
    this._selectedTask.set(null);
    this._loading.set(false);
    this._error.set(null);
  }
}
```

### 上下文傳遞機制

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

### API 設計

所有 API 透過 Repository 層封裝，遵循以下命名規範：

```typescript
// Repository 方法命名規範
findAll(): Promise<T[]>           // 取得所有
findById(id: string): Promise<T>  // 依 ID 查詢
findByXxx(xxx: any): Promise<T[]> // 依條件查詢
create(dto: CreateDto): Promise<T>
update(id: string, dto: UpdateDto): Promise<T>
delete(id: string): Promise<void>
```

### 元件設計規範

```typescript
// ✅ 正確：使用函數式 API
@Component({
  selector: 'app-task-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, NzButtonModule],
  templateUrl: './task-card.component.html',
  styleUrl: './task-card.component.less'
})
export class TaskCardComponent {
  // 輸入
  task = input.required<Task>();
  isEditable = input(false);

  // 輸出
  taskSelected = output<Task>();

  // 依賴注入
  private readonly store = inject(TaskStore);

  // 計算屬性
  protected readonly isOverdue = computed(() => {
    const task = this.task();
    return task.dueDate && new Date(task.dueDate) < new Date();
  });

  // 方法
  onSelect(): void {
    this.taskSelected.emit(this.task());
  }
}
```

```typescript
// ❌ 禁止：使用裝飾器
@Component({ ... })
export class TaskCardComponent {
  @Input() task!: Task;           // 禁止
  @Output() taskChange = new EventEmitter<Task>(); // 禁止
  constructor(private store: TaskStore) {} // 禁止
}
```

---

## 4. 安全與權限

### 元件權限控制

```typescript
// 使用權限指令
@Component({
  template: `
    @if (canEdit()) {
      <button nz-button (click)="edit()">編輯</button>
    }
  `
})
export class TaskComponent {
  private readonly context = inject(BlueprintContextFacade);
  
  readonly canEdit = computed(() => this.context.canEdit());
}
```

### XSS 防護

```typescript
// ❌ 禁止：直接使用 innerHTML
element.innerHTML = userInput;

// ✅ 正確：使用 Angular 內建綁定
@Component({ template: `<div [textContent]="userContent"></div>` })
class MyComponent {
  userContent = userInput; // Angular 自動轉義
}

// ⚠️ 需要 HTML 時，使用 DomSanitizer
@Component({ template: `<div [innerHTML]="trustedHtml"></div>` })
class MyComponent {
  private readonly sanitizer = inject(DomSanitizer);
  trustedHtml = this.sanitizer.bypassSecurityTrustHtml(knownSafeHtml);
}
```

---

## 5. 測試規範

### 測試命名規範

```typescript
// 格式：MethodName_Condition_ExpectedResult
it('loadTasks_whenBlueprintIdValid_shouldReturnTasks', () => { ... });
it('updateStatus_whenNoPermission_shouldThrowError', () => { ... });
```

### TestBed 配置

```typescript
describe('TaskStore', () => {
  let store: TaskStore;
  let mockRepository: jasmine.SpyObj<TaskRepository>;

  beforeEach(() => {
    mockRepository = jasmine.createSpyObj('TaskRepository', [
      'findByBlueprint',
      'create',
      'update',
      'delete'
    ]);

    TestBed.configureTestingModule({
      providers: [
        TaskStore,
        { provide: TaskRepository, useValue: mockRepository }
      ]
    });

    store = TestBed.inject(TaskStore);
  });

  it('loadTasks_whenSuccess_shouldUpdateState', async () => {
    const mockTasks = [{ id: '1', title: 'Task 1' }];
    mockRepository.findByBlueprint.and.returnValue(Promise.resolve(mockTasks));

    await store.loadTasks('blueprint-1');

    expect(store.tasks()).toEqual(mockTasks);
    expect(store.loading()).toBeFalse();
  });
});
```

### 覆蓋率目標

| 層級 | 目標 | 測試重點 |
|------|------|----------|
| Store 層 | 100% | 狀態變更、computed signals |
| Service 層 | 80%+ | API 呼叫、錯誤處理 |
| Component 層 | 60%+ | 關鍵交互、表單提交 |
| Utils | 100% | 純函數、邊界條件 |

---

## 6. 效能考量

### 變更檢測優化

- 永遠使用 `ChangeDetectionStrategy.OnPush`
- 避免在範本中直接呼叫函數
- 使用 `computed()` 快取計算結果

### Bundle 優化

- 啟用 Tree Shaking
- 使用動態導入分割程式碼
- 定期審查第三方套件大小
- 禁止循環依賴
- 使用 date-fns 替代 moment.js

### 效能指標

| 指標 | 目標值 |
|------|--------|
| 首次內容繪製 (FCP) | < 1.5s |
| 最大內容繪製 (LCP) | < 2.5s |
| 互動至下一次繪製 (INP) | < 200ms |
| 累積佈局偏移 (CLS) | < 0.1 |

---

## 7. 實作檢查清單

### 專案結構
- [ ] core/ 目錄建立
- [ ] shared/ 目錄建立
- [ ] features/ 目錄建立
- [ ] layout/ 目錄建立
- [ ] routes/ 目錄建立

### Core 層
- [ ] SupabaseService 實作
- [ ] WorkspaceContextFacade 實作
- [ ] AuthGuard 實作
- [ ] HTTP Interceptors 實作

### Shared 層
- [ ] 共用元件建立
- [ ] 共用指令建立
- [ ] 共用管道建立
- [ ] index.ts barrel export

### Feature 模組範本
- [ ] feature.routes.ts 範本
- [ ] shell component 範本
- [ ] store 範本
- [ ] repository 範本

### 開發規範
- [ ] ESLint 規則設定
- [ ] Prettier 設定
- [ ] 命名規範文件

### 測試規範
- [ ] 測試範本建立
- [ ] Mock 資料規範
- [ ] 覆蓋率門檻設定

---

## 附錄：Import 順序規範

```typescript
// 1. Angular 核心
import { Component, inject, signal } from '@angular/core';

// 2. ng-zorro-antd
import { NzButtonModule } from 'ng-zorro-antd/button';

// 3. @delon
import { PageHeaderModule } from '@delon/abc/page-header';

// 4. 專案內部 - 共用
import { SharedModule } from '@shared';

// 5. 專案內部 - 功能相關
import { TaskStore } from '../data-access/stores/task.store';
```

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
