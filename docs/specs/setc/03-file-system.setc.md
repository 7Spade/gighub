# 第 1.5 階段：檔案系統

> **Phase 1.5: File System**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P1.5 |
| **預計週數** | 7-8 週（2 週） |
| **總任務數** | 12 |
| **前置條件** | P1 完成 |
| **完成目標** | 檔案管理系統完整實作，支援上傳、下載、版本控制 |

---

## 階段目標

1. ✅ 檔案上傳至 Supabase Storage
2. ✅ 支援資料夾結構與搜尋
3. ✅ 版本歷史可查看與回滾
4. ✅ 圖片縮圖預覽
5. ✅ RLS 正確隔離檔案存取

---

## 任務清單

### P15-T01: files 資料表設計

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P1 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
設計檔案元資料資料表結構。

#### 執行步驟
1. 設計 `files` 資料表結構
   - id, workspace_id, parent_folder_id, name, mime_type
   - storage_path, size, created_by, created_at, updated_at
2. 建立 Supabase Migration
3. 設定 RLS 政策（工作區成員可存取）
4. 建立索引優化查詢

#### 驗收標準
- [ ] `files` 資料表已建立
- [ ] 支援資料夾結構（parent_folder_id）
- [ ] RLS 政策正確
- [ ] 查詢效能良好

#### 產出物
- `supabase/migrations/xxx_create_files_table.sql`

---

### P15-T02: file_versions 資料表設計

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P15-T01 |
| **負責角色** | 後端/資料庫 |

#### 描述
設計檔案版本歷史資料表。

#### 執行步驟
1. 設計 `file_versions` 資料表
   - id, file_id, version_number, storage_path
   - size, checksum, created_by, created_at, comment
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 建立觸發器自動記錄版本

#### 驗收標準
- [ ] `file_versions` 資料表已建立
- [ ] 版本號自動遞增
- [ ] 觸發器正確運作
- [ ] RLS 政策正確

#### 產出物
- `supabase/migrations/xxx_create_file_versions_table.sql`

---

### P15-T03: TypeScript 類型定義

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 0.5 天 |
| **前置依賴** | P15-T02 |
| **負責角色** | 前端工程師 |

#### 描述
建立檔案系統相關的 TypeScript 類型定義。

#### 執行步驟
1. 定義 FileModel 介面
2. 定義 FileVersionModel 介面
3. 定義 FolderModel 介面
4. 定義相關 Request/Response 類型
5. 匯出至 domain/types

#### 驗收標準
- [ ] 類型定義完整
- [ ] 與資料庫結構一致
- [ ] 正確匯出

#### 產出物
- `src/app/features/blueprint/domain/types/file.types.ts`
- `src/app/features/blueprint/domain/models/file.models.ts`

---

### P15-T04: Storage Bucket 配置

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P15-T01 |
| **負責角色** | 後端/DevOps |

#### 描述
配置 Supabase Storage Bucket 和存取政策。

#### 執行步驟
1. 建立 `workspace-files` Bucket
2. 設定 Bucket 為私有
3. 配置存取政策（基於 RLS）
4. 設定檔案大小限制
5. 配置 MIME 類型限制
6. 測試上傳/下載權限

#### 驗收標準
- [ ] Bucket 已建立
- [ ] 存取政策正確
- [ ] 檔案大小限制生效
- [ ] MIME 類型限制生效

#### 產出物
- `supabase/config/storage.toml`（或透過 Dashboard 設定）

---

### P15-T05: FileRepository 實作

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P15-T03 |
| **負責角色** | 前端工程師 |

#### 描述
實作檔案 Repository 層。

#### 執行步驟
1. 建立 `FileRepository` 類別
2. 實作檔案元資料 CRUD
3. 實作資料夾 CRUD
4. 實作版本歷史查詢
5. 撰寫單元測試

#### 驗收標準
- [ ] Repository CRUD 完整
- [ ] 資料夾操作正確
- [ ] 版本查詢正確
- [ ] 測試覆蓋 ≥ 80%

#### 產出物
- `src/app/features/blueprint/data-access/repositories/file.repository.ts`
- `src/app/features/blueprint/data-access/repositories/file.repository.spec.ts`

---

### P15-T06: FileService 實作

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P15-T05, P15-T04 |
| **負責角色** | 前端工程師 |

#### 描述
實作檔案 Service 層，整合 Storage 和 Database。

#### 執行步驟
1. 建立 `FileService` 類別
2. 實作上傳檔案（Storage + Database）
3. 實作下載檔案
4. 實作刪除檔案
5. 實作版本管理
6. 使用 Signals 管理狀態
7. 撰寫單元測試

#### 驗收標準
- [ ] 上傳整合 Storage 和 Database
- [ ] 下載正確取得檔案
- [ ] 刪除同時清理 Storage
- [ ] 版本管理正確
- [ ] 測試覆蓋 ≥ 80%

#### 產出物
- `src/app/features/blueprint/data-access/services/file.service.ts`
- `src/app/features/blueprint/data-access/services/file.service.spec.ts`

---

