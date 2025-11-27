# 06-diary-module.setc.md

## 1. 模組概述

### 業務價值
施工日誌系統是工地施工記錄的核心模組，用於記錄每日施工狀況：
- **施工記錄**：每日工作內容、工時、人數的完整記錄
- **天氣追蹤**：記錄施工當日天氣狀況，作為進度影響因素
- **照片存證**：現場施工照片的系統化管理
- **審核流程**：確保施工記錄的準確性與完整性

### 核心功能
1. **每日施工記錄**：每藍圖每日限一份日誌
2. **任務關聯**：記錄當日進行的任務及其工時
3. **照片上傳**：支援多張施工現場照片
4. **日誌審核**：工地主任審核機制
5. **日誌報表**：工時統計與週/月報表

### 在系統中的定位
日誌模組作為業務層的重要模組，記錄每日施工快照，與任務系統透過 `diary_tasks` 多對多關聯。

---

## 2. 功能需求

### 使用者故事列表

#### DIARY-001: 建立施工日誌
**作為** 施工人員
**我想要** 建立每日施工日誌
**以便於** 記錄當日施工情況

**驗收標準**：
- [ ] 每藍圖每日只能有一份日誌
- [ ] 可輸入工作摘要
- [ ] 可記錄施工工時與人數
- [ ] 可選擇天氣狀況
- [ ] 日誌可儲存為草稿

#### DIARY-002: 關聯任務記錄工時
**作為** 施工人員
**我想要** 關聯當日施工的任務
**以便於** 記錄各任務的工時投入

**驗收標準**：
- [ ] 可選擇 in_progress 狀態的任務關聯
- [ ] 可為每個任務記錄工時
- [ ] 可為每個任務添加工作備註
- [ ] 同一日誌不可重複關聯同一任務

#### DIARY-003: 日誌照片上傳
**作為** 施工人員
**我想要** 上傳施工現場照片
**以便於** 保留施工過程記錄

**驗收標準**：
- [ ] 支援多張照片上傳
- [ ] 支援相機直接拍攝
- [ ] 照片自動記錄 GPS 與時間戳
- [ ] 可為照片添加說明
- [ ] 支援離線上傳（恢復連線後同步）

#### DIARY-004: 日誌審核
**作為** 工地主任
**我想要** 審核施工日誌
**以便於** 確保日誌內容準確

**驗收標準**：
- [ ] 可查看待審核日誌列表
- [ ] 可審核通過或退回
- [ ] 退回時需填寫原因
- [ ] 審核通過後日誌鎖定不可修改
- [ ] 支援批次審核

#### DIARY-005: 日誌報表生成
**作為** 專案經理
**我想要** 查看日誌統計報表
**以便於** 分析施工進度與資源投入

**驗收標準**：
- [ ] 可按日期範圍查詢
- [ ] 顯示工時統計與人數統計
- [ ] 顯示天氣分布統計
- [ ] 可匯出 PDF/Excel
- [ ] 可生成週報/月報

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 日誌 CRUD | 藍圖系統 |
| P0 | 任務關聯 | 日誌 CRUD、任務系統 |
| P1 | 照片上傳 | 日誌 CRUD、檔案系統 |
| P1 | 日誌審核 | 日誌 CRUD |
| P2 | 日誌報表 | 日誌 CRUD |

---

## 3. 技術設計

### 資料模型

**diaries（施工日誌主表）**:
```sql
CREATE TABLE diaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  work_summary TEXT,
  work_hours DECIMAL(5,2) DEFAULT 0,
  worker_count INTEGER DEFAULT 0,
  weather TEXT CHECK (weather IN (
    'sunny', 'cloudy', 'rainy', 'stormy', 'snowy', 'foggy'
  )),
  status TEXT DEFAULT 'draft' CHECK (status IN (
    'draft', 'submitted', 'approved', 'rejected'
  )),
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES accounts(id),
  rejection_reason TEXT,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (blueprint_id, work_date)
);

CREATE INDEX idx_diaries_blueprint_id ON diaries(blueprint_id);
CREATE INDEX idx_diaries_work_date ON diaries(work_date);
CREATE INDEX idx_diaries_status ON diaries(status);
CREATE INDEX idx_diaries_created_by ON diaries(created_by);
```

