# AGENTS.md - NG-ALAIN Enterprise Project Guidelines

> **核心原則**: 企業化標準 + 奧卡姆剃刀 (Occam's Razor) - 以最簡潔的方式解決問題

---

## 一、專案概述

本專案基於 **NG-ALAIN** 企業級中後台前端框架，整合 **Angular 20+**、**@delon** 和 **ng-zorro-antd**，採用以下架構模式：

- **橫向分層架構**：適用於 `core`、`shared`、`routes`、`layout` 層
- **垂直切片架構**：適用於 `features` 層

---

## 二、技術棧與優先級

### 2.1 UI 元件使用優先級

```
優先級：NG-ZORRO > NG-ALAIN (@delon/abc) > 自行開發
```

| 優先級 | 來源 | 說明 |
|--------|------|------|
| 🥇 1st | `ng-zorro-antd` | Ant Design Angular 實現，基礎 UI 元件 |
| 🥈 2nd | `@delon/abc` | 企業級業務元件 (ST, SE, SV, SF 等) |
| 🥉 3rd | 自行開發 | **僅在上述無法滿足需求時** |

### 2.2 共享導入優先使用

```typescript
// ✅ 優先使用 shared-imports.ts
import { SHARED_IMPORTS } from '@shared';

@Component({
  imports: [...SHARED_IMPORTS],
})
```

詳見：`src/app/shared/shared-imports.ts`

---

## 三、架構模式

### 3.1 橫向分層架構（Horizontal Layered）

適用於：`core`、`shared`、`routes`、`layout`

```
┌─────────────────────────────────────────────┐
│                  layout/                    │ ← 版面配置
├─────────────────────────────────────────────┤
│                  routes/                    │ ← 路由頁面
├─────────────────────────────────────────────┤
│                  shared/                    │ ← 共享資源
├─────────────────────────────────────────────┤
│                   core/                     │ ← 核心服務
└─────────────────────────────────────────────┘
```

### 3.2 垂直切片架構（Vertical Slice）

適用於：`features/`

```
features/
└── blueprint/              ← 功能模組 (Feature)
    ├── data-access/        ← 資料存取層
    │   ├── stores/         ← Signal Stores (狀態管理)
    │   ├── repositories/   ← 資料存取抽象
    │   └── services/       ← 業務邏輯服務
    ├── domain/             ← 領域層
    │   ├── models/         ← 領域模型
    │   ├── interfaces/     ← 介面定義
    │   ├── types/          ← 型別定義
    │   └── enums/          ← 列舉定義
    ├── shell/              ← Shell 元件 (Smart Components)
    ├── ui/                 ← UI 元件 (Presentational)
    ├── guards/             ← 路由守衛
    ├── directives/         ← 指令
    ├── pipes/              ← 管道
    ├── utils/              ← 工具函數
    └── constants/          ← 常數配置
```

---

## 四、狀態管理標準

### 4.1 狀態管理流向

```
┌────────────────────────────────────────────────────────┐
│                     UI Component                        │
│                         │                               │
│                         ▼                               │
│    ┌──────────────────────────────────────────┐        │
│    │          Store (Signal Store)            │        │
│    │   ┌──────────────────────────────────┐   │        │
│    │   │    Signal State Management       │   │        │
│    │   │    - state = signal({...})       │   │        │
│    │   │    - computed signals            │   │        │
│    │   └──────────────────────────────────┘   │        │
│    └──────────────────────────────────────────┘        │
│                         │                               │
│                         ▼                               │
│    ┌──────────────────────────────────────────┐        │
│    │         Repository / Service             │        │
│    └──────────────────────────────────────────┘        │
│                         │                               │
│                         ▼                               │
│    ┌──────────────────────────────────────────┐        │
│    │            Supabase Client               │        │
│    └──────────────────────────────────────────┘        │
└────────────────────────────────────────────────────────┘
```

### 4.2 Store 在垂直切片中的位置

```
features/[feature-name]/
└── data-access/
    └── stores/           ← Signal Stores 放置於此
        ├── [feature].store.ts
        └── index.ts
```

---

## 五、認證與授權流程

### 5.1 認證流程鏈

```
Supabase Auth → @delon/auth → DA_SERVICE_TOKEN → @delon/acl
```

| 階段 | 元件 | 職責 |
|------|------|------|
| 1 | `SupabaseService` | Supabase 認證整合 |
| 2 | `@delon/auth` | Token 管理 (TokenService) |
| 3 | `DA_SERVICE_TOKEN` | Token 存取抽象 |
| 4 | `@delon/acl` | 權限控制 (ACL) |

### 5.2 認證狀態管理

```typescript
// core/services/auth-context.service.ts
// 使用 Angular Signals 管理認證狀態
readonly authState = signal<AuthStateData>({...});
readonly isAuthenticated = computed(() => this.authState().status === 'authenticated');
```

---

## 六、Angular 20+ 模板語法規範

### 6.1 新控制流語法

```html
<!-- ✅ 使用新語法 -->
@if (isLoading()) {
  <nz-spin></nz-spin>
} @else {
  <div>Content</div>
}

@for (item of items(); track item.id) {
  <div>{{ item.name }}</div>
}

@switch (status()) {
  @case ('active') { <span>Active</span> }
  @case ('inactive') { <span>Inactive</span> }
  @default { <span>Unknown</span> }
}
```

### 6.2 Signal 輸入/輸出（Angular 19+）

```typescript
// ✅ 使用新的 Signal API
export class MyComponent {
  // Inputs
  readonly data = input<Data>();
  readonly required = input.required<string>();

  // Outputs
  readonly save = output<Data>();

  // ViewChild
  readonly template = viewChild<TemplateRef>('tmpl');
}
```

---

## 七、模組邊界管理

### 7.1 公開 API 原則

```typescript
// features/blueprint/index.ts
// 只導出應該對外公開的部分
export { BLUEPRINT_ROUTES } from './blueprint.routes';
export * from './domain';     // 領域類型
export * from './constants';  // 常數配置
// ⚠️ 不要導出內部實現細節
```

### 7.2 依賴方向

```
features → shared → core
    │         │
    └─────────┴──────→ @delon/* / ng-zorro-antd
```

---

## 八、Context7 MCP 查詢判斷

### 8.1 何時使用 Context7 MCP

| 情況 | 是否使用 MCP |
|------|--------------|
| Agent 有絕對把握（常見 API、標準模式） | ❌ 不查 |
| Agent 沒有把握（新功能、版本特定、邊緣情況） | ✅ 使用 MCP |
| @delon 特定 API | ✅ 建議查詢 |
| NG-ZORRO 進階用法 | ✅ 建議查詢 |
| Angular 新版本特性 | ✅ 建議查詢 |

---

## 九、單一職責原則 (SRP)

### 9.1 各層職責

| 層級 | 職責 | 禁止事項 |
|------|------|----------|
| `core/` | 全局服務、認證、攔截器 | 不包含 UI 元件 |
| `shared/` | 共享元件、指令、管道 | 不包含業務邏輯 |
| `layout/` | 版面配置元件 | 不包含業務邏輯 |
| `routes/` | 路由頁面元件 | 複雜邏輯應委派給 feature |
| `features/` | 完整業務功能模組 | 不直接依賴其他 feature |

---

## 十、序列化思考 (Sequential Thinking)

在進行開發時，請遵循以下思考順序：

1. **理解需求** - 確認要解決的問題
2. **檢查現有** - 是否已有類似實現
3. **選擇模式** - 橫向分層 vs 垂直切片
4. **元件優先** - NG-ZORRO → @delon/abc → 自行開發
5. **狀態管理** - 使用 Angular Signals
6. **測試驗證** - 確保功能正確
7. **文檔更新** - 維護相關 AGENTS.md

---

## 十一、目錄結構概覽

```
src/app/
├── core/                   # 核心層 (橫向分層)
│   ├── facades/           # Facade 模式
│   ├── i18n/              # 國際化
│   ├── infra/             # 基礎設施
│   ├── net/               # 網路層
│   ├── services/          # 核心服務
│   └── startup/           # 啟動服務
├── shared/                 # 共享層 (橫向分層)
│   ├── base/              # 基礎元件
│   ├── directives/        # 共享指令
│   ├── pipes/             # 共享管道
│   ├── services/          # 共享服務
│   ├── models/            # 共享模型
│   └── utils/             # 工具函數
├── layout/                 # 版面層 (橫向分層)
│   ├── basic/             # 基礎版面
│   ├── blank/             # 空白版面
│   └── passport/          # 登入版面
├── routes/                 # 路由層 (橫向分層)
│   ├── account/           # 帳戶頁面
│   ├── demo/              # 示範頁面
│   ├── exception/         # 例外頁面
│   └── passport/          # 登入頁面
└── features/               # 功能層 (垂直切片)
    └── blueprint/         # Blueprint 功能模組
        ├── data-access/   # 資料存取
        ├── domain/        # 領域模型
        ├── shell/         # Smart Components
        ├── ui/            # Presentational Components
        └── ...
```

---

## 十二、相關 AGENTS.md

- [`src/app/AGENTS.md`](src/app/AGENTS.md) - 應用層級指引
- [`src/app/core/AGENTS.md`](src/app/core/AGENTS.md) - Core 層指引
- [`src/app/shared/AGENTS.md`](src/app/shared/AGENTS.md) - Shared 層指引
- [`src/app/layout/AGENTS.md`](src/app/layout/AGENTS.md) - Layout 層指引
- [`src/app/routes/AGENTS.md`](src/app/routes/AGENTS.md) - Routes 層指引
- [`src/app/features/AGENTS.md`](src/app/features/AGENTS.md) - Features 層指引
- [`src/app/features/blueprint/AGENTS.md`](src/app/features/blueprint/AGENTS.md) - Blueprint 功能指引
