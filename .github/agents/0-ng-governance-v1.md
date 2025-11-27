# Angular 企業級開發規範文件

## 1. 專案分層架構與單一職責原則 (SRP)

**適用場景**：`需求分析` | `架構設計` | `實作開發` | `代碼審查`

**關鍵問題**：
- 我應該在哪個目錄下開發？
- 這個功能應該用橫向分層還是垂直切片？
- 各層之間的依賴關係是什麼？

### 1.1 架構模式說明（重要：避免混淆）

本專案採用**混合架構模式**，不同目錄使用不同的架構組織方式：

#### 橫向分層架構（適用於 core、shared、routes、layout）

以下目錄採用**橫向分層架構**，必須遵守以下層級順序流動，禁止跨層或反方向依賴：

```
Types → Repositories → Models → Services → Facades → Routes/Components
```

**適用範圍**：
- `src/app/core/` - 核心模組（Facades、Infrastructure、Types）
- `src/app/shared/` - 共享模組（UI 元件、Pipes、Directives、Services）
- `src/app/routes/` - 路由頁面（對應 URL 的頁面元件）
- `src/app/layout/` - 佈局元件（basic、blank、passport）

**特點**：
- 代碼按層級橫向組織（所有 Types 在一起，所有 Repositories 在一起）
- 清晰的層級劃分，符合傳統企業級架構
- 跨功能模組共享基礎設施

#### 垂直切片架構（適用於 features）

以下目錄採用**垂直切片架構**（Vertical Slice Architecture），依賴方向相同但代碼組織方式不同：

```
domain/types → data-access/repositories → domain/models 
→ data-access/services → shell/ui
```

**適用範圍**：
- `src/app/features/` - 功能模組（業務領域，支援 Lazy Load）

**特點**：
- 代碼按功能垂直組織（所有相關代碼集中在同一 feature 目錄下）
- 每個 feature 包含完整的 domain、data-access、ui、shell 等層級
- 功能完全獨立，易於並行開發
- **邏輯容器（Blueprint Container）**：`blueprint` 是邏輯容器範例，提供共享上下文，能最大幅度減少 RLS 開發，且能搭配上下文切換器（Account Context Switcher）

**重要**：兩種架構模式的**依賴方向完全相同**，只是**代碼組織方式不同**。在開發時必須明確區分當前工作在哪個目錄，並遵循對應的架構模式。

### 1.2 各層職責定義

#### Types 層
- 僅定義資料結構 (Domain Types / DTO Types)
- 禁止包含任何邏輯

#### Repositories 層
- 純後端存取操作 (Supabase CRUD)
- 處理 RLS 驗證錯誤
- 禁止包含業務邏輯

#### Models 層
- 負責資料轉換 (DTO → Domain Model → View Model)
- 純資料映射職責

#### Services 層
- 實作業務邏輯與流程控制 (use cases)
- 禁止接觸 UI 層

#### Facades 層
- 提供 UI 專用的統一 API
- 封裝 service/store
- 禁止包含商業邏輯

#### Routes/Components 層
- 僅負責 UI 呈現與事件觸發
- 禁止直接操作 store、service、repository

---

## 2. 開發思考流程與工具使用規範

**適用場景**：`需求分析` | `架構設計` | `實作開發` | `問題排查`

**關鍵問題**：
- 我應該如何開始一個新功能？
- 什麼時候使用 Sequential Thinking？
- 什麼時候使用 Software Planning Tool？
- 什麼時候查詢 Supabase MCP 或 Context7 MCP？

### 2.1 Sequential Thinking (序列化思考)
開發任何功能時必須遵循序列化思考流程:

#### 思考順序
1. 理解需求與業務目標
2. 識別涉及的資料結構與流向
3. 確認分層架構與職責劃分
4. 規劃模組邊界與依賴關係
5. 設計錯誤處理策略
6. 實作與測試

#### 禁止行為
- 跳躍式開發(直接寫 Component 而未規劃架構)
- 邊寫邊想(缺乏整體規劃就開始編碼)
- 忽略依賴方向檢查

### 2.2 Software Planning Tool 使用規範
在開始編碼前必須使用 Software Planning Tool 進行:

#### 架構規劃
- 確認模組結構與邊界
- 設計資料流向與依賴關係
- 規劃公開 API 與私有實作

#### 技術設計
- 選擇適當的設計模式
- 確認使用的 NG-ALAIN / NG-ZORRO 元件
- 評估效能與可維護性

#### 流程產生
- 產生開發步驟清單
- 建立測試計畫
- 規劃錯誤處理機制

### 2.3 Supabase MCP 使用規範
數據庫相關開發必須使用 Supabase MCP 作為事實來源:

#### 使用時機
- 查詢數據庫表格結構
- 確認 RLS (Row Level Security) 政策
- 驗證欄位型別與約束條件
- 檢查索引與關聯設定

