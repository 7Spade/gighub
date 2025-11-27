# ✅ 開發後檢查清單

> **目標**: 確保程式碼品質，避免遺漏

---

## 📝 程式碼品質檢查

### 基本規範

- [ ] 所有檔案命名使用 kebab-case
- [ ] Component 行數 < 500 行
- [ ] Template 行數 < 300 行
- [ ] 無循環依賴

### Angular 規範

- [ ] 使用 Standalone Components
- [ ] 使用 `inject()` 函數
- [ ] 使用 `input()` / `output()` 函數
- [ ] 使用 `ChangeDetectionStrategy.OnPush`
- [ ] 使用新控制流語法 (`@if`, `@for`, `@switch`)

### TypeScript 規範

- [ ] 無 `any` 類型（除非有明確理由）
- [ ] 所有公開 API 有類型定義
- [ ] 使用嚴格模式

---

## 🏗️ 架構合規檢查

### 垂直切片架構

- [ ] 功能模組結構完整
  ```
  features/{feature}/
  ├── domain/           ✅
  ├── data-access/      ✅
  ├── shell/            ✅
  ├── ui/               ✅
  └── index.ts          ✅
  ```

### 依賴方向

- [ ] `features/` → `shared/` → `core/` ✅
- [ ] `features/` 之間無直接依賴 ✅
- [ ] 無 `layout/` 依賴 ✅
- [ ] 無 `routes/` 依賴 ✅

### 公開 API

- [ ] `index.ts` 只導出應公開的部分
- [ ] 內部實現不被導出

---

## 📊 狀態管理檢查

### Signal Store

- [ ] 私有狀態使用 `signal()`
- [ ] 公開狀態使用 `computed()`
- [ ] 狀態更新使用 `_state.update()`
- [ ] 錯誤處理完整

### Store 提供位置

- [ ] 全域 Store → `providedIn: 'root'`
- [ ] 功能 Store → Shell `providers`

---

## 🎨 UI 元件檢查

### Shell 元件

- [ ] 注入必要的 Store
- [ ] 在 `ngOnInit` 載入資料
- [ ] 處理 loading 和 error 狀態

### UI 元件

- [ ] 使用 `input()` 接收資料
- [ ] 使用 `output()` 發送事件
- [ ] 無業務邏輯
- [ ] 無 Store 注入

### 模板語法

- [ ] 使用 `@if` / `@else` / `@else if`
- [ ] 使用 `@for` + `track`
- [ ] 使用 `@switch` / `@case` / `@default`
- [ ] 使用 `@empty` 處理空列表

---

## 🔒 安全性檢查

### 前端安全

- [ ] 輸入驗證使用 Angular Forms
- [ ] 避免 `innerHTML`（使用 DomSanitizer）
- [ ] API 錯誤不暴露內部細節
- [ ] 敏感資料不記錄到日誌

### 資料層安全

- [ ] API 呼叫經過 Repository 封裝
- [ ] 使用參數化查詢
- [ ] RLS 政策生效

---

## 🧪 測試檢查

### 測試覆蓋

- [ ] Store 層 100% 覆蓋
- [ ] Service 層 80%+ 覆蓋
- [ ] Component 層 60%+ 覆蓋
- [ ] Utils 100% 覆蓋

### 測試命名

- [ ] 遵循 `MethodName_Condition_ExpectedResult` 格式
  ```typescript
  it('loadTasks_whenBlueprintIdValid_shouldReturnTasks', () => { ... });
  ```

---

## 📋 Lint 檢查

### ESLint

- [ ] 執行 `yarn lint:ts`
- [ ] 無錯誤
- [ ] 無警告（或已確認可忽略）

### Stylelint

- [ ] 執行 `yarn lint:style`
- [ ] 無錯誤
- [ ] 無警告（或已確認可忽略）

---

## 📚 文件更新

### 必要更新

- [ ] 相關 AGENTS.md（如有變更）
- [ ] API 文件（如有新 API）
- [ ] 使用說明（如有新功能）

### 可選更新

- [ ] README.md
- [ ] CHANGELOG.md

---

## 🚀 部署準備

### 編譯檢查

- [ ] 執行 `yarn build`
- [ ] 無編譯錯誤
- [ ] 無編譯警告（或已確認可忽略）

### 測試檢查

- [ ] 執行 `yarn test`
- [ ] 所有測試通過

---

## ✅ 最終確認

- [ ] 程式碼已完成自我審查
- [ ] 所有檢查項目已通過
- [ ] 準備提交 Code Review

---

## 下一步

準備提交後，請確認：
1. Commit message 遵循規範
2. PR 描述清晰完整
3. 指派適當的 Reviewer

---

**最後更新**: 2025-11-27
