# 03-container-infrastructure.setc.md

## 1. 模組概述

### 業務價值
容器層的 12 項基礎設施提供了藍圖運作所需的核心能力，確保：
- **上下文一致性**：自動注入 Blueprint/User/Permissions
- **權限統一管理**：RBAC 多層級權限體系
- **跨模組協作**：事件總線、搜尋引擎、通知中心
- **資料治理**：隔離、生命週期、配置管理

### 核心功能（12 項基礎設施）
1. **上下文注入**：自動注入 Blueprint/User/Permissions
2. **權限系統**：RBAC 多層級權限
3. **時間軸服務**：跨模組活動追蹤
4. **通知中心**：多渠道通知路由
5. **事件總線**：模組間解耦通訊
6. **搜尋引擎**：跨模組全文檢索
7. **關聯管理**：跨模組資源引用
8. **資料隔離**：RLS 多租戶隔離
9. **生命週期**：Draft/Active/Archived/Deleted
10. **配置中心**：藍圖級配置管理
11. **元數據系統**：自訂欄位支援
12. **API 閘道**：對外 API 統一入口

### 在系統中的定位
這 12 項基礎設施是容器層的技術支撐，為業務模組提供統一的基礎能力。

---

## 2. 功能需求

### 2.1 上下文注入 (Context Injection)

**使用者故事**：作為開發者，我希望業務模組能夠自動取得當前藍圖和用戶資訊。

**驗收標準**：
- [ ] 進入藍圖後自動注入 blueprintId
- [ ] 自動注入當前用戶資訊
- [ ] 自動注入用戶權限列表
- [ ] 上下文變更時自動通知訂閱者

### 2.2 權限系統 (Permission System)

**使用者故事**：作為藍圖管理員，我希望能夠精細控制成員的操作權限。

**驗收標準**：
- [ ] 支援 RBAC 角色權限模型
- [ ] 支援自訂角色定義
- [ ] 權限可繼承（組織 → 藍圖 → 模組）
- [ ] 權限變更即時生效

### 2.3 時間軸服務 (Timeline Service)

**使用者故事**：作為用戶，我希望能夠查看藍圖內所有活動的時間軸。

**驗收標準**：
- [ ] 記錄所有重要操作（建立、更新、刪除）
- [ ] 支援按時間範圍查詢
- [ ] 支援按操作類型篩選
- [ ] 支援按操作者篩選

### 2.4 通知中心 (Notification Center)

**使用者故事**：作為用戶，我希望能夠接收系統通知。

**驗收標準**：
- [ ] 支援站內通知
- [ ] 支援 Email 通知
- [ ] 支援推播通知（未來）
- [ ] 可設定通知偏好

### 2.5 事件總線 (Event Bus)

**使用者故事**：作為開發者，我希望模組間能夠解耦通訊。

**驗收標準**：
- [ ] 支援發布/訂閱模式
- [ ] 事件可追蹤與記錄
- [ ] 支援同步與異步事件
- [ ] 事件失敗可重試

### 2.6 搜尋引擎 (Search Engine)

**使用者故事**：作為用戶，我希望能夠在藍圖內搜尋內容。

**驗收標準**：
- [ ] 支援全文檢索
- [ ] 支援按類型篩選（任務/日誌/檔案）
- [ ] 搜尋結果權限過濾
- [ ] 支援搜尋建議

### 2.7 關聯管理 (Reference Manager)

**使用者故事**：作為用戶，我希望能夠在各模組間建立關聯。

**驗收標準**：
- [ ] 支援 @提及
- [ ] 支援跨模組連結
- [ ] 關聯自動雙向同步
- [ ] 關聯刪除時清理

### 2.8 資料隔離 (Data Isolation)

**使用者故事**：作為藍圖擁有者，我希望藍圖資料與其他藍圖完全隔離。

