# 11-module-integration.setc.md

## 1. 模組概述

### 業務價值
模組整合定義各業務模組間的協作機制：
- **資料流管理**：模組間數據傳遞規範
- **事件協調**：跨模組事件傳遞機制
- **統一搜尋**：跨模組全文檢索
- **時間軸整合**：統一活動記錄

### 核心功能
1. **模組間資料流**：定義數據傳遞方式
2. **事件傳遞機制**：領域事件的發布與訂閱
3. **跨模組搜尋**：統一搜尋入口
4. **統一時間軸**：整合所有模組活動
5. **品質驗收整合**：任務驗收流程與日誌關聯
6. **問題追蹤整合**：缺陷與任務的關聯機制

### 在系統中的定位
模組整合作為業務層的協調機制，確保各模組間的無縫協作。

---

## 2. 功能需求

### 使用者故事列表

#### INT-001: 統一搜尋
**作為** 使用者
**我想要** 在全藍圖範圍內搜尋
**以便於** 快速找到相關資訊

**驗收標準**：
- [ ] 搜尋範圍涵蓋任務、日誌、檔案、連結
- [ ] 顯示搜尋結果來源模組
- [ ] 支援結果分類篩選
- [ ] 點擊可跳轉至對應項目

#### INT-002: 統一時間軸
**作為** 使用者
**我想要** 查看藍圖活動時間軸
**以便於** 追蹤專案動態

**驗收標準**：
- [ ] 整合所有模組的活動記錄
- [ ] 支援依模組篩選
- [ ] 支援依日期範圍篩選
- [ ] 顯示操作者與時間
- [ ] 支援無限捲動載入

#### INT-003: 跨模組關聯
**作為** 使用者
**我想要** 建立模組間的關聯
**以便於** 追蹤相關資訊

**驗收標準**：
- [ ] 任務可關聯日誌
- [ ] 任務可關聯檔案
- [ ] 日誌可關聯照片檔案
- [ ] 關聯項目可快速導航

#### INT-004: 品質驗收流程整合
**作為** 品管人員
**我想要** 在任務驗收時引用施工日誌
**以便於** 確保品質依據完整

**驗收標準**：
- [ ] 驗收時可查閱關聯日誌
- [ ] 驗收記錄保留日誌參考
- [ ] 驗收結果同步更新任務狀態
- [ ] 驗收歷史可追蹤

#### INT-005: 問題追蹤整合
**作為** 工地主任
**我想要** 從任務或驗收結果開立問題
**以便於** 追蹤缺陷處理進度

**驗收標準**：
- [ ] 可從任務開立問題（缺陷）
- [ ] 可從驗收不通過開立問題
- [ ] 問題解決後可觸發重新驗收
- [ ] 問題狀態與任務狀態連動

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P1 | 統一搜尋 | 所有業務模組 |
| P1 | 統一時間軸 | 所有業務模組 |
| P2 | 跨模組關聯 | 任務、日誌、檔案 |
| P1 | 品質驗收整合 | 任務、日誌 |
| P1 | 問題追蹤整合 | 任務、驗收 |

---

## 3. 技術設計

### 事件驅動架構

```typescript
// 領域事件基類
interface DomainEvent {
  event_type: string;
  blueprint_id: string;
  entity_type: string;
  entity_id: string;
  actor_id: string;
  payload: Record<string, unknown>;
  occurred_at: string;
}

// 事件類型
type EventType =
  | 'task.created' | 'task.updated' | 'task.deleted' | 'task.status_changed'
  | 'task.acceptance.submitted' | 'task.acceptance.approved' | 'task.acceptance.rejected'
  | 'diary.created' | 'diary.submitted' | 'diary.approved'
  | 'file.uploaded' | 'file.deleted' | 'file.shared'
  | 'link.created' | 'link.deleted'
  | 'issue.created' | 'issue.assigned' | 'issue.resolved' | 'issue.closed';
```

### 資料模型

**activities（活動記錄表）**:
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  entity_name VARCHAR(500),
  actor_id UUID NOT NULL REFERENCES accounts(id),
  changes JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activities_blueprint_id ON activities(blueprint_id);
CREATE INDEX idx_activities_event_type ON activities(event_type);
CREATE INDEX idx_activities_entity_type ON activities(entity_type);
CREATE INDEX idx_activities_actor_id ON activities(actor_id);
CREATE INDEX idx_activities_created_at ON activities(created_at DESC);
```

**entity_links（實體關聯表）**:
```sql
CREATE TABLE entity_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL,
  source_id UUID NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  link_type TEXT DEFAULT 'reference',
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (source_type, source_id, target_type, target_id)
);

