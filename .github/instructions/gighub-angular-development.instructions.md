---
description: 'GigHub 專案專屬 Angular 20 開發規範（與通用 angular.instructions.md 互補），涵蓋本專案的 ng-alain、Signals 狀態管理、新控制流語法等特定實踐'
applyTo: '**/*.ts, **/*.html, **/*.less, **/*.css'
---

# GigHub Angular 20 開發實踐

> Angular 20 現代化開發規範，適用於所有前端程式碼

---

## 🎯 Angular 20 核心特性

### Standalone 架構

- 完全採用 Standalone 元件架構
- 不使用 NgModule
- 使用 `bootstrapApplication` 啟動應用程式
- 使用 `provide*` APIs 設定（provideHttpClient, provideRouter 等）

### Signals 狀態管理

- 使用 `signal()`, `computed()`, `effect()` 管理狀態
- Signal 用於同步反應式，Observable 用於非同步與時間序列
- 使用 `toSignal()` / `toObservable()` 進行轉換
- `computed()` 必須是純函數，不可有副作用
- `effect()` 應盡量少用，優先使用聲明式 computed

### 新控制流語法

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

@switch (status()) {
  @case ('pending') { <nz-tag nzColor="default">待處理</nz-tag> }
  @case ('completed') { <nz-tag nzColor="success">已完成</nz-tag> }
}
```

```html
<!-- ❌ 禁止使用舊語法 -->
<div *ngIf="loading">...</div>
<div *ngFor="let task of tasks">...</div>
<div [ngSwitch]="status">...</div>
```

---

## 🧩 Component 規範

### 必須使用的 API

```typescript
// ✅ 正確：函數式 API
@Component({
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TaskComponent {
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
}
```

```typescript
// ❌ 禁止：使用裝飾器
@Input() task!: Task;
@Output() taskChange = new EventEmitter<Task>();
constructor(private store: TaskStore) {}
```

### 變更檢測

- 永遠使用 `ChangeDetectionStrategy.OnPush`
- 避免在範本中直接呼叫函數（會在每次變更檢測時執行）
- 使用 `computed()` 快取計算結果

---

## 📦 Store 風格 (Signals)

### Store 模板

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

  // Update method
  async createTask(data: CreateTaskDto): Promise<Task | null> {
    const task = await this.repository.create(data);
    this._tasks.update(tasks => [...tasks, task]); // ✅ Use update
    return task;
  }

  // Reset state
  reset(): void {
    this._tasks.set([]);
    this._loading.set(false);
    this._error.set(null);
  }
}
```

### Signal 操作規則

```typescript
// ❌ 禁止：直接修改 Signal 內部值
this._tasks().push(newTask);

// ✅ 正確：使用 update 方法
this._tasks.update(tasks => [...tasks, newTask]);
```

---

## 🔄 RxJS 訂閱管理

### 記憶體洩漏預防

```typescript
// ✅ 正確：使用 takeUntilDestroyed
private destroyRef = inject(DestroyRef);

ngOnInit() {
  this.data$
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe(data => { ... });
}
```

```typescript
// ❌ 禁止：未清理 Subscription
ngOnInit() {
  this.data$.subscribe(data => { ... });
}
```

### 優先使用 async pipe

在範本中優先使用 `async` pipe 避免手動訂閱

---

## ⚡ 效能優化

### OnPush 策略

所有元件必須使用 `ChangeDetectionStrategy.OnPush`

### trackBy 必須使用

```html
<!-- ✅ 新語法自動追蹤 -->
@for (task of tasks(); track task.id) {
  <app-task-card [task]="task" />
}
```

### 延遲載入

```html
<!-- 使用 @defer 延遲載入 -->
@defer (on viewport) {
  <heavy-component />
} @placeholder {
  <nz-skeleton />
}
```

### Bundle 優化

- 啟用 Tree Shaking
- 使用動態導入分割程式碼
- 定期審查第三方套件大小
- 禁止循環依賴
- 使用 date-fns 替代 moment.js

---

## 🎨 樣式規範

### LESS 變數使用

```less
@import '~@delon/theme/styles/layout/default/mixins';

.task-card {
  padding: @padding-md;
  border-radius: @border-radius-base;
  background: @component-background;
}
```

### 禁止內聯樣式

使用元件 LESS 或 ng-alain 工具類

---

## 🔗 Import 順序

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

## 🧪 測試規範

### 測試命名

```typescript
// 格式：MethodName_Condition_ExpectedResult
it('loadTasks_whenBlueprintIdValid_shouldReturnTasks', () => { ... });
it('updateStatus_whenNoPermission_shouldThrowError', () => { ... });
```

### Signal 測試

使用 Angular 測試工具測試 Signal 變化

### 覆蓋率目標

| 層級 | 目標 |
|------|------|
| Store | 100% |
| Service | 80%+ |
| Component | 60%+ |
| Utils | 100% |

---

## 📊 效能指標

| 指標 | 目標 |
|------|------|
| FCP | < 1.5s |
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| 任務樹渲染 (1000節點) | < 500ms |

---

**最後更新**: 2025-11-27
