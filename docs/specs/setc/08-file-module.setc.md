# 08-file-module.setc.md

## 1. 模組概述

### 業務價值
檔案模組提供完整的文件管理功能：
- **文件管理**：工程圖檔、規格書、合約等文件管理
- **版本控制**：追蹤檔案變更歷史
- **分享機制**：團隊內部檔案分享
- **安全存取**：權限控制與存取記錄

### 核心功能
1. **檔案樹狀結構**：資料夾階層組織
2. **版本控制**：檔案變更追蹤
3. **分享與權限**：靈活的分享機制
4. **預覽功能**：常見檔案格式預覽
5. **搜尋功能**：檔名與內容搜尋

### 在系統中的定位
檔案模組是藍圖的文件管理中心，提供獨立於任務的文件組織功能。

---

## 2. 功能需求

### 使用者故事列表

#### FILE-001: 檔案上傳
**作為** 使用者
**我想要** 上傳文件到藍圖
**以便於** 集中管理工程文件

**驗收標準**：
- [ ] 支援多檔案上傳
- [ ] 支援拖曳上傳
- [ ] 顯示上傳進度
- [ ] 檔案大小限制提示
- [ ] 支援暫停/繼續上傳

#### FILE-002: 資料夾管理
**作為** 使用者
**我想要** 建立資料夾組織文件
**以便於** 分類管理檔案

**驗收標準**：
- [ ] 可建立多層資料夾
- [ ] 可重新命名資料夾
- [ ] 可移動檔案/資料夾
- [ ] 可刪除空資料夾
- [ ] 支援資料夾圖示自訂

#### FILE-003: 版本控制
**作為** 使用者
**我想要** 追蹤檔案版本
**以便於** 查看歷史變更

**驗收標準**：
- [ ] 上傳同名檔案自動建立新版本
- [ ] 可查看版本歷史
- [ ] 可下載歷史版本
- [ ] 可還原到指定版本
- [ ] 顯示版本差異（適用於文字檔）

#### FILE-004: 檔案預覽
**作為** 使用者
**我想要** 預覽檔案內容
**以便於** 快速確認檔案

**驗收標準**：
- [ ] 支援圖片預覽
- [ ] 支援 PDF 預覽
- [ ] 支援文字檔預覽
- [ ] 支援 Office 文件預覽（透過服務）
- [ ] 不支援的格式顯示下載按鈕

#### FILE-005: 檔案分享
**作為** 使用者
**我想要** 分享檔案給特定人員
**以便於** 協作檢視文件

**驗收標準**：
- [ ] 可產生分享連結
- [ ] 可設定連結過期時間
- [ ] 可設定存取密碼
- [ ] 可追蹤存取記錄
- [ ] 可取消分享

#### FILE-006: 檔案搜尋
**作為** 使用者
**我想要** 搜尋藍圖內的檔案
**以便於** 快速找到需要的文件

**驗收標準**：
- [ ] 支援檔名搜尋
- [ ] 支援檔案類型篩選
- [ ] 支援日期範圍篩選
- [ ] 支援上傳者篩選
- [ ] 搜尋結果可預覽

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 檔案上傳 | Storage 系統 |
| P0 | 資料夾管理 | 檔案上傳 |
| P1 | 檔案預覽 | 檔案上傳 |
| P1 | 版本控制 | 檔案上傳 |
| P2 | 檔案分享 | 檔案上傳 |
| P2 | 檔案搜尋 | 檔案上傳 |

---

## 3. 技術設計

### 資料模型

**files（檔案主表）**:
```sql
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  folder_id UUID REFERENCES files(id),
  name VARCHAR(500) NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN (
    'folder', 'image', 'document', 'spreadsheet', 'cad', 'video', 'audio', 'other'
  )),
  mime_type VARCHAR(255),
  size_bytes BIGINT,
  storage_path TEXT,
  thumbnail_path TEXT,
  version INTEGER DEFAULT 1,
  current_version_id UUID,
  description TEXT,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_files_blueprint_id ON files(blueprint_id);
CREATE INDEX idx_files_folder_id ON files(folder_id);
CREATE INDEX idx_files_name ON files(name);
CREATE INDEX idx_files_file_type ON files(file_type);
CREATE INDEX idx_files_created_by ON files(created_by);
```

**file_versions（檔案版本表）**:
```sql
CREATE TABLE file_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  storage_path TEXT NOT NULL,
  size_bytes BIGINT,
  change_notes TEXT,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (file_id, version)
);

CREATE INDEX idx_file_versions_file_id ON file_versions(file_id);
```

