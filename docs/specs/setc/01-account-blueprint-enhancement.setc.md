# 第零階段：帳戶與藍圖強化

> **Phase 0: Account & Blueprint Enhancement**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P0 |
| **預計週數** | 1-2 週 |
| **總任務數** | 11 |
| **前置條件** | 現有帳戶體系 80%、藍圖系統 70% |
| **完成目標** | 帳戶體系與藍圖系統達到企業標準 |

---

## 階段目標

1. ✅ 完善 ACL 權限控制，支援 CRUD + 模組級權限
2. ✅ 強化路由守衛，確保未授權存取被阻擋
3. ✅ 藍圖模板管理完整 CRUD
4. ✅ 藍圖複製功能實作
5. ✅ 工作區切換與藍圖系統整合

---

## 任務清單

### P0-T01: ACL 權限矩陣設計

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | 無 |
| **負責角色** | 系統架構師 |

#### 描述
設計完整的 ACL 權限矩陣，定義角色、權限、資源之間的關係。此設計將作為後續所有權限控制的基礎。

#### 執行步驟
1. 分析 PRD 中所有功能模組的存取需求
2. 定義角色層級：Owner, Admin, Manager, Member, Viewer
3. 定義權限類型：Create, Read, Update, Delete, Export, Share
4. 定義資源範圍：Blueprint, Workspace, Task, Diary, File, Report
5. 建立權限矩陣文件
6. 團隊審查確認

#### 驗收標準
- [ ] 權限矩陣文件已建立並審查通過
- [ ] 涵蓋所有 PRD 定義的功能模組
- [ ] 角色與權限映射清晰無歧義
- [ ] 與 @delon/acl 整合方案已確認

#### 產出物
- `docs/specs/acl-permission-matrix.md`

---

### P0-T02: @delon/acl 權限整合

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 2 天 |
| **前置依賴** | P0-T01 |
| **負責角色** | 前端工程師 |

#### 描述
基於權限矩陣，實作 @delon/acl 的整合配置，包括權限服務、指令和守衛。

#### 執行步驟
1. 建立 `AclPermissionService` 擴展 `ACLService`
2. 實作 `loadPermissions(userId: string)` 從 Supabase 載入
3. 建立權限快取機制（使用 @delon/cache）
4. 擴展 `*aclIf` 指令支援細粒度控制
5. 撰寫單元測試
6. 更新相關文件

#### 驗收標準
- [ ] `AclPermissionService` 可載入用戶權限
- [ ] 權限快取正確運作
- [ ] `*aclIf` 指令支援角色和能力檢查
- [ ] 單元測試覆蓋率 ≥ 80%

#### 產出物
- `src/app/core/services/acl-permission.service.ts`
- `src/app/core/services/acl-permission.service.spec.ts`

---

### P0-T03: 路由守衛強化

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T02 |
| **負責角色** | 前端工程師 |

#### 描述
強化路由守衛，確保所有受保護路由正確驗證權限。

#### 執行步驟
1. 審查現有 `JWTGuard` 與 `ACLGuard` 配置
2. 建立 `WorkspaceGuard` 驗證工作區存取權
3. 更新路由定義，加入 `data: { guard: {...} }`
4. 實作未授權跳轉邏輯（403 頁面）
5. 撰寫 E2E 測試

#### 驗收標準
- [ ] 未登入用戶被導向登入頁
- [ ] 無權限用戶被導向 403 頁面
- [ ] 工作區切換時正確驗證權限
- [ ] E2E 測試涵蓋主要授權場景

#### 產出物
- `src/app/core/guards/workspace.guard.ts`
- `src/app/routes/exception/403.component.ts`
- `e2e/auth/permission.spec.ts`

---

### P0-T04: 藍圖模板資料模型

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | 無 |
| **負責角色** | 後端/資料庫 |

#### 描述
定義藍圖模板的資料模型，包括資料庫結構和前端類型。

#### 執行步驟
1. 設計 `blueprint_templates` 資料表結構
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 生成 TypeScript 類型定義
5. 建立前端模型和介面

#### 驗收標準
- [ ] `blueprint_templates` 資料表已建立
- [ ] RLS 政策正確隔離租戶資料
- [ ] TypeScript 類型與資料庫一致
- [ ] 前端模型包含必要的業務屬性

#### 產出物
- `supabase/migrations/xxx_create_blueprint_templates.sql`
- `src/app/features/blueprint/domain/types/template.types.ts`
- `src/app/features/blueprint/domain/models/template.models.ts`

---

### P0-T05: 藍圖模板 Repository

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T04 |
| **負責角色** | 前端工程師 |

#### 描述
實作藍圖模板的 Repository 層，封裝 Supabase 資料存取。

#### 執行步驟
1. 建立 `BlueprintTemplateRepository` 類別
2. 實作 CRUD 方法：findAll, findById, create, update, delete
3. 實作 findByOwner 和 findPublic 方法
4. 加入錯誤處理和類型轉換
5. 撰寫單元測試

#### 驗收標準
- [ ] Repository 實作完整 CRUD 操作
- [ ] 支援按擁有者和公開狀態查詢
- [ ] 錯誤處理符合專案標準
- [ ] 單元測試覆蓋率 ≥ 80%

#### 產出物
- `src/app/features/blueprint/data-access/repositories/template.repository.ts`
- `src/app/features/blueprint/data-access/repositories/template.repository.spec.ts`

---

### P0-T06: 藍圖模板 Service

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T05 |
| **負責角色** | 前端工程師 |

#### 描述
實作藍圖模板的 Service 層，處理業務邏輯和狀態管理。

