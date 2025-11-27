# AGENTS.md - Features Layer Guidelines

> **架構模式**: 垂直切片架構 (Vertical Slice Architecture)
> **核心原則**: 單一職責原則 (SRP) + 奧卡姆剃刀 + 企業化標準

---

## 一、Features 層概述

`features/` 採用**垂直切片架構**，每個功能模組是一個獨立的垂直切片，包含：

- 該功能所需的所有層級 (data-access, domain, shell, ui)
- 完整的業務邏輯
- 功能特定的狀態管理

---

## 二、垂直切片架構

### 2.1 架構圖示

```
features/
└── [feature-name]/           # 功能模組 (垂直切片)
    ├── data-access/          # 資料存取層
    │   ├── stores/           # ⭐ Signal Stores (狀態管理)
    │   │   ├── [feature].store.ts
    │   │   └── index.ts
    │   ├── repositories/     # 資料存取抽象
    │   │   └── [feature].repository.ts
    │   ├── services/         # 業務邏輯服務
    │   │   └── [feature].service.ts
    │   └── index.ts
    ├── domain/               # 領域層
    │   ├── models/           # 領域模型
    │   ├── interfaces/       # 介面定義
    │   ├── types/            # 型別定義
    │   ├── enums/            # 列舉定義
    │   └── index.ts
    ├── shell/                # Shell 元件 (Smart Components)
    │   ├── [feature]-shell/  # 主要容器元件
    │   ├── dialogs/          # 對話框元件 (CRUD)
    │   └── index.ts
    ├── ui/                   # UI 元件 (Presentational)
    │   ├── [feature]-list/   # 列表元件
    │   ├── [feature]-card/   # 卡片元件
    │   └── index.ts
    ├── guards/               # 路由守衛
    ├── directives/           # 指令
    ├── pipes/                # 管道
    ├── utils/                # 工具函數
    ├── constants/            # 常數配置
    ├── [feature].routes.ts   # 路由定義
    └── index.ts              # ⭐ 公開 API
```

### 2.2 各層職責

| 層級 | 職責 | 內容 |
|------|------|------|
| `data-access/` | 資料存取與狀態管理 | Stores, Repositories, Services |
| `domain/` | 領域模型定義 | Models, Interfaces, Types, Enums |
| `shell/` | 智能元件 | 容器元件、對話框 |
| `ui/` | 展示元件 | 純展示、無業務邏輯 |

---

## 三、狀態管理標準

### 3.1 Store 在垂直切片中的位置

```
features/[feature]/
└── data-access/
    └── stores/              # ⭐ Signal Stores 放置於此
        ├── [feature].store.ts
        ├── [related].store.ts
        └── index.ts
```

### 3.2 Signal Store 實作模式

```typescript
// features/blueprint/data-access/stores/blueprint.store.ts
import { Injectable, computed, inject, signal } from '@angular/core';

interface BlueprintState {
  items: Blueprint[];
  selectedId: string | null;
  loading: boolean;
  error: string | null;
}

@Injectable()
export class BlueprintStore {
  private readonly repository = inject(BlueprintRepository);

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
  readonly isEmpty = computed(() => this.items().length === 0);

  // 動作方法
  async loadItems(): Promise<void> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items, loading: false }));
    } catch (error) {
      this._state.update(s => ({
        ...s,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      }));
    }
  }

  selectItem(id: string): void {
    this._state.update(s => ({ ...s, selectedId: id }));
  }
}
```

### 3.3 狀態管理流向

