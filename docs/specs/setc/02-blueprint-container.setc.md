# 02-blueprint-container.setc.md

## 1. 模組概述

### 業務價值
藍圖容器層是 GigHub 系統的資料隔離核心，提供：
- **工作空間隔離**：每個藍圖作為獨立工作區，資料完全隔離
- **Git-like 分支管理**：支援分支、合併請求等版本控制功能
- **靈活的成員管理**：藍圖級別的角色與權限控制
- **跨組織協作**：支援 Fork 功能，讓外部團隊協作

### 核心功能
1. **藍圖生命週期**：Draft → Active → Archived → Deleted
2. **藍圖成員管理**：Owner / Admin / Member / Viewer 四種角色
3. **藍圖分支**：Git-like 的分支管理機制
4. **合併請求**：分支合併與審核流程

### 在系統中的定位
藍圖容器層承上啟下，向上依賴基礎層的帳戶體系，向下為業務模組提供資料隔離與權限控制。

```
問：涉及藍圖、工作區、分支、權限嗎？
├── 是 → 在容器層處理
└── 否 → 在業務層處理
```

---

## 2. 功能需求

### 核心概念定義

| 概念 | 說明 |
|------|------|
| 藍圖 (Blueprint) | 邏輯容器，提供資料隔離的工作空間 |
| 工作區 (Workspace) | **藍圖即工作區**（奧卡姆剃刀決策） |
| 藍圖分支 (Branch) | Git-like 的分支管理 |
| 合併請求 (Pull Request) | 分支合併請求 |
| Fork | 複製藍圖給協作組織 |
| 主分支 (Main Branch) | 原始藍圖的主線 |

### 使用者故事列表

#### GH-009: 建立藍圖
- **ID**: GH-009
- **優先級**: P0 (最高)
- **描述**: 作為用戶/組織管理員，我希望能夠建立藍圖。
- **驗收標準**:
  - [ ] 可選擇建立在個人/組織/團隊下
  - [ ] 可輸入藍圖名稱、描述
  - [ ] 可選擇藍圖範本（空白/預設結構）
  - [ ] 建立者自動成為藍圖擁有者
  - [ ] 藍圖建立後進入編輯模式

#### GH-010: 藍圖成員管理
- **ID**: GH-010
- **優先級**: P0 (最高)
- **描述**: 作為藍圖擁有者/管理員，我希望能夠管理成員。
- **驗收標準**:
  - [ ] 可邀請用戶加入藍圖
  - [ ] 可設定藍圖角色（owner/admin/member/viewer）
  - [ ] 可移除藍圖成員
  - [ ] 支援從組織/團隊批次加入
  - [ ] 成員權限變更即時生效

#### GH-011: 藍圖設定
- **ID**: GH-011
- **優先級**: P1
- **描述**: 作為藍圖擁有者，我希望能夠管理藍圖設定。
- **驗收標準**:
  - [ ] 可修改藍圖名稱、描述
  - [ ] 可設定藍圖狀態（draft/active/archived）
  - [ ] 可設定藍圖參數（時區、日期格式等）
  - [ ] 可設定預設角色權限
  - [ ] 可匯出藍圖資料

#### GH-012: 藍圖分支管理
- **ID**: GH-012
- **優先級**: P2
- **描述**: 作為藍圖管理員，我希望能夠使用分支功能。
- **驗收標準**:
  - [ ] 可從主分支建立分支
  - [ ] 分支隔離修改不影響主分支
  - [ ] 可提交合併請求 (Pull Request)
  - [ ] 合併前可預覽差異
  - [ ] 合併後分支可刪除或保留

### 藍圖生命週期

```
┌─────────┐    發布    ┌─────────┐    歸檔    ┌──────────┐
│  Draft  │ ─────────> │  Active │ ─────────> │ Archived │
└─────────┘            └─────────┘            └──────────┘
     │                      │                       │
     │                      │                       │
     └──────────────────────┴───────────────────────┘
                            │
                            ▼ 刪除
                     ┌──────────┐
                     │ Deleted  │ (軟刪除)
                     └──────────┘
```

### 藍圖角色體系

| 角色 | 系統角色 | 業務角色 | 權限說明 |
|------|----------|----------|----------|
| 擁有者 | owner | 專案經理 | 完整控制權，可刪除藍圖 |
| 管理員 | admin | 工地主任 | 可管理成員、修改設定 |
| 成員 | member | 施工人員 | 可編輯內容 |
| 觀察者 | viewer | 品管/觀察者 | 僅可檢視 |

---

## 3. 技術設計

### 資料模型

#### blueprints 藍圖主表

```sql
CREATE TABLE blueprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES accounts(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  slug VARCHAR(100),
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'internal', 'public')),
  settings JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  cover_image_url TEXT,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (owner_id, slug)
);

CREATE INDEX idx_blueprints_owner_id ON blueprints(owner_id);
CREATE INDEX idx_blueprints_status ON blueprints(status);
CREATE INDEX idx_blueprints_slug ON blueprints(slug);
```