CREATE INDEX idx_entity_links_source ON entity_links(source_type, source_id);
CREATE INDEX idx_entity_links_target ON entity_links(target_type, target_id);
```

### 搜尋設計

```typescript
// 統一搜尋 API
GET /api/blueprints/{blueprint_id}/search
Query: { 
  q: string, 
  types?: string[], 
  limit?: number, 
  offset?: number 
}
Response: {
  results: SearchResult[],
  total: number,
  facets: { type: string, count: number }[]
}

interface SearchResult {
  type: 'task' | 'diary' | 'file' | 'link' | 'issue';
  id: string;
  title: string;
  snippet: string;
  score: number;
  metadata: Record<string, unknown>;
}
```

### 前端元件結構

```
src/app/features/integration/
├── data-access/
│   ├── stores/
│   │   ├── search.store.ts
│   │   ├── activity.store.ts
│   │   └── entity-link.store.ts
│   └── services/
│       ├── search.service.ts
│       └── activity.service.ts
└── ui/
    ├── global-search/
    │   └── global-search.component.ts
    ├── activity-timeline/
    │   └── activity-timeline.component.ts
    └── entity-linker/
        └── entity-linker.component.ts
```

### 事件總線實作

```typescript
@Injectable({ providedIn: 'root' })
export class EventBusService {
  private readonly supabase = inject(SupabaseService);
  private eventSubject = new Subject<DomainEvent>();

  events$ = this.eventSubject.asObservable();

  // 發布事件
  async publish(event: Omit<DomainEvent, 'occurred_at'>): Promise<void> {
    const fullEvent: DomainEvent = {
      ...event,
      occurred_at: new Date().toISOString()
    };

    // 寫入活動記錄
    await this.supabase.client
      .from('activities')
      .insert({
        blueprint_id: event.blueprint_id,
        event_type: event.event_type,
        entity_type: event.entity_type,
        entity_id: event.entity_id,
        actor_id: event.actor_id,
        changes: event.payload
      });

    // 本地廣播
    this.eventSubject.next(fullEvent);
  }

  // 訂閱特定事件類型
  on(eventType: string): Observable<DomainEvent> {
    return this.events$.pipe(
      filter(event => event.event_type === eventType)
    );
  }

  // 訂閱特定實體的事件
  forEntity(entityType: string, entityId: string): Observable<DomainEvent> {
    return this.events$.pipe(
      filter(event => 
        event.entity_type === entityType && 
        event.entity_id === entityId
      )
    );
  }
}
```

---

## 4. 安全與權限

### RLS 政策

```sql
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blueprint_members_can_view_activities" ON activities FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- 活動記錄只能由系統寫入，不允許用戶直接操作
CREATE POLICY "system_only_insert_activities" ON activities FOR INSERT
WITH CHECK (false);

ALTER TABLE entity_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blueprint_members_can_view_links" ON entity_links FOR SELECT
USING (is_blueprint_member(blueprint_id));

CREATE POLICY "blueprint_members_can_create_links" ON entity_links FOR INSERT
WITH CHECK (is_blueprint_member(blueprint_id));
```

---

## 5. 測試規範

### 單元測試清單

```typescript
describe('EventBusService', () => {
  it('publish_shouldInsertActivity');
  it('publish_shouldBroadcastEvent');
  it('on_shouldFilterByEventType');
  it('forEntity_shouldFilterByEntityId');
});

describe('SearchStore', () => {
  it('search_shouldReturnMultiTypeResults');
  it('search_withTypeFilter_shouldFilterResults');
  it('search_shouldCalculateFacets');
});

describe('ActivityStore', () => {
  it('loadActivities_shouldReturnTimeline');
  it('loadActivities_withFilter_shouldFilterByType');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 統一搜尋 | < 300ms |
| 載入時間軸 (50條) | < 200ms |
| 事件發布 | < 100ms |

### 優化策略

1. **搜尋索引**：使用 PostgreSQL 全文搜尋或獨立搜尋引擎
2. **活動分頁**：時間軸使用游標分頁
3. **事件批次**：批量處理高頻事件
4. **快取策略**：搜尋結果短時快取

---

## 7. 實作檢查清單

- [ ] 建立 activities 資料表
- [ ] 建立 entity_links 資料表
- [ ] 設定 RLS 政策
- [ ] 實作 EventBusService
- [ ] 實作 SearchService
- [ ] 實作 ActivityService
- [ ] 實作 global-search 元件
- [ ] 實作 activity-timeline 元件
- [ ] 實作 entity-linker 元件
- [ ] 各業務模組整合事件發布
- [ ] 撰寫測試

---

**文件版本**: v1.1
**最後更新**: 2025-11-28
**維護者**: 專案架構師
