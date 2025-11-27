# AGENTS.md - Application Layer Guidelines

> **核心原則**: 應用層級配置與協調，遵循企業化標準與奧卡姆剃刀原則

---

## 一、應用層級概述

`src/app/` 是應用程式的根目錄，負責：

- 應用程式配置 (`app.config.ts`)
- 根元件定義 (`app.component.ts`)
- 各層級模組的協調與整合

---

## 二、目錄結構

```
src/app/
├── app.component.ts       # 根元件
├── app.config.ts          # 應用程式配置
├── core/                  # 核心層 (橫向分層)
├── shared/                # 共享層 (橫向分層)
├── layout/                # 版面層 (橫向分層)
├── routes/                # 路由層 (橫向分層)
└── features/              # 功能層 (垂直切片)
```

---

## 三、應用程式配置 (app.config.ts)

### 3.1 Provider 註冊順序

```typescript
// ⚠️ 重要：Provider 註冊順序影響認證流程
const providers = [
  // 1. HTTP Client (含攔截器)
  provideHttpClient(withInterceptors([
    ...environment.interceptorFns,
    authSimpleInterceptor,    // @delon/auth 攔截器
    defaultInterceptor        // 預設攔截器
  ])),

  // 2. 動畫支援
  provideAnimations(),

  // 3. 路由配置
  provideRouter(routes, ...routerFeatures),

  // 4. NG-ALAIN 框架配置
  provideAlain({ config: alainConfig, defaultLang, i18nClass: I18NService, icons }),

  // 5. NG-ZORRO 配置
  provideNzConfig(ngZorroConfig),

  // 6. 認證配置 (@delon/auth)
  provideAuth(),

  // 7. 業務元件配置
  provideCellWidgets(...CELL_WIDGETS),
  provideSTWidgets(...ST_WIDGETS),
  provideSFConfig({ widgets: SF_WIDGETS }),

  // 8. 啟動服務
  provideStartup(),
];
```

### 3.2 認證流程整合

```
Supabase Auth → @delon/auth → DA_SERVICE_TOKEN → @delon/acl
```

詳見 `core/services/auth-context.service.ts`

---

## 四、各層職責分配

| 層級 | 架構模式 | 主要職責 | AGENTS.md |
|------|----------|----------|-----------|
| `core/` | 橫向分層 | 全局服務、認證、攔截器 | [core/AGENTS.md](core/AGENTS.md) |
| `shared/` | 橫向分層 | 共享元件、指令、管道 | [shared/AGENTS.md](shared/AGENTS.md) |
| `layout/` | 橫向分層 | 版面配置元件 | [layout/AGENTS.md](layout/AGENTS.md) |
| `routes/` | 橫向分層 | 路由頁面、簡單 CRUD | [routes/AGENTS.md](routes/AGENTS.md) |
| `features/` | 垂直切片 | 完整業務功能模組 | [features/AGENTS.md](features/AGENTS.md) |

---

## 五、依賴方向規則

```
┌─────────────────────────────────────────────────────────┐
│                       app.config.ts                      │
│                            │                             │
│         ┌──────────────────┼──────────────────┐         │
│         ▼                  ▼                  ▼         │
│    ┌─────────┐       ┌──────────┐       ┌─────────┐    │
│    │  core/  │       │ shared/  │       │ layout/ │    │
│    └─────────┘       └──────────┘       └─────────┘    │
│         │                  │                  │         │
│         └──────────────────┼──────────────────┘         │
│                            ▼                             │
│                      ┌──────────┐                        │
│                      │ routes/  │                        │
│                      └──────────┘                        │
│                            │                             │
│                            ▼                             │
│                     ┌───────────┐                        │
│                     │ features/ │                        │
│                     └───────────┘                        │
└─────────────────────────────────────────────────────────┘
```

### 5.1 允許的依賴