#### 作為事實來源原則
- 禁止憑記憶或假設撰寫數據庫相關程式碼
- 必須透過 Supabase MCP 查詢遠端數據庫的實際狀態
- 所有 Repository 層實作必須以 MCP 查詢結果為準
- 發現數據庫結構與預期不符時,必須先同步理解再編碼

### 2.4 Context7 MCP 使用時機與判斷準則

#### 使用決策流程
```
def should_use_context7_mcp(agent_confident: bool) -> bool:
    """
    判斷 Agent 是否需要使用 Context7 MCP 查詢
    """
    if agent_confident:
        # Agent 有絕對把握 → 不查
        return False
    else:
        # Agent 沒有把握 → 使用 MCP
        return True
```

#### 情境 1: 有絕對把握
**判斷條件:**
- 可以自己確定 API 簽名
- 確認版本號與相容性
- 熟悉語法且無歧義

**動作:**
- 不使用 Context7 MCP
- 直接基於已知資訊開發

**原因:**
- 已掌握正確資料
- 無需額外查詢
- 節省資源與時間

#### 情境 2: 沒有絕對把握
**判斷條件:**
- 不確定函式參數順序或型別
- 存在版本差異疑慮
- 不確定最新用法或最佳實踐
- 擔心 LLM 產生幻覺 API
- 涉及較新的框架特性

**動作:**
- 必須使用 Context7 MCP 查詢
- 基於官方文件進行開發

**原因:**
- 需要官方、最新、版本對應的資料
- 提高程式碼準確性
- 避免因錯誤資訊導致的技術債

#### 具體使用案例

**必須使用 Context7 MCP:**
- Angular 20 新語法特性(如 @if, @for)
- NG-ZORRO 20.3.x 特定元件 API
- NG-ALAIN 20.0.x 模組使用方式
- TypeScript 5.9.x 新特性
- RxJS 7.8.x 操作符變更

**可以不使用 Context7 MCP:**
- 基礎 TypeScript 語法
- 常用的 JavaScript 標準函式
- 穩定且熟悉的設計模式
- 已驗證過的專案內部 API

---

## 3. 模組邊界管理 (Module Boundary)

**適用場景**：`架構設計` | `實作開發` | `代碼審查` | `重構`

**關鍵問題**：
- 這個功能應該放在哪個模組？
- Feature Module 之間可以互相 import 嗎？
- 如何決定是否建立新的 Feature Module？
- Store 和 Facade 的區別是什麼？

### 3.1 Feature Module（垂直切片架構）
- 每個業務領域建立獨立 Feature Module
- 採用**垂直切片架構**（Vertical Slice Architecture），所有相關代碼集中在同一 feature 目錄下
- 包含該領域的 domain、data-access、ui、shell 等層級
- 各 Feature 之間禁止互相 import
- 必須支援 Lazy Load
- 可獨立維護與測試

**垂直切片架構結構**：
```
features/blueprint/
├── domain/              # 領域層（types、models、interfaces、enums）
├── data-access/         # 數據訪問層
│   ├── repositories/    # 資料存取（Supabase CRUD）
│   ├── services/        # 業務邏輯 + Signals 狀態管理
│   └── stores/          # ⭐ Facade 層（統一對外 API，Store = Facade）
├── ui/                  # 展示層（Dumb Components）
├── shell/               # 容器層（Smart Components、Dialogs）
├── directives/          # 自定義指令
├── pipes/               # 自定義管道
├── guards/              # 路由守衛
└── utils/               # 工具函數
```

**依賴方向**（在垂直切片中仍保持）：
```
domain/types → data-access/repositories → domain/models 
→ data-access/services → data-access/stores → shell/ui
```

**Store = Facade（在垂直切片中）**：
- **位置**：`features/*/data-access/stores/*.store.ts`
- **命名**：使用 `*.store.ts`（區分於 `core/facades/` 的 `*.facade.ts`）
- **職責**：統一對外 API，協調多個 Service，暴露 ReadonlySignal
- **與 Core Facades 的區別**：
  - **Core Facades**（`core/facades/`）：跨 feature 共享，如 `WorkspaceContextFacade`
  - **Feature Stores**（`features/*/data-access/stores/`）：Feature 內部使用，如 `BlueprintStore`

**邏輯容器（Blueprint Container）**：
- `blueprint` 是邏輯容器範例，用於管理可重用的工作區模板（blueprints）
- **共享上下文設計**：邏輯容器內部提供共享上下文（Shared Context），所有相關的資料存取、業務邏輯、UI 組件都在同一上下文中運作
- **RLS 開發優勢**：共享上下文能最大幅度減少 RLS（Row Level Security）開發複雜度，因為：
  - 所有相關的資料表、查詢邏輯、權限檢查都在同一 feature 目錄下，context 完整可見
  - 撰寫 RLS policy 時不需要在多個目錄間切換查找資訊
  - 權限邏輯與業務邏輯緊密結合，易於理解和維護
