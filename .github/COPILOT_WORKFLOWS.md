# 🚀 GitHub Copilot 工作流程指南

> 本文件總結了從 [github/awesome-copilot](https://github.com/github/awesome-copilot) 引入的資源及其在 GigHub 專案中的使用方式。

---

## 📁 目錄結構說明

```
.github/
├── copilot-instructions.md          # 全域 Copilot 指引（自動套用）
├── copilot/                          # Copilot 擴展配置
│   ├── copilot-instructions.md      # 行為規範
│   ├── architecture-rules.md        # 架構決策
│   ├── styleguide.md                # 程式風格
│   ├── domain-glossary.md           # 領域詞彙
│   └── constraints.md               # 系統約束
├── instructions/                     # 🔧 被動套用的指引（根據檔案類型自動載入）
├── prompts/                          # 📝 主動調用的提示模板
├── agents/                           # 🤖 專用 Agent 代理
└── collections/                      # 📦 工具集合
```

---

## 🔧 被動套用的設置 (Instructions)

**這些檔案會根據您編輯的檔案類型自動載入到 Copilot 上下文中。**

### 專案專屬指引（GigHub）
| 檔案 | 適用範圍 | 說明 |
|------|----------|------|
| `gighub-core-principles.instructions.md` | 所有檔案 | 核心開發理念（奧卡姆剃刀、功能最小化） |
| `gighub-angular-development.instructions.md` | `.ts`, `.html`, `.less` | Angular 20 開發實踐 |
| `gighub-architecture-layers.instructions.md` | `.ts` | 三層架構決策 |
| `gighub-supabase-practices.instructions.md` | `.ts`, `.sql` | Supabase 開發規範 |
| `gighub-domain-concepts.instructions.md` | 所有檔案 | 工地領域概念 |
| `gighub-security-quality.instructions.md` | 所有檔案 | 安全與品質規範 |

### 通用開發指引
| 檔案 | 適用範圍 | 說明 |
|------|----------|------|
| `angular.instructions.md` | `.ts`, `.html` | Angular 通用開發指南 |
| `typescript-5-es2022.instructions.md` | `.ts` | TypeScript 5 最佳實踐 |
| `playwright-typescript.instructions.md` | 測試檔案 | E2E 測試指南 |
| `security-and-owasp.instructions.md` | 所有檔案 | OWASP 安全規範 |
| `performance-optimization.instructions.md` | 所有檔案 | 效能優化指南 |
| `github-actions-ci-cd-best-practices.instructions.md` | `.yml` | CI/CD 最佳實踐 |

### 新增的指引（來自 awesome-copilot）
| 檔案 | VSCode 安裝連結 | 說明 |
|------|-----------------|------|
| `reactjs.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/reactjs.instructions.md) | React.js 開發最佳實踐 |
| `vuejs3.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/vuejs3.instructions.md) | Vue.js 3 開發指南 |
| `nextjs.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/nextjs.instructions.md) | Next.js 開發指南 |
| `python.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/python.instructions.md) | Python 開發指南 |
| `sql-sp-generation.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/sql-sp-generation.instructions.md) | SQL 存儲過程生成 |
| `mongo-dba.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/mongo-dba.instructions.md) | MongoDB 管理指南 |
| `ms-sql-dba.instructions.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-instructions?url=https://raw.githubusercontent.com/github/awesome-copilot/main/instructions/ms-sql-dba.instructions.md) | MS SQL 管理指南 |

---

## 📝 主動調用的提示 (Prompts)

**使用方式**: 在 Copilot Chat 中輸入 `/` 並選擇對應的 prompt。

### 專案規劃與設計
| Prompt | 用途 | 使用場景 |
|--------|------|----------|
| `create-specification.prompt.md` | 創建規格文件 | 新功能設計 |
| `create-implementation-plan.prompt.md` | 創建實作計劃 | 開發規劃 |
| `create-architectural-decision-record.prompt.md` | 創建 ADR | 架構決策記錄 |
| `breakdown-feature-prd.prompt.md` | 分解 PRD | 需求分析 |
| `breakdown-epic-arch.prompt.md` | 分解 Epic（架構視角） | 大型功能拆分 |
| `breakdown-epic-pm.prompt.md` | 分解 Epic（PM 視角） | 產品規劃 |

### 程式碼生成與重構
| Prompt | 用途 | 使用場景 |
|--------|------|----------|
| `generate-custom-instructions-from-codebase.prompt.md` | 從代碼生成指引 | 新專案設置 |
| `add-educational-comments.prompt.md` | 添加教學式註解 | 代碼文檔化 |
| `review-and-refactor.prompt.md` | 審查與重構 | 代碼改進 |
| `conventional-commit.prompt.md` | 生成 Commit 訊息 | Git 提交 |

### 測試相關
| Prompt | 用途 | 使用場景 |
|--------|------|----------|
| `breakdown-test.prompt.md` | 測試計劃分解 | 測試規劃 |
| `playwright-generate-test.prompt.md` | 生成 Playwright 測試 | E2E 測試 |
| `pytest-coverage.prompt.md` | 測試覆蓋率分析 | 品質檢查 |

### 新增的提示（來自 awesome-copilot）
| Prompt | VSCode 安裝連結 | 說明 |
|--------|-----------------|------|
| `write-coding-standards-from-file.prompt.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-prompt?url=https://raw.githubusercontent.com/github/awesome-copilot/main/prompts/write-coding-standards-from-file.prompt.md) | 從現有代碼生成編碼規範 |
| `dotnet-best-practices.prompt.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-prompt?url=https://raw.githubusercontent.com/github/awesome-copilot/main/prompts/dotnet-best-practices.prompt.md) | .NET 最佳實踐分析 |
| `dotnet-design-pattern-review.prompt.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-prompt?url=https://raw.githubusercontent.com/github/awesome-copilot/main/prompts/dotnet-design-pattern-review.prompt.md) | 設計模式審查 |