- `features/` → `shared/`, `core/`
- `routes/` → `shared/`, `core/`, `layout/`, `features/`
- `layout/` → `shared/`, `core/`
- `shared/` → `core/`
- `core/` → 外部套件

### 5.2 禁止的依賴

- ❌ `core/` → `shared/`, `layout/`, `routes/`, `features/`
- ❌ `shared/` → `layout/`, `routes/`, `features/`
- ❌ `features/[A]` → `features/[B]` (功能模組間不能直接依賴)

---

## 六、共享導入標準

### 6.1 優先使用 SHARED_IMPORTS

```typescript
// ✅ 推薦方式
import { SHARED_IMPORTS } from '@shared';

@Component({
  imports: [...SHARED_IMPORTS, /* 額外需要的模組 */],
})
export class MyComponent {}
```

### 6.2 SHARED_IMPORTS 包含

- Angular 核心模組 (FormsModule, ReactiveFormsModule, RouterLink...)
- NG-ZORRO 元件模組
- @delon/abc 業務元件
- @delon/acl 權限指令
- @delon/form 表單模組
- @delon/util 工具

---

## 七、UI 元件選擇優先級

```
優先級：NG-ZORRO > @delon/abc > 自行開發
```

| 需求類型 | 推薦元件 |
|----------|----------|
| 基礎表單 | `nz-input`, `nz-select`, `nz-date-picker` |
| 企業表格 | `st` (@delon/abc) |
| 企業表單 | `sf` (@delon/form) |
| 資料展示 | `sv` (@delon/abc) |
| 頁面標頭 | `page-header` (@delon/abc) |

---

## 八、狀態管理策略

### 8.1 全局狀態 (core/)

```typescript
// 使用 Angular Signals
@Injectable({ providedIn: 'root' })
export class AuthContextService {
  private readonly _authState = signal<AuthStateData>({...});
  readonly authState = this._authState.asReadonly();
  readonly isAuthenticated = computed(() => this._authState().status === 'authenticated');
}
```

### 8.2 功能狀態 (features/)

```typescript
// 功能模組內的 Store
// features/[feature]/data-access/stores/[feature].store.ts
@Injectable()
export class FeatureStore {
  private readonly _state = signal<FeatureState>({...});
  // ...
}
```

---

## 九、Angular 20+ 模板語法

### 9.1 新控制流

```html
@if (condition()) {
  <!-- content -->
} @else {
  <!-- fallback -->
}

@for (item of items(); track item.id) {
  <!-- item template -->
} @empty {
  <!-- empty state -->
}

@switch (value()) {
  @case (1) { <!-- case 1 --> }
  @default { <!-- default --> }
}
```

### 9.2 Signal 輸入/輸出

```typescript
// ✅ Angular 19+ 推薦
readonly data = input<Data>();
readonly required = input.required<string>();
readonly save = output<Data>();
readonly child = viewChild<ElementRef>('ref');
```

---

## 十、Context7 MCP 查詢指引

### Agent 應查詢 MCP 的情況

1. **@delon 特定 API** - 版本間可能有差異
2. **NG-ZORRO 進階配置** - 複雜元件配置
3. **Angular 新版本特性** - Signal API、新控制流
4. **Supabase 整合** - 認證、RLS、Edge Functions

### Agent 可直接實作的情況

1. 標準 Angular 模式 (DI, 生命週期等)
2. 基本 TypeScript 語法
3. 常見 RxJS 操作符
4. 標準 HTML/CSS

---

## 十一、相關文件

- [根目錄 AGENTS.md](../AGENTS.md) - 專案總覽
- [core/AGENTS.md](core/AGENTS.md) - 核心層指引
- [shared/AGENTS.md](shared/AGENTS.md) - 共享層指引
- [layout/AGENTS.md](layout/AGENTS.md) - 版面層指引
- [routes/AGENTS.md](routes/AGENTS.md) - 路由層指引
- [features/AGENTS.md](features/AGENTS.md) - 功能層指引