- **上下文切換器整合**：設計用於與 Account Context Switcher 整合，支援多租戶隔離
- 採用垂直切片架構，所有相關代碼集中在 `features/blueprint/` 目錄下

### 3.2 Infrastructure Module
- 放置 Supabase Client、Repositories、Http Adapter
- 可依賴 Domain Module
- 禁止依賴 Feature Module
- **注意**：在垂直切片架構中，部分 Repositories 已遷移至 `features/*/data-access/repositories/`，但核心 Infrastructure 仍保留在 `core/infra/`

### 3.3 Domain Module
- 包含 Types、Models、Mappers
- 禁止依賴 Infrastructure Module
- 禁止依賴 Feature Module
- 禁止依賴 UI
- 僅包含純邏輯與純定義

### 3.4 Shared Module
- 僅放置可重用的 UI 元件、Pipe、Directive
- 禁止放置商業邏輯
- 禁止依賴 Feature Module

### 3.5 邊界禁止規則
- Component 不可呼叫 Repository / Service（應透過 Facade 或 Shell Component）
- Feature Module 不可 import 另一個 Feature Module
- Domain 不可引用 Infrastructure 層
- Shared 不可含商業邏輯
- Supabase client 僅可在 Repository 中使用
- **垂直切片架構**：在 `features/` 下的模組，依賴方向仍保持 Types → Repositories → Models → Services → Shell/UI，但代碼組織方式為垂直切片

---

## 4. 狀態管理標準

**適用場景**：`架構設計` | `實作開發` | `代碼審查` | `問題排查`

**關鍵問題**：
- 應該在哪一層管理狀態？
- 如何使用 Angular Signals？
- Store 和 Service 的職責如何劃分？
- 如何在垂直切片中管理狀態？

### 4.1 狀態管理流向（重要：區分架構模式）

本專案採用**混合架構模式**，狀態管理流向因架構模式而異：

#### 橫向分層架構（core、shared、routes、layout）

```
Component → Facade → Service → Repository → Types
```

#### 垂直切片架構（features）

```
UI Component (Dumb)
    ↓ inject
Shell Component (Smart) / Store (Facade)
    ↓ inject
Service (Business Logic + Signals)
    ↓ inject
Repository (Data Access)
    ↓ use
Types (Domain Types)
```

**重要**：兩種架構模式的依賴方向相同，但代碼組織方式不同。

### 4.2 Store 在垂直切片架構中的位置

在 `features/` 下的垂直切片架構中，**Store = Facade**（功能等同，命名不同以區分位置）。

#### Store 的定位與職責

**位置**：`features/*/data-access/stores/*.store.ts`

**職責**：
- 統一對外 API，協調多個 Service
- 暴露 Service 的 ReadonlySignal 給 Component
- 提供業務方法供 Component 呼叫
- 整合 Account Context（如需要）

**命名規範**：
- 使用 `*.store.ts` 命名（區分於 `core/facades/` 的 `*.facade.ts`）
- 範例：`blueprint.store.ts`、`task.store.ts`

**結構範例**：
```typescript
@Injectable({ providedIn: 'root' })
export class BlueprintStore {
  private readonly blueprintService = inject(BlueprintService);
  
  // 暴露 Service 的 Signals
  readonly blueprints = this.blueprintService.blueprints;
  readonly loading = this.blueprintService.loading;
  readonly error = this.blueprintService.error;
  
  // 提供業務方法
  async loadBlueprints(ownerId: string): Promise<void> {
    await this.blueprintService.loadBlueprintsByOwner(ownerId);
  }
}
```

**與 Core Facades 的區別**：
- **Core Facades**（`core/facades/`）：跨 feature 共享的 Facade，如 `WorkspaceContextFacade`
- **Feature Stores**（`features/*/data-access/stores/`）：Feature 內部的 Facade，僅在該 feature 內使用

### 4.3 各層狀態管理職責

#### Component 層（UI Component / Shell Component）

**UI Component（Dumb Component）**：
- 禁止直接注入 Service 或 Repository
- 僅可注入 Store（Feature Store）或 Core Facade
- 禁止直接操作 Signal（使用 `update()` 或 `set()`）
- 僅可綁定 ReadonlySignal 與呼叫 Store/Facade 方法
- 必須使用 `ChangeDetectionStrategy.OnPush`

**Shell Component（Smart Component）**：
- 可注入 Store 和 Core Facade
- 提供 Context 給子組件
- 處理路由邏輯
- 監聽 Context 變化並重新載入資料

#### Store 層（Feature Store = Feature Facade）

**位置**：`features/*/data-access/stores/`

**職責**：
- 統一對外 API，協調多個 Service
- 暴露 Service 的 ReadonlySignal
- 提供業務方法供 Component 呼叫
- 可整合 Account Context（透過 `WorkspaceContextFacade`）

**禁止事項**：
- 禁止包含業務邏輯（應委派給 Service）
- 禁止直接操作 Repository