---

## �� 專用 Agent 代理

**使用方式**: 在 Copilot Chat 中使用 `@agent-name` 調用。

### 專案專屬 Agents
| Agent | 用途 |
|-------|------|
| `prd.agent.md` | PRD 文件分析 |
| `planner.agent.md` | 任務規劃 |
| `postgresql-dba.agent.md` | PostgreSQL 資料庫管理 |
| `arch.agent.md` | 架構設計 |
| `blueprint-mode.agent.md` | 藍圖模式開發 |
| `code-tour.agent.md` | 代碼導覽 |

### 代碼審查與品質
| Agent | 用途 |
|-------|------|
| `gilfoyle.agent.md` | Gilfoyle 風格代碼審查 |
| `janitor.agent.md` | 代碼清理 |
| `critical-thinking.agent.md` | 批判性思考分析 |

### 新增的 Agents（來自 awesome-copilot）
| Agent | VSCode 安裝連結 | 說明 |
|-------|-----------------|------|
| `elasticsearch-observability.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/elasticsearch-observability.agent.md) | Elasticsearch 可觀察性專家 |
| `gpt-5-beast-mode.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/gpt-5-beast-mode.agent.md) | 增強思考模式 |
| `neon-optimization-analyzer.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/neon-optimization-analyzer.agent.md) | 數據庫優化分析 |
| `neon-migration-specialist.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/neon-migration-specialist.agent.md) | 數據遷移專家 |
| `hlbpa.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/hlbpa.agent.md) | 高級最佳實踐代理 |
| `wg-code-alchemist.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/wg-code-alchemist.agent.md) | 代碼轉換專家 |
| `wg-code-sentinel.agent.md` | [安裝](vscode-insiders://GitHub.copilot-chat/install-agent?url=https://raw.githubusercontent.com/github/awesome-copilot/main/agents/wg-code-sentinel.agent.md) | 代碼審查哨兵 |

---

## 📦 工具集合 (Collections)

| 集合 | 說明 |
|------|------|
| `project-planning.collection.yml` | 專案規劃工具集 |
| `frontend-web-dev.collection.yml` | 前端開發工具集 |
| `testing-automation.collection.yml` | 測試自動化工具集 |
| `security-best-practices.collection.yml` | 安全最佳實踐工具集 |
| `devops-oncall.collection.yml` | DevOps 值班工具集 |
| `typescript-mcp-development.collection.yml` | TypeScript MCP 開發工具集 |

---

## 🔄 推薦工作流程

### 1️⃣ 新功能開發流程
```
1. 使用 prd.agent.md 分析需求文件
2. 使用 create-specification.prompt.md 創建規格
3. 使用 arch.agent.md 進行架構設計
4. 使用 create-implementation-plan.prompt.md 創建實作計劃
5. 使用 blueprint-mode.agent.md 開發功能
6. 使用 breakdown-test.prompt.md 規劃測試
7. 使用 code-tour.agent.md 創建代碼導覽
```

### 2️⃣ 代碼審查流程
```
1. 使用 gilfoyle.agent.md 進行嚴格審查
2. 使用 wg-code-sentinel.agent.md 進行安全審查
3. 使用 critical-thinking.agent.md 進行邏輯分析
4. 使用 review-and-refactor.prompt.md 進行重構建議
```

### 3️⃣ 測試開發流程
```
1. 使用 breakdown-test.prompt.md 規劃測試策略
2. 使用 playwright-generate-test.prompt.md 生成 E2E 測試
3. 使用 pytest-coverage.prompt.md 分析覆蓋率
```

### 4️⃣ 數據庫優化流程
```
1. 使用 postgresql-dba.agent.md 分析數據庫
2. 使用 neon-optimization-analyzer.agent.md 優化查詢
3. 使用 sql-code-review.prompt.md 審查 SQL
4. 使用 postgresql-optimization.prompt.md 優化建議
```

### 5️⃣ 文檔生成流程
```
1. 使用 add-educational-comments.prompt.md 添加註解
2. 使用 create-readme.prompt.md 生成 README
3. 使用 documentation-writer.prompt.md 撰寫文檔
4. 使用 create-architectural-decision-record.prompt.md 記錄決策
```

---

## 💡 最佳實踐建議

### 對於 Angular 20 + Supabase 開發

1. **始終啟用相關 Instructions**
   - `gighub-angular-development.instructions.md`
   - `gighub-supabase-practices.instructions.md`
   - `typescript-5-es2022.instructions.md`

2. **使用專案特定的 Agents**
   - `blueprint-mode.agent.md` - 藍圖容器開發
   - `postgresql-dba.agent.md` - Supabase 數據庫

3. **遵循架構規範**
   - 參考 `gighub-architecture-layers.instructions.md`
   - 使用三層架構：Foundation / Container / Business

4. **安全優先**
   - 參考 `security-and-owasp.instructions.md`
   - 使用 `wg-code-sentinel.agent.md` 進行安全審查

---

## 📚 相關資源

- [GitHub Copilot 官方文檔](https://docs.github.com/en/copilot)
- [Awesome GitHub Copilot](https://github.com/github/awesome-copilot)
- [ng-alain 文檔](https://ng-alain.com)
- [Supabase 文檔](https://supabase.com/docs)

---

**最後更新**: 2025-11-27
