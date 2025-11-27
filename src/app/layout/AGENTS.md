# AGENTS.md - Layout Layer Guidelines

> **架構模式**: 橫向分層架構 (Horizontal Layered Architecture)
> **核心原則**: 單一職責原則 (SRP) + 奧卡姆剃刀

---

## 一、Layout 層概述

`layout/` 是應用程式的版面配置層，提供：

- 應用程式版面結構
- 導航元件
- 版面相關的 Widget

---

## 二、目錄結構

```
layout/
├── basic/                 # 基礎版面 (已登入)
│   ├── basic.component.ts
│   ├── widgets/          # 版面 Widget
│   │   ├── header/       # 頂部導航
│   │   ├── sidebar/      # 側邊欄
│   │   └── ...
│   └── README.md
├── blank/                 # 空白版面
│   └── blank.component.ts
├── passport/              # 登入版面 (未登入)
│   ├── passport.component.ts
│   └── passport.component.less
└── index.ts               # 公開 API
```

---

## 三、版面類型

### 3.1 BasicLayout (LayoutBasicComponent)

**用途**: 已登入用戶的主版面

```typescript
// layout/basic/basic.component.ts
@Component({
  selector: 'layout-basic',
  template: `
    <layout-default [options]="options" [nav]="nav" [content]="content">
      <ng-template #nav>
        <!-- 側邊導航 -->
      </ng-template>
      <ng-template #content>
        <router-outlet />
      </ng-template>
    </layout-default>
  `
})
export class LayoutBasicComponent { }
```

**路由使用**:
```typescript
{
  path: '',
  component: LayoutBasicComponent,
  canActivate: [authSimpleCanActivate],
  children: [
    // 需要登入的路由
  ]
}
```

### 3.2 BlankLayout (LayoutBlankComponent)

**用途**: 無版面裝飾的頁面 (如全螢幕圖表)

```typescript
{
  path: 'data-v',
  component: LayoutBlankComponent,
  children: [
    // 全螢幕內容
  ]
}
```

### 3.3 PassportLayout

**用途**: 登入/註冊頁面版面

```typescript
// layout/passport/passport.component.ts
@Component({
  selector: 'layout-passport',
  template: `
    <div class="passport-container">
      <router-outlet />
    </div>
  `
})
export class PassportLayoutComponent { }
```

---

## 四、版面 Widget

### 4.1 Header Widgets

```
layout/basic/widgets/
├── header-user.component.ts      # 用戶頭像/下拉選單
├── header-notify.component.ts    # 通知圖示
├── header-search.component.ts    # 搜尋框
├── header-fullscreen.component.ts # 全螢幕切換
└── ...
```

### 4.2 Widget 設計原則

```typescript
// ✅ Widget 應該是展示型元件
@Component({
  selector: 'header-user',
  template: `
    <nz-dropdown [nzDropdownMenu]="userMenu">
      <nz-avatar [nzSrc]="userAvatar()"></nz-avatar>
    </nz-dropdown>
    <nz-dropdown-menu #userMenu="nzDropdownMenu">
      <!-- 選單內容 -->
    </nz-dropdown-menu>
  `
})
export class HeaderUserComponent {
  private readonly authContext = inject(AuthContextService);

  readonly userAvatar = computed(() => this.authContext.currentAccount()?.avatar_url);
  readonly userName = computed(() => this.authContext.currentAccount()?.name);
}
```

---

## 五、@delon/theme 整合

### 5.1 LayoutDefaultModule

```typescript
import { LayoutDefaultModule } from '@delon/theme/layout-default';

// 使用 NG-ALAIN 預設版面
<layout-default [options]="options">
  <!-- 版面內容 -->
</layout-default>
```

### 5.2 SettingDrawerModule

```typescript
import { SettingDrawerModule } from '@delon/theme/setting-drawer';

// 設定抽屜 (開發環境用)
<setting-drawer *ngIf="!environment.production" />
```

---

## 六、單一職責原則 (SRP)

### 6.1 Layout 層職責

| ✅ 應該包含 | ❌ 不應該包含 |
|-------------|---------------|
| 版面結構元件 | 業務邏輯 |
| 導航元件 | API 呼叫 |
| Header/Sidebar Widget | 表單處理 |
| 版面樣式 | 資料處理 |