#### Service 層

**職責**：
- 實作業務邏輯與流程控制
- 使用 Angular Signals 管理狀態（`signal()`, `computed()`）
- 暴露 ReadonlySignal 給 Store/Component
- 呼叫 Repository 取得資料

**狀態管理模式**：
```typescript
@Injectable({ providedIn: 'root' })
export class BlueprintService {
  // 私有可寫 Signal
  private blueprintsState = signal<BlueprintModel[]>([]);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);
  
  // 暴露 ReadonlySignal
  readonly blueprints = this.blueprintsState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();
  
  // Computed Signal
  readonly statistics = computed(() => ({
    total: this.blueprints().length,
    // ...
  }));
}
```

**禁止事項**：
- 禁止直接控制 Store（Store 不存在於 Service 層）
- 禁止接觸 UI 層

#### Repository 層

**職責**：
- 純資料來源存取（Supabase CRUD）
- 返回 Observable（使用 RxJS）
- 處理 RLS 驗證錯誤

**禁止事項**：
- 禁止包含業務邏輯
- 不涉及狀態管理（狀態管理在 Service 層）

---

## 5. 認證與授權架構

**適用場景**：`架構設計` | `實作開發` | `代碼審查` | `問題排查`

**關鍵問題**：
- 如何在 Component 中取得認證狀態？
- 如何整合 Account Context Switcher？
- 如何在垂直切片中使用 WorkspaceContextFacade？
- 認證流向的順序是什麼？

### 5.1 認證流向
必須遵守以下認證鏈:
```
Supabase Auth → @delon/auth → DA_SERVICE_TOKEN → @delon/acl
```

### 5.2 認證層級職責

#### Supabase Auth
- 作為底層認證提供者
- 處理使用者登入/登出/註冊
- 管理 Session 與 Token

#### @delon/auth
- 封裝 Supabase Auth 的認證邏輯
- 統一認證介面
- 管理認證狀態

#### DA_SERVICE_TOKEN
- 提供認證服務的注入 Token
- 確保認證服務的單一實例

#### @delon/acl
- 處理權限控制邏輯
- 管理使用者角色與權限
- 提供路由守衛與元件級權限控制

### 5.3 認證整合規範
- Repository 層透過 Supabase Auth 取得認證狀態
- Service 層透過 @delon/auth 處理認證業務邏輯
- Component 層透過 @delon/acl 控制 UI 權限顯示
- 禁止在 Component 直接存取 Supabase Auth

### 5.4 Account Context Switcher 整合規範

**WorkspaceContextFacade** 提供統一的帳戶上下文管理介面，支援多租戶隔離。

#### WorkspaceContextFacade 使用規範

**位置**：`src/app/core/facades/account/workspace-context.facade.ts`

**注入方式**：
```typescript
// ✅ 正確：在 Shell Component 或 Store 中注入
private readonly workspaceContext = inject(WorkspaceContextFacade);
```

**讀取 Context**：
```typescript
// ✅ 正確：使用 Signals
readonly contextId = this.workspaceContext.contextId();
readonly contextType = this.workspaceContext.contextType();
readonly contextLabel = this.workspaceContext.contextLabel();
readonly contextIcon = this.workspaceContext.contextIcon();
```

**監聽 Context 變化**：
```typescript
// ✅ 正確：使用 effect 監聽
effect(() => {
  const contextId = this.workspaceContext.contextId();
  const contextType = this.workspaceContext.contextType();
  if (contextId && contextType !== 'app') {
    this.loadDataForContext(contextId, contextType);
  }
});
```

**切換 Context**：
```typescript
// ✅ 正確：在 UI Component 中呼叫
switchToUser(userId: string): void {
  this.workspaceContext.switchToUser(userId);
}

switchToOrganization(orgId: string): void {
  this.workspaceContext.switchToOrganization(orgId);
}

switchToTeam(teamId: string): void {
  this.workspaceContext.switchToTeam(teamId);
}
```

#### 在垂直切片中整合 Account Context

**Shell Component 整合**：
```typescript
// features/blueprint/shell/blueprint-shell/blueprint-shell.component.ts
export class BlueprintShellComponent {
  private readonly workspaceContext = inject(WorkspaceContextFacade);
  private readonly blueprintStore = inject(BlueprintStore);
  
  constructor() {
    // 監聽 context 變化
    effect(() => {
      const contextId = this.workspaceContext.contextId();
      const contextType = this.workspaceContext.contextType();
      if (contextId && contextType !== 'app') {
        this.loadDataForContext(contextId, contextType);
      }
    });
  }
  
  private async loadDataForContext(contextId: string, contextType: ContextType): Promise<void> {
    // 根據 context 載入對應資料
    await this.blueprintStore.loadOwnerBlueprints(contextId);
  }
}
```

