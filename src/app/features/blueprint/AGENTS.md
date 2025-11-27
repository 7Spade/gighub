# AGENTS.md - Blueprint Feature Guidelines

> **架構模式**: 垂直切片架構 (Vertical Slice Architecture)
> **核心原則**: 單一職責原則 (SRP) + 奧卡姆剃刀 + 企業化標準

---

## 一、Blueprint 功能概述

`blueprint/` 是一個完整的垂直切片功能模組範例，包含：

- **Blueprint** (藍圖) - 主要業務實體
- **Task** (任務) - 相關子實體
- **Diary** (日記) - 相關子實體
- **Todo** (待辦) - 相關子實體

---

## 二、目錄結構 (實際)

```
features/blueprint/
├── data-access/              # 資料存取層
│   ├── repositories/         # 資料存取抽象
│   ├── services/             # 業務邏輯服務
│   ├── stores/               # ⭐ Signal Stores
│   │   ├── blueprint.store.ts
│   │   ├── task.store.ts
│   │   ├── diary.store.ts
│   │   ├── todo.store.ts
│   │   └── index.ts
│   └── index.ts
├── domain/                   # 領域層
│   ├── enums/               # 列舉定義
│   ├── interfaces/          # 介面定義
│   ├── models/              # 領域模型
│   ├── types/               # 型別定義
│   └── index.ts
├── shell/                    # Shell 元件
│   ├── blueprint-shell/     # 主容器元件
│   ├── dialogs/             # 對話框元件
│   │   ├── blueprint-form-dialog/
│   │   ├── task-form-dialog/
│   │   └── ...
│   └── index.ts
├── ui/                       # UI 元件
│   ├── blueprint-list/      # 藍圖列表
│   ├── task/                # 任務元件
│   ├── diary/               # 日記元件
│   ├── todo/                # 待辦元件
│   └── index.ts
├── guards/                   # 路由守衛
├── directives/               # 指令
├── pipes/                    # 管道
├── utils/                    # 工具函數
├── constants/                # 常數配置
├── blueprint.routes.ts       # 路由定義
└── index.ts                  # 公開 API
```

---

## 三、狀態管理 (data-access/stores/)

### 3.1 Store 架構

```
stores/
├── blueprint.store.ts    # 藍圖狀態管理
├── task.store.ts         # 任務狀態管理
├── diary.store.ts        # 日記狀態管理
├── todo.store.ts         # 待辦狀態管理
└── index.ts
```

### 3.2 BlueprintStore 實作範例

```typescript
// data-access/stores/blueprint.store.ts
@Injectable()
export class BlueprintStore {
  private readonly repository = inject(BlueprintRepository);
  private readonly authContext = inject(AuthContextService);

  // 私有狀態
  private readonly _state = signal<BlueprintState>({
    items: [],
    selectedId: null,
    loading: false,
    error: null
  });

  // 公開只讀 Signals
  readonly items = computed(() => this._state().items);
  readonly selectedId = computed(() => this._state().selectedId);
  readonly loading = computed(() => this._state().loading);
  readonly error = computed(() => this._state().error);

  // 衍生狀態
  readonly selectedItem = computed(() =>
    this.items().find(item => item.id === this.selectedId())
  );

  // 上下文感知載入
  async loadItems(): Promise<void> {
    const contextId = this.authContext.contextId();
    if (!contextId) return;

    this._state.update(s => ({ ...s, loading: true }));
    try {
      const items = await this.repository.findByContext(contextId);
      this._state.update(s => ({ ...s, items, loading: false }));
    } catch (error) {
      this._state.update(s => ({
        ...s,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      }));
    }
  }

  // CRUD 操作
  async create(input: BlueprintCreateInput): Promise<void> { ... }
  async update(id: string, input: BlueprintUpdateInput): Promise<void> { ... }
  async delete(id: string): Promise<void> { ... }
}
```

### 3.3 狀態流向圖

