# 專案關鍵詞清單（中英對照）

> 本文件收錄專案開發過程中的核心概念、架構原則與開發規範的中英對照關鍵詞。
> 
> **開發順序說明**：本文件按照開發階段順序組織，從基礎架構到運維優化，方便開發者按階段查閱。

---

## 📋 目錄結構

1. **[Phase 1] 基礎架構與設計原則** - 專案啟動前的架構設計與理念
2. **[Phase 2] 開發規範與架構標準** - 建立開發標準與規範
3. **[Phase 3] 技術基礎與實踐** - 技術實現的基礎建設
4. **[Phase 4] 核心業務功能** - 業務邏輯與功能開發
5. **[Phase 5] 品質保證與安全** - 品質控制與安全防護
6. **[Phase 6] 運維、監控與優化** - 生產環境的持續改進

---

# [Phase 1] 基礎架構與設計原則

> **階段說明**：專案啟動前必須確立的架構設計、開發理念與核心工具。

---

## 🎨 開發理念與原則

| 中文 | English | 說明 |
|------|---------|------|
| 奧卡姆剃刀原則 | Occam's Razor Principle | 保持簡單，避免不必要複雜 |
| 功能最小化 | Feature Minimization | 只做必要功能，避免膨脹 |
| 企業標準 | Enterprise Standard | 遵循企業級規範和最佳實務 |
| 易於擴展 | Easy to Extend | 模組可靈活擴展與延伸 |
| 避免冗餘 | Avoid Redundancy | 消除重複功能與資料以降低維護成本 |
| 藍圖是邏輯容器 | Blueprint is Logic Container | 藍圖負責承載業務邏輯與邊界 |
| 任務是主核心模組 | Task is Core Module | 任務模組為系統主要功能單元 |
| 其他模組依附任務 | Other Modules Depend on Tasks | 周邊模組應以任務為依賴中心 |
| 上下文層層傳遞 | Context Passed Layer by Layer | 上下文訊息以明確界面逐層傳遞 |
| 零認知開發 | Zero Cognitive Development | 降低開發者認知負擔，簡化使用介面與 API |
| 高內聚低耦合 | High Cohesion, Low Coupling | 模組內部功能緊密，高內聚；模組間依賴小 |
| 單一責任原則 | Single Responsibility Principle | 每個模組/物件只負責單一職責，便於測試與維護 |
| 可觀察性 | Observability | 系統狀態可追蹤、日誌與度量清楚，便於診斷 |
| 安全優先 | Security First | 認證、授權與資料保護為設計核心考量 |
| 企業標準+生產水平 | Enterprise Standard + Production Level | 適合生產環境的企業級標準與可運維性 |

---

## 🛠️ 核心工具與概念

| 中文 | English | 說明 |
|------|---------|------|
| 逐步執行的思考鏈 | Sequential Thinking / Thought Chain | 使用逐步推理方式分析問題，確保邏輯清晰 |
| 軟體規劃工具 | Software Planning Tool | 用於生成和驗證開發計劃的工具 |
| Supabase MCP 系統化 | Supabase MCP Systemization | 將 Supabase 操作透過 MCP 工具標準化 |
| 遠端資料庫檢視 | Remote Database Inspection | 透過 MCP 工具檢視遠端資料庫結構與資料 |
| RLS（行級安全） | Row Level Security (RLS) | PostgreSQL 行級安全機制，控制資料存取權限 |
| SECURITY DEFINER | SECURITY DEFINER | 函數以定義者權限執行，用於權限提升場景 |
| supabase\migrations 不作為判斷準則 | migrations are not evaluation criteria | 遷移檔案不應作為功能判斷的唯一依據 |

---

## 🧱 企業級分層架構

| 中文 | English | 說明 |
|------|---------|------|
| 單一職責原則 | Single Responsibility Principle (SRP) | 每個模組只負責一個明確的職責 |
| 關注點分離 | Separation of Concerns | 將不同關注點分離到不同層級 |
| 分層結構 | Layered Architecture | 系統按職責分層，層級間依賴單向 |
| 型別層 | Types Layer | 定義資料結構與型別定義 |
| 儲存庫層 | Repositories Layer | 負責後端資料存取抽象 |
| 模型層 | Models Layer | 負責資料映射與轉換 |
| 服務層 | Services Layer | 處理業務邏輯與工作流程 |
| 門面層 | Facades Layer | UI 的唯一入口，統一對外介面 |
| 路由/元件層 | Routes / Components Layer | 負責 UI 呈現與使用者互動 |
| 資料轉換 | Data Transformation | 在不同層級間轉換資料格式 |
| 網域類型 / 傳輸物件 | Domain Types / DTO Types | 網域模型與資料傳輸物件的型別定義 |
| DTO → Domain Model → View Model | DTO → Domain Model → View Model | 資料從後端到前端的轉換流程 |

---

## 🧭 模組邊界與規範