**Store 整合**：
```typescript
// features/blueprint/data-access/stores/blueprint.store.ts
export class BlueprintStore {
  private readonly workspaceContext = inject(WorkspaceContextFacade);
  private readonly blueprintService = inject(BlueprintService);
  
  // 自動使用當前 context 載入資料
  async loadCurrentContextBlueprints(): Promise<void> {
    const contextId = this.workspaceContext.contextId();
    const contextType = this.workspaceContext.contextType();
    if (contextId && contextType !== 'app') {
      await this.blueprintService.loadBlueprintsByOwner(contextId);
    }
  }
}
```

**Context 切換時的處理**：
- 監聽 `workspaceContext.contextId()` 變化
- Context 切換時清空當前 feature 的狀態
- 重新載入新 context 的資料
- 顯示載入狀態，避免資料閃爍

#### 禁止事項
- 禁止在 Repository 層直接使用 WorkspaceContextFacade
- 禁止在 Service 層切換 Context（應在 UI/Shell 層）
- 禁止在 Component 中直接存取 Supabase Auth（應透過 WorkspaceContextFacade）

---

## 6. NG-ALAIN 框架使用規範

**適用場景**：`實作開發` | `代碼審查` | `技術選型`

**關鍵問題**：
- 應該使用哪個 @delon 模組？
- 如何避免重複造輪子？
- 什麼時候應該自行開發元件？

### 6.1 核心模組使用原則
本專案基於 NG-ALAIN 企業級框架,必須優先使用以下模組以減少重複開發:

#### @delon/theme
- 統一使用此模組管理主題配置
- 包含佈局、樣式、主題切換
- 禁止自行實作主題系統

#### @delon/abc
- 優先使用內建的業務元件
- 包含常用的企業級 UI 模式
- 減少自定義元件開發

#### @delon/cache
- 統一使用此模組處理快取邏輯
- 支援記憶體快取與持久化快取
- 禁止自行實作快取機制

#### @delon/form
- 優先使用動態表單方案
- 透過 JSON Schema 定義表單
- 減少重複的表單程式碼

#### @delon/util
- 使用內建的工具函數
- 包含常用的輔助方法
- 避免重複實作工具函數

#### @delon/chart
- 統一使用此模組處理圖表需求
- 支援多種圖表類型
- 禁止引入其他圖表庫(除非有特殊需求)

### 6.2 避免重複造輪子原則
- 開發新功能前必須先檢查 NG-ALAIN 與 NG-ZORRO 是否已提供
- 優先使用框架內建方案
- 僅在框架無法滿足需求時才自行開發
- 自行開發的元件必須文件化並說明原因

---

## 7. UI 元件使用規範

**適用場景**：`實作開發` | `代碼審查` | `UI 設計` | `響應式設計`

**關鍵問題**：
- 應該使用哪個 UI 元件庫？
- 如何實現響應式設計？
- 元件使用優先級是什麼？
- 如何處理不同螢幕尺寸？

### 7.1 NG-ZORRO 元件庫
- 統一使用 ng-zorro-antd 作為基礎 UI 元件庫
- 所有標準 UI 元件必須使用 NG-ZORRO
- 禁止引入其他 UI 元件庫(除非有特殊需求並經過評估)

### 7.2 元件使用優先級
1. 優先使用 @delon/abc 的業務元件
2. 次要使用 ng-zorro-antd 的基礎元件
3. 最後才考慮自定義元件

### 7.3 自定義元件開發準則
- 必須基於 NG-ZORRO 元件擴展
- 必須遵循 Ant Design 設計規範
- 必須提供完整的文件與使用範例
- 必須說明為何不使用現有元件

### 7.4 響應式設計規範

#### 斷點系統（使用 Ant Design 標準）
```typescript
XS: 480px   // 手機
SM: 576px   // 平板直向
MD: 768px   // 平板橫向
LG: 992px   // 筆記型電腦
XL: 1200px  // 桌面
XXL: 1600px // 大螢幕
```

#### 使用方式

**1. 使用 ng-zorro 的響應式屬性**：
```html
<!-- ✅ 正確：使用 ng-zorro 的響應式屬性 -->
<div nz-row [nzGutter]="16">
  <div nz-col [nzXs]="24" [nzSm]="12" [nzMd]="8">
    <!-- 手機全寬，平板一半，桌面三分之一 -->
  </div>
</div>
```

**2. CSS 媒體查詢**：
```less
// ✅ 正確：使用 Less 變數
@media (max-width: @screen-md-max) {
  // 手機樣式
}

@media (min-width: @screen-lg) {
  // 桌面樣式
}
```

**3. 響應式服務（可選）**：
```typescript
// 如果需要程式化判斷，可注入 ResponsiveService（需實作）
readonly isMobile = this.responsiveService.isMobile();
readonly isTablet = this.responsiveService.isTablet();
readonly isDesktop = this.responsiveService.isDesktop();
```

