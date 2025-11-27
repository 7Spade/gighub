# 📦 Signal Store 範本

> Angular Signal Store 狀態管理範本

---

## 基本範本

```typescript
// features/{feature}/data-access/stores/{feature}.store.ts
import { Injectable, computed, inject, signal } from '@angular/core';
import { {Feature}Repository } from '../repositories/{feature}.repository';
import { {Feature} } from '../../domain/models/{feature}.model';

interface {Feature}State {
  items: {Feature}[];
  selectedId: string | null;
  loading: boolean;
  error: string | null;
}

const initialState: {Feature}State = {
  items: [],
  selectedId: null,
  loading: false,
  error: null,
};

@Injectable()
export class {Feature}Store {
  private readonly repository = inject({Feature}Repository);

  // 私有狀態
  private readonly _state = signal<{Feature}State>(initialState);

  // 公開只讀 Signals
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

  // ========== 查詢操作 ==========

  /**
   * 載入所有項目
   */
  async loadItems(): Promise<void> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items, loading: false }));
    } catch (error) {
      this._handleError(error, '載入資料失敗');
    }
  }

  /**
   * 載入單一項目
   */
  async loadItem(id: string): Promise<void> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const item = await this.repository.findById(id);
      if (item) {
        this._state.update(s => ({
          ...s,
          items: this._upsertItem(s.items, item),
          selectedId: id,
          loading: false,
        }));
      } else {
        this._handleError(new Error('項目不存在'), '項目不存在');
      }
    } catch (error) {
      this._handleError(error, '載入項目失敗');
    }
  }

  // ========== 變更操作 ==========

  /**
   * 建立新項目
   */
  async createItem(dto: Create{Feature}Dto): Promise<{Feature} | null> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const item = await this.repository.create(dto);
      this._state.update(s => ({
        ...s,
        items: [item, ...s.items],
        loading: false,
      }));
      return item;
    } catch (error) {
      this._handleError(error, '建立失敗');
      return null;
    }
  }

  /**
   * 更新項目
   */
  async updateItem(id: string, dto: Update{Feature}Dto): Promise<{Feature} | null> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const item = await this.repository.update(id, dto);
      this._state.update(s => ({
        ...s,
        items: this._upsertItem(s.items, item),
        loading: false,
      }));
      return item;
    } catch (error) {
      this._handleError(error, '更新失敗');
      return null;
    }
  }

  /**
   * 刪除項目
   */
  async deleteItem(id: string): Promise<boolean> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      await this.repository.delete(id);
      this._state.update(s => ({
        ...s,
        items: s.items.filter(item => item.id !== id),
        selectedId: s.selectedId === id ? null : s.selectedId,
        loading: false,
      }));
      return true;
    } catch (error) {
      this._handleError(error, '刪除失敗');
      return false;
    }
  }

  // ========== 狀態操作 ==========

  /**
   * 選擇項目
   */
  selectItem(id: string | null): void {
    this._state.update(s => ({ ...s, selectedId: id }));
  }

  /**
   * 清除錯誤
   */
  clearError(): void {
    this._state.update(s => ({ ...s, error: null }));
  }

  /**
   * 重置狀態
   */
  reset(): void {
    this._state.set(initialState);
  }

  // ========== 私有方法 ==========

  /**
   * 更新或插入項目到列表
   */
  private _upsertItem(items: {Feature}[], item: {Feature}): {Feature}[] {
    const index = items.findIndex(i => i.id === item.id);
    if (index >= 0) {
      return [...items.slice(0, index), item, ...items.slice(index + 1)];
    }
    return [item, ...items];
  }

  /**
   * 處理錯誤
   */
  private _handleError(error: unknown, defaultMessage: string): void {
    const message = error instanceof Error ? error.message : defaultMessage;
    this._state.update(s => ({
      ...s,
      loading: false,
      error: message,
    }));
    console.error(`[{Feature}Store] Error:`, error);
  }
}
```

---

## 進階範本 - 含篩選與分頁

```typescript
interface {Feature}State {
  items: {Feature}[];
  selectedId: string | null;
  loading: boolean;
  error: string | null;
  // 篩選
  filter: {Feature}Filter;
  // 分頁
  pagination: {
    page: number;
    pageSize: number;
    total: number;
  };
}

const initialState: {Feature}State = {
  items: [],
  selectedId: null,
  loading: false,
  error: null,
  filter: {},
  pagination: {
    page: 1,
    pageSize: 20,
    total: 0,
  },
};

@Injectable()
export class {Feature}Store {
  // ... 基本 Signals ...

  // 篩選 Signals
  readonly filter = computed(() => this._state().filter);
  readonly pagination = computed(() => this._state().pagination);
  readonly hasMore = computed(() => {
    const p = this.pagination();
    return p.page * p.pageSize < p.total;
  });

  // 篩選後的項目
  readonly filteredItems = computed(() => {
    const items = this.items();
    const filter = this.filter();
    
    return items.filter(item => {
      if (filter.status && item.status !== filter.status) return false;
      if (filter.search && !item.name.includes(filter.search)) return false;
      return true;
    });
  });

  /**
   * 更新篩選條件
   */
  setFilter(filter: Partial<{Feature}Filter>): void {
    this._state.update(s => ({
      ...s,
      filter: { ...s.filter, ...filter },
      pagination: { ...s.pagination, page: 1 },
    }));
    this.loadItems();
  }

  /**
   * 載入下一頁
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore() || this.loading()) return;

    const p = this.pagination();
    this._state.update(s => ({
      ...s,
      pagination: { ...s.pagination, page: p.page + 1 },
    }));
    
    // 載入更多項目並追加
    const newItems = await this.repository.findAll({
      page: p.page + 1,
      pageSize: p.pageSize,
    });
    
    this._state.update(s => ({
      ...s,
      items: [...s.items, ...newItems],
    }));
  }
}
```

---

## 使用範例

### 在 Shell 元件中使用

```typescript
@Component({
  selector: 'app-feature-shell',
  standalone: true,
  imports: [...SHARED_IMPORTS, {Feature}ListComponent],
  providers: [{Feature}Store],
  template: `
    @if (store.loading()) {
      <nz-spin nzTip="載入中..." />
    } @else if (store.error()) {
      <nz-alert [nzMessage]="store.error()" nzType="error" />
    } @else {
      <app-feature-list
        [items]="store.items()"
        [selectedId]="store.selectedId()"
        (select)="store.selectItem($event)"
        (delete)="onDelete($event)"
      />
    }
  `,
})
export class {Feature}ShellComponent implements OnInit {
  protected readonly store = inject({Feature}Store);

  ngOnInit(): void {
    this.store.loadItems();
  }

  async onDelete(id: string): Promise<void> {
    const success = await this.store.deleteItem(id);
    if (success) {
      // 顯示成功訊息
    }
  }
}
```

---

**最後更新**: 2025-11-27
