# GigHub 架構健康檢查與治理評估報告

## Executive Summary

本報告針對 GigHub 工地施工進度追蹤管理系統進行全面的架構健康檢查，基於最新的多租戶 SaaS 資料庫架構設計（`20251129000001_create_multi_tenant_saas_schema.sql`）進行分析。

### 評估範圍
- 企業架構治理
- 技術債務評估
- 合規性檢查
- 現有架構分析
- 目標架構設計
- 遷移策略規劃
- 文件一致性檢查

---

## 1. System Context Diagram

```mermaid
C4Context
    title GigHub 系統上下文圖

    Person(user, "使用者", "工地管理人員、施工人員、品管人員")
    Person(admin, "組織管理員", "組織與藍圖管理")
    Person(superadmin, "超級管理員", "平台層級管理")
    
    System(gighub, "GigHub 系統", "工地施工進度追蹤管理系統")
    
    System_Ext(supabase, "Supabase Backend", "BaaS - 認證、資料庫、即時訂閱、儲存")
    System_Ext(email, "Email Service", "通知郵件服務")
    System_Ext(storage, "Cloud Storage", "檔案與附件儲存")
    
    Rel(user, gighub, "使用", "HTTPS")
    Rel(admin, gighub, "管理", "HTTPS")
    Rel(superadmin, gighub, "系統管理", "HTTPS")
    
    Rel(gighub, supabase, "API 呼叫", "REST/Realtime WebSocket")
    Rel(gighub, email, "發送通知", "SMTP/API")
    Rel(gighub, storage, "檔案操作", "S3 API")
```

### 說明
- **使用者類型**：系統支援多種角色，從一般施工人員到超級管理員
- **核心系統**：GigHub 前端應用（Angular 20）
- **後端服務**：完全依賴 Supabase 提供的 BaaS 服務
- **外部整合**：郵件通知和雲端儲存服務

---

## 2. Component Architecture Diagram

```mermaid
flowchart TB
    subgraph Frontend["Angular 20 前端應用"]
        subgraph CoreLayer["Core Layer (核心層)"]
            AuthService["認證服務"]
            I18nService["國際化服務"]
            StartupService["啟動服務"]
            NetServices["網路服務層"]
        end
        
        subgraph FeatureLayer["Feature Layer (功能層)"]
            BlueprintFeature["藍圖功能模組"]
            TaskFeature["任務功能模組"]
            DiaryFeature["施工日誌模組"]
            ChecklistFeature["品質驗收模組"]
        end
        
        subgraph SharedLayer["Shared Layer (共享層)"]
            Components["共用元件"]
            Pipes["管道"]
            Directives["指令"]
            Utils["工具函數"]
        end
        
        subgraph DataAccess["Data Access Layer"]
            Repositories["Repositories"]
            Stores["Signal Stores"]
            Services["Business Services"]
        end
    end
    
    subgraph Backend["Supabase Backend"]
        subgraph AuthLayer["認證層"]
            SupabaseAuth["Supabase Auth"]
        end
        
        subgraph DatabaseLayer["資料庫層"]
            PostgreSQL["PostgreSQL"]
            RLS["Row Level Security"]
        end
        
        subgraph RealtimeLayer["即時層"]
            RealtimeEngine["Realtime Engine"]
        end
        
        subgraph StorageLayer["儲存層"]
            SupabaseStorage["Supabase Storage"]
        end
    end
    
    CoreLayer --> DataAccess
    FeatureLayer --> DataAccess
    SharedLayer --> FeatureLayer
    
    DataAccess --> Backend
```

### 架構設計決策

| 層級 | 職責 | 設計原則 |
|------|------|----------|
| Core Layer | 全域服務、認證、啟動邏輯 | 單例模式、全域可用 |
| Feature Layer | 業務功能模組 | 垂直切片、懶載入 |
| Shared Layer | 可重用元件與工具 | DRY 原則、低耦合 |
| Data Access | 資料存取抽象 | Repository 模式 |

---

## 3. Database Schema Architecture