**驗收標準**：
- [ ] 每張表都有 blueprint_id 欄位
- [ ] RLS 政策確保資料隔離
- [ ] 跨藍圖查詢不可能
- [ ] 刪除藍圖時級聯刪除所有資料

### 2.9 生命週期管理 (Lifecycle Management)

**使用者故事**：作為藍圖擁有者，我希望能夠管理藍圖的生命週期狀態。

**驗收標準**：
- [ ] 支援 Draft → Active → Archived → Deleted 流轉
- [ ] 狀態變更可逆（Archived 可還原）
- [ ] Deleted 為軟刪除，保留 30 天
- [ ] 狀態變更記錄審計

### 2.10 配置中心 (Configuration Center)

**使用者故事**：作為藍圖管理員，我希望能夠自訂藍圖設定。

**驗收標準**：
- [ ] 支援藍圖級設定
- [ ] 設定可繼承預設值
- [ ] 設定變更即時生效
- [ ] 設定匯入/匯出

### 2.11 元數據系統 (Metadata System)

**使用者故事**：作為藍圖管理員，我希望能夠為任務新增自訂欄位。

**驗收標準**：
- [ ] 支援多種欄位類型（文字/數字/日期/下拉）
- [ ] 自訂欄位可排序
- [ ] 自訂欄位可設定必填
- [ ] 自訂欄位可搜尋

### 2.12 API 閘道 (API Gateway)

**使用者故事**：作為第三方開發者，我希望能夠透過 API 存取藍圖資料。

**驗收標準**：
- [ ] RESTful API 設計
- [ ] API Key 認證
- [ ] 頻率限制
- [ ] API 文件自動生成

---

## 3. 技術設計

### 資料模型

#### activities 活動記錄表
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL REFERENCES accounts(id),
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  changes JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activities_blueprint_id ON activities(blueprint_id);
CREATE INDEX idx_activities_created_at ON activities(created_at DESC);
```

#### notifications 通知表
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  blueprint_id UUID REFERENCES blueprints(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_account_id ON notifications(account_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

#### blueprint_settings 藍圖設定表
```sql
CREATE TABLE blueprint_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (blueprint_id, key)
);
```

#### custom_fields 自訂欄位表
```sql
CREATE TABLE custom_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  name VARCHAR(100) NOT NULL,
  field_type TEXT NOT NULL,
  options JSONB DEFAULT '{}',
  is_required BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 前端元件結構

```
src/app/
├── core/
│   ├── facades/
│   │   └── blueprint/
│   │       └── blueprint-context.facade.ts  # 藍圖上下文 Facade
│   └── services/
│       ├── permission/
│       │   └── permission.service.ts         # 權限服務
│       ├── notification/
│       │   └── notification.service.ts       # 通知服務
│       ├── search/
│       │   └── search.service.ts             # 搜尋服務
│       └── activity/
│           └── activity.service.ts           # 活動追蹤服務
│
└── features/blueprint/
    └── ui/
        ├── timeline/                         # 時間軸元件
        ├── notification-center/              # 通知中心元件
        └── search-panel/                     # 搜尋面板元件
```

### 狀態管理

```typescript
// BlueprintContextFacade - 藍圖上下文管理
@Injectable({ providedIn: 'root' })
export class BlueprintContextFacade {
  // 當前藍圖 ID
  readonly blueprintId = signal<string | null>(null);
  
  // 當前用戶在藍圖的角色
  readonly userRole = signal<BlueprintRole | null>(null);
  
  // 用戶權限列表
  readonly permissions = signal<string[]>([]);
  
  // 計算屬性
  readonly canEdit = computed(() => {
    const role = this.userRole();
    return role === 'owner' || role === 'admin' || role === 'member';
  });
  
  readonly canManageMembers = computed(() => {
    const role = this.userRole();
    return role === 'owner' || role === 'admin';
  });
}
```

### 事件總線設計

