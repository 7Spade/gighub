# 📦 Feature 模組範本

> 建立完整功能模組的結構範本

---

## 目錄結構

```
src/app/features/{feature}/
├── {feature}.routes.ts          # 路由配置
├── index.ts                     # 公開 API
│
├── domain/                      # 領域層
│   ├── models/
│   │   └── {feature}.model.ts
│   ├── interfaces/
│   │   └── {feature}.interface.ts
│   ├── types/
│   │   └── {feature}.types.ts
│   ├── enums/
│   │   └── {feature}-status.enum.ts
│   └── index.ts
│
├── data-access/                 # 資料存取層
│   ├── repositories/
│   │   └── {feature}.repository.ts
│   ├── stores/
│   │   └── {feature}.store.ts
│   ├── services/
│   │   └── {feature}.service.ts
│   └── index.ts
│
├── shell/                       # 智能元件層
│   ├── {feature}-shell/
│   │   ├── {feature}-shell.component.ts
│   │   ├── {feature}-shell.component.html
│   │   └── {feature}-shell.component.less
│   ├── dialogs/
│   │   └── {feature}-dialog/
│   │       ├── {feature}-dialog.component.ts
│   │       ├── {feature}-dialog.component.html
│   │       └── {feature}-dialog.component.less
│   └── index.ts
│
├── ui/                          # 展示元件層
│   ├── {feature}-list/
│   │   ├── {feature}-list.component.ts
│   │   ├── {feature}-list.component.html
│   │   └── {feature}-list.component.less
│   ├── {feature}-card/
│   │   ├── {feature}-card.component.ts
│   │   ├── {feature}-card.component.html
│   │   └── {feature}-card.component.less
│   └── index.ts
│
├── utils/                       # 工具函數
│   └── {feature}.utils.ts
│
└── constants/                   # 常數配置
    └── {feature}.constants.ts
```

---

## 檔案範本

### 1. 路由配置 `{feature}.routes.ts`

```typescript
import { Routes } from '@angular/router';

export const {FEATURE}_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./shell/{feature}-shell/{feature}-shell.component').then(
        m => m.{Feature}ShellComponent
      ),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./ui/{feature}-list/{feature}-list.component').then(
            m => m.{Feature}ListComponent
          ),
      },
      {
        path: ':id',
        loadComponent: () =>
          import('./ui/{feature}-detail/{feature}-detail.component').then(
            m => m.{Feature}DetailComponent
          ),
      },
    ],
  },
];
```

### 2. 公開 API `index.ts`

```typescript
// Routes
export { {FEATURE}_ROUTES } from './{feature}.routes';

// Domain (公開類型)
export * from './domain';

// Constants
export * from './constants';

// Public Components (如需跨功能使用)
// export { {Feature}ShellComponent } from './shell';
// export { {Feature}ListComponent } from './ui';

// Store (Facade API)
// export { {Feature}Store } from './data-access';
```

### 3. 領域層 `domain/index.ts`

```typescript
// Models
export * from './models/{feature}.model';

// Interfaces
export * from './interfaces/{feature}.interface';

// Types
export * from './types/{feature}.types';

// Enums
export * from './enums/{feature}-status.enum';
```

### 4. 領域模型 `domain/models/{feature}.model.ts`

```typescript
import { {Feature}Status } from '../enums/{feature}-status.enum';

export interface {Feature} {
  id: string;
  name: string;
  description: string;
  status: {Feature}Status;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}
```

### 5. 介面定義 `domain/interfaces/{feature}.interface.ts`

```typescript
import { {Feature}Status } from '../enums/{feature}-status.enum';

export interface Create{Feature}Dto {
  name: string;
  description?: string;
  status?: {Feature}Status;
}

export interface Update{Feature}Dto {
  name?: string;
  description?: string;
  status?: {Feature}Status;
}

export interface {Feature}Filter {
  status?: {Feature}Status;
  search?: string;
}
```

### 6. 類型定義 `domain/types/{feature}.types.ts`

```typescript
import { {Feature} } from '../models/{feature}.model';

export type {Feature}CreateInput = Omit<{Feature}, 'id' | 'createdAt' | 'updatedAt'>;
export type {Feature}UpdateInput = Partial<{Feature}CreateInput>;
export type {Feature}ListItem = Pick<{Feature}, 'id' | 'name' | 'status'>;
```

### 7. 列舉定義 `domain/enums/{feature}-status.enum.ts`

```typescript
export enum {Feature}Status {
  DRAFT = 'draft',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ARCHIVED = 'archived',
}

export const {FEATURE}_STATUS_LABELS: Record<{Feature}Status, string> = {
  [{Feature}Status.DRAFT]: '草稿',
  [{Feature}Status.ACTIVE]: '進行中',
  [{Feature}Status.COMPLETED]: '已完成',
  [{Feature}Status.ARCHIVED]: '已封存',
};
```

### 8. 資料存取層 `data-access/index.ts`

```typescript
// Stores
export { {Feature}Store } from './stores/{feature}.store';

// Repositories
export { {Feature}Repository } from './repositories/{feature}.repository';

// Services (如有)
// export { {Feature}Service } from './services/{feature}.service';
```

---

## 使用方式

1. 建立目錄結構：
   ```bash
   mkdir -p src/app/features/{feature}/{domain,data-access,shell,ui}/{models,interfaces,types,enums,repositories,stores,services}
   ```

2. 複製並調整上述範本

3. 在主路由中註冊：
   ```typescript
   // src/app/routes/routes.ts
   {
     path: '{feature}',
     loadChildren: () => import('../features/{feature}/{feature}.routes')
       .then(m => m.{FEATURE}_ROUTES)
   }
   ```

---

**最後更新**: 2025-11-27
