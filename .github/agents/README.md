# GitHub Copilot Custom Agents

本目錄包含 GitHub Copilot 自訂代理配置檔案，專為 Angular / ng-alain / Supabase 企業級開發設計。

## 如何使用 GitHub Copilot Agent

在 VS Code 或 GitHub Copilot Chat 中，您可以透過 `@` 符號呼叫特定代理。例如：
- `@0-ng-ArchAI-v1` - 呼叫 ng-alain 企業級架構師
- `@debug` - 呼叫除錯模式
- `@plan` - 呼叫規劃模式

---

## 專案專屬代理（Project-Specific Agents）

### `0-ng-ArchAI-v1.agent.md`
**名稱**: ng-alain Enterprise Architect  
**描述**: 企業級 Angular 20 + ng-alain + Supabase 智能開發助手

**適用場景**:
- Angular 20+ 企業級應用開發
- ng-alain 框架與 @delon 業務元件整合
- ng-zorro-antd UI 元件最佳實踐
- Supabase 後端整合（認證、資料庫、Storage）
- 需求分析 → 架構設計 → 程式碼實作的完整流程
- Token 最佳化與效能調優

---

### `0-ng-governance-v1.md`
**名稱**: ng-alain Governance Rules  
**描述**: ng-alain 企業級開發規範文件

**適用場景**:
- 作為 `0-ng-ArchAI-v1` 的規範參考文件
- 檢查程式碼是否符合企業級標準
- 架構審查與程式碼品質驗證

---

## 通用開發代理（General Development Agents）

### 規劃與研究類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `plan.agent.md` | Plan Mode | 策略規劃與架構分析，實作前的深思熟慮 |
| `planner.agent.md` | Planning Mode | 功能開發或重構的實作計畫產出 |
| `implementation-plan.agent.md` | Implementation Plan | 新功能或重構的實作計畫產出 |
| `task-planner.agent.md` | Task Planner | 可執行的任務規劃（by microsoft/edge-ai）|
| `task-researcher.agent.md` | Task Researcher | 專案分析的深度研究（by microsoft/edge-ai）|
| `research-technical-spike.agent.md` | Technical Spike Research | 技術驗證與深度研究 |
| `prd.agent.md` | PRD Generator | 產品需求文件（PRD）產出，含使用者故事、驗收標準 |
| `specification.agent.md` | Specification | 規格文件產出與更新 |
| `refine-issue.agent.md` | Refine Issue | 需求精煉：驗收標準、技術考量、邊界案例、NFR |

### 程式碼品質類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `janitor.agent.md` | Janitor | 程式碼清理、簡化、技術債務處理 |

### 除錯與測試類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `debug.agent.md` | Debug Mode | 系統性除錯，識別、分析並解決 bug |
| `playwright-tester.agent.md` | Playwright Tester | Playwright E2E 測試開發 |

### 文件與教學類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `mentor.agent.md` | Mentor | 工程師指導與支援 |
| `demonstrate-understanding.agent.md` | Demonstrate Understanding | 透過引導式問答驗證對程式碼的理解 |

### PR 與 Issue 管理類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `critical-thinking.agent.md` | Critical Thinking | 挑戰假設，確保最佳解決方案 |

### Prompt 工程類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `prompt-builder.agent.md` | Prompt Builder | 高品質 Prompt 工程（by microsoft/edge-ai）|
| `prompt-engineer.agent.md` | Prompt Engineer | Prompt 分析與改進（基於 OpenAI 最佳實踐）|

### 資料庫類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `postgresql-dba.agent.md` | PostgreSQL DBA | PostgreSQL 資料庫管理（適用於 Supabase）|

### TypeScript / MCP 類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `context7.agent.md` | Context7 Expert | 使用最新文件查詢函式庫版本與最佳實踐 |

### Angular / Electron 類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `electron-angular-native.agent.md` | Electron Angular Review | Electron + Angular + 原生整合層的程式碼審查 |

### 架構類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `declarative-agents-architect.agent.md` | Declarative Agents Architect | 宣告式代理架構設計 |

### 其他工具類

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `monday-bug-fixer.agent.md` | Monday Bug Fixer | 從 Monday.com 平台資料豐富任務上下文，提供生產級修復 |

---

## 進階自主代理（Advanced Autonomous Agents）

這些代理具備較高的自主性，適合複雜任務或需要較少監督的場景：

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `4.1-Beast.agent.md` | GPT 4.1 Beast | 頂級程式碼代理，強大自主能力 |
| `Thinking-Beast-Mode.agent.md` | Thinking Beast Mode | 量子認知架構與對抗式智慧 |
| `Ultimate-Transparent-Thinking-Beast-Mode.agent.md` | Ultimate Beast Mode | 終極透明思維模式 |
| `voidbeast-gpt41enhanced.agent.md` | VoidBeast Enhanced | 進階全端開發代理（多模式）|
| `principal-software-engineer.agent.md` | Principal Engineer | 首席工程師級指導 |

---

## 工作流程代理（Workflow Agents）

| 代理檔案 | 名稱 | 適用場景 |
|----------|------|----------|
| `blueprint-mode.agent.md` | Blueprint Mode | 結構化工作流程執行（Debug/Express/Main/Loop）|
| `meta-agentic-project-scaffold.agent.md` | Project Scaffold | 專案工作流程建立與管理 |

---

## 使用建議

### 開發流程推薦

1. **需求階段**: `prd.agent.md` → `refine-issue.agent.md`
2. **規劃階段**: `plan.agent.md` → `implementation-plan.agent.md`
3. **開發階段**: `0-ng-ArchAI-v1.agent.md`（Angular 專案）
4. **測試階段**: `playwright-tester.agent.md`
5. **審查階段**: `critical-thinking.agent.md`
6. **重構階段**: `janitor.agent.md`

### 特定任務推薦

- **Angular/ng-alain 開發**: `0-ng-ArchAI-v1.agent.md`
- **架構設計**: `declarative-agents-architect.agent.md`
- **程式碼審查**: `critical-thinking.agent.md`
- **除錯**: `debug.agent.md`
- **E2E 測試**: `playwright-tester.agent.md`
- **資料庫**: `postgresql-dba.agent.md`

---

## 檔案統計

- **總檔案數**: 51 個（49 個 `.agent.md` + 1 個 `0-ng-governance-v1.md` + 1 個 `README.md`）
- **代理檔案數**: 49 個

---

## 維護記錄

- **2025-11-27**: 從 awesome-copilot 新增 19 個 agents
  - 新增 TDD 工作流程：tdd-red.agent.md, tdd-green.agent.md, tdd-refactor.agent.md
  - 新增架構：arch.agent.md, api-architect.agent.md, adr-generator.agent.md
  - 新增程式碼品質：address-comments.agent.md, code-tour.agent.md, gilfoyle.agent.md, tech-debt-remediation-plan.agent.md
  - 新增專家：typescript-mcp-expert.agent.md, expert-react-frontend-engineer.agent.md, expert-nextjs-developer.agent.md, software-engineer-agent-v1.agent.md
  - 新增安全與文件：accessibility.agent.md, stackhawk-security-onboarding.agent.md, technical-content-evaluator.agent.md, lingodotdev-i18n.agent.md
  - 新增工具：simple-app-idea-generator.agent.md
- **2025-11-26**: 更新 README 以反映實際存在的檔案，移除不存在的代理引用
- **2025-11-25**: 從 awesome-copilot 複製有價值的 agents
- **2025-11-23**: 移除不適用的代理，保留最佳化的 ng-alain 專用代理