```mermaid
erDiagram
    accounts ||--o{ organization_members : "has"
    accounts ||--o{ blueprints : "owns"
    accounts ||--o{ blueprint_members : "participates"
    accounts ||--o{ team_members : "belongs to"
    
    organizations ||--o{ organization_members : "has"
    organizations ||--o{ teams : "contains"
    organizations ||--o{ blueprints : "owns"
    
    teams ||--o{ team_members : "has"
    
    blueprints ||--o{ blueprint_members : "has"
    blueprints ||--o{ blueprint_roles : "defines"
    blueprints ||--o{ tasks : "contains"
    blueprints ||--o{ diaries : "records"
    blueprints ||--o{ checklists : "uses"
    
    tasks ||--o{ task_attachments : "has"
    tasks ||--o{ task_comments : "has"
    tasks ||--o{ task_acceptances : "undergoes"
    tasks ||--o{ task_history : "tracks"
    
    diaries ||--o{ diary_attachments : "has"
    
    checklists ||--o{ checklist_items : "contains"
    
    accounts {
        uuid id PK
        enum account_type "user|organization|bot"
        text email
        text display_name
        jsonb profile
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    organizations {
        uuid id PK
        text name
        text slug UK
        jsonb settings
        text plan
        timestamp created_at
    }
    
    blueprints {
        uuid id PK
        uuid owner_id FK
        uuid organization_id FK
        text name
        text description
        enum status
        jsonb settings
        timestamp created_at
    }
    
    tasks {
        uuid id PK
        uuid blueprint_id FK
        uuid parent_id FK
        text title
        text description
        enum status
        enum priority
        integer sort_order
        date due_date
        timestamp created_at
    }
```

### 新 Schema 關鍵變更

1. **統一帳戶模型** (`accounts` 表)
   - 合併 User、Organization、Bot 為單一多態表
   - 使用 `account_type` 枚舉區分類型
   - 支援軟刪除 (`deleted_at`)

2. **組織層級結構**
   - `organizations` 表獨立管理組織設定
   - `organization_members` 處理用戶-組織關係
   - `teams` 支援組織內團隊劃分

3. **藍圖核心模型**
   - 支援個人與組織擁有權
   - 完整的成員角色系統
   - 可擴展的設定 (JSONB)

---

## 4. Data Flow Diagram

```mermaid
flowchart LR
    subgraph UserActions["使用者操作"]
        UI[("Angular UI")]
    end
    
    subgraph DataLayer["資料存取層"]
        Store["Signal Store"]
        Repo["Repository"]
    end
    
    subgraph Supabase["Supabase"]
        Auth["Auth Service"]
        DB[("PostgreSQL")]
        RT["Realtime"]
        Storage["Storage"]
    end
    
    UI -->|"使用者輸入"| Store
    Store -->|"狀態更新"| UI
    Store -->|"CRUD 操作"| Repo
    Repo -->|"API 呼叫"| DB
    
    UI -->|"登入/登出"| Auth
    Auth -->|"JWT Token"| UI
    
    RT -->|"即時事件"| Store
    DB -->|"變更通知"| RT
    
    UI -->|"檔案上傳"| Storage
    Storage -->|"檔案 URL"| UI
```

### 資料流程說明

1. **認證流程**
   - 用戶透過 Supabase Auth 進行認證
   - JWT Token 儲存於前端
   - 所有 API 請求附帶 Token

2. **資料操作流程**
   - UI 觸發 Store 方法
   - Store 透過 Repository 呼叫 Supabase API
   - RLS 確保資料安全性
   - 結果更新回 Store，觸發 UI 更新

3. **即時同步流程**
   - 資料庫變更觸發 Realtime 事件
   - 前端訂閱相關頻道
   - 自動更新本地狀態

---

## 5. Deployment Architecture

```mermaid
flowchart TB
    subgraph Production["生產環境"]
        subgraph CDN["CDN Layer"]
            CF["CloudFlare / Vercel Edge"]
        end
        
        subgraph Frontend["前端託管"]
            Vercel["Vercel / Netlify"]
        end
        
        subgraph Backend["Supabase Cloud"]
            SupaAPI["Supabase API Gateway"]
            SupaAuth["Auth Service"]
            SupaDB[("PostgreSQL")]
            SupaRT["Realtime Service"]
            SupaStorage["Storage Service"]
        end
    end
    
    subgraph Development["開發環境"]
        LocalDev["Local Dev Server"]
        SupaLocal["Supabase Local"]
    end
    
    Users((使用者)) --> CF
    CF --> Frontend
    Frontend --> SupaAPI
    SupaAPI --> SupaAuth
    SupaAPI --> SupaDB
    SupaAPI --> SupaRT
    SupaAPI --> SupaStorage
    
    Developer((開發者)) --> LocalDev
    LocalDev --> SupaLocal
```

### 部署策略

| 環境 | 前端 | 後端 | 用途 |
|------|------|------|------|
| Development | localhost:4200 | Supabase Local | 本地開發 |
| Staging | Vercel Preview | Supabase Project (Staging) | 測試驗收 |
| Production | Vercel Production | Supabase Project (Prod) | 正式環境 |

---

## 6. 企業架構治理評估