```typescript
// 事件類型定義
interface DomainEvent {
  type: string;
  blueprintId: string;
  payload: unknown;
  metadata: {
    timestamp: Date;
    actorId: string;
    correlationId: string;
  };
}

// 事件發布
@Injectable({ providedIn: 'root' })
export class EventBus {
  private readonly events$ = new Subject<DomainEvent>();
  
  publish(event: DomainEvent): void {
    this.events$.next(event);
    this.persistEvent(event);
  }
  
  subscribe<T>(eventType: string): Observable<T> {
    return this.events$.pipe(
      filter(e => e.type === eventType),
      map(e => e.payload as T)
    );
  }
}
```

---

## 4. 安全與權限

### RLS 政策

#### activities 表
```sql
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members_can_view_activities" ON activities FOR SELECT
USING (is_blueprint_member(blueprint_id));

CREATE POLICY "system_can_insert_activities" ON activities FOR INSERT
WITH CHECK (is_blueprint_member(blueprint_id));
```

#### notifications 表
```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_can_view_own_notifications" ON notifications FOR SELECT
USING (account_id = get_user_account_id());

CREATE POLICY "users_can_update_own_notifications" ON notifications FOR UPDATE
USING (account_id = get_user_account_id());
```

### 權限檢查流程

```
請求 → 認證 (Auth) → 藍圖存取權 (Blueprint Access) → 角色權限 (Role Permission) → 操作執行
                            ↓ 無權                        ↓ 無權
                       返回 403                        返回 403
```

---

## 5. 測試規範

### 單元測試清單

#### BlueprintContextFacade
- [ ] `setContext_withValidBlueprintId_shouldUpdateState`
- [ ] `clearContext_shouldResetAllState`
- [ ] `canEdit_asOwner_shouldReturnTrue`
- [ ] `canEdit_asViewer_shouldReturnFalse`

#### EventBus
- [ ] `publish_shouldEmitEvent`
- [ ] `subscribe_shouldReceiveMatchingEvents`
- [ ] `subscribe_shouldNotReceiveUnmatchingEvents`

#### NotificationService
- [ ] `getNotifications_shouldReturnUserNotifications`
- [ ] `markAsRead_shouldUpdateIsRead`

### 整合測試場景
- [ ] 上下文切換後權限即時更新
- [ ] 事件發布後訂閱者收到通知
- [ ] 活動記錄正確寫入時間軸

---

## 6. 效能考量

### 效能目標
- 上下文切換 < 100ms
- 權限檢查 < 50ms
- 通知載入 < 200ms
- 搜尋回應 < 500ms

### 優化策略
1. **權限快取**：用戶權限於登入時載入並快取
2. **事件批次處理**：高頻事件採用批次寫入
3. **搜尋索引**：使用 PostgreSQL 全文檢索索引
4. **通知分頁**：通知列表分頁載入

### 監控指標
- 權限檢查頻率
- 事件發布頻率
- 通知未讀數量
- 搜尋查詢頻率

---

## 7. 實作檢查清單

### 資料表建立
- [ ] activities 表建立完成
- [ ] notifications 表建立完成
- [ ] blueprint_settings 表建立完成
- [ ] custom_fields 表建立完成
- [ ] custom_field_values 表建立完成

### RLS 政策設定
- [ ] activities RLS 政策設定
- [ ] notifications RLS 政策設定
- [ ] blueprint_settings RLS 政策設定
- [ ] custom_fields RLS 政策設定

### Services 實作
- [ ] BlueprintContextFacade 實作
- [ ] PermissionService 實作
- [ ] ActivityService 實作
- [ ] NotificationService 實作
- [ ] EventBus 實作
- [ ] SearchService 實作

### 元件開發
- [ ] timeline 元件
- [ ] notification-center 元件
- [ ] search-panel 元件

### 測試撰寫
- [ ] 單元測試完成
- [ ] 整合測試完成

### 文件更新
- [ ] API 文件更新
- [ ] 元件文件更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
