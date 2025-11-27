# 📦 Repository 範本

> Supabase 資料存取 Repository 範本

---

## 基本範本

```typescript
// features/{feature}/data-access/repositories/{feature}.repository.ts
import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@core';
import {
  {Feature},
  Create{Feature}Dto,
  Update{Feature}Dto,
} from '../../domain';

@Injectable({ providedIn: 'root' })
export class {Feature}Repository {
  private readonly supabase = inject(SupabaseService);
  private readonly TABLE = '{features}'; // 資料表名稱

  // ========== 查詢操作 ==========

  /**
   * 查詢所有項目
   */
  async findAll(): Promise<{Feature}[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data ?? [];
  }

  /**
   * 根據 ID 查詢單一項目
   */
  async findById(id: string): Promise<{Feature} | null> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single();

    if (error) {
      // PGRST116: 找不到資料
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  /**
   * 根據條件查詢
   */
  async findBy(conditions: Partial<{Feature}>): Promise<{Feature}[]> {
    let query = this.supabase.client
      .from(this.TABLE)
      .select('*')
      .is('deleted_at', null);

    // 動態添加條件
    Object.entries(conditions).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        query = query.eq(key, value);
      }
    });

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;
    return data ?? [];
  }

  // ========== 變更操作 ==========

  /**
   * 建立新項目
   */
  async create(dto: Create{Feature}Dto): Promise<{Feature}> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .insert(dto)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * 批次建立
   */
  async createMany(dtos: Create{Feature}Dto[]): Promise<{Feature}[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .insert(dtos)
      .select();

    if (error) throw error;
    return data ?? [];
  }

  /**
   * 更新項目
   */
  async update(id: string, dto: Update{Feature}Dto): Promise<{Feature}> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .update({
        ...dto,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * 軟刪除項目
   */
  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.client
      .from(this.TABLE)
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (error) throw error;
  }

  /**
   * 硬刪除項目 (謹慎使用)
   */
  async hardDelete(id: string): Promise<void> {
    const { error } = await this.supabase.client
      .from(this.TABLE)
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  // ========== 輔助方法 ==========

  /**
   * 檢查項目是否存在
   */
  async exists(id: string): Promise<boolean> {
    const { count, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*', { count: 'exact', head: true })
      .eq('id', id)
      .is('deleted_at', null);

    if (error) throw error;
    return (count ?? 0) > 0;
  }

  /**
   * 計算項目數量
   */
  async count(conditions?: Partial<{Feature}>): Promise<number> {
    let query = this.supabase.client
      .from(this.TABLE)
      .select('*', { count: 'exact', head: true })
      .is('deleted_at', null);

    if (conditions) {
      Object.entries(conditions).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          query = query.eq(key, value);
        }
      });
    }

    const { count, error } = await query;

    if (error) throw error;
    return count ?? 0;
  }
}
```

---

## 進階範本 - 含分頁與搜尋

```typescript
interface PagedResult<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

interface QueryOptions {
  page?: number;
  pageSize?: number;
  search?: string;
  orderBy?: string;
  orderDirection?: 'asc' | 'desc';
}

@Injectable({ providedIn: 'root' })
export class {Feature}Repository {
  // ... 基本方法 ...

  /**
   * 分頁查詢
   */
  async findPaged(options: QueryOptions = {}): Promise<PagedResult<{Feature}>> {
    const {
      page = 1,
      pageSize = 20,
      search,
      orderBy = 'created_at',
      orderDirection = 'desc',
    } = options;

    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = this.supabase.client
      .from(this.TABLE)
      .select('*', { count: 'exact' })
      .is('deleted_at', null);

    // 搜尋
    if (search) {
      query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
    }

    // 排序與分頁
    query = query
      .order(orderBy, { ascending: orderDirection === 'asc' })
      .range(from, to);

    const { data, count, error } = await query;

    if (error) throw error;

    const total = count ?? 0;

    return {
      data: data ?? [],
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  /**
   * 全文搜尋
   */
  async search(keyword: string): Promise<{Feature}[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .is('deleted_at', null)
      .or(`name.ilike.%${keyword}%,description.ilike.%${keyword}%`)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    return data ?? [];
  }
}
```

---

## 關聯查詢範本

```typescript
@Injectable({ providedIn: 'root' })
export class {Feature}Repository {
  // ... 基本方法 ...

  /**
   * 查詢並包含關聯資料
   */
  async findWithRelations(id: string): Promise<{Feature}WithRelations | null> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select(`
        *,
        creator:accounts!{features}_creator_id_fkey (
          id,
          display_name,
          avatar_url
        ),
        related_items:related_table!{features}_id_fkey (
          id,
          name
        )
      `)
      .eq('id', id)
      .is('deleted_at', null)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null;
      throw error;
    }
    return data;
  }

  /**
   * 根據父級 ID 查詢子項目
   */
  async findByParentId(parentId: string): Promise<{Feature}[]> {
    const { data, error } = await this.supabase.client
      .from(this.TABLE)
      .select('*')
      .eq('parent_id', parentId)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true });

    if (error) throw error;
    return data ?? [];
  }
}
```

---

## 使用範例

### 在 Store 中使用

```typescript
@Injectable()
export class {Feature}Store {
  private readonly repository = inject({Feature}Repository);

  async loadItems(): Promise<void> {
    this._state.update(s => ({ ...s, loading: true }));
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
}
```

### 直接在元件中使用 (不推薦)

```typescript
// ⚠️ 不推薦：應透過 Store 使用
@Component({ ... })
export class SomeComponent {
  private readonly repository = inject({Feature}Repository);

  async loadData(): Promise<void> {
    const items = await this.repository.findAll();
    // ...
  }
}
```

---

## 注意事項

1. **錯誤處理**: 所有 Supabase 操作都可能拋出錯誤，應在 Store 層統一處理
2. **軟刪除**: 預設使用軟刪除 (設定 `deleted_at`)，查詢時需過濾
3. **RLS**: 確保資料表有正確的 RLS 政策
4. **型別安全**: 使用 TypeScript 介面確保型別安全

---

**最後更新**: 2025-11-27