**diary_tasks（日誌任務關聯表）**:
```sql
CREATE TABLE diary_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID NOT NULL REFERENCES diaries(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  work_hours DECIMAL(5,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (diary_id, task_id)
);

CREATE INDEX idx_diary_tasks_diary_id ON diary_tasks(diary_id);
CREATE INDEX idx_diary_tasks_task_id ON diary_tasks(task_id);
```

**diary_attachments（日誌附件表）**:
```sql
CREATE TABLE diary_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID NOT NULL REFERENCES diaries(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES files(id),
  caption TEXT,
  gps_latitude DECIMAL(10,8),
  gps_longitude DECIMAL(11,8),
  taken_at TIMESTAMPTZ,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_diary_attachments_diary_id ON diary_attachments(diary_id);
```

### API 設計

**日誌 API**:
```typescript
// 取得日誌列表
GET /api/blueprints/{blueprint_id}/diaries
Query: { startDate?: string, endDate?: string, status?: string }
Response: { data: Diary[], total: number }

// 取得單一日誌
GET /api/diaries/{diary_id}
Response: { data: Diary }

// 建立日誌
POST /api/blueprints/{blueprint_id}/diaries
Body: { work_date: string, work_summary?: string, weather?: string }
Response: { data: Diary }

// 更新日誌
PATCH /api/diaries/{diary_id}
Body: Partial<Diary>
Response: { data: Diary }

// 提交日誌審核
POST /api/diaries/{diary_id}/submit
Response: { data: Diary }

// 審核日誌
POST /api/diaries/{diary_id}/approve
Body: { approved: boolean, rejection_reason?: string }
Response: { data: Diary }
```

### 前端元件結構

```
src/app/features/diary/
├── diary.routes.ts
├── shell/
│   └── diary-shell/
│       └── diary-shell.component.ts
├── data-access/
│   ├── stores/
│   │   └── diary.store.ts
│   ├── services/
│   │   └── diary.service.ts
│   └── repositories/
│       └── diary.repository.ts
├── domain/
│   ├── interfaces/
│   │   └── diary.interface.ts
│   └── enums/
│       ├── diary-status.enum.ts
│       └── weather.enum.ts
└── ui/
    ├── diary-list/
    │   └── diary-list.component.ts
    ├── diary-form/
    │   └── diary-form.component.ts
    ├── diary-detail/
    │   └── diary-detail.component.ts
    ├── diary-review/
    │   └── diary-review.component.ts
    └── diary-report/
        └── diary-report.component.ts
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class DiaryStore {
  private readonly repository = inject(DiaryRepository);

  // Private state
  private readonly _diaries = signal<Diary[]>([]);
  private readonly _selectedDiary = signal<Diary | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly diaries = this._diaries.asReadonly();
  readonly selectedDiary = this._selectedDiary.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed properties
  readonly pendingReviewDiaries = computed(() =>
    this._diaries().filter(d => d.status === 'submitted')
  );

  readonly approvedDiaries = computed(() =>
    this._diaries().filter(d => d.status === 'approved')
  );

  readonly diaryCount = computed(() => this._diaries().length);

  // Methods
  async loadDiaries(blueprintId: string, dateRange?: DateRange): Promise<void>;
  async createDiary(blueprintId: string, data: CreateDiaryDto): Promise<Diary>;
  async updateDiary(diaryId: string, data: UpdateDiaryDto): Promise<Diary>;
  async submitDiary(diaryId: string): Promise<Diary>;
  async approveDiary(diaryId: string, approved: boolean, reason?: string): Promise<Diary>;
  async deleteDiary(diaryId: string): Promise<void>;
}
```

---

## 4. 安全與權限

### RLS 政策