| 中文 | English | 說明 |
|------|---------|------|
| 功能模組 | Feature Module | 完整業務功能模組，採用垂直切片架構 |
| 基礎設施模組 | Infrastructure Module | 提供基礎設施服務的模組 |
| 網域模組 | Domain Module | 定義業務領域模型與規則 |
| 共用模組 | Shared Module | 跨模組共用的元件與工具 |
| 懶載入 | Lazy Load | 按需載入模組以提升效能 |
| 禁止 Feature 互相 import | Feature Modules must not import each other | 功能模組間保持獨立，避免循環依賴 |
| Domain 不可依賴 Infrastructure | Domain must not depend on Infrastructure | 網域層保持純淨，不依賴基礎設施 |
| Shared 不可包含商業邏輯 | Shared must not contain business logic | 共用模組只包含通用功能，不含業務邏輯 |
| Supabase Client 只能在 Repository | Supabase Client allowed only in Repository | Supabase 客戶端僅在儲存庫層使用 |

---

## 🏗️ 系統架構層級

| 中文 | English | 說明 |
|------|---------|------|
| 身份認證層 | Authentication Layer | 處理使用者身份驗證的系統層級 |
| 權限控制層 | Permission Control Layer | 管理使用者權限與存取控制的層級 |
| 專案藍圖層 | Project Blueprint Layer | 管理專案藍圖的業務邏輯層 |
| 任務執行模組 | Task Execution Module | 處理任務建立、更新、執行等核心功能 |
| 異常處理模組 | Exception Handling Module | 統一處理系統異常與錯誤的模組 |
| 協作溝通模組 | Collaboration & Communication Module | 提供協作與溝通功能的模組 |
| 資料分析模組 | Data Analysis Module | 提供資料分析與報表功能的模組 |
| 系統管理模組 | System Management Module | 系統設定與管理功能的模組 |
| Supabase 核心服務 | Supabase Core Services | 封裝 Supabase 核心功能的服務層 |

---

## 🗺️ 架構圖與資料模型（ER 圖）

| 中文 | English | 說明 |
|------|---------|------|
| ER 圖 / 資料模型 | ER Diagram / Data Model | 提供主要資料表與關係的 ER 圖，包含關鍵欄位註記 |
| 系統架構圖 | System Architecture Diagram | 放置高階系統元件圖（服務邊界、外部依賴、資料流） |
| 邊界說明 | Boundary Definitions | 說明功能模組/服務邊界、責任範圍與通訊協定 |

---

# [Phase 2] 開發規範與架構標準

> **階段說明**：建立開發標準、規範與各層職責定義，確保團隊開發一致性。

---

## 🧾 各層職責

| 中文 | English | 說明 |
|------|---------|------|
| 型別層僅定義資料結構 | Types define data structures only | 型別層只定義結構，不包含邏輯 |
| 儲存庫層純存取後端 | Repositories handle backend access only | 儲存庫層專注於資料存取，不處理業務邏輯 |
| 模型層負責資料映射 | Models handle data mapping | 模型層負責不同格式間的資料轉換 |
| 服務層負責業務邏輯 | Services handle business logic only | 服務層處理業務規則與工作流程 |
| 門面層是 UI 的唯一入口 | Facades are the single UI access point | UI 元件只能透過門面層存取資料與操作 |
| 元件層僅負責呈現 | Components handle UI rendering only | 元件層專注於 UI 呈現，不包含業務邏輯 |
| 禁止跨層依賴 | No cross-layer dependencies | 層級間只能依賴相鄰層級，不可跨層 |
| 禁止反向依賴 | No reverse dependencies | 下層不可依賴上層，保持單向依賴 |

---

## 🔄 狀態管理

| 中文 | English | 說明 |
|------|---------|------|
| 狀態管理分層原則 | State Management Layering Principles | 狀態管理遵循分層架構原則 |
| 門面暴露可觀察資料 | Facade exposes observable data | 門面層提供可觀察的資料流給 UI |
| Store 操作必須由 Facade 執行 | Store operations must go through Facade | 所有 Store 操作需透過門面層進行 |
| 元件不可直接操作 Store | Components must not directly operate Store | UI 元件不能直接存取或修改 Store |
| 事件驅動資料流 | Event-driven data flow | 使用事件驅動方式管理資料流動 |
| 狀態層 | Store Layer | 使用 Angular Signals 管理狀態的層級 |
| 服務層處理業務流程 | Services handle workflow, not UI | 服務層專注業務流程，不處理 UI 邏輯 |

---

## ❌ 錯誤處理與映射

| 中文 | English | 說明 |
|------|---------|------|
| 全域錯誤處理器 | Global Error Handler | 統一處理應用程式層級的錯誤 |
| HTTP 拦截器 | HTTP Interceptor | 攔截 HTTP 請求與回應，統一處理錯誤 |
| 錯誤映射流程 | Error Mapping Flow | 將不同層級的錯誤轉換為適當格式 |
| Supabase Error → Domain Error → UI Error | Supabase Error → Domain Error → UI Error | 錯誤從後端到前端的轉換流程 |
| RLS 被拒錯誤處理 | RLS Rejection Error Handling | 處理行級安全拒絕存取的特殊錯誤情況 |

---

## 📦 匯出規範