### P15-T07: FileStore 實作

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 0.5 天 |
| **前置依賴** | P15-T06 |
| **負責角色** | 前端工程師 |

#### 描述
實作檔案 Store（Facade）層。

#### 執行步驟
1. 建立 `FileStore` 類別
2. 暴露 Service 狀態和方法
3. 加入便捷方法
4. 撰寫測試

#### 驗收標準
- [ ] Store 正確暴露狀態
- [ ] 方法符合 Facade 模式
- [ ] 測試完整

#### 產出物
- `src/app/features/blueprint/data-access/stores/file.store.ts`

---

### P15-T08: 檔案上傳元件

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 2 天 |
| **前置依賴** | P15-T07 |
| **負責角色** | 前端工程師 |

#### 描述
建立檔案上傳元件，支援拖放和進度顯示。

#### 執行步驟
1. 建立 `FileUploadComponent`
2. 整合 ng-zorro-antd Upload
3. 實作拖放上傳
4. 顯示上傳進度
5. 處理上傳錯誤
6. 支援多檔上傳
7. 撰寫測試

#### 驗收標準
- [ ] 拖放上傳功能正常
- [ ] 進度顯示正確
- [ ] 錯誤處理完善
- [ ] 支援多檔上傳
- [ ] 檔案類型/大小驗證

#### 產出物
- `src/app/features/blueprint/ui/file/file-upload/file-upload.component.ts`

---

### P15-T09: 檔案列表元件

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 2 天 |
| **前置依賴** | P15-T08 |
| **負責角色** | 前端工程師 |

#### 描述
建立檔案列表元件，支援表格和網格視圖。

#### 執行步驟
1. 建立 `FileListComponent`
2. 實作表格視圖（ST）
3. 實作網格視圖（縮圖）
4. 實作資料夾導航
5. 實作搜尋功能
6. 實作右鍵選單
7. 撰寫測試

#### 驗收標準
- [ ] 表格/網格視圖切換
- [ ] 資料夾導航正確
- [ ] 搜尋功能正常
- [ ] 右鍵選單完整

#### 產出物
- `src/app/features/blueprint/ui/file/file-list/file-list.component.ts`
- `src/app/features/blueprint/ui/file/file-grid/file-grid.component.ts`

---

### P15-T10: 檔案預覽元件

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P15-T09 |
| **負責角色** | 前端工程師 |

#### 描述
建立檔案預覽元件，支援常見檔案類型。

#### 執行步驟
1. 建立 `FilePreviewComponent`
2. 實作圖片預覽（縮圖 + 原圖）
3. 實作 PDF 預覽
4. 實作文件預覽（Office Viewer 整合）
5. 實作下載功能
6. 撰寫測試

#### 驗收標準
- [ ] 圖片預覽正常
- [ ] PDF 預覽正常
- [ ] Office 文件可預覽或下載
- [ ] 未知類型顯示下載選項

#### 產出物
- `src/app/features/blueprint/ui/file/file-preview/file-preview.component.ts`

---

### P15-T11: 版本歷史 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 1 天 |
| **前置依賴** | P15-T10 |
| **負責角色** | 前端工程師 |

#### 描述
建立版本歷史 UI，支援查看和回滾。

#### 執行步驟
1. 建立 `FileVersionHistoryComponent`
2. 顯示版本列表（時間軸）
3. 顯示版本差異（大小、上傳者）
4. 實作版本預覽
5. 實作版本回滾
6. 撰寫測試

#### 驗收標準
- [ ] 版本列表正確顯示
- [ ] 可預覽歷史版本
- [ ] 可回滾至指定版本
- [ ] 回滾有確認對話框

#### 產出物
- `src/app/features/blueprint/ui/file/file-version-history/file-version-history.component.ts`

---

### P15-T12: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P1.5 |
| **預估工時** | 2 天 |
| **前置依賴** | P15-T01 ~ P15-T11 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 測試大檔案上傳
4. 測試並發上傳
5. 測試版本回滾
6. 效能測試
7. 修復問題
8. 更新測試報告

#### 驗收標準
- [ ] 所有測試通過
- [ ] 大檔案上傳正常（100MB+）
- [ ] 版本回滾正確
- [ ] 效能符合預期
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p15-test-report.md`
- `e2e/file/file-management.spec.ts`

---

## 階段完成檢查清單

- [ ] P15-T01: files 資料表設計
- [ ] P15-T02: file_versions 資料表設計
- [ ] P15-T03: TypeScript 類型定義
- [ ] P15-T04: Storage Bucket 配置
- [ ] P15-T05: FileRepository 實作
- [ ] P15-T06: FileService 實作
- [ ] P15-T07: FileStore 實作
- [ ] P15-T08: 檔案上傳元件
- [ ] P15-T09: 檔案列表元件
- [ ] P15-T10: 檔案預覽元件
- [ ] P15-T11: 版本歷史 UI
- [ ] P15-T12: 階段測試與整合驗證

---

## 下一階段

完成 P1.5 後，進入 [第二階段：日誌系統](./04-diary-system.setc.md)