#### 響應式設計要求
- 所有組件必須支援響應式設計
- 使用 ng-zorro 的響應式屬性（`[nzXs]`, `[nzSm]`, `[nzMd]`, `[nzLg]`, `[nzXl]`, `[nzXXl]`）
- 採用 Mobile First 設計原則（從最小螢幕開始設計，逐步增強）
- 確保在各種螢幕尺寸下都有良好的使用者體驗

---

## 8. 錯誤處理與錯誤映射標準

**適用場景**：`實作開發` | `代碼審查` | `問題排查` | `錯誤修復`

**關鍵問題**：
- 錯誤應該在哪一層處理？
- 如何將 Supabase Error 轉換為使用者友善訊息？
- 垂直切片中的錯誤處理流程是什麼？
- 如何顯示錯誤訊息？

### 8.1 錯誤處理流向

錯誤處理流向因架構模式而異：

#### 橫向分層架構
```
Supabase Error → Domain Error → UI Error
```

#### 垂直切片架構
```
Supabase Error (Repository)
    ↓ 轉換
Domain Error (Service)
    ↓ 轉換
UI Error Message (Store/Shell)
    ↓ 顯示
Component (UI)
```

### 8.2 各層錯誤處理職責

#### Global ErrorHandler
- 處理不可預期的全域錯誤
- 提供統一的錯誤攔截機制

#### HTTP Interceptor
- 攔截並標準化 HTTP 錯誤
- 統一處理認證與授權錯誤

#### Repository 層
- 將 Supabase Error 轉換為 Domain Error
- 處理 RLS 錯誤並分類
- 拋出 Domain Error 給上層處理

**範例**：
```typescript
catch (error) {
  if (error.code === 'PGRST116') {
    throw new DomainError('NOT_FOUND', 'Blueprint not found');
  }
  if (error.code === '42501') {
    throw new DomainError('PERMISSION_DENIED', 'Insufficient permissions');
  }
  throw new DomainError('UNKNOWN', error.message);
}
```

#### Service 層（垂直切片）
- 捕獲 Domain Error
- 設置 error signal（`errorState.set()`）
- 將 Domain Error 轉換為使用者友善訊息
- 繼續向上拋出錯誤（供 Store 處理）

**範例**：
```typescript
async loadBlueprintsByOwner(ownerId: string): Promise<void> {
  this.loadingState.set(true);
  this.errorState.set(null);
  
  try {
    const blueprints = await firstValueFrom(this.blueprintRepo.findByOwner(ownerId));
    this.blueprintsState.set(blueprints);
  } catch (error) {
    const userMessage = this.getUserFriendlyMessage(error);
    this.errorState.set(userMessage);
    throw error; // 繼續向上拋出
  } finally {
    this.loadingState.set(false);
  }
}
```

#### Store 層（垂直切片中的 Facade）
- 暴露 Service 的 error signal
- 提供清除錯誤的方法
- 可進行額外的錯誤處理（如記錄日誌）

**範例**：
```typescript
readonly error = this.blueprintService.error;

clearError(): void {
  this.blueprintService.clearError();
}
```

#### Shell Component 層（垂直切片）
- 可處理 Store 的錯誤
- 決定錯誤的 UI 呈現方式
- 可提供錯誤重試機制

#### Component 層（UI Component）
- 僅負責顯示錯誤訊息
- 禁止處理邏輯錯誤
- 使用 Store 的 error signal 顯示錯誤

**範例**：
```typescript
// ✅ 正確：僅顯示錯誤
@if (error()) {
  <nz-alert [nzMessage]="error()" nzType="error" />
}
```

---

## 9. 環境管理與安全策略

**適用場景**：`環境配置` | `安全審查` | `部署上線`

**關鍵問題**：
- 如何管理不同環境的配置？
- Supabase Key 應該如何管理？
- 如何確保安全性？

### 9.1 環境配置管理
- 區分 dev/staging/prod 環境
- 各環境使用獨立的 Supabase URL 與 Key
- 環境變數於 build 時注入,禁止寫死在程式碼中

### 9.2 Supabase Key 安全規範
- anon key 禁止直接放在程式碼中
- 必須透過環境變數管理
- 於 build 時動態注入

### 9.3 配置集中管理
- Config 必須由 Infrastructure Module 集中提供
- 禁止在各 Feature Module 分散管理配置

### 9.4 Schema 與 DTO 版本管理
- MCP schema/dto 必須建立版本管理機制
- 確保向後相容性
- 記錄所有 breaking changes

---

## 10. 模組匯出規範 (Public API Boundary)

**適用場景**：`架構設計` | `實作開發` | `代碼審查` | `API 設計`

**關鍵問題**：
- 哪些內容應該公開？
- Feature Module 應該公開什麼？
- Facade 在垂直切片中的角色是什麼？

### 10.1 Domain Module
- 必須提供 `index.ts` 統一輸出
- 明確定義公開 API

### 10.2 Feature Module（垂直切片架構）