| 中文 | English | 說明 |
|------|---------|------|
| Barrel File 匯出規範 | Barrel File Export Rules | 使用 index.ts 統一管理模組匯出 |
| 公開介面邊界 | Public API Boundary | 明確定義模組對外公開的介面 |
| Domain 只能匯出 index.ts | Domain must expose only index.ts | 網域模組僅透過 index.ts 對外暴露 |
| Feature 僅公開 Facade | Feature exposes only Facade | 功能模組只公開門面層，隱藏內部實作 |
| Infrastructure 不可匯出 Repository | Infrastructure must not expose Repository | 基礎設施層不直接暴露儲存庫實作 |

---

## 🔐 環境管理與密鑰安全

| 中文 | English | 說明 |
|------|---------|------|
| 多環境設定 | Multi-environment configuration | 支援開發、測試、生產等多環境配置 |
| Build 時注入金鑰 | Inject keys at build time | 敏感資訊在建置時注入，不寫入程式碼 |
| anon key 不可放在程式碼中 | anon key must not be stored in code | 匿名金鑰需透過環境變數管理，避免洩漏 |
| MCP schema / dto 版本管理 | MCP schema/dto versioning | MCP 相關的 schema 與 DTO 需進行版本控制 |
| 集中式 Config 管理 | Centralized configuration management | 統一管理所有配置資訊，便於維護 |

---

## 🔧 技術架構組件

| 中文 | English | 說明 |
|------|---------|------|
| Vertical Slice Architecture | Vertical Slice Architecture | 垂直切片架構，適用於功能模組 |
| 邏輯容器 | Logic Container | 封裝業務邏輯的容器元件 |
| Shell Component | Shell Component | 智慧型元件，負責資料與邏輯處理 |
| 資料隔離 | Data Isolation | 不同模組間的資料隔離機制 |
| 上下文共享 | Context Sharing | 在模組間共享上下文資訊 |
| 多模組擴展 | Multi-module Extension | 支援多個模組擴展的架構設計 |
| 工作區上下文切換器 | Workspace Context Switcher | 切換不同工作區上下文的元件 |
| 個人工作區 | Personal Workspace (USER) | 使用者個人的工作區 |
| 組織工作區 | Organization Workspace | 組織層級的工作區 |
| 團隊工作區 | Team Workspace | 團隊專屬的工作區 |
| 機器人工作區 | Bot Workspace | 機器人自動化任務的工作區 |
| 藍圖 Shell | Blueprint Shell | 藍圖功能的 Shell 元件 |
| 任務樹狀圖 | Task Tree View | 以樹狀結構顯示任務的視圖 |
| 任務表格視圖 | Task Table View | 以表格形式顯示任務的視圖 |
| 視圖切換 | View Switching | 在不同視圖間切換的功能 |
| 日誌列表 | Diary List | 顯示施工日誌的列表元件 |
| 待辦列表 | Todo List | 顯示待辦事項的列表元件 |

---

# [Phase 3] 技術基礎與實踐

> **階段說明**：建立技術實現的基礎建設，包括 Angular 技術實踐、型別安全、測試等。

---

## 🔧 Angular 企業級技術實踐

### RxJS 訂閱管理與記憶體洩漏預防

| 中文 | English | 說明 |
|------|---------|------|
| RxJS 訂閱生命週期管理 | RxJS Subscription Lifecycle Management | 管理 Observable 訂閱的完整生命週期 |
| 記憶體洩漏預防 | Memory Leak Prevention | 防止未取消訂閱導致的記憶體洩漏 |
| takeUntil 模式 | takeUntil Pattern | 使用 takeUntil 操作符自動取消訂閱的標準模式 |
| takeUntilDestroyed (Angular 16+) | takeUntilDestroyed Operator | Angular 16+ 提供的自動取消訂閱操作符 |
| DestroyRef (Angular 16+) | DestroyRef Service | Angular 16+ 的銷毀參考服務 |
| async pipe 優先原則 | Async Pipe First Principle | 優先使用 async pipe 避免手動訂閱 |
| 訂閱洩漏檢測 | Subscription Leak Detection | 檢測未正確取消的訂閱 |
| Zombie 訂閱 | Zombie Subscriptions | 看似完成但仍會意外發送事件的訂閱 |
| 禁止在 ngOnInit 中裸訂閱 | No Naked Subscriptions in ngOnInit | ngOnInit 中的訂閱必須有取消機制 |
| 服務層訂閱管理 | Service Layer Subscription Management | providedIn: 'root' 服務中的訂閱管理規範 |
| Subject 完成機制 | Subject Completion Pattern | 使用 Subject.complete() 釋放資源 |

### 效能優化與變更檢測

| 中文 | English | 說明 |
|------|---------|------|
| OnPush 變更檢測策略 | OnPush Change Detection Strategy | 使用 OnPush 減少變更檢測次數 |
| trackBy 函數必須使用 | trackBy Function Required for ngFor | ngFor 必須使用 trackBy 避免不必要的重繪 |
| 純管道優先 | Pure Pipes First | 優先使用純管道以利用快取機制 |
| 避免範本中的函數呼叫 | Avoid Function Calls in Templates | 範本中避免函數呼叫，會在每次變更檢測時執行 |
| 計算屬性快取 | Computed Property Caching | 快取計算結果避免重複運算 |
| Virtual Scrolling | Virtual Scrolling | 大量資料列表使用虛擬滾動 |
| 圖片懶載入 | Image Lazy Loading | 圖片延遲載入以提升初始載入速度 |
| Zone Pollution 防範 | Zone Pollution Prevention | 避免不必要的 Zone 觸發 |
| runOutsideAngular | runOutsideAngular | 在 Angular Zone 外執行高頻操作 |

