# Copilot Instructions

This file provides repository-level context and instructions for GitHub Copilot when working in this codebase.

## 📚 開發指南文件 (Development Guidelines)

本專案的開發理念與規範來自 `KEEP.md`，已整理為以下指引文件，Copilot 將自動套用：

| 指引文件 | 說明 | 適用範圍 |
|----------|------|----------|
| `gighub-core-principles.instructions.md` | 核心開發理念（奧卡姆剃刀、功能最小化） | 所有檔案 |
| `gighub-angular-development.instructions.md` | Angular 20 開發實踐（Standalone、Signals） | `.ts`, `.html`, `.less` |
| `gighub-architecture-layers.instructions.md` | 三層架構決策（Foundation/Container/Business） | `.ts` |
| `gighub-supabase-practices.instructions.md` | Supabase 開發規範（Repository 模式、RLS） | `.ts`, `.sql` |
| `gighub-domain-concepts.instructions.md` | 工地領域概念（任務系統、施工日誌） | 所有檔案 |
| `gighub-security-quality.instructions.md` | 安全與品質規範（測試、安全） | 所有檔案 |

> 這些指引文件位於 `.github/instructions/` 目錄，會根據編輯的檔案類型自動載入。

---

## Project Overview

This is an Angular 20 enterprise application scaffold based on the **ng-alain** framework, using **ng-zorro-antd** component library and **@delon** business component packages.

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Angular | 20.3.0 | Frontend framework |
| TypeScript | 5.9.2 | Language |
| ng-alain | 20.1.0 | Admin panel framework |
| ng-zorro-antd | 20.3.1 | UI component library |
| @delon/* | 20.1.0 | Business component packages |
| Supabase | 2.84.0 | Backend-as-a-Service |
| RxJS | 7.8.x | Reactive programming |
| LESS | - | CSS preprocessor |

## Development Commands

```bash
# Install dependencies
yarn install

# Start development server with HMR
yarn start        # or: ng s -o
yarn hmr          # with Hot Module Replacement

# Build for production
yarn build

# Linting
yarn lint         # Run all linting (TypeScript + LESS)
yarn lint:ts      # TypeScript/HTML linting only
yarn lint:style   # LESS/CSS linting only

# Testing
yarn test                                         # Unit tests in watch mode
yarn test-coverage                                # Unit tests with coverage
ng test --browsers=ChromeHeadless --no-watch     # CI headless testing
yarn e2e                                          # End-to-end tests (Playwright)
```

## Project Structure

```
src/
├── app/
│   ├── core/           # Core services, guards, interceptors
│   │   ├── facades/    # Service facades
│   │   ├── i18n/       # Internationalization
│   │   ├── infra/      # Infrastructure services
│   │   ├── net/        # HTTP/Network services
│   │   └── startup/    # Application bootstrapping
│   ├── features/       # Feature modules (domain-specific)
│   ├── layout/         # Layout components (header, sidebar, etc.)
│   ├── routes/         # Route configurations and views
│   └── shared/         # Shared modules, components, utilities
├── assets/             # Static assets (images, fonts, etc.)
├── environments/       # Environment configurations
└── styles/             # Global styles and themes

_mock/                  # Mock API data for development
supabase/               # Supabase migrations and configuration
e2e/                    # End-to-end test files
```

## Path Aliases

When importing modules, use these TypeScript path aliases:

```typescript
import { ... } from '@shared';       // src/app/shared/index
import { ... } from '@core';         // src/app/core/index
import { ... } from '@features';     // src/app/features/index
import { ... } from '@features/xyz'; // src/app/features/xyz
import { ... } from '@env/*';        // src/environments/*
import { ... } from '@_mock';        // _mock/index
```

## Coding Standards

### Angular Component Guidelines

- Use **standalone components** by default
- Use **Angular Signals** for state management (`signal()`, `computed()`, `effect()`)
- Use function-based APIs for component inputs/outputs:
  - `input()`, `output()` instead of decorators
  - `viewChild()`, `viewChildren()`, `contentChild()`, `contentChildren()`
- Prefer `OnPush` change detection strategy for performance
- Use the `inject()` function for dependency injection in standalone components

### File Naming Conventions

Follow ng-alain naming conventions:

- Components: `feature.component.ts`
- Services: `feature.service.ts`
- Guards: `feature.guard.ts`
- Pipes: `feature.pipe.ts`
- Directives: `feature.directive.ts`
- Models/Interfaces: `feature.model.ts` or `feature.interface.ts`

### Style Guidelines

- Use **LESS** for component styles
- Follow ng-zorro-antd theming patterns
- Use ng-alain's built-in utility classes when available
- Keep component styles scoped (ViewEncapsulation.Emulated is default)

### Import Organization

Imports must be ordered alphabetically within groups, with newlines between groups:

```typescript
// External packages first
import { Component, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';

// Internal modules next
import { SharedModule } from '@shared';

// Relative imports last
import { MyService } from './my.service';
```

## Testing Guidelines

### Unit Tests

- Use **Jasmine** with **Karma** for unit testing
- Write tests for components, services, and pipes
- Use `TestBed` for component testing with mocked dependencies
- Mock HTTP requests using `provideHttpClientTesting`
- Test file naming: `feature.spec.ts`

### E2E Tests

- Use **Playwright** for end-to-end testing
- Configuration: `playwright.config.ts`
- Test files location: `e2e/`

## @delon Package Usage

This project uses @delon packages for business functionality:

- **@delon/abc** - Basic business components
- **@delon/acl** - Access Control List functionality
- **@delon/auth** - User authentication
- **@delon/cache** - Caching utilities
- **@delon/chart** - Chart components
- **@delon/form** - Dynamic form generation
- **@delon/mock** - Mock API support
- **@delon/theme** - Theme and layout services
- **@delon/util** - Utility functions

Refer to https://ng-alain.com for @delon documentation.

## Supabase Integration

The project integrates with Supabase for backend services. Configuration and migrations are in the `supabase/` directory.

## Things to Avoid

- Do NOT use `@Input()` and `@Output()` decorators - use `input()` and `output()` functions instead
- Do NOT bypass Angular's security (e.g., avoid `innerHTML` without sanitization)
- Do NOT commit environment secrets or API keys
- Do NOT modify files in `node_modules/`, `dist/`, or `.angular/`
- Do NOT add inline styles - use component LESS files or ng-alain utilities
- Do NOT use `any` type without explicit justification

## Additional Resources

- [ng-alain Documentation](https://ng-alain.com)
- [Angular Documentation](https://angular.dev)
- [ng-zorro-antd Documentation](https://ng.ant.design)
- [@delon Packages](https://github.com/ng-alain/delon)
- [Supabase Documentation](https://supabase.com/docs)

---

## 📁 相關文件結構 (Related Documentation)

```
.github/
├── copilot-instructions.md          # 本文件（Copilot 全域指引）
├── copilot/                          # Copilot 擴展配置
│   ├── copilot-instructions.md      # Copilot 行為規範
│   ├── architecture-rules.md        # 架構決策規則
│   ├── constraints.md               # 系統約束與反模式
│   ├── domain-glossary.md           # 領域專有名詞
│   └── styleguide.md                # 程式風格指南
└── instructions/                     # 自動套用的指引文件
    ├── gighub-core-principles.instructions.md
    ├── gighub-angular-development.instructions.md
    ├── gighub-architecture-layers.instructions.md
    ├── gighub-supabase-practices.instructions.md
    ├── gighub-domain-concepts.instructions.md
    └── gighub-security-quality.instructions.md
```

> **原始來源**: 所有開發理念均源自 `KEEP.md` 專案關鍵詞清單
