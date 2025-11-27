# AGENTS.md - Core Layer Guidelines

> **架構模式**: 橫向分層架構 (Horizontal Layered Architecture)
> **核心原則**: 單一職責原則 (SRP) + 企業化標準

---

## 一、Core 層概述

`core/` 是應用程式的核心層，提供：

- 全局單例服務 (providedIn: 'root')
- 認證與授權服務
- HTTP 攔截器
- 基礎設施服務
- 啟動服務

---

## 二、目錄結構

```
core/
├── facades/               # Facade 模式 (對外簡化介面)
│   ├── account/          # 帳戶相關 Facade
│   └── index.ts
├── i18n/                  # 國際化服務
│   └── i18n.service.ts
├── infra/                 # 基礎設施
│   ├── repositories/     # 資料存取抽象
│   ├── supabase/         # Supabase 整合
│   └── types/            # 基礎型別定義
├── net/                   # 網路層
│   ├── default.interceptor.ts
│   ├── helper.ts
│   ├── refresh-token.ts
│   └── index.ts
├── services/              # 核心服務
│   ├── auth-context.service.ts  # 認證上下文服務
│   └── index.ts
├── startup/               # 啟動服務
│   └── startup.service.ts
├── start-page.guard.ts    # 啟動頁面守衛
└── index.ts               # 公開 API
```

---

## 三、認證流程 (重要)

### 3.1 認證流程鏈

```
Supabase Auth → @delon/auth → DA_SERVICE_TOKEN → @delon/acl
```

### 3.2 AuthContextService

核心認證服務，使用 Angular Signals 管理狀態：

```typescript
// core/services/auth-context.service.ts
@Injectable({ providedIn: 'root' })
export class AuthContextService {
  // 私有狀態
  private readonly _authState = signal<AuthStateData>({
    status: 'loading',
    user: null,
    session: null,
    error: null
  });

  // 公開只讀 Signals
  readonly authState = this._authState.asReadonly();
  readonly isAuthenticated = computed(() => this._authState().status === 'authenticated');
  readonly authStatus = computed(() => this._authState().status);

  // 認證流程：監聽 Supabase Auth 事件
  private initializeAuthListener(): void {
    this.supabaseService.getClient().auth.onAuthStateChange(async (event, session) => {
      // 處理認證事件
    });
  }
}
```

### 3.3 上下文類型

```typescript
export enum ContextType {
  USER = 'user',
  ORGANIZATION = 'organization',
  TEAM = 'team',
  BOT = 'bot'
}
```

### 3.4 認證流程實作指引

**Step 1: Supabase Auth 事件監聽**
```typescript
// AuthContextService 在建構子中初始化監聽
this.supabaseService.getClient().auth.onAuthStateChange((event, session) => {
  switch (event) {
    case 'SIGNED_IN':
      // 更新內部 Signal 狀態
      this._authState.set({ status: 'authenticated', user: session.user, ... });
      // 載入工作區資料
      this.initializeWorkspace(session.user.id);
      break;
    case 'SIGNED_OUT':
      this.reset();
      break;
  }
});
```

**Step 2: @delon/auth Token 同步**
```typescript
// 在 app.config.ts 中配置
provideHttpClient(withInterceptors([
  authSimpleInterceptor,  // 自動注入 Token
  defaultInterceptor
])),
provideAuth(),  // 提供 TokenService
```

**Step 3: ACL 權限設定**
```typescript
// 在元件中使用
<button *aclIf="'admin'">管理功能</button>
```

**詳細實作參考**：`core/services/auth-context.service.ts`

---

## 四、基礎設施 (infra/)

### 4.1 Supabase 整合

```typescript
// core/infra/supabase/supabase.service.ts
@Injectable({ providedIn: 'root' })
export class SupabaseService {
  private supabase: SupabaseClient;

  getClient(): SupabaseClient { return this.supabase; }
  async getSession(): Promise<Session | null> { ... }
}
```

### 4.2 型別定義

```
core/infra/types/
├── account.ts        # 帳戶相關型別
└── supabase.types.ts # Supabase 型別 (User, Session)
```

---

## 五、HTTP 攔截器 (net/)