### Bundle 大小優化

| 中文 | English | 說明 |
|------|---------|------|
| Tree Shaking 優化 | Tree Shaking Optimization | 移除未使用的程式碼 |
| 動態導入 | Dynamic Imports | 使用動態導入分割程式碼 |
| 第三方套件審查 | Third-party Package Audit | 定期審查第三方套件大小與必要性 |
| Webpack Bundle Analyzer | Webpack Bundle Analyzer | 分析 bundle 組成找出優化空間 |
| 死程式碼偵測 | Dead Code Detection | 偵測並移除未使用的程式碼 |
| 禁止循環依賴 | No Circular Dependencies | 循環依賴導致 bundle 膨脹 |
| moment.js 替代方案 | Replace moment.js | 使用輕量級替代方案如 date-fns |

### 型別安全與編譯時檢查

| 中文 | English | 說明 |
|------|---------|------|
| 嚴格模式啟用 | Strict Mode Enabled | tsconfig.json 啟用 strict: true |
| 禁用 any 類型 | No Implicit Any | 禁止使用 any，使用 unknown 替代 |
| 型別守衛 | Type Guards | 使用型別守衛確保執行時型別安全 |
| 泛型約束 | Generic Constraints | 為泛型添加適當約束 |
| 非空斷言審查 | Non-null Assertion Review | 審慎使用非空斷言操作符 (!) |
| 列舉 vs 聯合型別 | Enums vs Union Types | 優先使用聯合型別而非列舉 |
| as const 斷言 | as const Assertion | 使用 as const 獲得更精確的型別推斷 |

### 測試覆蓋率與品質

| 中文 | English | 說明 |
|------|---------|------|
| 單元測試覆蓋率門檻 | Unit Test Coverage Threshold | 設定最低測試覆蓋率要求（如 80%） |
| 整合測試策略 | Integration Test Strategy | 關鍵業務流程的整合測試 |
| E2E 測試 | End-to-End Testing | 使用 Playwright/Cypress 進行 E2E 測試 |
| 測試金字塔 | Test Pyramid | 遵循測試金字塔原則分配測試資源 |
| Mock 策略 | Mocking Strategy | 統一的 Mock 資料與服務策略 |
| 測試隔離 | Test Isolation | 確保測試間相互獨立 |
| 快照測試 | Snapshot Testing | 使用快照測試防止非預期的 UI 變更 |

---

## 🌐 Supabase 服務

| 中文 | English | 說明 |
|------|---------|------|
| PostgreSQL Database | PostgreSQL Database | Supabase 基於 PostgreSQL 資料庫 |
| 關聯式資料庫 | Relational Database | 使用關聯式資料庫模型 |
| ACID 保證 | ACID Guarantee | 保證資料交易的 ACID 特性 |
| 索引優化 | Index Optimization | 透過索引優化查詢效能 |
| Foreign Keys | Foreign Keys | 外鍵約束確保資料完整性 |
| Database Triggers | Database Triggers | 資料庫觸發器自動執行邏輯 |
| Materialized Views | Materialized Views | 物化視圖提升查詢效能 |
| Supabase Storage | Supabase Storage | Supabase 提供的物件儲存服務 |
| 物件儲存 | Object Storage | 用於儲存檔案與媒體 |
| Bucket 管理 | Bucket Management | 管理儲存桶的設定與權限 |
| 存取控制 | Access Control | 控制儲存桶的存取權限 |
| Realtime | Realtime | Supabase 即時資料同步服務 |
| WebSocket 連接 | WebSocket Connection | 透過 WebSocket 建立即時連接 |
| Database 變更訂閱 | Database Change Subscription | 訂閱資料庫變更事件 |
| Broadcast 廣播 | Broadcast | 廣播訊息給所有連線用戶 |
| Presence 狀態 | Presence Status | 追蹤使用者的在線狀態 |
| Edge Functions | Edge Functions | Supabase 邊緣函數服務 |
| Deno Runtime | Deno Runtime | 使用 Deno 執行環境 |
| 無伺服器運算 | Serverless Computing | 無需管理伺服器的運算模式 |
| 第三方 API 整合 | Third-party API Integration | 整合第三方 API 服務 |
| 背景任務 | Background Task | 執行背景處理任務 |

---

## 🧑‍💻 開發者體驗（DX）與上手文件

| 中文 | English | 說明 |
|------|---------|------|
| Local 開發流程 | Local Dev Setup | 提供一鍵啟動、環境變數範例與常見問題（README / scripts） |
| 環境啟動步驟 | Environment Startup Steps | 明確列出開發 / staging / production 啟動步驟與檢查清單 |
| 貢獻指南 | Contribution Guide | PR 流程、程式碼審查標準、commit message 規範 |
| 程式碼審查守則 | Code Review Guidelines | 審查重點清單（可讀性、測試、安安/效能/安全檢查） |

---

# [Phase 4] 核心業務功能

> **階段說明**：開發核心業務邏輯與功能模組，包括業務領域概念、角色權限、工作流程等。

