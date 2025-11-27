# GitHub Copilot VS Code 使用指南

本文件詳細說明如何在 VS Code 中使用 GitHub Copilot，包括 prompts、instructions、agents 的使用方式，以及如何搭配 MCP (Model Context Protocol) 實現智能切換與自動化工作流程。

## 📚 目錄

1. [環境準備](#環境準備)
2. [Copilot 基本使用](#copilot-基本使用)
3. [Prompts 使用方式](#prompts-使用方式)
4. [Instructions 自動套用機制](#instructions-自動套用機制)
5. [Agents 切換與使用](#agents-切換與使用)
6. [MCP 整合與自動化](#mcp-整合與自動化)
7. [工作流程推薦](#工作流程推薦)
8. [常見問題](#常見問題)

---

## 環境準備

### 1. 安裝必要的 VS Code 擴充套件

```json
// .vscode/extensions.json
{
  "recommendations": [
    "github.copilot",
    "github.copilot-chat"
  ]
}
```

### 2. 確認 Copilot 設定

在 VS Code 中按 `Ctrl+,` 或 `Cmd+,` 開啟設定，確認以下項目：

```json
{
  "github.copilot.enable": {
    "*": true
  },
  "github.copilot.chat.localeOverride": "zh-TW"  // 可選：設定語言
}
```

### 3. 專案資源位置

| 資源類型 | 位置 | 數量 |
|----------|------|------|
| Prompts | `.github/prompts/` | 69 |
| Instructions | `.github/instructions/` | 32 |
| Agents | `.github/agents/` | 49 |
| Collections | `.github/collections/` | 12 |

---

## Copilot 基本使用

### 開啟 Copilot Chat

- **快捷鍵**: `Ctrl+Shift+I` (Windows/Linux) 或 `Cmd+Shift+I` (Mac)
- **側邊欄**: 點擊左側 Copilot 圖示
- **命令面板**: `Ctrl+Shift+P` → 輸入 "Copilot Chat"

### 基本互動模式

```
# 直接對話
輸入問題或需求，Copilot 會根據當前上下文回答

# 選取程式碼後對話
選取程式碼 → 右鍵 → "Copilot: Explain This" 或直接在 Chat 中詢問

# 內聯建議
在編輯器中輸入時，Copilot 會自動提供補全建議
按 Tab 接受，按 Esc 忽略
```

---

## Prompts 使用方式

### 什麼是 Prompts？

Prompts 是預定義的任務指令，存放在 `.github/prompts/` 目錄中，以 `.prompt.md` 結尾。

### 如何使用 Prompts

**方法 1: 使用 `/` 指令**

在 Copilot Chat 中輸入 `/` 會顯示可用的 prompts：

```
/create-readme          # 建立 README.md
/playwright-generate-test   # 產生 Playwright 測試
/sql-optimization       # SQL 最佳化建議
/conventional-commit    # 產生規範的 commit 訊息
```

**方法 2: 使用 @workspace 搭配 prompts**

```
@workspace /create-implementation-plan 為用戶登入功能建立實作計畫
```

### 常用 Prompts 分類

#### 測試相關
| Prompt | 用途 | 使用方式 |
|--------|------|----------|
| `/javascript-typescript-jest` | 產生 Jest 測試 | 選取函式後使用 |
| `/playwright-generate-test` | 產生 E2E 測試 | 描述測試場景 |
| `/breakdown-test` | 分解測試案例 | 提供功能規格 |

#### 文件相關
| Prompt | 用途 | 使用方式 |
|--------|------|----------|
| `/create-readme` | 建立 README | 在專案根目錄使用 |
| `/documentation-writer` | 撰寫技術文件 | 提供主題或程式碼 |
| `/add-educational-comments` | 新增教學註解 | 選取程式碼後使用 |

#### 資料庫相關
| Prompt | 用途 | 使用方式 |
|--------|------|----------|
| `/sql-optimization` | SQL 最佳化 | 提供 SQL 查詢 |
| `/postgresql-code-review` | PostgreSQL 審查 | 貼上 SQL 程式碼 |

---

## Instructions 自動套用機制

### 什麼是 Instructions？

Instructions 是上下文感知的指令，會根據檔案類型自動套用，存放在 `.github/instructions/` 目錄。

### 自動套用原理

每個 instruction 檔案的 frontmatter 中定義了 `applyTo` 欄位：

```yaml
---
description: 'Angular 開發指引'
applyTo: '**/*.ts, **/*.html, **/*.scss'
---
```

當你開啟符合模式的檔案時，該 instruction 會自動提供上下文給 Copilot。

### 本專案的主要 Instructions

| Instruction | 自動套用檔案 | 用途 |
|-------------|--------------|------|
| `angular.instructions.md` | `**/*.ts, **/*.html` | Angular 最佳實踐 |
| `typescript-5-es2022.instructions.md` | `**/*.ts` | TypeScript 標準 |
| `playwright-typescript.instructions.md` | `**/*.spec.ts` | Playwright 測試 |
| `security-and-owasp.instructions.md` | `**/*` | OWASP 安全指引 |
| `github-actions-ci-cd-best-practices.instructions.md` | `**/*.yml` | CI/CD 最佳實踐 |

### 手動觸發 Instructions

雖然 instructions 會自動套用，但你也可以在 Chat 中明確參考：

```
請根據 security-and-owasp.instructions.md 的指引審查這段程式碼
```

---

## Agents 切換與使用

### 什麼是 Agents？

Agents 是專門化的 AI 助手，各自具有特定的專業領域和行為模式，存放在 `.github/agents/` 目錄。

### 如何切換 Agents

**方法 1: 使用 @ 語法**

在 Copilot Chat 中使用 `@agent-name` 來呼叫特定 agent：

```
@tdd-red 為 UserService 撰寫失敗的測試案例
@tdd-green 讓這些測試通過
@tdd-refactor 重構這段程式碼
```

**方法 2: 在 Chat 模式中切換**

點擊 Chat 視窗上方的 agent 選擇器，選擇要使用的 agent。

### 主要 Agents 分類

#### TDD 工作流程 Agents

```mermaid
graph LR
    A[@tdd-red] --> B[@tdd-green] --> C[@tdd-refactor]
    A -->|寫失敗測試| B
    B -->|讓測試通過| C
    C -->|重構程式碼| A
```

| Agent | 用途 | 使用場景 |
|-------|------|----------|
| `@tdd-red` | 撰寫失敗的測試 | 開始新功能時 |
| `@tdd-green` | 讓測試通過 | 實作功能時 |
| `@tdd-refactor` | 重構程式碼 | 測試通過後 |

#### 架構設計 Agents

| Agent | 用途 | 使用場景 |
|-------|------|----------|
| `@arch` | 架構決策 | 設計系統架構 |
| `@api-architect` | API 設計 | 設計 RESTful/GraphQL API |
| `@adr-generator` | 產生 ADR | 記錄架構決策 |

#### 程式碼品質 Agents

| Agent | 用途 | 使用場景 |
|-------|------|----------|
| `@gilfoyle` | 毒舌程式碼審查 | 嚴格的程式碼審查 |
| `@address-comments` | 處理 PR 評論 | 回應程式碼審查 |
| `@tech-debt-remediation-plan` | 技術債計畫 | 處理技術債 |

#### 專家 Agents

| Agent | 用途 | 使用場景 |
|-------|------|----------|
| `@typescript-mcp-expert` | TypeScript MCP 專家 | MCP 伺服器開發 |
| `@software-engineer-agent-v1` | 軟體工程師 | 一般開發任務 |
| `@accessibility` | 無障礙專家 | a11y 審查與修正 |

---

## MCP 整合與自動化

### 什麼是 MCP (Model Context Protocol)？

MCP 是一種協定，允許 Copilot 與外部工具和服務進行通訊，實現更智能的上下文感知和自動化工作流程。

### 本專案的 MCP 資源

| 資源 | 位置 | 用途 |
|------|------|------|
| `typescript-mcp-server.instructions.md` | `.github/instructions/` | MCP 伺服器開發指引 |
| `typescript-mcp-server-generator.prompt.md` | `.github/prompts/` | 產生 MCP 伺服器 |
| `typescript-mcp-expert.agent.md` | `.github/agents/` | MCP 專家 agent |
| `typescript-mcp-development.collection.yml` | `.github/collections/` | MCP 開發資源集合 |

### 啟用 MCP 功能

#### 1. 設定 VS Code

在 `.vscode/settings.json` 中加入 MCP 相關設定：

```json
{
  "github.copilot.advanced": {
    "debug.overrideProxyUrl": "",
    "debug.testOverrideProxyUrl": ""
  },
  "github.copilot.chat.experimental.mcp": {
    "enabled": true
  }
}
```

#### 2. 建立 MCP 伺服器

使用 prompt 產生 MCP 伺服器：

```
/typescript-mcp-server-generator 建立一個處理 Supabase 操作的 MCP 伺服器
```

#### 3. 設定 MCP 連接

建立 `mcp.json` 設定檔（如有需要）：

```json
{
  "servers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": {
        "SUPABASE_URL": "${env:SUPABASE_URL}",
        "SUPABASE_ANON_KEY": "${env:SUPABASE_ANON_KEY}"
      }
    }
  }
}
```

### 自動切換 Agent 搭配 MCP

#### 場景 1: 資料庫操作自動化

```
# 步驟 1: 使用 MCP 連接 Supabase
@typescript-mcp-expert 設定 Supabase MCP 連接

# 步驟 2: 自動偵測資料庫結構
@workspace 分析 Supabase 資料表結構

# 步驟 3: 產生相關程式碼
@software-engineer-agent-v1 基於資料表結構產生 TypeScript 型別
```

#### 場景 2: 測試自動化工作流程

```
# 自動切換 TDD 工作流程
@tdd-red → 分析需求，撰寫失敗測試
@tdd-green → 實作功能讓測試通過
@tdd-refactor → 重構並優化程式碼

# 搭配 MCP 取得上下文
@playwright-tester 根據 MCP 提供的頁面結構產生 E2E 測試
```

### 進階: 自動化 Agent 切換腳本

你可以建立 VS Code Tasks 來自動化工作流程：

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "TDD Workflow",
      "type": "shell",
      "command": "echo 'Start TDD workflow'",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

---

## 工作流程推薦

### 🚀 功能開發工作流程

```
1. 規劃階段
   /breakdown-plan → @planner → /create-specification

2. 實作階段
   @tdd-red → @tdd-green → @tdd-refactor

3. 審查階段
   @gilfoyle → @address-comments → /conventional-commit
```

### 🧪 測試工作流程

```
1. 單元測試
   /javascript-typescript-jest → @tdd-red → @tdd-green

2. E2E 測試
   /playwright-generate-test → @playwright-tester

3. 資料庫測試
   /sql-code-review → /postgresql-optimization
```

### 📝 文件工作流程

```
1. 專案文件
   /create-readme → /documentation-writer

2. 技術文件
   /create-technical-spike → @adr-generator

3. 程式碼文件
   /add-educational-comments → /update-oo-component-documentation
```

### 🔒 安全審查工作流程

```
1. 程式碼審查
   @gilfoyle → (自動套用 security-and-owasp.instructions)

2. SQL 審查
   /sql-code-review → /postgresql-optimization

3. 無障礙審查
   @accessibility → (自動套用 a11y.instructions)
```

---

## 常見問題

### Q1: Prompts 沒有出現在 `/` 選單中？

**解決方案**:
1. 確認檔案位於 `.github/prompts/` 目錄
2. 確認檔案以 `.prompt.md` 結尾
3. 重新載入 VS Code 視窗 (`Ctrl+Shift+P` → "Reload Window")

### Q2: Instructions 沒有自動套用？

**解決方案**:
1. 確認 `applyTo` 模式正確
2. 確認檔案在 `.github/instructions/` 目錄
3. 開啟新檔案測試套用

### Q3: Agent 無法使用 @ 語法？

**解決方案**:
1. 確認 agent 檔案在 `.github/agents/` 目錄
2. 確認檔案以 `.agent.md` 結尾
3. 確認 Copilot Chat 擴充套件已更新至最新版

### Q4: MCP 連接失敗？

**解決方案**:
1. 確認環境變數已正確設定
2. 確認 MCP 伺服器已安裝
3. 檢查 `mcp.json` 設定是否正確

### Q5: 如何知道有哪些可用資源？

**解決方案**:
```bash
# 列出所有 prompts
ls .github/prompts/*.prompt.md

# 列出所有 agents
ls .github/agents/*.agent.md

# 列出所有 instructions
ls .github/instructions/*.instructions.md
```

或參考 `docs/copilot/AWESOME-COPILOT-SUMMARY.md` 完整說明。

---

## 延伸閱讀

- [GitHub Copilot 官方文件](https://docs.github.com/en/copilot)
- [MCP 協定說明](https://modelcontextprotocol.io/)
- [awesome-copilot 資源庫](https://github.com/github/awesome-copilot)
- [專案 Copilot 資源總覽](./docs/copilot/AWESOME-COPILOT-SUMMARY.md)

---

## 資源統計

| 類型 | 數量 | 位置 |
|------|------|------|
| Prompts | 69 | `.github/prompts/` |
| Instructions | 32 | `.github/instructions/` |
| Agents | 49 | `.github/agents/` |
| Collections | 12 | `.github/collections/` |

---

*最後更新: 2025-11-27*
