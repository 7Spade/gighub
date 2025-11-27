# AGENTS.md - Routes Layer Guidelines

> **架構模式**: 橫向分層架構 (Horizontal Layered Architecture)
> **核心原則**: 單一職責原則 (SRP) + 奧卡姆剃刀 + 企業化標準

---

## 一、Routes 層概述

`routes/` 是應用程式的路由層，負責：

- 定義應用程式路由結構
- 簡單頁面元件
- 懶載入功能模組
- 路由守衛配置

---

## 二、目錄結構

```
routes/
├── account/               # 帳戶相關頁面
│   ├── settings/         # 設定頁面
│   └── routes.ts
├── demo/                  # 示範頁面
│   ├── dashboard/        # 儀表板
│   ├── widgets/          # Widget 示範
│   ├── style/            # 樣式示範
│   ├── delon/            # @delon 示範
│   ├── extras/           # 額外功能
│   ├── pro/              # Pro 版示範
│   └── data-v/           # 資料視覺化
├── exception/             # 例外頁面
│   ├── 403/              # 無權限
│   ├── 404/              # 找不到頁面
│   ├── 500/              # 伺服器錯誤
│   └── routes.ts
├── passport/              # 登入/註冊頁面
│   ├── login/
│   ├── register/
│   └── routes.ts
└── routes.ts              # ⭐ 主路由配置
```

---

## 三、主路由配置 (routes.ts)

### 3.1 路由結構

```typescript
// routes/routes.ts
export const routes: Routes = [
  // 1. 已登入用戶主版面
  {
    path: '',
    component: LayoutBasicComponent,
    canActivate: [startPageGuard, authSimpleCanActivate],
    canActivateChild: [authSimpleCanActivateChild],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', loadChildren: () => import('./demo/dashboard/routes').then(m => m.routes) },
      { path: 'account', loadChildren: () => import('./account/routes').then(m => m.routes) },
      // Feature 模組整合
      { path: 'blueprint', loadChildren: () => import('../features/blueprint/blueprint.routes').then(m => m.BLUEPRINT_ROUTES) }
    ]
  },

  // 2. 空白版面
  {
    path: 'data-v',
    component: LayoutBlankComponent,
    children: [...]
  },

  // 3. 登入版面
  { path: '', loadChildren: () => import('./passport/routes').then(m => m.routes) },

  // 4. 例外頁面
  { path: 'exception', loadChildren: () => import('./exception/routes').then(m => m.routes) },

  // 5. 萬用路由
  { path: '**', redirectTo: 'exception/404' }
];
```

### 3.2 路由守衛配置

| 守衛 | 用途 | 來源 |
|------|------|------|
| `startPageGuard` | 啟動頁面檢查 | `@core` |
| `authSimpleCanActivate` | Token 驗證 | `@delon/auth` |
| `authSimpleCanActivateChild` | 子路由 Token 驗證 | `@delon/auth` |

---

## 四、懶載入模式

### 4.1 標準懶載入

```typescript
// 路由級別懶載入
{
  path: 'dashboard',
  loadChildren: () => import('./demo/dashboard/routes').then(m => m.routes)
}
```

### 4.2 Feature 模組整合

```typescript
// 整合 features/ 下的功能模組
{
  path: 'blueprint',
  loadChildren: () => import('../features/blueprint/blueprint.routes').then(m => m.BLUEPRINT_ROUTES)
}
```

### 4.3 子路由文件結構

```typescript
// routes/demo/dashboard/routes.ts
export const routes: Routes = [
  {
    path: '',
    component: DashboardComponent
  }
];
```

---

## 五、頁面元件設計

### 5.1 簡單頁面 (routes/)

```typescript
// routes/ 適合簡單頁面
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <page-header />
    <nz-card>
      <!-- 簡單展示內容 -->
    </nz-card>
  `
})
export class DashboardComponent { }
```

### 5.2 複雜功能 → features/

```typescript
// ❌ routes/ 不適合複雜業務邏輯
// 複雜功能應該放在 features/