---

## 🎯 業務領域概念

| 中文 | English | 說明 |
|------|---------|------|
| 工地施工進度追蹤管理系統 | Construction Site Management System | 本系統的核心業務領域 |
| 工作區上下文切換 | Workspace Context Switching | 在不同工作區（個人/組織）間切換上下文 |
| 藍圖邏輯容器 | Blueprint Logic Container | 藍圖作為業務邏輯的邊界容器 |
| 主分支 | Main Branch | 專案的主要分支，類似 Git 主分支概念 |
| 組織分支 | Organization Branch | 組織層級的分支，可包含多個專案 |
| Fork 機制 | Fork Mechanism | 分支複製機制，用於專案衍生 |
| Pull Request | Pull Request (PR) | 分支合併請求，用於審查與整合 |
| 承攬關係 | Contractor Relationship | 承包商與發包方的業務關係 |
| 任務樹狀結構 | Task Tree Structure | 任務以樹狀結構組織，支援父子關係 |
| 任務膠囊狀態 | Task Capsule Status | 任務的封裝狀態，包含完整資訊 |
| 暫存區 | Staging Area | 任務完成後暫存，等待驗收的區域 |
| 48 小時可撤回 | 48-hour Reversible Period | 任務完成後 48 小時內可撤回 |
| 每日施工日誌 | Daily Construction Diary | 記錄每日施工狀況的日誌功能 |
| 品質驗收 | Quality Acceptance | 任務完成後的品質驗收流程 |
| 品質檢查清單 | Quality Checklist | 驗收時使用的檢查項目清單 |
| 問題追蹤 | Issue Tracking | 追蹤與管理施工過程中的問題 |
| 跨分支同步 | Cross-branch Synchronization | 不同分支間的資料同步機制 |
| 討論區 | Discussion Forum | 提供專案討論與協作的論壇功能 |
| 通知中心 | Notification Center | 集中管理所有通知訊息的中心 |
| 待辦中心 | Todo Center | 管理待辦事項的中心 |
| 五狀態分類 | Five Status Categories | 任務的五種狀態分類系統 |
| 活動記錄 | Activity Log | 記錄系統中所有活動的日誌 |
| 文件管理 | Document Management | 管理專案相關文件的系統 |
| 版本控制 | Version Control | 文件與資料的版本管理機制 |
| 軟刪除 | Soft Delete | 標記刪除而非實際刪除資料 |
| 圖片縮圖 | Image Thumbnail | 為上傳圖片自動生成縮圖 |

---

## 👥 角色與權限

| 中文 | English | 說明 |
|------|---------|------|
| 平台層級角色 | Platform-level Roles | 系統平台層級的角色定義 |
| 藍圖層級角色 | Blueprint-level Roles | 專案藍圖層級的角色定義 |
| 超級管理員 | Super Admin | 擁有系統最高權限的管理員 |
| 組織擁有者 | Organization Owner | 組織的擁有者，擁有組織最高權限 |
| 組織管理員 | Organization Admin | 組織的管理員，可管理組織設定 |
| 一般用戶 | User | 系統的一般使用者 |
| 專案經理 | Project Manager | 負責專案管理的角色 |
| 工地主任 | Site Director | 負責工地現場管理的角色 |
| 施工人員 | Worker | 執行施工任務的人員 |
| 品管人員 | QA Staff | 負責品質檢查與驗收的人員 |
| 觀察者 | Observer | 僅能查看，無法修改的觀察者角色 |
| 自訂角色 | Custom Role | 可自訂權限的彈性角色 |
| 權限存取矩陣 | Permission Access Matrix | 定義角色與權限對應關係的矩陣 |

---

## 📊 資料與狀態

| 中文 | English | 說明 |
|------|---------|------|
| 任務狀態 | Task Status | 任務當前的狀態標記 |
| 待處理 | Pending / TODO | 任務已建立但尚未開始 |
| 進行中 | In Progress | 任務正在執行中 |
| 暫存中 | Staging | 任務完成，暫存等待驗收 |
| 品管中 | In QA | 任務進入品質檢查階段 |
| 驗收中 | In Acceptance | 任務正在進行驗收流程 |
| 已完成 | Completed / Done | 任務已完成並通過驗收 |
| 已取消 | Cancelled | 任務已被取消 |
| 任務優先級 | Task Priority | 任務的重要程度等級 |
| 最低/低/中/高/最高 | Lowest / Low / Medium / High / Highest | 優先級的五個等級 |
| 任務類型 | Task Type | 任務的分類類型 |
| 任務/里程碑/錯誤/功能/改進 | Task / Milestone / Bug / Feature / Improvement | 任務類型的具體分類 |
| 進度百分比 | Progress Percentage | 任務完成的百分比進度 |
| 完工圖片 | Completion Photos | 任務完成時上傳的圖片 |
| 任務指派 | Task Assignment | 將任務指派給特定人員 |
| 負責人 | Assignee | 任務的主要負責人 |
| 協作人員 | Collaborators | 參與任務協作的人員 |

---

## 🔄 工作流程