**公開 API 原則**：
- 僅公開 Store（Feature Facade）
- 禁止公開 Service
- 禁止公開 Repository
- 禁止公開 Model（除非是跨 feature 共享的類型）

**公開範例**：
```typescript
// features/blueprint/index.ts
// ✅ 正確：僅公開 Store
export * from './data-access/stores';

// ✅ 正確：公開必要的類型（如果跨 feature 使用）
export * from './domain/types/blueprint.types';

// ❌ 錯誤：禁止公開 Service
// export * from './data-access/services';

// ❌ 錯誤：禁止公開 Repository
// export * from './data-access/repositories';
```

**Shell Component 公開**：
- Shell Component 可作為 Feature 的入口點
- 透過路由配置公開，而非直接 export

### 10.3 Infrastructure Module
- 禁止讓外部直接引用 Repository
- 僅可透過 Service 或 Facade 間接存取

### 10.4 Barrel Files 使用原則
- 每個模組必須有明確的 `index.ts`
- 嚴格控制模組的公開介面
- 避免內部實作細節外洩

### 10.5 Facade 在垂直切片中的角色

**Facade 的雙重定位**：

**1. Core Facades**（`core/facades/`）：
- **用途**：跨 feature 共享的 Facade
- **範例**：`WorkspaceContextFacade`（帳戶上下文）
- **特點**：可被多個 feature 使用
- **命名**：`*.facade.ts`

**2. Feature Stores**（`features/*/data-access/stores/`）：
- **用途**：Feature 內部的 Facade
- **範例**：`BlueprintStore`（藍圖功能）
- **特點**：僅在該 feature 內使用
- **命名**：`*.store.ts`（區分於 Core Facades）

**使用原則**：
- Feature 內部：使用 Feature Store（`BlueprintStore`）
- 跨 Feature：使用 Core Facade（`WorkspaceContextFacade`）
- Shell Component：可同時注入 Feature Store 和 Core Facade

**範例**：
```typescript
// ✅ 正確：Shell Component 同時注入 Store 和 Core Facade
export class BlueprintShellComponent {
  private readonly blueprintStore = inject(BlueprintStore); // Feature Store
  private readonly workspaceContext = inject(WorkspaceContextFacade); // Core Facade
}
```

---

## 11. Angular 20+ 模板語法規範

**適用場景**：`實作開發` | `代碼審查` | `語法遷移`

**關鍵問題**：
- 應該使用新語法還是舊語法？
- @if/@for/@switch 的正確用法是什麼？

### 11.1 新控制流語法
- 必須使用 `@if` / `@else` 取代 `*ngIf`
- 必須使用 `@for` 取代 `*ngFor`
- 必須使用 `@switch` / `@case` 取代 `*ngSwitch`
- 使用 `@defer` 進行延遲載入

### 11.2 禁用語法
- 禁止使用 `*ngIf`
- 禁止使用 `*ngFor`
- 禁止使用 `*ngSwitch`
- 禁止使用任何舊版結構型指令

---

## 12. 套件管理規範

**適用場景**：`專案設置` | `依賴管理` | `CI/CD`

**關鍵問題**：
- 應該使用 yarn 還是 npm？
- UI 框架的優先順序是什麼？

### 12.1 套件管理器
- 統一使用 `yarn` 作為套件管理器
- 禁止使用 `npm` 指令

### 12.2 UI 框架優先順序
- 優先使用 NG-ZORRO 元件
- 次要使用 NG-ALAIN 企業級元件
- 避免自行開發已有的標準元件

---

## 13. 程式碼品質管理

**適用場景**：`代碼審查` | `測試` | `CI/CD` | `品質保證`

**關鍵問題**：
- 如何確保程式碼品質？
- 測試覆蓋率要求是什麼？
- Git Hooks 如何配置？

### 13.1 程式碼檢查
- 必須通過 ESLint 檢查
- 必須符合 Prettier 格式規範

### 13.2 測試要求
- 使用 Jasmine + Karma 撰寫測試
- 各層必須有對應的單元測試

### 13.3 Git Hooks
- 使用 Husky 管理 Git hooks
- commit 前必須通過 lint-staged 檢查

---

## 14. TypeScript 開發規範

**適用場景**：`實作開發` | `代碼審查` | `型別定義`

**關鍵問題**：
- 應該使用哪個 TypeScript 版本？
- 如何定義型別？
- 什麼時候可以使用 any？

### 14.1 語言版本
- 使用 TypeScript 5.9.x 以上版本

### 14.2 型別定義
- 所有公開介面必須明確定義型別
- 禁止使用 `any` 型別,除非有充分理由並註解說明
- 優先使用 interface 而非 type alias 定義物件結構

---

# Angular 企業級快速檢查清單（含完整模組邊界）

---

## 1. 架構與分層 (Architecture)

### 分層依賴
- [ ] 是否遵守 Types → Repositories → Models → Services → Facades → Components 的順序？
- [ ] 是否沒有跨層依賴（如 Component→Repository）？
- [ ] Component 是否未直接操作 store / service / repository？
- [ ] 是否使用 barrel file（index.ts）定義公開 API？