// ✅ 正確做法：在 routes.ts 中引用 feature
{
  path: 'blueprint',
  loadChildren: () => import('../features/blueprint/blueprint.routes')
    .then(m => m.BLUEPRINT_ROUTES)
}
```

---

## 六、Routes vs Features 判斷

### 6.1 何時使用 routes/

| 適合 routes/ | 說明 |
|--------------|------|
| 儀表板 | 數據展示頁面 |
| 設定頁面 | 簡單表單頁面 |
| 個人資料 | 基本 CRUD |
| 例外頁面 | 403, 404, 500 |
| 登入/註冊 | 認證相關頁面 |

### 6.2 何時使用 features/

| 適合 features/ | 說明 |
|----------------|------|
| 複雜業務邏輯 | 多步驟流程 |
| 狀態管理 | 需要 Store |
| 多個相關頁面 | 功能模組化 |
| 可重用元件 | 跨頁面共享 |

---

## 七、認證與授權

### 7.1 路由級別授權

```typescript
{
  path: 'admin',
  loadChildren: () => import('./admin/routes').then(m => m.routes),
  data: {
    // ACL 權限設定
    guard: { role: ['admin'] }
  }
}
```

### 7.2 頁面級別授權

```html
<!-- 使用 @delon/acl 指令 -->
<button *aclIf="'admin'" nz-button>管理功能</button>
```

---

## 八、UI 元件使用

### 8.1 優先使用 SHARED_IMPORTS

```typescript
import { SHARED_IMPORTS } from '@shared';

@Component({
  imports: [...SHARED_IMPORTS],
  // ...
})
export class MyPageComponent { }
```

### 8.2 頁面常用元件

| 用途 | 元件 | 來源 |
|------|------|------|
| 頁面標頭 | `page-header` | `@delon/abc` |
| 數據表格 | `st` | `@delon/abc` |
| 表單佈局 | `se`, `sg` | `@delon/abc` |
| 卡片容器 | `nz-card` | `ng-zorro-antd` |

---

## 九、單一職責原則 (SRP)

### 9.1 Routes 層職責

| ✅ 應該包含 | ❌ 不應該包含 |
|-------------|---------------|
| 路由定義 | 複雜業務邏輯 |
| 簡單頁面元件 | 狀態管理 (Store) |
| 路由守衛配置 | 共享元件 |
| 懶載入配置 | 工具函數 |

### 9.2 複雜邏輯委派

```typescript
// ✅ 正確：複雜邏輯委派給 Feature
@Component({ ... })
export class BlueprintPageComponent {
  // 簡單的容器元件，實際邏輯在 feature 中
}

// ❌ 錯誤：在路由頁面中實作複雜業務
@Component({ ... })
export class BlueprintPageComponent {
  async loadData() { ... }
  processBusinessLogic() { ... }
  handleComplexValidation() { ... }
}
```

---

## 十、Angular 20+ 模板語法

### 10.1 頁面元件範例

```typescript
@Component({
  selector: 'app-account-settings',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <page-header [title]="'帳戶設定'" />

    <nz-card>
      @if (isLoading()) {
        <nz-spin />
      } @else {
        <form nz-form [formGroup]="form">
          <se label="名稱">
            <input nz-input formControlName="name" />
          </se>
          <se label="Email">
            <input nz-input formControlName="email" />
          </se>
        </form>
      }
    </nz-card>
  `
})
export class AccountSettingsComponent {
  readonly isLoading = signal(false);
  readonly form = inject(FormBuilder).group({
    name: [''],
    email: ['']
  });
}
```

---

## 十一、模組邊界管理

### 11.1 依賴規則

```
routes/ 可以依賴：
├── core/          # ✅ 核心服務
├── shared/        # ✅ 共享元件
├── layout/        # ✅ 版面元件
├── features/      # ✅ 功能模組 (透過路由)
├── @angular/*
├── @delon/*
└── ng-zorro-antd

routes/ 不可依賴：
└── (無特別限制，但應保持簡潔)
```

### 11.2 Feature 整合方式

```typescript
// 只透過路由整合，不直接導入 feature 內部
{
  path: 'blueprint',
  loadChildren: () => import('../features/blueprint/blueprint.routes')
    .then(m => m.BLUEPRINT_ROUTES)
}
```

---

## 十二、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **Angular Router 進階配置** - 解析器、延遲載入策略
2. **@delon/auth 守衛** - 認證守衛配置
3. **@delon/acl 權限** - 路由權限設定
4. **page-header 配置** - 麵包屑、標題設定

### 可直接實作的情況

1. 基本路由定義
2. 簡單頁面元件
3. 標準懶載入

---

## 十三、相關文件

- [根目錄 AGENTS.md](../../AGENTS.md) - 專案總覽
- [app/AGENTS.md](../AGENTS.md) - 應用層級指引
- [layout/AGENTS.md](../layout/AGENTS.md) - 版面層指引 (routes 使用 layout)
- [features/AGENTS.md](../features/AGENTS.md) - 功能層指引 (routes 整合 features)