| 中文 | English | 說明 |
|------|---------|------|
| 任務建立 | Task Creation | 建立新任務的流程 |
| 任務更新 | Task Update | 更新任務資訊的流程 |
| 任務刪除 | Task Deletion | 刪除任務的流程（通常為軟刪除） |
| 任務拖拉排序 | Task Drag & Drop Sorting | 透過拖拉方式調整任務順序 |
| 進度更新 | Progress Update | 更新任務進度的操作 |
| 進度自動彙總 | Automatic Progress Aggregation | 子任務進度自動彙總到父任務 |
| 進度儀表板 | Progress Dashboard | 顯示整體進度的儀表板 |
| 計劃 vs 實際進度 | Planned vs Actual Progress | 比較計劃與實際進度的功能 |
| 里程碑追蹤 | Milestone Tracking | 追蹤專案里程碑的達成狀況 |
| 進度風險預警 | Progress Risk Alert | 當進度落後時發出預警 |
| 驗收流程 | Acceptance Process | 任務完成後的驗收流程 |
| 驗收申請 | Acceptance Request | 申請進行驗收的操作 |
| 驗收判定 | Acceptance Judgment | 驗收人員判定驗收結果 |
| 通過/不通過/有條件通過 | Passed / Failed / Conditional Pass | 驗收結果的三種狀態 |
| 串驗收 | Chain Acceptance | 多個任務串聯的驗收流程 |
| 問題開立 | Issue Creation | 建立問題追蹤單 |
| 問題指派 | Issue Assignment | 將問題指派給處理人員 |
| 問題處理 | Issue Handling | 處理問題的流程 |
| 問題關閉 | Issue Closure | 關閉已解決的問題 |

---

## 🧑‍💻 UI 與業務實作

| 中文 | English | 說明 |
|------|---------|------|
| 藍圖建立按鈕缺失 | Missing "Create Blueprint" button | 藍圖列表頁面缺少建立新藍圖的按鈕 |
| 任務 CRUD 實作 | Task CRUD implementation | 任務的建立、讀取、更新、刪除功能實作 |
| 企業級 @delon/form modal | Enterprise-standard @delon/form modal | 使用 @delon/form 建立符合企業標準的表單彈窗 |
| 依據專案命名規範開發 | Follow project naming conventions | 開發時需遵循專案既定的命名規範 |
| 不做任何修改，先分析問題 | Analyze first, modify later | 遇到問題時先分析，確認後再進行修改 |

---

## 📁 檔案與儲存

| 中文 | English | 說明 |
|------|---------|------|
| Supabase Storage | Supabase Storage | Supabase 提供的物件儲存服務 |
| Storage Buckets | Storage Buckets | 儲存桶，用於組織檔案 |
| 檔案上傳 | File Upload | 上傳檔案到儲存系統 |
| 批次上傳 | Batch Upload | 一次上傳多個檔案 |
| 檔案分類 | File Classification | 對檔案進行分類管理 |
| 檔案標籤 | File Tags | 為檔案添加標籤以便搜尋 |
| 資料夾結構 | Folder Structure | 檔案的資料夾組織結構 |
| 檔案版本控制 | File Version Control | 管理檔案的不同版本 |
| 檔案預覽 | File Preview | 在瀏覽器中預覽檔案內容 |
| 存取權限控制 | Access Permission Control | 控制檔案的存取權限 |
| 下載記錄追蹤 | Download Record Tracking | 記錄檔案的下載歷史 |
| CDN 加速 | CDN Acceleration | 使用 CDN 加速檔案存取 |
| 自動縮圖生成 | Automatic Thumbnail Generation | 上傳圖片時自動生成縮圖 |
| 大檔案分片上傳 | Large File Chunk Upload | 將大檔案分片後上傳 |
| EXIF 資訊 | EXIF Information | 圖片檔案的 EXIF 元資料 |
| 照片壓縮 | Image Compression | 上傳前壓縮照片以節省空間 |
| 離線暫存 | Offline Cache | 離線時暫存檔案資料 |

---

## 🔔 通知與協作

| 中文 | English | 說明 |
|------|---------|------|
| 即時通知 | Real-time Notification | 使用 WebSocket 即時推送通知 |
| 站內通知 | In-app Notification | 應用程式內的通知訊息 |
| Email 通知 | Email Notification | 透過電子郵件發送通知 |
| 推播通知 | Push Notification | 瀏覽器推播通知 |
| 通知規則 | Notification Rules | 定義通知觸發的規則 |
| 通知訂閱 | Notification Subscription | 使用者訂閱特定通知類型 |
| 已讀管理 | Read Status Management | 管理通知的已讀/未讀狀態 |
| 留言功能 | Comment Function | 在任務或討論中留言 |
| 巢狀回覆 | Nested Reply | 支援多層級的留言回覆 |
| @提及功能 | @Mention Function | 使用 @ 提及特定使用者 |
| 即時訊息 | Real-time Message | 即時通訊功能 |
| Realtime 廣播 | Realtime Broadcast | 使用 Supabase Realtime 廣播訊息 |
| 已讀狀態 | Read Status | 訊息的已讀狀態標記 |

---

## 📈 報表與分析