```sql
ALTER TABLE diaries ENABLE ROW LEVEL SECURITY;

-- SELECT: 藍圖成員可查看
CREATE POLICY "blueprint_members_can_view_diaries" ON diaries FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- INSERT: member 以上可建立
CREATE POLICY "blueprint_members_can_create_diaries" ON diaries FOR INSERT
WITH CHECK (
  is_blueprint_member(blueprint_id) AND
  get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin', 'member')
);

-- UPDATE: 本人或 admin 可修改未審核日誌
CREATE POLICY "diary_creators_can_update" ON diaries FOR UPDATE
USING (
  (created_by = get_user_account_id() AND status IN ('draft', 'rejected'))
  OR get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin')
);

-- DELETE: admin 以上可刪除
CREATE POLICY "blueprint_admins_can_delete_diaries" ON diaries FOR DELETE
USING (get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin'));
```

### 權限檢查點

| 操作 | 所需權限 | 額外條件 |
|------|----------|----------|
| 查看日誌 | 藍圖成員 | - |
| 建立日誌 | member 以上 | - |
| 修改日誌 | 本人或 admin | 狀態為 draft 或 rejected |
| 提交審核 | 本人 | 狀態為 draft |
| 審核日誌 | admin 以上 | 狀態為 submitted |
| 刪除日誌 | admin 以上 | - |

### 資料隔離策略
- 日誌資料按 `blueprint_id` 隔離
- 日誌附件繼承日誌的藍圖隔離
- 審核通過後日誌進入只讀狀態

---

## 5. 測試規範

### 單元測試清單

**DiaryStore 測試**:
```typescript
describe('DiaryStore', () => {
  it('loadDiaries_whenBlueprintIdValid_shouldReturnDiaries');
  it('createDiary_whenDataValid_shouldCreateDiary');
  it('createDiary_whenDuplicateDate_shouldThrowError');
  it('updateDiary_whenStatusDraft_shouldUpdateDiary');
  it('updateDiary_whenStatusApproved_shouldThrowError');
  it('submitDiary_whenStatusDraft_shouldChangeToSubmitted');
  it('approveDiary_whenAdmin_shouldApprove');
  it('approveDiary_whenNotAdmin_shouldThrowError');
});
```

**DiaryRepository 測試**:
```typescript
describe('DiaryRepository', () => {
  it('findByBlueprint_shouldReturnDiaries');
  it('findByDateRange_shouldFilterCorrectly');
  it('create_shouldInsertDiary');
  it('update_shouldModifyDiary');
});
```

### 整合測試場景

1. **日誌建立流程**：建立日誌 → 關聯任務 → 上傳照片 → 提交審核
2. **審核流程**：提交審核 → 審核通過/退回 → 狀態更新
3. **報表生成**：日期範圍查詢 → 統計計算 → 匯出

### E2E 測試案例

```typescript
describe('Diary Module E2E', () => {
  it('should create diary and submit for review');
  it('should upload photos to diary');
  it('should approve diary as admin');
  it('should reject diary with reason');
  it('should generate monthly report');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 載入日誌列表 (30天) | < 200ms |
| 建立/更新日誌 | < 300ms |
| 照片上傳 (5MB) | < 3s |
| 生成月報表 | < 1s |

### 優化策略

1. **索引優化**：`blueprint_id + work_date` 複合索引
2. **分頁查詢**：大量日誌使用分頁載入
3. **照片壓縮**：上傳前前端壓縮，後端生成縮圖
4. **報表快取**：統計結果快取，定時更新

### 監控指標

- 日誌 API 回應時間
- 照片上傳成功率
- 日誌審核處理時間

---

## 7. 實作檢查清單

### 資料庫
- [ ] 建立 diaries 資料表
- [ ] 建立 diary_tasks 資料表
- [ ] 建立 diary_attachments 資料表
- [ ] 設定 RLS 政策

### 後端
- [ ] 實作 DiaryRepository
- [ ] 實作日誌 CRUD API
- [ ] 實作審核流程 API
- [ ] 實作報表 API

### 前端
- [ ] 實作 DiaryStore
- [ ] 實作 diary-list 元件
- [ ] 實作 diary-form 元件
- [ ] 實作 diary-detail 元件
- [ ] 實作 diary-review 元件
- [ ] 實作 diary-report 元件

### 測試
- [ ] DiaryStore 單元測試
- [ ] DiaryRepository 單元測試
- [ ] 整合測試
- [ ] E2E 測試

### 文件
- [ ] API 文件更新
- [ ] 使用者指南更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