### 6.2 Widget 無業務邏輯原則

```typescript
// ✅ 正確：從 Service 取得資料展示
@Component({ ... })
export class HeaderUserComponent {
  private readonly authContext = inject(AuthContextService);
  readonly userName = computed(() => this.authContext.currentAccount()?.name);
}

// ❌ 錯誤：Widget 直接呼叫 API
@Component({ ... })
export class HeaderUserComponent {
  async loadUserData() {
    // 不應在 Widget 中直接載入資料
    this.user = await this.http.get('/api/user').toPromise();
  }
}
```

---

## 七、路由守衛整合

### 7.1 認證守衛

```typescript
// routes/routes.ts
{
  path: '',
  component: LayoutBasicComponent,
  canActivate: [startPageGuard, authSimpleCanActivate],
  canActivateChild: [authSimpleCanActivateChild],
  children: [
    // 受保護的路由
  ]
}
```

### 7.2 守衛來源

| 守衛 | 來源 | 用途 |
|------|------|------|
| `authSimpleCanActivate` | `@delon/auth` | Token 驗證 |
| `authSimpleCanActivateChild` | `@delon/auth` | 子路由 Token 驗證 |
| `startPageGuard` | `core/` | 啟動頁面檢查 |

---

## 八、Angular 20+ 模板語法

### 8.1 新控制流在版面中的使用

```html
<!-- layout/basic/basic.component.ts -->
<layout-default>
  <layout-default-header-item direction="right">
    @if (isAuthenticated()) {
      <header-user />
    }
  </layout-default-header-item>

  <ng-template #content>
    <router-outlet />
  </ng-template>
</layout-default>
```

### 8.2 Signal 在 Widget 中的使用

```typescript
@Component({ ... })
export class HeaderNotifyComponent {
  private readonly notifyService = inject(NotifyService);

  // 使用 computed signal
  readonly unreadCount = computed(() =>
    this.notifyService.notifications().filter(n => !n.read).length
  );
  readonly hasUnread = computed(() => this.unreadCount() > 0);
}
```

---

## 九、樣式規範

### 9.1 版面樣式文件

```
layout/
├── basic/
│   └── basic.component.less    # 基礎版面樣式
└── passport/
    └── passport.component.less # 登入版面樣式
```

### 9.2 樣式原則

```less
// ✅ 使用 NG-ALAIN 變數
@import '~@delon/theme/styles/default';

.custom-header {
  background: @header-bg;
  height: @header-height;
}

// ❌ 避免硬編碼值
.custom-header {
  background: #fff;  // 應使用變數
  height: 64px;      // 應使用變數
}
```

---

## 十、模組邊界管理

### 10.1 公開 API (index.ts)

```typescript
// layout/index.ts
export { LayoutBasicComponent } from './basic/basic.component';
export { LayoutBlankComponent } from './blank/blank.component';
export { PassportLayoutComponent } from './passport/passport.component';
```

### 10.2 依賴規則

```
layout/ 可以依賴：
├── core/          # ✅ 認證服務
├── shared/        # ✅ 共享元件
├── @angular/*
├── @delon/theme
└── ng-zorro-antd

layout/ 不可依賴：
├── routes/        # ❌
└── features/      # ❌
```

---

## 十一、Context7 MCP 查詢指引

### 應查詢 MCP 的情況

1. **@delon/theme 版面配置** - LayoutDefault 選項
2. **NG-ALAIN 版面自訂** - Header、Sidebar 自訂
3. **ReuseTab 配置** - 標籤頁重用設定

### 可直接實作的情況

1. 基本版面結構
2. 簡單 Widget 元件
3. 路由出口配置

---

## 十二、相關文件

- [根目錄 AGENTS.md](../../AGENTS.md) - 專案總覽
- [app/AGENTS.md](../AGENTS.md) - 應用層級指引
- [routes/AGENTS.md](../routes/AGENTS.md) - 路由層指引 (使用 layout)
- [core/AGENTS.md](../core/AGENTS.md) - 核心層指引 (layout 依賴 core)