| 中文 | English | 說明 |
|------|---------|------|
| 進度報表 | Progress Report | 顯示專案進度狀況的報表 |
| 品質報表 | Quality Report | 顯示品質檢查結果的報表 |
| 工時報表 | Work Hours Report | 統計工作時數的報表 |
| 統計報表 | Statistical Report | 各種統計數據的報表 |
| 報表匯出 | Report Export | 將報表匯出為檔案 |
| PDF 格式 | PDF Format | 以 PDF 格式匯出報表 |
| Excel 格式 | Excel Format | 以 Excel 格式匯出報表 |
| 報表排程 | Report Scheduling | 定期自動產生報表 |
| 報表訂閱 | Report Subscription | 訂閱特定報表定期接收 |
| 數據分析 | Data Analysis | 對專案數據進行分析 |
| 圖表視覺化 | Chart Visualization | 以圖表方式呈現數據 |
| 分析快取 | Analytics Cache | 快取分析結果以提升效能 |
| 預計算報表 | Pre-computed Report | 預先計算報表數據 |
| 多層級聚合 | Multi-level Aggregation | 多層級的數據聚合計算 |

---

## ⚙️ 系統管理

| 中文 | English | 說明 |
|------|---------|------|
| 系統設定 | System Settings | 系統層級的設定選項 |
| 全域設定 | Global Settings | 應用程式全域的設定 |
| 專案設定 | Project Settings | 專案層級的設定 |
| 個人偏好 | Personal Preferences | 使用者的個人偏好設定 |
| 功能開關 | Feature Flags | 控制功能啟用/停用的開關 |
| 灰度發布 | Gray Release | 逐步釋出新功能給部分使用者 |
| A/B 測試 | A/B Testing | 同時測試不同版本的功能 |
| 天氣整合 | Weather Integration | 整合天氣資訊到日誌系統 |
| 機器人系統 | Bot System | 自動化機器人系統 |
| 定期報表機器人 | Scheduled Report Bot | 定期產生報表的機器人 |
| 通知機器人 | Notification Bot | 自動發送通知的機器人 |
| 備份機器人 | Backup Bot | 自動執行備份的機器人 |
| 任務佇列 | Task Queue | 管理背景任務的佇列 |
| 執行日誌 | Execution Log | 記錄系統執行的日誌 |
| 備份還原 | Backup & Restore | 資料備份與還原功能 |
| 自動化備份 | Automated Backup | 自動執行備份的機制 |

---

# [Phase 5] 品質保證與安全

> **階段說明**：建立品質控制機制與安全防護措施，確保系統安全與品質。

---

## 🔐 Security（資安）全面策略

| 中文 | English | 說明 |
|------|---------|------|
| 秘密管理與輪換 | Secret Management & Rotation | 使用集中式金鑰管理（如 Vault / AWS Secrets Manager），定期輪換、存取稽核與最小權限存取 |
| 軟體組件分析 (SCA) | Software Composition Analysis (SCA) | 定期掃描相依性漏洞、使用 SBOM、建立升級與否決策略 |
| 靜態/動態安全測試 | SAST / DAST | 將 SAST 集成在 PR 檢查，DAST 在 staging 執行，回歸測試列入 CI 流程 |
| 威脅建模 | Threat Modeling | 定期對關鍵服務/邊界執行威脅建模並記錄風險與緩解措施 |
| 事件應變與稽核 | Incident Response & Audit | 建立事件分級、通報流程、回溯稽核機制與演練頻率 |
| 最小權限與 RBAC | Least Privilege & RBAC | 服務/資料庫/存取皆採最小權限與角色化存取控制 |

---

## 🔒 前端安全性最佳實踐

| 中文 | English | 說明 |
|------|---------|------|
| XSS 防護 | XSS Protection | 跨站腳本攻擊防護 |
| CSRF 防護 | CSRF Protection | 跨站請求偽造防護 |
| 內容安全策略 | Content Security Policy (CSP) | 設定 CSP 標頭限制資源載入 |
| 敏感資料不可存於前端 | No Sensitive Data in Frontend | 敏感資料不可存在前端程式碼或 localStorage |
| JWT 安全管理 | JWT Secure Management | JWT token 的安全儲存與傳輸 |
| 輸入驗證與淨化 | Input Validation and Sanitization | 所有使用者輸入必須驗證與淨化 |
| 依賴套件漏洞掃描 | Dependency Vulnerability Scanning | 定期掃描依賴套件漏洞（npm audit） |

---

## 🔒 Compliance / 隱私與資料治理

| 中文 | English | 說明 |
|------|---------|------|
| 隱私政策 | Privacy Policy | 定義 PII 類別、處理目的與使用者權利 |
| PII 處理 | PII Handling | 分級保護、最小蒐集、加密與匿名化策略 |
| 法規遵循 | Regulatory Compliance | 列出適用法規（如 GDPR）與對應執行要點 |
| 資料保留政策 | Data Retention Policy | 定義不同資料類型的保存期限與刪除流程 |

---

## 🔧 程式碼品質自動化檢查