### 6.1 架構原則遵循度

| 原則 | 狀態 | 說明 |
|------|------|------|
| **單一資料來源** | ✅ 符合 | Supabase 作為唯一後端 |
| **關注點分離** | ✅ 符合 | 三層架構明確分離 |
| **Repository 模式** | ✅ 符合 | 資料存取層封裝良好 |
| **依賴注入** | ✅ 符合 | 使用 Angular DI |
| **最小權限原則** | ⚠️ 部分 | RLS 政策需完善 |

### 6.2 架構治理建議

```mermaid
flowchart TB
    subgraph Governance["架構治理框架"]
        ADR["架構決策記錄 (ADR)"]
        Standards["編碼標準"]
        Review["架構審查流程"]
    end
    
    subgraph Monitoring["監控機制"]
        Metrics["效能指標"]
        Alerts["告警系統"]
        Logging["日誌分析"]
    end
    
    subgraph Quality["品質保證"]
        Testing["自動化測試"]
        Security["安全掃描"]
        CodeReview["程式碼審查"]
    end
    
    Governance --> Monitoring
    Governance --> Quality
```

---

## 7. 技術債務評估

### 7.1 識別的技術債務

| ID | 類型 | 嚴重度 | 描述 | 影響範圍 |
|----|------|--------|------|----------|
| TD-001 | Schema 同步 | 🔴 高 | 前端介面與新 Schema 不一致 | 全域 |
| TD-002 | 文件過時 | 🟡 中 | domain-glossary.md 需更新 | 文件 |
| TD-003 | 類型定義 | 🟡 中 | TypeScript 介面需更新 | 類型安全 |
| TD-004 | RLS 覆蓋 | 🟡 中 | 部分表缺少 RLS 政策 | 安全性 |
| TD-005 | 測試覆蓋 | 🟡 中 | 單元測試覆蓋率不足 | 品質 |

### 7.2 技術債務分佈

```mermaid
pie title 技術債務分佈
    "Schema 同步" : 35
    "文件更新" : 25
    "類型定義" : 20
    "安全性" : 15
    "測試" : 5
```

### 7.3 債務清償優先順序

1. **緊急**：Schema 同步 (影響核心功能)
2. **重要**：RLS 政策完善 (安全性)
3. **一般**：類型定義更新 (開發體驗)
4. **低**：文件更新 (知識傳承)

---

## 8. 合規性檢查

### 8.1 資料保護合規

| 要求 | 狀態 | 實施方式 |
|------|------|----------|
| LGPD 合規 | ✅ 設計中 | 軟刪除、資料保留政策 |
| 資料加密 | ✅ 符合 | Supabase TLS + 靜態加密 |
| 存取控制 | ✅ 符合 | RLS + RBAC |
| 稽核日誌 | ⚠️ 部分 | 需完善 history 表 |

### 8.2 安全合規檢查清單

```markdown
✅ 認證：使用 Supabase Auth (JWT)
✅ 授權：RLS + 自訂角色系統
✅ 傳輸加密：HTTPS/TLS
✅ 靜態加密：Supabase 提供
⚠️ 稽核追蹤：需強化 history 表
⚠️ 密碼政策：需在應用層實施
```

---

## 9. 現有架構分析

### 9.1 架構成熟度評估

```mermaid
radar
    title 架構成熟度雷達圖
```

| 維度 | 分數 (1-5) | 說明 |
|------|------------|------|
| **可擴展性** | 4 | Supabase 支援良好 |
| **安全性** | 3.5 | RLS 基礎完善，需強化 |
| **可維護性** | 4 | 模組化設計良好 |
| **效能** | 3.5 | 需優化查詢與快取 |
| **可觀察性** | 2.5 | 缺乏完整監控 |

### 9.2 架構優勢

1. **現代化技術棧**
   - Angular 20 + Signals 狀態管理
   - Supabase BaaS 降低後端複雜度
   - TypeScript 確保類型安全

2. **清晰的分層架構**
   - Foundation → Container → Business 三層模型
   - Repository 模式封裝資料存取
   - 依賴注入促進可測試性

3. **多租戶支援**
   - 統一帳戶模型支援多種實體
   - 組織/團隊層級隔離
   - 藍圖級別的資料隔離

### 9.3 架構弱點

1. **文件與實作不同步**
2. **部分安全機制未完善**
3. **缺乏完整的監控與可觀察性**
4. **測試覆蓋率待提升**

---

## 10. 目標架構設計

### 10.1 Phase 1: 基礎對齊 (短期 1-2 週)

