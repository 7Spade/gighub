# AGENTS.md - Shared Layer Guidelines

> **架構模式**: 橫向分層架構 (Horizontal Layered Architecture)
> **核心原則**: 單一職責原則 (SRP) + 奧卡姆剃刀 + 企業化標準

---

## 一、Shared 層概述

`shared/` 是應用程式的共享層，提供：

- 共享元件、指令、管道
- 共享服務 (非全局單例)
- 共享模型與介面
- 工具函數
- **統一導入模組** (`shared-imports.ts`)

### 1.1 Shared Services vs Core Services 區分

| 類型 | 位置 | 註冊方式 | 用途 |
|------|------|----------|------|
| **Core Services** | `core/services/` | `providedIn: 'root'` | 全局單例，應用程式生命週期 |
| **Shared Services** | `shared/services/` | 按需提供或功能層級 | 可實例化多次，功能特定 |

**Core Services 範例**：
- `AuthContextService` - 全局認證狀態
- `I18NService` - 全局國際化
- `StartupService` - 應用程式啟動

**Shared Services 範例**：
- `AccountService` - 帳戶 CRUD 操作
- `OrganizationService` - 組織 CRUD 操作
- `MenuManagementService` - 菜單管理操作

---

## 二、目錄結構

```
shared/
├── base/                      # 基礎元件/類別
│   └── base-context-aware.component.ts
├── cell-widget/               # Cell Widget 配置
├── directives/                # 共享指令
├── json-schema/               # JSON Schema (SF) 配置
├── models/                    # 共享模型 (Supabase 整合)
├── pipes/                     # 共享管道
├── services/                  # 共享服務
├── st-widget/                 # ST Widget 配置
├── upload/                    # 上傳元件
├── utils/                     # 工具函數
├── shared-core-services.ts    # 核心服務 Provider
├── shared-delon.module.ts     # @delon 模組匯出
├── shared-imports.ts          # ⭐ 統一導入模組
├── shared-zorro.module.ts     # NG-ZORRO 模組匯出
└── index.ts                   # 公開 API
```

---

## 三、統一導入模組 (重要)

### 3.1 SHARED_IMPORTS 使用

```typescript
// ✅ 推薦：使用 SHARED_IMPORTS
import { SHARED_IMPORTS } from '@shared';

@Component({
  selector: 'app-my-component',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `...`
})
export class MyComponent {}
```

### 3.2 SHARED_IMPORTS 內容

```typescript
// shared/shared-imports.ts
export const SHARED_IMPORTS = [
  // Angular 核心
  FormsModule,
  ReactiveFormsModule,
  RouterLink,
  RouterOutlet,
  NgTemplateOutlet,
  AsyncPipe,
  JsonPipe,

  // Delon 主題
  DatePipe,
  I18nPipe,

  // Delon 業務組件
  ...SHARED_DELON_MODULES,

  // NG-ZORRO 組件
  ...SHARED_ZORRO_MODULES
];
```

---

## 四、UI 元件優先級

### 4.1 優先級規則

```
優先級：NG-ZORRO > @delon/abc > 自行開發
```

### 4.2 NG-ZORRO 元件 (第一優先)

```typescript
// shared/shared-zorro.module.ts
export const SHARED_ZORRO_MODULES = [
  // 通用組件
  NzButtonModule, NzIconModule, NzTypographyModule,

  // 布局組件
  NzGridModule, NzLayoutModule, NzSpaceModule,

  // 數據錄入
  NzFormModule, NzInputModule, NzSelectModule, NzDatePickerModule,

  // 數據展示
  NzTableModule, NzCardModule, NzListModule, NzTagModule,

  // 反饋組件
  NzModalModule, NzDrawerModule, NzAlertModule, NzSpinModule,
  // ...
];
```

### 4.3 @delon/abc 元件 (第二優先)

```typescript
// shared/shared-delon.module.ts
export const SHARED_DELON_MODULES = [
  // 企業表格
  STModule,              // ⭐ 強大的數據表格

  // 企業表單
  SEModule, SGModule,    // 表單佈局
  DelonFormModule,       // ⭐ JSON-Schema 表單 (SF)

  // 數據展示
  SVModule,              // 查看/詳情展示

  // 頁面結構
  PageHeaderModule,      // 頁面標頭
  FooterToolbarModule,   // 底部工具欄
  FullContentModule,     // 全螢幕內容

  // 權限控制
  ACLDirective,          // *aclIf
  ACLIfDirective,        // 結構指令

  // 圖表 (@delon/chart)
  G2BarModule, G2PieModule, G2TimelineModule,
  // ...
];
```

---

## 五、共享服務 (services/)

### 5.1 服務類型

| 服務類型 | 位置 | 說明 |
|----------|------|------|
| 全局單例 | `core/services/` | `providedIn: 'root'` |
| 共享服務 | `shared/services/` | 功能共享，非全局 |

### 5.2 Supabase 整合服務

```
shared/services/
├── account.service.ts           # 帳戶服務
├── organization.service.ts      # 組織服務
├── team.service.ts              # 團隊服務
├── menu-management.service.ts   # 菜單管理
└── index.ts
```

---

## 六、共享模型 (models/)

### 6.1 Supabase 資料模型

```typescript
// shared/models/
├── account.model.ts         # Account 表模型
├── organization.model.ts    # Organization 表模型
├── team.model.ts            # Team 表模型
└── index.ts
```

### 6.2 型別定義模式