```
┌────────────────────────────────────────────────────────┐
│                  BlueprintShellComponent               │
│                          │                              │
│            ┌─────────────┴─────────────┐               │
│            ▼                           ▼               │
│   ┌─────────────────┐        ┌─────────────────┐      │
│   │ BlueprintStore  │        │    TaskStore    │      │
│   └─────────────────┘        └─────────────────┘      │
│            │                           │               │
│            ▼                           ▼               │
│   ┌─────────────────┐        ┌─────────────────┐      │
│   │BlueprintRepository│      │ TaskRepository  │      │
│   └─────────────────┘        └─────────────────┘      │
│            │                           │               │
│            └───────────┬───────────────┘               │
│                        ▼                               │
│              ┌─────────────────┐                       │
│              │  Supabase Client │                      │
│              └─────────────────┘                       │
└────────────────────────────────────────────────────────┘
```

---

## 四、領域層 (domain/)

### 4.1 模型定義

```typescript
// domain/models/blueprint.model.ts
export interface Blueprint {
  id: string;
  name: string;
  description: string;
  status: BlueprintStatus;
  owner_id: string;
  context_type: ContextType;
  context_id: string;
  created_at: string;
  updated_at: string;
}

// domain/enums/blueprint-status.enum.ts
export enum BlueprintStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ARCHIVED = 'archived'
}

// domain/types/blueprint.types.ts
export type BlueprintCreateInput = Omit<Blueprint, 'id' | 'created_at' | 'updated_at'>;
export type BlueprintUpdateInput = Partial<BlueprintCreateInput>;
```

### 4.2 介面定義

```typescript
// domain/interfaces/blueprint-repository.interface.ts
export interface IBlueprintRepository {
  findAll(): Promise<Blueprint[]>;
  findById(id: string): Promise<Blueprint | null>;
  findByContext(contextId: string): Promise<Blueprint[]>;
  create(input: BlueprintCreateInput): Promise<Blueprint>;
  update(id: string, input: BlueprintUpdateInput): Promise<Blueprint>;
  delete(id: string): Promise<void>;
}
```

---

## 五、Shell 元件 (shell/)

### 5.1 BlueprintShellComponent

```typescript
// shell/blueprint-shell/blueprint-shell.component.ts
@Component({
  selector: 'app-blueprint-shell',
  standalone: true,
  imports: [...SHARED_IMPORTS, BlueprintListComponent, TaskListComponent],
  // ✅ 在 Shell 層級提供需要的 Stores
  // 注意：只提供當前 Shell 實際使用的 Stores
  providers: [BlueprintStore, TaskStore],
  template: `
    <page-header [title]="'蓍圖管理'" />

    <nz-card>
      @if (blueprintStore.loading()) {
        <nz-spin [nzTip]="'載入中...'" />
      } @else {
        <app-blueprint-list
          [items]="blueprintStore.items()"
          [selectedId]="blueprintStore.selectedId()"
          (select)="onSelectBlueprint($event)"
          (create)="onCreateBlueprint()"
          (edit)="onEditBlueprint($event)"
          (delete)="onDeleteBlueprint($event)"
        />
      }
    </nz-card>

    @if (blueprintStore.selectedItem()) {
      <nz-card [nzTitle]="'任務列表'">
        <app-task-list
          [tasks]="taskStore.items()"
          (create)="onCreateTask()"
        />
      </nz-card>
    }
  `
})
export class BlueprintShellComponent implements OnInit {
  protected readonly blueprintStore = inject(BlueprintStore);
  protected readonly taskStore = inject(TaskStore);
  private readonly modal = inject(NzModalService);

  ngOnInit(): void {
    this.blueprintStore.loadItems();
  }

  onSelectBlueprint(id: string): void {
    this.blueprintStore.selectItem(id);
    this.taskStore.loadByBlueprint(id);
  }

  onCreateBlueprint(): void {
    this.modal.create({
      nzTitle: '新增 Blueprint',
      nzContent: BlueprintFormDialogComponent,
      nzData: { mode: 'create' }
    });
  }
  // ...
}
```

