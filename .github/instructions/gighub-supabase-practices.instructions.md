---
description: 'GigHub Supabase 開發實踐指南，涵蓋 Repository 模式、RLS 安全政策、資料庫操作規範'
applyTo: '**/*.ts, **/*.sql'
---

# GigHub Supabase 開發實踐

> Supabase 整合規範與安全最佳實踐

---

## 🏗️ Repository 模式

### 核心原則

- Supabase Client 只能在 Repository 層使用
- 元件和服務不可直接呼叫 Supabase API
- Repository 封裝所有資料存取邏輯

### Repository 模板

```typescript
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
    const { data } = await this.supabase.client
      .from('tasks')
      .select('*');
  }
}

// ✅ 正確：透過 Repository 封裝
@Component({ ... })
export class TaskComponent {
  private readonly repository = inject(TaskRepository);

  async loadTasks() {
    const tasks = await this.repository.findAll();
  }
}
```

---

## 🔐 RLS (Row Level Security)

### 核心原則

- 每張表必須有 RLS 政策
- 使用 Helper Functions 封裝權限檢查
- 避免在 RLS 中直接查詢受保護的表（防止遞迴）

### RLS 政策範本

```sql
-- ✅ 正確：使用 Helper Function
CREATE POLICY "users_can_view_own_tasks"
ON tasks FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- ✅ 正確：使用 SECURITY DEFINER 函數
CREATE OR REPLACE FUNCTION is_blueprint_member(p_blueprint_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = auth.uid()
  );
END;
$$;
```

```sql
-- ❌ 禁止：在 RLS 中直接查詢受保護的表（會導致無限遞迴）
CREATE POLICY "..." ON accounts
USING (id IN (SELECT account_id FROM organization_members WHERE ...));
```

### 必須啟用 RLS

```sql
-- ❌ 禁止：沒有 RLS 政策的表
CREATE TABLE tasks (...);

-- ✅ 正確：建表後必須啟用 RLS 並建立政策
CREATE TABLE tasks (...);
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "..." ON tasks USING (...);
```

---

## 💾 資料完整性

### 軟刪除

```sql
-- ❌ 禁止：硬刪除重要資料
DELETE FROM tasks WHERE id = :id;

-- ✅ 正確：軟刪除
UPDATE tasks SET deleted_at = now() WHERE id = :id;
```

### 外鍵約束

```sql
-- ❌ 禁止：沒有外鍵約束
CREATE TABLE task_attachments (
  task_id UUID  -- 沒有 REFERENCES
);

-- ✅ 正確：建立外鍵約束
CREATE TABLE task_attachments (
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE
);
```

---

## 🌐 Supabase 服務

### 核心服務

| 服務 | 說明 |
|------|------|
| PostgreSQL Database | 關聯式資料庫，支援 ACID |
| Row Level Security | 行級安全控制 |
| Supabase Storage | 物件儲存服務 |
| Realtime | WebSocket 即時訂閱 |
| Edge Functions | Deno Runtime 無伺服器函數 |

### Realtime 訂閱

```typescript
// ✅ 正確：在 ngOnDestroy 中取消訂閱
private channel: RealtimeChannel | null = null;

ngOnInit() {
  this.channel = this.supabase.client
    .channel('tasks')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'tasks' },
      payload => this.handleChange(payload))
    .subscribe();
}

ngOnDestroy() {
  this.channel?.unsubscribe();
}
```

```typescript
// ❌ 禁止：未取消訂閱
ngOnInit() {
  this.supabase.client.channel('tasks').subscribe();
}
```

---

## ❌ 錯誤處理

### 錯誤映射流程

```
Supabase Error → Domain Error → UI Error
```

### 錯誤處理範本

```typescript
async loadTasks(blueprintId: string): Promise<void> {
  this._loading.set(true);
  this._error.set(null);

  try {
    const tasks = await this.repository.findByBlueprint(blueprintId);
    this._tasks.set(tasks);
  } catch (error) {
    // 映射為使用者友善訊息
    this._error.set('載入任務失敗，請稍後再試');
    console.error('[TaskStore] loadTasks error:', error);
  } finally {
    this._loading.set(false);
  }
}
```

### RLS 被拒錯誤

特別處理 RLS 權限拒絕的錯誤情況：

```typescript
if (error.code === 'PGRST301') {
  this._error.set('您沒有權限存取此資源');
}
```

---

## 🔐 安全規範

### 環境管理

- 多環境設定（dev/staging/production）
- Build 時注入金鑰，不寫入程式碼
- `anon key` 不可放在程式碼中

### 敏感資料

- 密碼使用 Hash 存儲
- Token 不記錄到日誌
- 個人資料遵循 LGPD

### SQL 注入防護

```typescript
// ❌ 禁止：字串拼接 SQL
const query = `SELECT * FROM tasks WHERE name = '${userInput}'`;

// ✅ 正確：使用參數化查詢
const { data } = await this.supabase.client
  .from('tasks')
  .select('*')
  .eq('name', userInput);
```

---

## 📊 效能指標

| 指標 | 目標 |
|------|------|
| API P50 | < 200ms |
| API P95 | < 500ms |
| API P99 | < 1s |
| 資料庫查詢 P95 | < 100ms |

### 優化建議

- 使用索引優化查詢
- 使用 Materialized Views 提升查詢效能
- 實作快取策略（Stale-While-Revalidate）

---

## 📋 審查檢查清單

### 資料庫審查必檢項目

```
□ 新表有啟用 RLS
□ RLS 政策不會導致無限遞迴
□ 重要資料使用軟刪除
□ 外鍵約束正確設置
□ 敏感欄位有適當保護
□ 索引已建立（常用查詢欄位）
```

---

**最後更新**: 2025-11-27