---

## 2. 模組邊界 (Module Boundary)

### Feature Module
- [ ] Feature Module 是否未 import 其他 Feature Module？
- [ ] Feature 是否支援 Lazy Load？
- [ ] Feature 是否僅公開 Facade，不公開 Service/Model？

### Domain Module
- [ ] Domain 是否僅包含 Types / Models / Mappers？
- [ ] Domain 是否未依賴 Infrastructure？
- [ ] Domain 是否未依賴 Feature？
- [ ] Domain 是否未包含 UI 或商業邏輯？

### Infrastructure Module
- [ ] Infrastructure 是否僅包含 Supabase client、Repositories、Adapter？
- [ ] Feature 是否未直接引用 Repository（應透過 Service）？
- [ ] Infrastructure 是否未依賴 Feature？

### Shared Module
- [ ] Shared 是否僅包含 UI（components/pipes/directives）？
- [ ] Shared 是否未包含商業邏輯？
- [ ] Shared 是否未依賴 Feature Module？

### 禁止規則（強制）
- [ ] Component 禁止直接呼叫 Repository
- [ ] Component 禁止直接呼叫 Service（只能 Facade）
- [ ] Domain 禁止引用 Infrastructure
- [ ] Feature Module 之間禁止互相 import
- [ ] Supabase Client 僅能出現在 Repository 層

---

## 3. 開發流程 (Development Process)

- [ ] 是否使用 Sequential Thinking 規劃開發？
- [ ] 是否使用 Software Planning Tool 設計架構？
- [ ] 資料庫相關是否使用 Supabase MCP 查詢？
- [ ] 不確定 API 時是否使用 Context7 MCP 驗證？

---

## 4. 認證與框架 (Auth & Framework)

- [ ] 是否遵循 Supabase Auth → @delon/auth → @delon/acl 流程？
- [ ] Component 是否未直接存取 Supabase Auth？
- [ ] 是否優先使用 NG-ALAIN / NG-ZORRO？
- [ ] 是否使用 @delon/cache 而非自行實作？
- [ ] 表單是否優先使用 @delon/form？

---

## 5. 狀態管理 (State Management)

### 流程
- [ ] 是否遵循 Component → Facade → Service → Store？

### Component
- [ ] 是否未使用 select / dispatch / update？
- [ ] 是否僅呼叫 Facade？

### Facade
- [ ] 是否為唯一操作 Store 的層級？

### Service
- [ ] 是否僅執行邏輯，完全不操控 Store？

### Repository
- [ ] 是否僅做 Supabase CRUD，不含商業邏輯？

---

## 6. NG-ALAIN / NG-ZORRO 規範

- [ ] 是否使用 @delon/theme 管理主題？
- [ ] 是否使用 @delon/abc 的業務元件？
- [ ] 是否統一使用 NG-ZORRO UI 元件？
- [ ] 是否避免引入額外 UI/Chart 庫（若有是否記錄理由）？
- [ ] 自製元件是否遵守 Ant Design 規範？

---

## 7. 錯誤處理與錯誤映射 (Error Handling)

- [ ] 是否遵循 Supabase Error → Domain Error → UI Error？
- [ ] Repository 是否有轉換 Supabase Error → Domain Error？
- [ ] Facade 是否負責將 Domain Error → UI 訊息？
- [ ] Component 是否僅顯示錯誤、不處理邏輯？
- [ ] 是否有 HTTP Interceptor 處理 Auth/Error？

---

## 8. 環境管理與安全 (Environment & Security)

- [ ] anon key 是否未出現在程式碼？
- [ ] 是否使用 dev/staging/prod 不同 Key？
- [ ] Config 是否由 Infrastructure Module 統一提供？
- [ ] MCP schema/dto 是否有版本管理？

---

## 9. Angular 20+ 語法 (Syntax)

- [ ] 是否使用 @if / @for / @switch？
- [ ] 是否避免 *ngIf / *ngFor / *ngSwitch？
- [ ] 是否使用 @defer？

---

## 10. 套件管理 (Package)

- [ ] 是否全部使用 yarn？
- [ ] UI 元件是否遵守 NG-ALAIN → NG-ZORRO → 自製 的優先順序？

---

## 11. 程式碼品質 (Code Quality)

- [ ] 是否通過 ESLint？
- [ ] 是否符合 Prettier？
- [ ] 是否具備單元測試？
- [ ] 是否使用 Husky + lint-staged？

---

## 12. TypeScript 規範 (TypeScript)

- [ ] 是否使用 TS 5.9+？
- [ ] 是否避免 any 並提供註解？
- [ ] 所有公開 API 是否有明確型別？
- [ ] 是否優先使用 interface？

---

# ✔ 最終確認
- [ ] 以上所有項目皆符合 → 功能/模組符合企業級標準。

