# ⚡ 快速上手指南

> **目標**: 5 分鐘內開始開發，無需閱讀大量文檔

---

## 📑 目錄

- [環境檢查](#環境檢查)
- [建立新功能](#建立新功能)
- [元件開發](#元件開發)
- [資料層開發](#資料層開發)
- [常見問題](#常見問題)

---

## 環境檢查

### 1. 確認開發環境

```bash
# 檢查 Node.js 版本 (需要 18+)
node --version

# 檢查 Yarn 版本
yarn --version

# 安裝依賴
yarn install

# 啟動開發伺服器
yarn start
```

### 2. 開發前必讀

| 項目 | 時間 | 文件 |
|------|------|------|
| 核心原則 | 2 分鐘 | [AGENTS.md](../../AGENTS.md) §一 |
| 技術棧 | 1 分鐘 | [AGENTS.md](../../AGENTS.md) §二 |
| 命名規範 | 2 分鐘 | [copilot-instructions.md](../../.github/copilot/copilot-instructions.md) §命名規範 |

---

## 建立新功能

### 快速流程

```
1. 確認功能層級 (基礎/容器/業務)
   └─→ 參考 ./architecture-decision-tree.md

2. 建立目錄結構
   └─→ 使用 ./module-templates/feature.template.md

3. 建立領域模型
   └─→ domain/models/, domain/interfaces/

4. 建立資料層
   └─→ data-access/repositories/, data-access/stores/

5. 建立 UI 元件
   └─→ shell/, ui/

6. 配置路由
   └─→ [feature].routes.ts
```

### 目錄結構範本

```
src/app/features/{feature-name}/
├── {feature-name}.routes.ts     # 路由配置
├── index.ts                     # 公開 API
│
├── domain/                      # 領域層
│   ├── models/
│   │   └── {feature}.model.ts
│   ├── interfaces/
│   │   └── {feature}.interface.ts
│   ├── enums/
│   │   └── {feature}-status.enum.ts
│   └── index.ts
│
├── data-access/                 # 資料存取層
│   ├── repositories/
│   │   └── {feature}.repository.ts
│   ├── stores/
│   │   └── {feature}.store.ts
│   └── index.ts
│
├── shell/                       # 智能元件
│   └── {feature}-shell/
│       ├── {feature}-shell.component.ts
│       ├── {feature}-shell.component.html
│       └── {feature}-shell.component.less
│
└── ui/                          # 展示元件
    └── {feature}-list/
        ├── {feature}-list.component.ts
        ├── {feature}-list.component.html
        └── {feature}-list.component.less
```

---

## 元件開發

### Shell 元件 (Smart Component)

**特徵**：
- ✅ 注入 Store
- ✅ 處理業務邏輯
- ✅ 管理狀態

```typescript
// {feature}-shell.component.ts
import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';
import { FeatureStore } from '../../data-access/stores/feature.store';

@Component({
  selector: 'app-feature-shell',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  providers: [FeatureStore],
  templateUrl: './feature-shell.component.html',
  styleUrl: './feature-shell.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FeatureShellComponent implements OnInit {
  protected readonly store = inject(FeatureStore);

  ngOnInit(): void {
    this.store.loadItems();
  }
}
```

### UI 元件 (Presentational Component)

**特徵**：
- ✅ 使用 `input()` / `output()`
- ✅ 無業務邏輯
- ✅ 純展示用途

```typescript
// {feature}-list.component.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';
import { Feature } from '../../domain/models/feature.model';

@Component({
  selector: 'app-feature-list',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  templateUrl: './feature-list.component.html',
  styleUrl: './feature-list.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FeatureListComponent {
  readonly items = input<Feature[]>([]);
  readonly selectedId = input<string | null>(null);

  readonly select = output<string>();
  readonly delete = output<string>();
}
```

### 模板語法 (Angular 20+)

```html
<!-- 條件渲染 -->
@if (store.loading()) {
  <nz-spin nzTip="載入中..." />
} @else if (store.error()) {
  <nz-alert [nzMessage]="store.error()" nzType="error" />
} @else {
  <!-- 列表渲染 -->
  @for (item of store.items(); track item.id) {
    <app-feature-card [item]="item" />
  } @empty {
    <nz-empty nzNotFoundContent="暫無資料" />
  }
}

<!-- 切換渲染 -->
@switch (item.status) {
  @case ('active') { <nz-tag nzColor="green">進行中</nz-tag> }
  @case ('completed') { <nz-tag nzColor="blue">已完成</nz-tag> }
  @default { <nz-tag>未知</nz-tag> }
}
```

---

## 資料層開發

### Signal Store 範本

```typescript
// {feature}.store.ts
import { Injectable, computed, inject, signal } from '@angular/core';
import { FeatureRepository } from '../repositories/feature.repository';
import { Feature } from '../../domain/models/feature.model';

interface FeatureState {
  items: Feature[];
  selectedId: string | null;
  loading: boolean;
  error: string | null;
}

const initialState: FeatureState = {
  items: [],
  selectedId: null,
  loading: false,
  error: null,
};

@Injectable()
export class FeatureStore {
  private readonly repository = inject(FeatureRepository);
  private readonly _state = signal<FeatureState>(initialState);

  // 公開 Signals
  readonly items = computed(() => this._state().items);
  readonly selectedId = computed(() => this._state().selectedId);
  readonly loading = computed(() => this._state().loading);
  readonly error = computed(() => this._state().error);

  // 衍生 Signals
  readonly selectedItem = computed(() =>
    this.items().find(item => item.id === this.selectedId())
  );
  readonly isEmpty = computed(() => this.items().length === 0);
  readonly itemCount = computed(() => this.items().length);

  // 載入資料
  async loadItems(): Promise<void> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items, loading: false }));
    } catch (error) {
      this._state.update(s => ({
        ...s,
        loading: false,
        error: error instanceof Error ? error.message : '載入失敗',
      }));
    }
  }

  // 選擇項目
  selectItem(id: string | null): void {
    this._state.update(s => ({ ...s, selectedId: id }));
  }

  // 重置狀態
  reset(): void {
    this._state.set(initialState);
  }
}
```

### Repository 範本

```typescript
// {feature}.repository.ts
import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@core';
import { Feature, CreateFeatureDto, UpdateFeatureDto } from '../../domain';

@Injectable({ providedIn: 'root' })
export class FeatureRepository {
  private readonly supabase = inject(SupabaseService);
  private readonly TABLE = 'features';

  async findAll(): Promise<Feature[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data ?? [];
  }

  async findById(id: string): Promise<Feature | null> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  async create(dto: CreateFeatureDto): Promise<Feature> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .insert(dto)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async update(id: string, dto: UpdateFeatureDto): Promise<Feature> {
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
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (error) throw error;
  }
}
```

---

## 常見問題

### Q: 如何選擇 Shell vs UI 元件？

| 特徵 | Shell (Smart) | UI (Presentational) |
|------|---------------|---------------------|
| 注入 Store | ✅ | ❌ |
| 業務邏輯 | ✅ | ❌ |
| input/output | 較少 | 大量使用 |
| 狀態管理 | 管理狀態 | 無狀態 |
| 複用性 | 低 | 高 |

### Q: 如何選擇元件庫？

```
優先級：NG-ZORRO > @delon/abc > 自行開發
```

| 需求 | 推薦元件 | 來源 |
|------|----------|------|
| 數據表格 | `st` | `@delon/abc` |
| JSON 表單 | `sf` | `@delon/form` |
| 詳情展示 | `sv` | `@delon/abc` |
| 頁面標頭 | `page-header` | `@delon/abc` |
| 基礎 UI | `nz-*` | `ng-zorro-antd` |

### Q: 如何處理錯誤？

```typescript
// Store 中統一處理
async loadItems(): Promise<void> {
  this._state.update(s => ({ ...s, loading: true, error: null }));
  try {
    const items = await this.repository.findAll();
    this._state.update(s => ({ ...s, items, loading: false }));
  } catch (error) {
    this._state.update(s => ({
      ...s,
      loading: false,
      error: error instanceof Error ? error.message : '未知錯誤',
    }));
    console.error('[FeatureStore] loadItems error:', error);
  }
}
```

---

## 下一步

- 查看 [架構決策樹](./architecture-decision-tree.md) 了解如何選擇架構位置
- 查看 [開發前檢查清單](./checklists/pre-development.md) 確保準備就緒
- 查看 [程式碼範本](./module-templates/) 獲取可直接使用的範本

---

**最後更新**: 2025-11-27