#### blueprint_members 藍圖成員表

```sql
CREATE TABLE blueprint_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  business_role TEXT,
  joined_at TIMESTAMPTZ DEFAULT now(),
  invited_by UUID REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (blueprint_id, account_id)
);

CREATE INDEX idx_blueprint_members_blueprint_id ON blueprint_members(blueprint_id);
CREATE INDEX idx_blueprint_members_account_id ON blueprint_members(account_id);
```

#### blueprint_branches 藍圖分支表

```sql
CREATE TABLE blueprint_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  source_branch_id UUID REFERENCES blueprint_branches(id),
  is_default BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'merged', 'closed')),
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (blueprint_id, name)
);
```

### API 設計

#### 藍圖 CRUD
```typescript
// 建立藍圖
POST /rest/v1/blueprints
Body: { owner_id, name, description, status }

// 取得藍圖列表
GET /rest/v1/blueprints?owner_id=eq.{id}

// 取得單一藍圖
GET /rest/v1/blueprints?id=eq.{id}

// 更新藍圖
PATCH /rest/v1/blueprints?id=eq.{id}
Body: { name, description, status }

// 刪除藍圖 (軟刪除)
PATCH /rest/v1/blueprints?id=eq.{id}
Body: { deleted_at: 'now()' }
```

#### 藍圖成員管理
```typescript
// 取得成員列表
GET /rest/v1/blueprint_members?blueprint_id=eq.{id}&select=*,accounts(*)

// 新增成員
POST /rest/v1/blueprint_members
Body: { blueprint_id, account_id, role }

// 更新成員角色
PATCH /rest/v1/blueprint_members?id=eq.{id}
Body: { role }

// 移除成員
DELETE /rest/v1/blueprint_members?id=eq.{id}
```

### 前端元件結構

```
src/app/features/blueprint/
├── blueprint.routes.ts              # 路由配置
├── shell/
│   └── blueprint-shell/
│       ├── blueprint-shell.component.ts    # 藍圖外殼元件
│       ├── blueprint-shell.component.html
│       └── blueprint-shell.component.less
├── domain/
│   ├── enums/
│   │   └── blueprint-status.enum.ts
│   ├── interfaces/
│   │   └── blueprint.interface.ts
│   └── models/
│       └── blueprint.model.ts
├── data-access/
│   ├── stores/
│   │   └── blueprint.store.ts       # 藍圖狀態管理
│   ├── services/
│   │   └── blueprint.service.ts
│   └── repositories/
│       └── blueprint.repository.ts   # Supabase 存取層
└── ui/
    ├── blueprint-list/
    ├── blueprint-settings/
    └── blueprint-members/
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class BlueprintStore {
  private readonly repository = inject(BlueprintRepository);

  // Private State
  private readonly _blueprints = signal<Blueprint[]>([]);
  private readonly _currentBlueprint = signal<Blueprint | null>(null);
  private readonly _members = signal<BlueprintMember[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public Readonly State
  readonly blueprints = this._blueprints.asReadonly();
  readonly currentBlueprint = this._currentBlueprint.asReadonly();
  readonly members = this._members.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed Properties
  readonly blueprintId = computed(() => this._currentBlueprint()?.id);
  readonly isOwner = computed(() => {
    const current = this._currentBlueprint();
    const userId = this.getUserAccountId();
    return current?.created_by === userId;
  });
  readonly userRole = computed(() => {
    const members = this._members();
    const userId = this.getUserAccountId();
    return members.find(m => m.account_id === userId)?.role;
  });
}
```

---

## 4. 安全與權限

### RLS 政策

#### blueprints 表
```sql
ALTER TABLE blueprints ENABLE ROW LEVEL SECURITY;

-- SELECT: 成員可查看
CREATE POLICY "blueprint_members_can_view" ON blueprints FOR SELECT
USING (is_blueprint_member(id) OR owner_id = get_user_account_id());

-- INSERT: 任何登入用戶可建立
CREATE POLICY "authenticated_users_can_create" ON blueprints FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: 只有 owner 和 admin 可修改
CREATE POLICY "blueprint_admins_can_update" ON blueprints FOR UPDATE
USING (get_user_role_in_blueprint(id) IN ('owner', 'admin'));

-- DELETE: 只有 owner 可刪除
CREATE POLICY "blueprint_owner_can_delete" ON blueprints FOR DELETE
USING (get_user_role_in_blueprint(id) = 'owner');
```