#### 執行步驟
1. 建立 `BlueprintTemplateService` 類別
2. 使用 Angular Signals 管理狀態
3. 實作載入、建立、更新、刪除方法
4. 加入快取策略（@delon/cache）
5. 撰寫單元測試

#### 驗收標準
- [ ] Service 使用 Signals 管理狀態
- [ ] 支援快取以減少 API 呼叫
- [ ] 錯誤狀態正確傳播
- [ ] 單元測試覆蓋率 ≥ 80%

#### 產出物
- `src/app/features/blueprint/data-access/services/template.service.ts`
- `src/app/features/blueprint/data-access/services/template.service.spec.ts`

---

### P0-T07: 藍圖模板列表 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 2 天 |
| **前置依賴** | P0-T06 |
| **負責角色** | 前端工程師 |

#### 描述
建立藍圖模板列表 UI 元件，使用 @delon/abc ST 元件。

#### 執行步驟
1. 建立 `TemplateListComponent` 元件
2. 定義 ST 欄位配置
3. 實作新增、編輯、刪除按鈕
4. 加入搜尋和篩選功能
5. 實作分頁
6. 撰寫元件測試

#### 驗收標準
- [ ] 列表正確顯示模板資料
- [ ] 支援新增、編輯、刪除操作
- [ ] 搜尋和篩選功能正常
- [ ] 分頁正確運作
- [ ] 元件測試覆蓋主要互動

#### 產出物
- `src/app/features/blueprint/ui/template/template-list/template-list.component.ts`
- `src/app/features/blueprint/ui/template/template-list/template-list.component.html`
- `src/app/features/blueprint/ui/template/template-list/template-list.component.spec.ts`

---

### P0-T08: 藍圖模板表單 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T06 |
| **負責角色** | 前端工程師 |

#### 描述
建立藍圖模板表單 UI 元件，使用 @delon/form SF 元件。

#### 執行步驟
1. 建立 `TemplateFormComponent` 元件
2. 定義 SF Schema
3. 實作新增和編輯模式
4. 加入表單驗證
5. 撰寫元件測試

#### 驗收標準
- [ ] 表單支援新增和編輯模式
- [ ] 驗證規則正確執行
- [ ] 提交後正確儲存
- [ ] 元件測試覆蓋表單互動

#### 產出物
- `src/app/features/blueprint/ui/template/template-form/template-form.component.ts`
- `src/app/features/blueprint/ui/template/template-form/template-form.component.spec.ts`

---

### P0-T09: 藍圖複製功能

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T06 |
| **負責角色** | 前端工程師 |

#### 描述
實作藍圖複製功能，支援深複製藍圖及其相關資料。

#### 執行步驟
1. 在 `BlueprintService` 加入 `copyBlueprint` 方法
2. 實作深複製邏輯（含任務、設定等）
3. 更新 `BlueprintStore` 暴露複製方法
4. 在列表 UI 加入複製按鈕
5. 撰寫整合測試

#### 驗收標準
- [ ] 複製功能正確建立副本
- [ ] 所有子項目（任務等）正確複製
- [ ] 複製後名稱自動加上「副本」標記
- [ ] 整合測試驗證複製完整性

#### 產出物
- 更新 `src/app/features/blueprint/data-access/services/blueprint.service.ts`
- 更新 `src/app/features/blueprint/data-access/stores/blueprint.store.ts`

---

### P0-T10: 工作區切換整合藍圖

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 2 天 |
| **前置依賴** | P0-T03, P0-T09 |
| **負責角色** | 前端工程師 |

#### 描述
整合工作區切換與藍圖系統，確保切換時正確載入對應藍圖。

#### 執行步驟
1. 擴展 `WorkspaceContextFacade` 加入藍圖感知
2. 實作 `loadWorkspaceBlueprints` 方法
3. 在切換工作區時自動載入藍圖
4. 更新 UI 顯示當前工作區藍圖
5. 處理無藍圖的預設狀態
6. 撰寫 E2E 測試

#### 驗收標準
- [ ] 切換工作區時自動載入對應藍圖
- [ ] UI 正確顯示當前工作區藍圖
- [ ] 無藍圖時顯示適當提示
- [ ] E2E 測試驗證切換流程

#### 產出物
- 更新 `src/app/core/facades/account/workspace-context.facade.ts`
- `e2e/workspace/blueprint-integration.spec.ts`

---

### P0-T11: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P0 |
| **預估工時** | 1 天 |
| **前置依賴** | P0-T01 ~ P0-T10 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試，驗證所有 P0 功能正確整合。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 手動測試主要流程
4. 效能基準測試
5. 修復發現的問題
6. 更新測試報告

#### 驗收標準
- [ ] 所有單元測試通過
- [ ] 所有 E2E 測試通過
- [ ] 手動測試無重大問題
- [ ] 效能符合預期
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p0-test-report.md`

---

## 階段完成檢查清單

- [ ] P0-T01: ACL 權限矩陣設計
- [ ] P0-T02: @delon/acl 權限整合
- [ ] P0-T03: 路由守衛強化
- [ ] P0-T04: 藍圖模板資料模型
- [ ] P0-T05: 藍圖模板 Repository
- [ ] P0-T06: 藍圖模板 Service
- [ ] P0-T07: 藍圖模板列表 UI
- [ ] P0-T08: 藍圖模板表單 UI
- [ ] P0-T09: 藍圖複製功能
- [ ] P0-T10: 工作區切換整合藍圖
- [ ] P0-T11: 階段測試與整合驗證

---

## 下一階段

完成 P0 後，進入 [第一階段：任務系統生產級](./02-task-system-production.setc.md)