```mermaid
flowchart TB
    subgraph Phase1["Phase 1: 基礎對齊"]
        A1["更新 TypeScript 介面"]
        A2["同步文件內容"]
        A3["完善 RLS 政策"]
        A4["驗證現有功能"]
    end
    
    A1 --> A2 --> A3 --> A4
```

**目標**：
- 消除 Schema 與程式碼的不一致
- 更新所有相關文件
- 確保安全機制完整

### 10.2 Phase 2: 功能強化 (中期 2-4 週)

```mermaid
flowchart TB
    subgraph Phase2["Phase 2: 功能強化"]
        B1["實作組織管理功能"]
        B2["完善團隊協作"]
        B3["增強稽核追蹤"]
        B4["優化效能"]
    end
    
    B1 --> B2 --> B3 --> B4
```

**目標**：
- 實作新 Schema 支援的功能
- 完善協作與權限機制
- 建立完整稽核軌跡

### 10.3 Phase 3: 成熟化 (長期 1-2 月)

```mermaid
flowchart TB
    subgraph Phase3["Phase 3: 成熟化"]
        C1["建立監控系統"]
        C2["提升測試覆蓋"]
        C3["效能調優"]
        C4["文件完善"]
    end
    
    C1 --> C2 --> C3 --> C4
```

**目標**：
- 建立完整可觀察性
- 達到 80%+ 測試覆蓋率
- 優化使用者體驗

---

## 11. 遷移策略

### 11.1 遷移流程

```mermaid
flowchart LR
    subgraph Migration["遷移策略"]
        M1["分析影響範圍"]
        M2["建立遷移腳本"]
        M3["測試環境驗證"]
        M4["分階段部署"]
        M5["監控與回滾"]
    end
    
    M1 --> M2 --> M3 --> M4 --> M5
```

### 11.2 資料遷移考量

| 項目 | 策略 | 風險等級 |
|------|------|----------|
| 帳戶合併 | 漸進式遷移 | 中 |
| 組織結構 | 新建資料 | 低 |
| 藍圖關聯 | 更新外鍵 | 中 |
| 歷史資料 | 保留並映射 | 低 |

### 11.3 回滾計畫

1. **資料庫備份**：遷移前完整備份
2. **版本標記**：使用 Git tags 標記穩定版本
3. **功能開關**：新功能可透過 Feature Flag 控制
4. **監控告警**：異常自動通知

---

## 12. 文件一致性檢查

### 12.1 需更新的文件清單

| 文件路徑 | 衝突類型 | 優先級 | 說明 |
|----------|----------|--------|------|
| `.github/copilot/domain-glossary.md` | 術語定義 | 🔴 高 | 新增帳戶類型、組織概念 |
| `.github/instructions/gighub-domain-concepts.instructions.md` | 領域概念 | 🔴 高 | 更新核心實體定義 |
| `.github/instructions/gighub-architecture-layers.instructions.md` | 架構層級 | 🟡 中 | 更新資料表對應 |
| `.github/instructions/gighub-supabase-practices.instructions.md` | Supabase 實踐 | 🟡 中 | 新增 RLS 範例 |
| `src/app/features/*/domain/interfaces/` | TypeScript 介面 | 🔴 高 | 同步新 Schema |

### 12.2 術語對照更新

| 舊術語 | 新術語 | Schema 對應 |
|--------|--------|-------------|
| User | Account (type: USER) | `accounts` 表 |
| Organization Account | Account (type: ORGANIZATION) | `accounts` 表 |
| - | Bot Account | `accounts` 表 (type: BOT) |
| Blueprint Owner | Account (owner_id) | `blueprints.owner_id` |

### 12.3 新增概念

根據新 Schema，需要在文件中新增：

1. **帳戶類型枚舉** (`account_type`)
   - `user`: 個人用戶
   - `organization`: 組織帳戶
   - `bot`: 自動化機器人

2. **組織成員角色** (`organization_role`)
   - `owner`: 組織擁有者
   - `admin`: 組織管理員
   - `member`: 一般成員

3. **藍圖成員角色** (`blueprint_role`)
   - `owner`: 藍圖擁有者
   - `admin`: 藍圖管理員
   - `editor`: 編輯者
   - `viewer`: 檢視者

4. **通用狀態枚舉** (`common_status`)
   - `draft`: 草稿
   - `active`: 啟用
   - `archived`: 已歸檔
   - `deleted`: 已刪除

---

## 13. 非功能性需求分析

### 13.1 可擴展性 (Scalability)

| 維度 | 現況 | 目標 | 策略 |
|------|------|------|------|
| 用戶數 | 100+ | 10,000+ | Supabase 自動擴展 |
| 併發連接 | 50 | 500 | Connection pooling |
| 資料量 | GB 級 | TB 級 | 分區、索引優化 |