#### blueprint_members 表
```sql
ALTER TABLE blueprint_members ENABLE ROW LEVEL SECURITY;

-- SELECT: 藍圖成員可查看成員列表
CREATE POLICY "members_can_view_members" ON blueprint_members FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- INSERT: admin 以上可新增成員
CREATE POLICY "admins_can_add_members" ON blueprint_members FOR INSERT
WITH CHECK (
  get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin')
);

-- UPDATE: owner 可修改成員角色
CREATE POLICY "owner_can_update_roles" ON blueprint_members FOR UPDATE
USING (get_user_role_in_blueprint(blueprint_id) = 'owner');

-- DELETE: admin 以上可移除成員
CREATE POLICY "admins_can_remove_members" ON blueprint_members FOR DELETE
USING (get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin'));
```

### Helper Functions

```sql
-- 檢查是否為藍圖成員
CREATE OR REPLACE FUNCTION is_blueprint_member(p_blueprint_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blueprint_members
    WHERE blueprint_id = p_blueprint_id
    AND account_id = get_user_account_id()
  );
END;
$$;

-- 取得用戶在藍圖的角色
CREATE OR REPLACE FUNCTION get_user_role_in_blueprint(p_blueprint_id uuid)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_role TEXT;
BEGIN
  SELECT role INTO v_role
  FROM blueprint_members
  WHERE blueprint_id = p_blueprint_id
  AND account_id = get_user_account_id();
  
  RETURN COALESCE(v_role, 'none');
END;
$$;
```

### 權限檢查點
1. **藍圖存取**：進入藍圖前檢查成員資格
2. **角色驗證**：操作前檢查用戶角色
3. **資料隔離**：RLS 確保只能存取有權藍圖的資料

---

## 5. 測試規範

### 單元測試清單

#### BlueprintStore
- [ ] `loadBlueprints_whenUserHasBlueprints_shouldReturnList`
- [ ] `loadBlueprints_whenUserHasNoBlueprints_shouldReturnEmptyList`
- [ ] `createBlueprint_withValidData_shouldCreateAndSetAsCurrent`
- [ ] `updateBlueprint_asOwner_shouldUpdate`
- [ ] `updateBlueprint_asViewer_shouldThrowError`
- [ ] `deleteBlueprint_asOwner_shouldSoftDelete`

#### BlueprintRepository
- [ ] `findByOwner_shouldReturnOwnedBlueprints`
- [ ] `findById_whenExists_shouldReturnBlueprint`
- [ ] `findById_whenNotExists_shouldReturnNull`
- [ ] `create_withValidData_shouldInsertAndReturn`
- [ ] `update_whenAuthorized_shouldUpdateFields`

### 整合測試場景
- [ ] 藍圖建立後自動成為擁有者
- [ ] 邀請成員後可存取藍圖
- [ ] 角色變更後權限即時生效
- [ ] 移除成員後無法存取藍圖

### E2E 測試案例
```typescript
describe('藍圖管理', () => {
  it('should_createBlueprint_andBecomeOwner', async () => {
    // 建立藍圖
    // 驗證擁有者角色
    // 確認藍圖出現在列表
  });

  it('should_inviteMember_andGrantAccess', async () => {
    // 邀請新成員
    // 切換到該成員登入
    // 確認可存取藍圖
  });
});
```

---

## 6. 效能考量

### 效能目標
- 藍圖列表載入 < 200ms
- 成員列表載入 < 300ms
- 藍圖切換 < 100ms

### 優化策略
1. **藍圖列表快取**：首次載入後快取於 IndexedDB
2. **成員預載**：進入藍圖時預載成員資訊
3. **增量更新**：僅同步變更的資料

### 監控指標
- 藍圖存取頻率
- 成員操作頻率
- 平均藍圖大小（任務數量）

---

## 7. 實作檢查清單

### 資料表建立
- [ ] blueprints 表建立完成
- [ ] blueprint_members 表建立完成
- [ ] blueprint_roles 表建立完成
- [ ] blueprint_branches 表建立完成
- [ ] blueprint_pull_requests 表建立完成

### RLS 政策設定
- [ ] blueprints RLS 政策設定
- [ ] blueprint_members RLS 政策設定
- [ ] blueprint_branches RLS 政策設定

### Helper Functions
- [ ] `is_blueprint_member()` 實作
- [ ] `get_user_role_in_blueprint()` 實作

### Repository 實作
- [ ] BlueprintRepository 實作
- [ ] BlueprintMemberRepository 實作
- [ ] BlueprintBranchRepository 實作

### Store 實作
- [ ] BlueprintStore 實作
- [ ] BlueprintMemberStore 實作

### 元件開發
- [ ] blueprint-shell 元件
- [ ] blueprint-list 元件
- [ ] blueprint-settings 元件
- [ ] blueprint-members 元件
- [ ] blueprint-branches 元件

### 測試撰寫
- [ ] 單元測試完成
- [ ] 整合測試完成
- [ ] E2E 測試完成

### 文件更新
- [ ] API 文件更新
- [ ] 元件文件更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