```
┌─────────────────────────────────────────────────────────┐
│                     UI Component                         │
│                          │                               │
│           ┌──────────────┴──────────────┐               │
│           ▼                              ▼               │
│    ┌─────────────┐              ┌─────────────┐         │
│    │   Display   │              │   Actions   │         │
│    │  (signals)  │              │  (methods)  │         │
│    └─────────────┘              └─────────────┘         │
│           │                              │               │
│           └──────────────┬──────────────┘               │
│                          ▼                               │
│              ┌───────────────────┐                       │
│              │       Store       │                       │
│              │  (Signal Store)   │                       │
│              └───────────────────┘                       │
│                          │                               │
│                          ▼                               │
│              ┌───────────────────┐                       │
│              │    Repository     │                       │
│              └───────────────────┘                       │
│                          │                               │
│                          ▼                               │
│              ┌───────────────────┐                       │
│              │  Supabase Client  │                       │
│              └───────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

---

## 四、Smart vs Presentational 元件

### 4.1 Shell 元件 (Smart Components)

**Store 提供最佳實踐**：
- ✅ 只在 Shell 層級提供實際使用的 Stores
- ✅ 避免提供未使用的 Stores（浪費實例化）
- ✅ 子元件可透過路由懶載入提供其他 Stores

```typescript
// features/blueprint/shell/blueprint-shell/blueprint-shell.component.ts
@Component({
  selector: 'app-blueprint-shell',
  standalone: true,
  imports: [...SHARED_IMPORTS, BlueprintListComponent],
  // ✅ 只提供當前 Shell 需要的 Store
  providers: [BlueprintStore],
  template: `
    <page-header [title]="'Blueprint 管理'" />

    @if (store.loading()) {
      <nz-spin [nzTip]="'載入中...'" />
    } @else {
      <app-blueprint-list
        [items]="store.items()"
        [selectedId]="store.selectedId()"
        (select)="onSelect($event)"
        (delete)="onDelete($event)"
      />
    }
  `
})
export class BlueprintShellComponent implements OnInit {
  protected readonly store = inject(BlueprintStore);

  ngOnInit(): void {
    this.store.loadItems();
  }

  onSelect(id: string): void {
    this.store.selectItem(id);
  }