| 中文 | English | 說明 |
|------|---------|------|
| 程式碼複雜度檢查 | Code Complexity Check | 檢查圈複雜度，限制函數複雜度 |
| 技術債務標記 | Technical Debt Tagging | 使用統一標記（如 // TECH_DEBT:） |
| 重複程式碼檢測 | Duplicate Code Detection | 偵測並消除重複程式碼 |
| SonarQube 整合 | SonarQube Integration | 整合 SonarQube 進行程式碼品質分析 |
| 認知複雜度限制 | Cognitive Complexity Limit | 限制函數的認知複雜度 |
| 程式碼審查檢查清單 | Code Review Checklist | 標準化的程式碼審查檢查清單 |
| Pre-commit Hooks | Pre-commit Hooks | 提交前自動執行檢查（lint、test、format） |

---

# [Phase 6] 運維、監控與優化

> **階段說明**：建立生產環境的監控、可觀察性與持續優化機制。

---

## 📈 Observability / SRE（可觀察性）

| 中文 | English | 說明 |
|------|---------|------|
| 指標 / Metrices | Metrics | 定義關鍵 SLI/SLO（例如 API 延遲、錯誤率、可用性）並設定收集與保存策略 |
| 分佈式追蹤 | Distributed Tracing | 使用 OpenTelemetry / Jaeger 追蹤跨服務呼叫，定義 trace 標準與採樣策略 |
| 日誌格式與保存 | Log Format & Retention | 統一結構化日誌（JSON）、定義保留週期與存取權限 |
| 告警策略 | Alerting Strategy | 根據 SLO 設定告警分級、抑制與回復流程 |
| SLA / SLI 定義 | SLA / SLI | 定義對外 SLA（若有），內部 SLI 作為效能可靠性衡量指標 |

---

## ⚡ Performance & Scalability（效能與可擴展性）

| 中文 | English | 說明 |
|------|---------|------|
| 性能目標 | Performance Targets | 定義延遲、吞吐、資源使用等目標與衡量方法 |
| 效能測試流程 | Performance Testing | 建立負載/壓力/效能測試流程與自動化腳本（CI 時段化執行） |
| 快取策略 | Caching Strategy | 定義快取層（CDN / Redis）、失效策略與一致性保證 |
| 容量規劃 | Capacity Planning | 預估流量、設定 auto-scaling 規則與成本/效能平衡指標 |

---

## 🔗 API 與 Contract 管理

| 中文 | English | 說明 |
|------|---------|------|
| OpenAPI 規格 | OpenAPI Specification | 所有 HTTP API 提供 OpenAPI 規格並納入版本控制 |
| 版本策略 | Versioning Strategy | 明確的版本號與向後相容策略（minor vs major 的變化規則） |
| 契約測試 | Contract Testing | 使用契約測試（如 Pact）驗證前後端/服務契約的一致性 |
| 向後相容政策 | Backwards Compatibility Policy | 小幅改動保持向後相容，破壞性變更需公告與遷移計畫 |

---

## 🧑‍💻 前端監控與可觀察性

| 中文 | English | 說明 |
|------|---------|------|
| 錯誤追蹤 | Error Tracking | 使用 Sentry 等工具追蹤生產環境錯誤 |
| 效能監控 | Performance Monitoring | 監控應用效能指標（FCP, LCP, CLS） |
| 使用者行為分析 | User Behavior Analytics | 分析使用者使用模式 |
| 日誌等級管理 | Log Level Management | 不同環境使用不同日誌等級 |
| Source Map 管理 | Source Map Management | 生產環境 Source Map 的安全管理 |

---

## 🚀 CI/CD 與 DevOps

| 中文 | English | 說明 |
|------|---------|------|
| 自動化建置流程 | Automated Build Pipeline | 完整的自動化建置與測試流程 |
| 品質門檻 | Quality Gates | 設定必須通過的品質門檻 |
| 自動化部署 | Automated Deployment | 自動化部署流程避免人為錯誤 |
| 回滾機制 | Rollback Mechanism | 快速回滾到前一版本的機制 |
| 環境一致性 | Environment Consistency | 確保開發、測試、生產環境一致 |
| 建置快取策略 | Build Cache Strategy | 優化建置時間的快取策略 |

---

## 📘 文件與知識管理

| 中文 | English | 說明 |
|------|---------|------|
| ADR (架構決策記錄) | Architecture Decision Records | 記錄重要架構決策及其背景 |
| API 文件自動生成 | API Documentation Auto-generation | 使用 Compodoc 自動生成 API 文件 |
| 變更日誌 | Changelog | 維護結構化的變更日誌（CHANGELOG.md） |
| 故障排除指南 | Troubleshooting Guide | 常見問題的故障排除文件 |
| 新人入職指南 | Onboarding Guide | 新成員快速上手的完整指南 |
| 程式碼註解規範 | Code Comment Guidelines | 何時需要註解，何時應重構 |
| 藍圖功能缺口分析 | Blueprint Gap Analysis | 分析藍圖功能實作缺口與待辦事項 |
| 共享上下文 | Shared Context | 專案共享的上下文資訊與知識庫 |
| 企業級開發指南 | Angular Enterprise Development Guidelines | Angular 企業級開發規範與最佳實務 |
| 日誌設計指南 | diary-design.md | 施工日誌功能的設計文件 |
| 待辦設計指南 | todo-design.md | 待辦功能模組的設計文件 |
| 當前任務文件 | TASK_NOW.md | 記錄當前進行中的任務與狀態 |

---

**最後更新**：2025-11-27