### 5.2 對話框元件 (dialogs/)

```typescript
// shell/dialogs/blueprint-form-dialog/blueprint-form-dialog.component.ts
@Component({
  selector: 'app-blueprint-form-dialog',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <form nz-form [formGroup]="form">
      <se label="名稱" required>
        <input nz-input formControlName="name" />
      </se>
      <se label="描述">
        <textarea nz-input formControlName="description" rows="4"></textarea>
      </se>
      <se label="狀態">
        <nz-select formControlName="status">
          @for (status of statusOptions; track status.value) {
            <nz-option [nzValue]="status.value" [nzLabel]="status.label" />
          }
        </nz-select>
      </se>
    </form>
  `
})
export class BlueprintFormDialogComponent {
  readonly data = inject<BlueprintFormDialogData>(NZ_MODAL_DATA);
  private readonly store = inject(BlueprintStore);

  readonly form = inject(FormBuilder).group({
    name: ['', Validators.required],
    description: [''],
    status: [BlueprintStatus.DRAFT]
  });

  readonly statusOptions = [
    { value: BlueprintStatus.DRAFT, label: '草稿' },
    { value: BlueprintStatus.ACTIVE, label: '進行中' },
    { value: BlueprintStatus.COMPLETED, label: '已完成' }
  ];