  async onDelete(id: string): Promise<void> {
    await this.store.deleteItem(id);
  }
}
```

### 4.2 UI 元件 (Presentational Components)

```typescript
// features/blueprint/ui/blueprint-list/blueprint-list.component.ts
@Component({
  selector: 'app-blueprint-list',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <nz-table [nzData]="items()">
      <thead>
        <tr>
          <th>名稱</th>
          <th>狀態</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        @for (item of items(); track item.id) {
          <tr [class.selected]="item.id === selectedId()">
            <td>{{ item.name }}</td>
            <td><nz-tag>{{ item.status }}</nz-tag></td>
            <td>
              <button nz-button (click)="select.emit(item.id)">選擇</button>
              <button nz-button nzDanger (click)="delete.emit(item.id)">刪除</button>
            </td>
          </tr>
        }
      </tbody>
    </nz-table>
  `
})
export class BlueprintListComponent {
  // Inputs (Signal API)
  readonly items = input<Blueprint[]>([]);
  readonly selectedId = input<string | null>(null);

  // Outputs
  readonly select = output<string>();
  readonly delete = output<string>();
}
```

---

## 五、領域層 (domain/)

### 5.1 模型定義

```typescript
// features/blueprint/domain/models/blueprint.model.ts
export interface Blueprint {
  id: string;
  name: string;
  description: string;
  status: BlueprintStatus;
  createdAt: Date;
  updatedAt: Date;
}

// features/blueprint/domain/enums/blueprint-status.enum.ts
export enum BlueprintStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  ARCHIVED = 'archived'
}

// features/blueprint/domain/types/blueprint.types.ts
export type BlueprintCreateInput = Omit<Blueprint, 'id' | 'createdAt' | 'updatedAt'>;
export type BlueprintUpdateInput = Partial<BlueprintCreateInput>;
```

---

## 六、路由配置

### 6.1 Feature 路由

```typescript
// features/blueprint/blueprint.routes.ts
export const BLUEPRINT_ROUTES: Routes = [
  {
    path: '',
    component: BlueprintShellComponent,
    children: [
      { path: '', redirectTo: 'list', pathMatch: 'full' },
      { path: 'list', component: BlueprintListPageComponent },
      { path: ':id', component: BlueprintDetailPageComponent },
      { path: ':id/edit', component: BlueprintEditPageComponent }
    ]
  }
];
```

### 6.2 在主路由中整合

```typescript
// routes/routes.ts
{
  path: 'blueprint',
  loadChildren: () => import('../features/blueprint/blueprint.routes')
    .then(m => m.BLUEPRINT_ROUTES)
}
```

---

## 七、模組邊界管理

### 7.1 公開 API (index.ts)

```typescript
// features/blueprint/index.ts
// ✅ 只導出應該公開的部分

// Routes
export { BLUEPRINT_ROUTES } from './blueprint.routes';

// Domain (公開類型)
export * from './domain';

// Constants
export * from './constants';

// Public Shell Components (如需要跨功能使用)
export { BlueprintShellComponent } from './shell';

// Public UI Components (如需要跨功能使用)
export { BlueprintListComponent } from './ui';

// Stores (Facade API)
export { BlueprintStore } from './data-access';

// ❌ 不要導出內部實現
// export * from './data-access/repositories';  // 內部實現
// export * from './data-access/services';      // 內部實現
```

### 7.2 依賴規則

```
features/[feature-name]/ 可以依賴：
├── core/          # ✅ 核心服務
├── shared/        # ✅ 共享元件
├── @angular/*
├── @delon/*
└── ng-zorro-antd

features/[feature-name]/ 不可依賴：
├── layout/        # ❌
├── routes/        # ❌
└── features/[other-feature]/  # ❌ 功能模組間不能直接依賴
```

### 7.3 功能模組間通訊

```typescript
// ❌ 錯誤：直接依賴其他功能模組
import { OtherFeatureStore } from '../other-feature';

// ✅ 正確：透過 shared/ 或 core/ 共享
import { SharedService } from '@shared';
```

---

## 八、UI 元件優先級

### 8.1 選擇原則

```
優先級：NG-ZORRO > @delon/abc > 自行開發
```

### 8.2 常用元件對照

| 需求 | 推薦元件 | 來源 |
|------|----------|------|
| 數據表格 | `st` | `@delon/abc` |
| JSON 表單 | `sf` | `@delon/form` |
| 詳情展示 | `sv` | `@delon/abc` |
| 頁面標頭 | `page-header` | `@delon/abc` |
| 基礎表格 | `nz-table` | `ng-zorro-antd` |
| 表單佈局 | `se`, `sg` | `@delon/abc` |
| 卡片 | `nz-card` | `ng-zorro-antd` |
| 模態框 | `nz-modal` | `ng-zorro-antd` |

---

## 九、Angular 20+ 模板語法

### 9.1 新控制流

```html
@if (store.loading()) {
  <nz-spin />
} @else if (store.error()) {
  <nz-alert [nzMessage]="store.error()" nzType="error" />
} @else {
  @for (item of store.items(); track item.id) {
    <app-item-card [item]="item" />
  } @empty {
    <nz-empty />
  }
}
```

### 9.2 Signal 輸入/輸出

```typescript
// UI 元件使用 Signal API
export class ItemCardComponent {
  readonly item = input.required<Item>();
  readonly isSelected = input(false);

  readonly select = output<string>();
  readonly delete = output<string>();
}
```

---

## 十、序列化思考 (Sequential Thinking)

### 10.1 開發新功能的思考流程

```
1. 領域分析
   └── 定義 domain/ 下的模型、介面、列舉

2. 資料層設計
   └── 設計 data-access/ 下的 Repository → Service → Store

3. UI 元件設計
   └── 設計 ui/ 下的展示元件 (無業務邏輯)

4. Shell 元件整合
   └── 在 shell/ 中整合 Store 與 UI

5. 路由配置
   └── 配置 [feature].routes.ts

6. 公開 API 定義
   └── 在 index.ts 中定義公開導出
```

---

## 十一、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **@delon/abc ST 元件** - 複雜表格配置
2. **@delon/form SF 元件** - JSON-Schema 表單
3. **Angular Signals 進階** - Signal Effects、Signal 最佳實踐
4. **Supabase 查詢** - 複雜查詢、RLS 設定

### 可直接實作的情況

1. 標準 Signal Store 模式
2. 基本 CRUD 操作
3. 簡單 UI 元件

---

## 十二、相關文件

- [根目錄 AGENTS.md](../../AGENTS.md) - 專案總覽
- [app/AGENTS.md](../AGENTS.md) - 應用層級指引
- [shared/AGENTS.md](../shared/AGENTS.md) - 共享層指引 (features 依賴 shared)
- [blueprint/AGENTS.md](./blueprint/AGENTS.md) - Blueprint 功能範例
