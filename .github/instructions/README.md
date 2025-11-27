# GitHub Copilot Instructions

本目錄包含 GitHub Copilot 指令配置檔案，提供專案特定的開發指引與最佳實踐。

## 如何使用 Instructions

在 VS Code 的 Copilot Chat 中，Instructions 會自動套用到相關的檔案類型，為 AI 助手提供上下文感知的開發指引。

---

## 指令檔案列表

### Angular 相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `angular.instructions.md` | Angular 開發指引 | Angular 專案開發標準與最佳實踐 |

### TypeScript 相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `typescript-5-es2022.instructions.md` | TypeScript 5 ES2022 | TypeScript 5 與 ES2022 標準開發指引 |

### 測試相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `playwright-python.instructions.md` | Playwright Python | Playwright Python 測試框架指引 |

### 程式碼品質相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `gilfoyle-code-review.instructions.md` | Gilfoyle 程式碼審查 | 毒舌但精準的程式碼審查指引 |
| `self-explanatory-code-commenting.instructions.md` | 自解釋程式碼註解 | 程式碼註解最佳實踐 |

### Prompt 工程相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `prompt.instructions.md` | Prompt 工程指引 | Prompt 工程最佳實踐 |
| `ai-prompt-engineering-safety-best-practices.instructions.md` | AI Prompt 安全性最佳實踐 | AI Prompt 安全性與最佳實踐 |

### Copilot 使用相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `instructions.instructions.md` | Instructions 使用指引 | Instructions 檔案的使用說明 |
| `copilot-thought-logging.instructions.md` | Copilot 思考日誌 | Copilot 思考過程記錄指引 |
| `taming-copilot.instructions.md` | 馴服 Copilot | 有效使用 Copilot 的技巧與策略 |

### 架構相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `dotnet-architecture-good-practices.instructions.md` | .NET 架構最佳實踐 | .NET 架構設計最佳實踐 |

### 平台相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `pcf-code-components.instructions.md` | PCF 程式碼元件 | Power Apps Component Framework 程式碼元件指引 |
| `pcf-model-driven-apps.instructions.md` | PCF 模型驅動應用 | Power Apps Component Framework 模型驅動應用指引 |

### 工具相關

| 指令檔案 | 描述 | 適用場景 |
|----------|------|----------|
| `shell.instructions.md` | Shell 指令指引 | Shell 指令與腳本開發指引 |

---

## 檔案統計

- **總檔案數**: 33 個（32 個指令檔案 + 1 個 `README.md`）
- **指令檔案數**: 32 個

---

## 維護記錄

- **2025-11-27**: 從 awesome-copilot 新增 18 個 instructions
  - 新增可訪問性：a11y.instructions.md
  - 新增效能與安全性：performance-optimization.instructions.md, security-and-owasp.instructions.md
  - 新增 CI/CD：github-actions-ci-cd-best-practices.instructions.md, containerization-docker-best-practices.instructions.md, kubernetes-deployment-best-practices.instructions.md, devops-core-principles.instructions.md
  - 新增測試：playwright-typescript.instructions.md, nodejs-javascript-vitest.instructions.md
  - 新增開發流程：spec-driven-workflow-v1.instructions.md, task-implementation.instructions.md, tasksync.instructions.md
  - 新增程式碼品質：object-calisthenics.instructions.md
  - 新增 TypeScript MCP：typescript-mcp-server.instructions.md
  - 新增文件：markdown.instructions.md, memory-bank.instructions.md, localization.instructions.md, collections.instructions.md
- **2025-11-26**: 建立完整的 README 文件，列出所有指令檔案

