# ⏳ 載入狀態模式

> 處理非同步操作的 UI 狀態

---

## Store 狀態定義

### 基本載入狀態

```typescript
interface FeatureState {
  items: Feature[];
  loading: boolean;
  error: string | null;
}

const initialState: FeatureState = {
  items: [],
  loading: false,
  error: null,
};

@Injectable()
export class FeatureStore {
  private readonly _state = signal<FeatureState>(initialState);

  readonly items = computed(() => this._state().items);
  readonly loading = computed(() => this._state().loading);
  readonly error = computed(() => this._state().error);

  // 衍生狀態
  readonly isEmpty = computed(() => !this.loading() && this.items().length === 0);
  readonly hasData = computed(() => !this.loading() && this.items().length > 0);
}
```

### 細粒度載入狀態

```typescript
interface FeatureState {
  items: Feature[];
  loadingStates: {
    list: boolean;      // 列表載入
    detail: boolean;    // 詳情載入
    create: boolean;    // 建立中
    update: boolean;    // 更新中
    delete: boolean;    // 刪除中
  };
  error: string | null;
}

const initialState: FeatureState = {
  items: [],
  loadingStates: {
    list: false,
    detail: false,
    create: false,
    update: false,
    delete: false,
  },
  error: null,
};

@Injectable()
export class FeatureStore {
  private readonly _state = signal<FeatureState>(initialState);

  // 個別載入狀態
  readonly listLoading = computed(() => this._state().loadingStates.list);
  readonly detailLoading = computed(() => this._state().loadingStates.detail);
  readonly creating = computed(() => this._state().loadingStates.create);
  readonly updating = computed(() => this._state().loadingStates.update);
  readonly deleting = computed(() => this._state().loadingStates.delete);

  // 任何操作進行中
  readonly anyLoading = computed(() => {
    const states = this._state().loadingStates;
    return Object.values(states).some(Boolean);
  });

  private _setLoading(key: keyof FeatureState['loadingStates'], value: boolean): void {
    this._state.update(s => ({
      ...s,
      loadingStates: { ...s.loadingStates, [key]: value },
    }));
  }

  async loadItems(): Promise<void> {
    this._setLoading('list', true);
    try {
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items }));
    } finally {
      this._setLoading('list', false);
    }
  }
}
```

---

## UI 模式

### 全頁載入

```html
@if (store.loading()) {
  <div class="loading-container">
    <nz-spin nzSize="large" nzTip="載入中..." />
  </div>
} @else {
  <!-- 正常內容 -->
}
```

```less
.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}
```

### 區域載入

```html
<nz-card>
  <nz-spin [nzSpinning]="store.loading()" nzTip="載入中...">
    @if (store.isEmpty()) {
      <nz-empty nzNotFoundContent="暫無資料" />
    } @else {
      <nz-table [nzData]="store.items()" />
    }
  </nz-spin>
</nz-card>
```

### 骨架屏載入

```html
@if (store.loading()) {
  <nz-skeleton [nzActive]="true" [nzParagraph]="{ rows: 4 }" />
} @else {
  <!-- 正常內容 -->
}
```

### 列表項目載入

```html
<nz-list [nzLoading]="store.loading()">
  @for (item of store.items(); track item.id) {
    <nz-list-item>{{ item.name }}</nz-list-item>
  }
</nz-list>
```

### 按鈕載入狀態

```html
<button
  nz-button
  nzType="primary"
  [nzLoading]="store.creating()"
  [disabled]="store.anyLoading()"
  (click)="onCreate()"
>
  {{ store.creating() ? '建立中...' : '建立' }}
</button>
```

### 表格行操作載入

```html
<td>
  @if (deletingId() === item.id) {
    <nz-spin nzSize="small" />
  } @else {
    <button nz-button nzType="link" (click)="onDelete(item.id)">刪除</button>
  }
</td>
```

---

## 進階模式

### 樂觀更新

```typescript
async updateItem(id: string, dto: UpdateFeatureDto): Promise<void> {
  const originalItem = this.items().find(i => i.id === id);
  
  // 樂觀更新 UI
  this._state.update(s => ({
    ...s,
    items: s.items.map(i => i.id === id ? { ...i, ...dto } : i),
  }));

  try {
    await this.repository.update(id, dto);
  } catch (error) {
    // 回滾
    if (originalItem) {
      this._state.update(s => ({
        ...s,
        items: s.items.map(i => i.id === id ? originalItem : i),
      }));
    }
    throw error;
  }
}
```

### 載入更多 (無限滾動)

```typescript
interface FeatureState {
  items: Feature[];
  loading: boolean;
  loadingMore: boolean;
  hasMore: boolean;
  page: number;
}

@Injectable()
export class FeatureStore {
  readonly loadingMore = computed(() => this._state().loadingMore);
  readonly hasMore = computed(() => this._state().hasMore);

  async loadMore(): Promise<void> {
    if (this.loadingMore() || !this.hasMore()) return;

    this._state.update(s => ({ ...s, loadingMore: true }));
    try {
      const page = this._state().page + 1;
      const { data, hasMore } = await this.repository.findPaged({ page });
      this._state.update(s => ({
        ...s,
        items: [...s.items, ...data],
        page,
        hasMore,
        loadingMore: false,
      }));
    } catch (error) {
      this._state.update(s => ({ ...s, loadingMore: false }));
      throw error;
    }
  }
}
```

```html
<nz-list [nzDataSource]="store.items()">
  @for (item of store.items(); track item.id) {
    <nz-list-item>{{ item.name }}</nz-list-item>
  }
  @if (store.loadingMore()) {
    <nz-list-item>
      <nz-spin />
    </nz-list-item>
  }
</nz-list>

@if (store.hasMore() && !store.loadingMore()) {
  <button nz-button nzBlock (click)="store.loadMore()">載入更多</button>
}
```

---

## 狀態組合

### 完整狀態模式

```html
<nz-card>
  @if (store.loading()) {
    <!-- 載入中 -->
    <nz-spin nzTip="載入中...">
      <nz-skeleton [nzActive]="true" />
    </nz-spin>
  } @else if (store.error()) {
    <!-- 錯誤 -->
    <nz-result nzStatus="error" [nzTitle]="store.error()">
      <div nz-result-extra>
        <button nz-button nzType="primary" (click)="store.loadItems()">重試</button>
      </div>
    </nz-result>
  } @else if (store.isEmpty()) {
    <!-- 空資料 -->
    <nz-empty nzNotFoundContent="暫無資料">
      <button nz-button nzType="primary" (click)="onCreate()">
        新增第一筆資料
      </button>
    </nz-empty>
  } @else {
    <!-- 正常內容 -->
    <app-feature-list [items]="store.items()" />
  }
</nz-card>
```

---

**最後更新**: 2025-11-27