### 13.2 效能 (Performance)

| 指標 | 當前 | 目標 |
|------|------|------|
| FCP | < 2s | < 1.5s |
| LCP | < 3s | < 2.5s |
| API P95 | < 800ms | < 500ms |
| 資料庫查詢 P95 | < 200ms | < 100ms |

### 13.3 安全性 (Security)

```mermaid
flowchart TB
    subgraph SecurityLayers["安全層級"]
        L1["網路層: TLS/HTTPS"]
        L2["認證層: Supabase Auth + JWT"]
        L3["授權層: RLS + RBAC"]
        L4["應用層: 輸入驗證"]
        L5["資料層: 加密 + 軟刪除"]
    end
    
    L1 --> L2 --> L3 --> L4 --> L5
```

### 13.4 可靠性 (Reliability)

- **SLA 目標**: 99.9% 可用性
- **RPO**: < 1 小時
- **RTO**: < 4 小時
- **備份策略**: Supabase 自動備份

### 13.5 可維護性 (Maintainability)

| 面向 | 實施方式 |
|------|----------|
| 模組化 | 功能模組獨立、懶載入 |
| 文件化 | ADR、API 文件、程式碼註解 |
| 自動化 | CI/CD、自動測試、Lint |
| 監控 | 錯誤追蹤、效能監控 |

---

## 14. 風險與緩解策略

### 14.1 風險矩陣

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|----------|
| Schema 遷移失敗 | 中 | 高 | 漸進式遷移、完整測試 |
| 效能退化 | 中 | 中 | 效能測試、監控告警 |
| 安全漏洞 | 低 | 高 | 安全審計、RLS 強化 |
| 資料遺失 | 低 | 高 | 備份策略、軟刪除 |

### 14.2 風險緩解計畫

```mermaid
flowchart TB
    subgraph RiskMitigation["風險緩解流程"]
        R1["識別風險"]
        R2["評估影響"]
        R3["制定對策"]
        R4["實施監控"]
        R5["定期審查"]
    end
    
    R1 --> R2 --> R3 --> R4 --> R5
    R5 -.-> R1
```

---

## 15. 技術棧建議

### 15.1 當前技術棧

| 層級 | 技術 | 版本 |
|------|------|------|
| 前端框架 | Angular | 20.x |
| UI 元件 | ng-zorro-antd | 20.x |
| 狀態管理 | Angular Signals | Built-in |
| 後端服務 | Supabase | Latest |
| 資料庫 | PostgreSQL | 15+ |
| 樣式 | LESS | - |
| 建構工具 | Angular CLI | 20.x |

### 15.2 建議優化

| 領域 | 建議 | 理由 |
|------|------|------|
| 監控 | 整合 Sentry | 錯誤追蹤 |
| 效能 | 使用 Web Vitals | 效能監控 |
| 測試 | 增加 Playwright E2E | 端到端測試 |
| 文件 | 使用 Compodoc | API 文件自動生成 |

---

## 16. 下一步行動計畫

### 16.1 立即行動 (本週)

- [ ] 審查並確認本評估報告
- [ ] 更新 `domain-glossary.md` 術語定義
- [ ] 更新 `gighub-domain-concepts.instructions.md`
- [ ] 同步 TypeScript 介面定義

### 16.2 短期計畫 (2 週內)

- [ ] 完善 RLS 政策
- [ ] 更新所有相關文件
- [ ] 建立遷移測試環境
- [ ] 執行功能回歸測試

### 16.3 中期計畫 (1 個月內)

- [ ] 實作組織管理功能
- [ ] 完善稽核追蹤機制
- [ ] 建立監控儀表板
- [ ] 提升測試覆蓋率

---

## 17. 附錄

### A. 參考文件

- [Angular 風格指南](https://angular.dev/style-guide)
- [Supabase 文件](https://supabase.com/docs)
- [ng-alain 文件](https://ng-alain.com)
- 專案 KEEP.md 文件

### B. 相關架構決策記錄 (ADR)

建議建立以下 ADR：
1. ADR-001: 統一帳戶模型設計
2. ADR-002: 多租戶資料隔離策略
3. ADR-003: RLS 政策設計原則
4. ADR-004: 軟刪除實施方針

### C. 版本歷史

| 版本 | 日期 | 作者 | 變更說明 |
|------|------|------|----------|
| 1.0 | 2025-11-29 | Architecture Team | 初始版本 |

---

*本文件由 GigHub 架構團隊維護，最後更新：2025-11-29*