```typescript
// 使用 interface 定義資料模型
export interface AccountModel {
  id: string;
  auth_user_id: string;
  name: string;
  email: string;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
}

// 使用 type 定義衍生類型
export type AccountCreateInput = Omit<AccountModel, 'id' | 'created_at' | 'updated_at'>;
export type AccountUpdateInput = Partial<AccountCreateInput>;
```

---

## 七、基礎元件 (base/)

### 7.1 BaseContextAwareComponent

```typescript
// shared/base/base-context-aware.component.ts
export abstract class BaseContextAwareComponent {
  protected readonly authContext = inject(AuthContextService);

  // 上下文相關的便捷方法
  protected get contextType(): ContextType { ... }
  protected get contextId(): string | null { ... }
  protected get isAuthenticated(): boolean { ... }
}
```

### 7.2 使用方式

```typescript
@Component({ ... })
export class MyFeatureComponent extends BaseContextAwareComponent {
  constructor() {
    super();
    // 可直接使用 this.contextType, this.contextId 等
  }
}
```

---

## 八、工具函數 (utils/)

### 8.1 常用工具

```
shared/utils/
├── yuan.ts         # 金額格式化
├── form.utils.ts   # 表單工具
└── index.ts
```

### 8.2 使用原則

```typescript
// ✅ 純函數，無副作用
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat('zh-TW', {
    style: 'currency',
    currency: 'TWD'
  }).format(value);
}

// ❌ 避免有狀態的工具函數
```

---

## 九、Widget 配置

### 9.1 ST Widget (st-widget/)

```typescript
// 自訂 ST 表格的 Widget
export const ST_WIDGETS = [
  // 自訂 Widget 配置
];
```

### 9.2 SF Widget (json-schema/)

```typescript
// 自訂 SF 表單的 Widget
export const SF_WIDGETS = [
  // 自訂 Widget 配置
];
```

### 9.3 Cell Widget (cell-widget/)

```typescript
// 自訂 Cell 的 Widget
export const CELL_WIDGETS = [
  // 自訂 Widget 配置
];
```

---

## 十、單一職責原則 (SRP)

### 10.1 Shared 層職責

| ✅ 應該包含 | ❌ 不應該包含 |
|-------------|---------------|
| 共享 UI 元件 | 全局單例服務 |
| 共享指令 | 認證/授權邏輯 |
| 共享管道 | HTTP 攔截器 |
| 共享模型/介面 | 啟動服務 |
| 工具函數 | 業務邏輯 |
| Widget 配置 | 路由定義 |

### 10.2 無業務邏輯原則

```typescript
// ✅ 正確：通用展示元件
@Component({
  selector: 'app-avatar-display',
  template: `<nz-avatar [nzSrc]="src()" [nzSize]="size()"></nz-avatar>`
})
export class AvatarDisplayComponent {
  readonly src = input<string>();
  readonly size = input<number>(32);
}

// ❌ 錯誤：包含業務邏輯
@Component({
  selector: 'app-user-avatar',
  template: `...`
})
export class UserAvatarComponent {
  // 不應包含載入用戶資料的邏輯
  async loadUserData() { ... }
}
```

---

## 十一、模組邊界管理

### 11.1 公開 API (index.ts)

```typescript
// shared/index.ts
export * from './base/base-context-aware.component';
export * from './upload';
export * from './utils/yuan';
export * from './utils/form.utils';
export * from './shared-imports';
export * from './json-schema/index';
export * from './st-widget/index';
export * from './cell-widget/index';
export * from './models';
export * from './services';
export * from './directives';
export * from './pipes';
```

### 11.2 依賴規則

```
shared/ 可以依賴：
├── core/          # ✅ 核心服務 (見下方說明)
├── @angular/*
├── @delon/*
├── ng-zorro-antd
└── rxjs

shared/ 不可依賴：
├── layout/        # ❌
├── routes/        # ❌
└── features/      # ❌
```

### 11.3 Shared 依賴 Core 的架構說明

> **重要**：本專案採用「核心層作為基礎設施」的架構模式

傳統分層架構中，下層不應依賴上層。但本專案 `core/` 定位為：

```
core/ = 基礎設施層 (Infrastructure Layer)
├── 提供全局單例服務
├── 提供 Supabase 整合
├── 提供認證狀態
└── 提供 HTTP 攚截器
```

因此 `shared/` 依賴 `core/` 是合理的，因為：
1. `core/` 提供基礎設施，不是業務邏輯
2. `shared/` 的基礎元件需要使用認證上下文 (`AuthContextService`)
3. 依賴流向：`features/` → `shared/` → `core/` → 外部套件

---

## 十二、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **ST 元件配置** - 複雜表格配置、自訂 Widget
2. **SF 元件配置** - JSON-Schema 表單、驗證規則
3. **NG-ZORRO 進階用法** - 模態框、抽屜、表格自訂
4. **@delon/util 工具** - 工具函數使用方式

### 可直接實作的情況

1. 基本 NG-ZORRO 元件使用
2. 標準 Angular 指令/管道
3. 簡單工具函數

---

## 十三、相關文件

- [根目錄 AGENTS.md](../../AGENTS.md) - 專案總覽
- [app/AGENTS.md](../AGENTS.md) - 應用層級指引
- [core/AGENTS.md](../core/AGENTS.md) - 核心層指引 (shared 依賴 core)
- [features/AGENTS.md](../features/AGENTS.md) - 功能層指引 (features 依賴 shared)