### 5.1 攔截器順序

```typescript
// app.config.ts
provideHttpClient(withInterceptors([
  ...environment.interceptorFns,  // 環境特定攔截器
  authSimpleInterceptor,          // @delon/auth Token 注入
  defaultInterceptor              // 預設錯誤處理
])),
```

### 5.2 DefaultInterceptor

```typescript
// core/net/default.interceptor.ts
export const defaultInterceptor: HttpInterceptorFn = (req, next) => {
  // 處理 HTTP 請求/回應
  // - 錯誤處理
  // - Token 刷新
  // - 通知顯示
};
```

---

## 六、Facade 模式

### 6.1 用途

Facade 提供簡化的介面，隱藏複雜的子系統：

```typescript
// core/facades/account/account.facade.ts
@Injectable({ providedIn: 'root' })
export class AccountFacade {
  // 組合多個服務，提供簡化 API
  constructor(
    private authContext: AuthContextService,
    private accountService: AccountService,
    private organizationService: OrganizationService
  ) {}

  // 簡化的公開方法
  async getCurrentUserProfile(): Promise<UserProfile> { ... }
}
```

---

## 七、啟動服務 (startup/)

### 7.1 StartupService

```typescript
// core/startup/startup.service.ts
export function provideStartup(): EnvironmentProviders {
  return makeEnvironmentProviders([
    StartupService,
    {
      provide: APP_INITIALIZER,
      useFactory: (service: StartupService) => () => service.load(),
      deps: [StartupService],
      multi: true
    }
  ]);
}
```

---

## 八、單一職責原則 (SRP)

### 8.1 Core 層職責

| ✅ 應該包含 | ❌ 不應該包含 |
|-------------|---------------|
| 全局服務 | UI 元件 |
| 認證/授權 | 業務邏輯元件 |
| HTTP 攔截器 | 頁面元件 |
| 基礎設施服務 | 功能模組 |
| 啟動邏輯 | 表單驗證器 |

### 8.2 服務註冊

```typescript
// ✅ 核心服務使用 providedIn: 'root'
@Injectable({ providedIn: 'root' })
export class AuthContextService { ... }

// ❌ 避免在核心層使用功能特定的 provider
```

---

## 九、狀態管理標準

### 9.1 使用 Angular Signals

```typescript
@Injectable({ providedIn: 'root' })
export class CoreService {
  // 私有可寫 Signal
  private readonly _state = signal<State>(initialState);

  // 公開只讀 Signal
  readonly state = this._state.asReadonly();

  // 衍生狀態
  readonly derivedValue = computed(() => this._state().someProperty);

  // 更新方法
  updateState(partial: Partial<State>): void {
    this._state.update(current => ({ ...current, ...partial }));
  }
}
```

---

## 十、模組邊界管理

### 10.1 公開 API (index.ts)

```typescript
// core/index.ts
// Infrastructure
export * from './infra';

// Services
export * from './services';

// Legacy Services (逐步遷移)
export * from './i18n/i18n.service';
export * from './net/index';
export * from './startup/startup.service';

// Guards
export * from './start-page.guard';

// Facades
export * from './facades';
```

### 10.2 依賴規則

```
core/ 可以依賴：
├── @angular/*
├── @delon/*
├── ng-zorro-antd
├── @supabase/supabase-js
└── rxjs

core/ 不可依賴：
├── shared/
├── layout/
├── routes/
└── features/
```

---

## 十一、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **Supabase Auth API** - 認證方法、Session 管理
2. **@delon/auth 配置** - TokenService、攔截器設定
3. **@delon/acl 權限設定** - ACL 規則配置
4. **Angular APP_INITIALIZER** - 啟動流程配置

### 可直接實作的情況

1. 標準 Injectable 服務
2. 基本 Signal 操作
3. HTTP 攔截器基本模式

---

## 十二、相關文件

- [根目錄 AGENTS.md](../../AGENTS.md) - 專案總覽
- [app/AGENTS.md](../AGENTS.md) - 應用層級指引
- [shared/AGENTS.md](../shared/AGENTS.md) - 共享層指引 (core 可被 shared 依賴)