  async onSubmit(): Promise<void> {
    if (this.form.invalid) return;

    if (this.data.mode === 'create') {
      await this.store.create(this.form.value);
    } else {
      await this.store.update(this.data.id!, this.form.value);
    }
  }
}
```

---

## 六、UI 元件 (ui/)

### 6.1 BlueprintListComponent

```typescript
// ui/blueprint-list/blueprint-list.component.ts
@Component({
  selector: 'app-blueprint-list',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <div class="toolbar">
      <button nz-button nzType="primary" (click)="create.emit()">
        <span nz-icon nzType="plus"></span>
        新增
      </button>
    </div>

    <nz-table [nzData]="items()" [nzShowPagination]="items().length > 10">
      <thead>
        <tr>
          <th>名稱</th>
          <th>狀態</th>
          <th>建立時間</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        @for (item of items(); track item.id) {
          <tr
            [class.selected]="item.id === selectedId()"
            (click)="select.emit(item.id)"
          >
            <td>{{ item.name }}</td>
            <td>
              <nz-tag [nzColor]="getStatusColor(item.status)">
                {{ item.status }}
              </nz-tag>
            </td>
            <td>{{ item.created_at | date:'yyyy-MM-dd' }}</td>
            <td>
              <button nz-button nzSize="small" (click)="edit.emit(item.id); $event.stopPropagation()">
                編輯
              </button>
              <button nz-button nzSize="small" nzDanger (click)="delete.emit(item.id); $event.stopPropagation()">
                刪除
              </button>
            </td>
          </tr>
        } @empty {
          <tr>
            <td colspan="4">
              <nz-empty [nzNotFoundContent]="'暫無資料'" />
            </td>
          </tr>
        }
      </tbody>
    </nz-table>
  `
})
export class BlueprintListComponent {
  // Inputs
  readonly items = input<Blueprint[]>([]);
  readonly selectedId = input<string | null>(null);

  // Outputs
  readonly select = output<string>();
  readonly create = output<void>();
  readonly edit = output<string>();
  readonly delete = output<string>();

  getStatusColor(status: BlueprintStatus): string {
    const colors: Record<BlueprintStatus, string> = {
      [BlueprintStatus.DRAFT]: 'default',
      [BlueprintStatus.ACTIVE]: 'processing',
      [BlueprintStatus.COMPLETED]: 'success',
      [BlueprintStatus.ARCHIVED]: 'warning'
    };
    return colors[status];
  }
}
```

---

## 七、路由配置

```typescript
// blueprint.routes.ts
export const BLUEPRINT_ROUTES: Routes = [
  {
    path: '',
    component: BlueprintShellComponent,
    children: [
      { path: '', redirectTo: 'list', pathMatch: 'full' },
      {
        path: 'list',
        component: BlueprintListPageComponent
      },
      {
        path: ':id',
        component: BlueprintDetailPageComponent
      }
    ]
  }
];
```

---

## 八、公開 API (index.ts)

```typescript
// index.ts
/**
 * Blueprint Feature Module - Public API
 * 只導出應該對外公開的部分
 */

// Routes
export { BLUEPRINT_ROUTES } from './blueprint.routes';

// Domain (公開類型)
export * from './domain';

// Constants
export * from './constants';

// Utils
export * from './utils';

// Directives
export * from './directives';

// Pipes
export * from './pipes';

// Guards
export * from './guards';

// Shell (公開元件)
export { BlueprintShellComponent } from './shell';
export {
  BlueprintFormDialogComponent,
  BlueprintFormDialogData,
  TaskFormDialogComponent,
  TaskFormDialogData
} from './shell';

// UI (公開元件)
export {
  BlueprintListComponent,
  TaskListComponent,
  DiaryListComponent,
  TodoListComponent
} from './ui';

// Stores (Facade API)
export {
  BlueprintStore,
  TaskStore,
  DiaryStore,
  TodoStore
} from './data-access';
```

---

## 九、認證整合

### 9.1 上下文感知

```typescript
// 所有資料操作都應該考慮當前上下文
@Injectable()
export class BlueprintStore {
  private readonly authContext = inject(AuthContextService);

  async loadItems(): Promise<void> {
    const contextId = this.authContext.contextId();
    const contextType = this.authContext.contextType();

    if (!contextId) {
      console.warn('No context available');
      return;
    }

    // 根據上下文類型載入對應資料
    const items = await this.repository.findByContext(contextId, contextType);
    // ...
  }
}
```

### 9.2 認證流程

```
Supabase Auth → @delon/auth → DA_SERVICE_TOKEN → @delon/acl
      │
      ▼
AuthContextService (Signal State)
      │
      ▼
BlueprintStore (Context-Aware)
```

---

## 十、UI 元件優先級

```
優先級：NG-ZORRO > @delon/abc > 自行開發
```

### 10.1 本功能使用的元件

| 用途 | 元件 | 來源 |
|------|------|------|
| 頁面標頭 | `page-header` | `@delon/abc` |
| 表格 | `nz-table` | `ng-zorro-antd` |
| 卡片 | `nz-card` | `ng-zorro-antd` |
| 標籤 | `nz-tag` | `ng-zorro-antd` |
| 模態框 | `nz-modal` | `ng-zorro-antd` |
| 表單 | `nz-form`, `se` | `ng-zorro-antd`, `@delon/abc` |
| 空狀態 | `nz-empty` | `ng-zorro-antd` |
| 載入 | `nz-spin` | `ng-zorro-antd` |

---

## 十一、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **@delon/abc ST 複雜配置** - 自訂欄位、Widget
2. **@delon/form SF 表單** - JSON-Schema 驗證
3. **Supabase 查詢** - 複雜過濾、RLS
4. **Angular Signals 進階** - Effect、Signal 互動

### 可直接實作的情況

1. 基本 Signal Store 模式
2. 標準 CRUD 操作
3. 簡單 UI 元件
4. 基本表單驗證

---

## 十二、相關文件

- [根目錄 AGENTS.md](../../../AGENTS.md) - 專案總覽
- [features/AGENTS.md](../AGENTS.md) - Features 層指引
- [shared/AGENTS.md](../../shared/AGENTS.md) - 共享層指引
- [core/AGENTS.md](../../core/AGENTS.md) - 核心層指引