**file_shares（檔案分享表）**:
```sql
CREATE TABLE file_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  share_token TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  expires_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0,
  max_access_count INTEGER,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_file_shares_file_id ON file_shares(file_id);
CREATE INDEX idx_file_shares_share_token ON file_shares(share_token);
```

### Storage 路徑規劃

```
storage/blueprints/{blueprint_id}/files/
├── {folder_id}/                 # 資料夾結構
│   └── {file_id}/
│       ├── v1/                  # 版本目錄
│       │   └── original.pdf
│       ├── v2/
│       │   └── original.pdf
│       └── thumb.jpg            # 縮圖
```

### API 設計

**檔案 API**:
```typescript
// 取得檔案列表
GET /api/blueprints/{blueprint_id}/files
Query: { folder_id?: string, type?: string, search?: string }
Response: { data: File[], total: number }

// 建立資料夾
POST /api/blueprints/{blueprint_id}/folders
Body: { name: string, parent_id?: string }
Response: { data: File }

// 上傳檔案
POST /api/blueprints/{blueprint_id}/files
Content-Type: multipart/form-data
Body: { file: File, folder_id?: string, description?: string }
Response: { data: File }

// 更新檔案（上傳新版本）
PUT /api/files/{file_id}
Content-Type: multipart/form-data
Body: { file: File, change_notes?: string }
Response: { data: File }

// 取得檔案版本歷史
GET /api/files/{file_id}/versions
Response: { data: FileVersion[] }

// 建立分享連結
POST /api/files/{file_id}/share
Body: { password?: string, expires_at?: string, max_access?: number }
Response: { data: FileShare }

// 存取分享連結
GET /api/shared/{share_token}
Query: { password?: string }
Response: { data: File, download_url: string }
```

### 前端元件結構

```
src/app/features/file/
├── file.routes.ts
├── shell/
│   └── file-shell/
│       └── file-shell.component.ts
├── data-access/
│   ├── stores/
│   │   └── file.store.ts
│   ├── services/
│   │   ├── file.service.ts
│   │   └── file-upload.service.ts
│   └── repositories/
│       └── file.repository.ts
├── domain/
│   ├── interfaces/
│   │   └── file.interface.ts
│   └── enums/
│       └── file-type.enum.ts
└── ui/
    ├── file-browser/
    │   └── file-browser.component.ts
    ├── file-upload/
    │   └── file-upload.component.ts
    ├── file-preview/
    │   └── file-preview.component.ts
    ├── file-versions/
    │   └── file-versions.component.ts
    ├── file-share/
    │   └── file-share.component.ts
    └── file-search/
        └── file-search.component.ts
```

### 狀態管理

```typescript
@Injectable({ providedIn: 'root' })
export class FileStore {
  private readonly repository = inject(FileRepository);
  private readonly uploadService = inject(FileUploadService);

  // Private state
  private readonly _files = signal<FileItem[]>([]);
  private readonly _currentFolder = signal<FileItem | null>(null);
  private readonly _breadcrumbs = signal<FileItem[]>([]);
  private readonly _selectedFiles = signal<FileItem[]>([]);
  private readonly _uploadProgress = signal<Map<string, number>>(new Map());
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Public readonly state
  readonly files = this._files.asReadonly();
  readonly currentFolder = this._currentFolder.asReadonly();
  readonly breadcrumbs = this._breadcrumbs.asReadonly();
  readonly selectedFiles = this._selectedFiles.asReadonly();
  readonly uploadProgress = this._uploadProgress.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Computed properties
  readonly folders = computed(() =>
    this._files().filter(f => f.file_type === 'folder')
  );

  readonly documents = computed(() =>
    this._files().filter(f => f.file_type !== 'folder')
  );

  readonly totalSize = computed(() =>
    this._files().reduce((sum, f) => sum + (f.size_bytes || 0), 0)
  );

  // Methods
  async loadFiles(blueprintId: string, folderId?: string): Promise<void>;
  async createFolder(blueprintId: string, name: string, parentId?: string): Promise<FileItem>;
  async uploadFile(blueprintId: string, file: File, folderId?: string): Promise<FileItem>;
  async updateFile(fileId: string, file: File, changeNotes?: string): Promise<FileItem>;
  async moveFiles(fileIds: string[], targetFolderId: string): Promise<void>;
  async deleteFiles(fileIds: string[]): Promise<void>;
  async createShare(fileId: string, options: ShareOptions): Promise<FileShare>;
  selectFile(file: FileItem): void;
  clearSelection(): void;
}
```

---

## 4. 安全與權限

### RLS 政策

```sql
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- SELECT: 藍圖成員可查看
CREATE POLICY "blueprint_members_can_view_files" ON files FOR SELECT
USING (is_blueprint_member(blueprint_id));

-- INSERT: member 以上可上傳
CREATE POLICY "blueprint_members_can_upload_files" ON files FOR INSERT
WITH CHECK (
  is_blueprint_member(blueprint_id) AND
  get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin', 'member')
);

-- UPDATE: 本人或 admin 可修改
CREATE POLICY "file_owners_can_update" ON files FOR UPDATE
USING (
  created_by = get_user_account_id()
  OR get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin')
);

-- DELETE: admin 以上可刪除
CREATE POLICY "blueprint_admins_can_delete_files" ON files FOR DELETE
USING (get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin'));
```

### Storage RLS Policy

```sql
-- 藍圖成員可存取藍圖下的檔案
CREATE POLICY "blueprint_file_access"
ON storage.objects FOR ALL
USING (
  bucket_id = 'blueprints'
  AND is_blueprint_member(
    (storage.foldername(name))[1]::uuid
  )
);
```

### 權限檢查點

| 操作 | 所需權限 | 額外條件 |
|------|----------|----------|
| 查看檔案 | 藍圖成員 | - |
| 上傳檔案 | member 以上 | - |
| 建立資料夾 | member 以上 | - |
| 修改檔案 | 本人或 admin | - |
| 刪除檔案 | admin 以上 | - |
| 建立分享 | member 以上 | - |

### 資料隔離策略
- 檔案按 `blueprint_id` 隔離
- Storage 路徑包含 blueprint_id 確保物理隔離
- 分享連結透過獨立 token 驗證

---

## 5. 測試規範

### 單元測試清單

**FileStore 測試**:
```typescript
describe('FileStore', () => {
  it('loadFiles_whenBlueprintIdValid_shouldReturnFiles');
  it('loadFiles_withFolderId_shouldReturnFolderContents');
  it('createFolder_shouldCreateAndReturn');
  it('uploadFile_shouldUploadAndCreateRecord');
  it('updateFile_shouldCreateNewVersion');
  it('moveFiles_shouldUpdateFolderId');
  it('deleteFiles_shouldSoftDelete');
  it('createShare_shouldGenerateToken');
});
```

**FileUploadService 測試**:
```typescript
describe('FileUploadService', () => {
  it('upload_shouldReportProgress');
  it('upload_whenFileTooLarge_shouldReject');
  it('upload_whenInvalidType_shouldReject');
  it('generateThumbnail_forImage_shouldCreate');
});
```

### 整合測試場景

1. **上傳流程**：選擇檔案 → 上傳 → 顯示在列表
2. **版本控制**：上傳新版本 → 查看歷史 → 還原
3. **分享流程**：建立分享 → 存取連結 → 下載

### E2E 測試案例

```typescript
describe('File Module E2E', () => {
  it('should upload file via drag and drop');
  it('should create folder and organize files');
  it('should preview image file');
  it('should download file version');
  it('should share file with password');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 載入檔案列表 | < 200ms |
| 上傳 5MB 檔案 | < 5s |
| 生成縮圖 | < 2s |
| 檔案預覽載入 | < 3s |

### 優化策略

1. **分塊上傳**：大檔案分塊上傳
2. **縮圖快取**：預生成並快取縮圖
3. **延遲載入**：列表中的縮圖延遲載入
4. **CDN 分發**：靜態資源使用 CDN

### 檔案大小限制

| 檔案類型 | 最大大小 |
|----------|----------|
| 圖片 | 10 MB |
| 文件 | 50 MB |
| 工程圖 | 100 MB |

### 監控指標

- 上傳成功率
- 平均上傳速度
- Storage 使用量

---

## 7. 實作檢查清單

### 資料庫
- [ ] 建立 files 資料表
- [ ] 建立 file_versions 資料表
- [ ] 建立 file_shares 資料表
- [ ] 設定 RLS 政策
- [ ] 設定 Storage RLS

### 後端
- [ ] 實作 FileRepository
- [ ] 實作檔案上傳 API
- [ ] 實作資料夾管理 API
- [ ] 實作版本控制 API
- [ ] 實作分享 API
- [ ] 實作縮圖生成

### 前端
- [ ] 實作 FileStore
- [ ] 實作 FileUploadService
- [ ] 實作 file-browser 元件
- [ ] 實作 file-upload 元件
- [ ] 實作 file-preview 元件
- [ ] 實作 file-versions 元件
- [ ] 實作 file-share 元件
- [ ] 實作 file-search 元件

### 測試
- [ ] FileStore 單元測試
- [ ] FileUploadService 單元測試
- [ ] 整合測試
- [ ] E2E 測試

### 文件
- [ ] API 文件更新
- [ ] 使用者指南更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
