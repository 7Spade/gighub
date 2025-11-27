# Awesome Copilot Resources Summary

This document provides a comprehensive summary of all GitHub Copilot prompts, instructions, agents, and collections that have been set up in this repository from the [awesome-copilot](https://github.com/github/awesome-copilot) repository.

## 📚 Table of Contents

1. [Overview](#overview)
2. [How to Use](#how-to-use)
3. [Prompts](#prompts)
4. [Instructions](#instructions)
5. [Agents](#agents)
6. [Collections](#collections)
7. [Workflows](#workflows)
8. [VS Code Installation](#vs-code-installation)

---

## Overview

This Angular 20 ng-alain application has been enhanced with GitHub Copilot resources to assist in:

- **Development workflows** - Planning, implementation, and testing
- **Code quality** - Code review, refactoring, and best practices
- **Documentation** - README, ADR, and component documentation
- **DevOps** - CI/CD, Docker, and deployment
- **Security** - OWASP, security scanning, and auditing
- **Testing** - Unit tests, E2E with Playwright, and TDD workflows

---

## How to Use

### In VS Code Copilot Chat

1. **Prompts**: Type `/` followed by the prompt name (e.g., `/create-readme`)
2. **Agents**: Use `@agent-name` syntax (e.g., `@tdd-red`)
3. **Instructions**: Automatically applied based on file type via `applyTo` patterns

### Installation Links

To install individual resources, use the VS Code Insiders install links provided below.

---

## Prompts

Location: `.github/prompts/`

### Testing Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `javascript-typescript-jest.prompt.md` | Generate Jest unit tests for TypeScript/JavaScript | `/javascript-typescript-jest` |
| `playwright-generate-test.prompt.md` | Generate Playwright E2E tests | `/playwright-generate-test` |
| `playwright-explore-website.prompt.md` | Explore and test website with Playwright | `/playwright-explore-website` |
| `breakdown-test.prompt.md` | Break down features into test cases | `/breakdown-test` |

### SQL/Database Prompts (Supabase)

| Prompt | Description | Usage |
|--------|-------------|-------|
| `sql-code-review.prompt.md` | Review SQL code for best practices | `/sql-code-review` |
| `sql-optimization.prompt.md` | Optimize SQL queries | `/sql-optimization` |
| `postgresql-code-review.prompt.md` | PostgreSQL-specific code review | `/postgresql-code-review` |
| `postgresql-optimization.prompt.md` | PostgreSQL optimization | `/postgresql-optimization` |

### Documentation Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `documentation-writer.prompt.md` | Generate technical documentation | `/documentation-writer` |
| `add-educational-comments.prompt.md` | Add educational comments to code | `/add-educational-comments` |
| `update-oo-component-documentation.prompt.md` | Update OO component docs | `/update-oo-component-documentation` |
| `create-technical-spike.prompt.md` | Create technical spike documents | `/create-technical-spike` |
| `create-readme.prompt.md` | Generate README files | `/create-readme` |
| `create-agentsmd.prompt.md` | Generate AGENTS.md file | `/create-agentsmd` |

### Git/GitHub Workflow Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `conventional-commit.prompt.md` | Generate conventional commit messages | `/conventional-commit` |
| `git-flow-branch-creator.prompt.md` | Create Git flow branches | `/git-flow-branch-creator` |
| `my-issues.prompt.md` | List and manage your GitHub issues | `/my-issues` |
| `my-pull-requests.prompt.md` | List and manage your PRs | `/my-pull-requests` |

### DevOps Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `multi-stage-dockerfile.prompt.md` | Create multi-stage Dockerfiles | `/multi-stage-dockerfile` |
| `editorconfig.prompt.md` | Generate .editorconfig files | `/editorconfig` |

### Code Generation Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `typescript-mcp-server-generator.prompt.md` | Generate TypeScript MCP servers | `/typescript-mcp-server-generator` |
| `generate-custom-instructions-from-codebase.prompt.md` | Generate Copilot instructions from code | `/generate-custom-instructions-from-codebase` |

### Architecture and Planning Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `architecture-blueprint-generator.prompt.md` | Generate architecture blueprints | `/architecture-blueprint-generator` |
| `breakdown-plan.prompt.md` | Break down epics into tasks | `/breakdown-plan` |
| `create-implementation-plan.prompt.md` | Create implementation plans | `/create-implementation-plan` |
| `create-specification.prompt.md` | Create specifications | `/create-specification` |

### Utility Prompts

| Prompt | Description | Usage |
|--------|-------------|-------|
| `shuffle-json-data.prompt.md` | Shuffle/anonymize JSON data | `/shuffle-json-data` |
| `update-markdown-file-index.prompt.md` | Update markdown file indexes | `/update-markdown-file-index` |
| `repo-story-time.prompt.md` | Generate repo story/history | `/repo-story-time` |
| `create-llms.prompt.md` | Create LLMs.txt file | `/create-llms` |
| `update-llms.prompt.md` | Update LLMs.txt file | `/update-llms` |

---

## Instructions

Location: `.github/instructions/`

### Accessibility and UX

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `a11y.instructions.md` | Web accessibility guidelines | `**/*.html, **/*.tsx` |

### Performance and Security

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `performance-optimization.instructions.md` | Performance optimization | `**/*` |
| `security-and-owasp.instructions.md` | OWASP security guidelines | `**/*` |

### CI/CD and DevOps

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `github-actions-ci-cd-best-practices.instructions.md` | GitHub Actions best practices | `**/*.yml, **/*.yaml` |
| `containerization-docker-best-practices.instructions.md` | Docker best practices | `**/Dockerfile*` |
| `kubernetes-deployment-best-practices.instructions.md` | Kubernetes deployment | `**/*.yaml, **/*.yml` |
| `devops-core-principles.instructions.md` | Core DevOps principles | `**/*` |

### Testing

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `playwright-typescript.instructions.md` | Playwright TypeScript testing | `**/*.spec.ts` |
| `nodejs-javascript-vitest.instructions.md` | Vitest testing guidelines | `**/*.test.ts` |

### Development Workflow

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `spec-driven-workflow-v1.instructions.md` | Specification-driven workflow | `**/*` |
| `task-implementation.instructions.md` | Task implementation patterns | `**/*` |
| `tasksync.instructions.md` | Task synchronization | `**/*` |

### Code Quality

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `object-calisthenics.instructions.md` | Object calisthenics rules | `**/*.ts` |
| `self-explanatory-code-commenting.instructions.md` | Code commenting standards | `**/*` |

### TypeScript and Angular

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `typescript-5-es2022.instructions.md` | TypeScript 5 ES2022 standards | `**/*.ts` |
| `angular.instructions.md` | Angular development | `**/*.ts, **/*.html` |
| `typescript-mcp-server.instructions.md` | MCP server development | `**/*.ts` |

### Documentation

| Instruction | Description | ApplyTo |
|-------------|-------------|---------|
| `markdown.instructions.md` | Markdown writing | `**/*.md` |
| `memory-bank.instructions.md` | Memory bank patterns | `**/*` |
| `localization.instructions.md` | i18n/l10n guidelines | `**/*` |

---

## Agents

Location: `.github/agents/`

### Testing Agents (TDD Workflow)

| Agent | Description | Usage |
|-------|-------------|-------|
| `tdd-red.agent.md` | Write failing tests first | `@tdd-red` |
| `tdd-green.agent.md` | Make tests pass | `@tdd-green` |
| `tdd-refactor.agent.md` | Refactor code | `@tdd-refactor` |
| `playwright-tester.agent.md` | E2E testing specialist | `@playwright-tester` |

### Architecture and Planning Agents

| Agent | Description | Usage |
|-------|-------------|-------|
| `arch.agent.md` | Architecture decisions | `@arch` |
| `api-architect.agent.md` | API design specialist | `@api-architect` |
| `adr-generator.agent.md` | ADR document generator | `@adr-generator` |
| `plan.agent.md` | Project planning | `@plan` |
| `planner.agent.md` | Task planning | `@planner` |

### Code Quality Agents

| Agent | Description | Usage |
|-------|-------------|-------|
| `address-comments.agent.md` | Address PR comments | `@address-comments` |
| `code-tour.agent.md` | Code tour generator | `@code-tour` |
| `gilfoyle.agent.md` | Sarcastic code reviewer | `@gilfoyle` |
| `tech-debt-remediation-plan.agent.md` | Tech debt planning | `@tech-debt-remediation-plan` |

### Expert Agents

| Agent | Description | Usage |
|-------|-------------|-------|
| `typescript-mcp-expert.agent.md` | TypeScript MCP expert | `@typescript-mcp-expert` |
| `expert-react-frontend-engineer.agent.md` | React frontend expert | `@expert-react-frontend-engineer` |
| `expert-nextjs-developer.agent.md` | Next.js expert | `@expert-nextjs-developer` |
| `software-engineer-agent-v1.agent.md` | General software engineer | `@software-engineer-agent-v1` |
| `principal-software-engineer.agent.md` | Principal engineer | `@principal-software-engineer` |

### Security and Documentation Agents

| Agent | Description | Usage |
|-------|-------------|-------|
| `accessibility.agent.md` | Accessibility specialist | `@accessibility` |
| `stackhawk-security-onboarding.agent.md` | Security onboarding | `@stackhawk-security-onboarding` |
| `technical-content-evaluator.agent.md` | Content evaluation | `@technical-content-evaluator` |
| `lingodotdev-i18n.agent.md` | Internationalization | `@lingodotdev-i18n` |

### Utility Agents

| Agent | Description | Usage |
|-------|-------------|-------|
| `simple-app-idea-generator.agent.md` | Generate app ideas | `@simple-app-idea-generator` |
| `research-technical-spike.agent.md` | Technical research | `@research-technical-spike` |
| `task-researcher.agent.md` | Task research | `@task-researcher` |

---

## Collections

Location: `.github/collections/`

| Collection | Description |
|------------|-------------|
| `awesome-copilot.md` | Meta collection for discovering Copilot resources |
| `frontend-web-dev.md` | Frontend web development resources |
| `testing-automation.md` | Testing and automation resources |
| `project-planning.md` | Project planning resources |
| `database-data-management.md` | Database management resources |
| `security-best-practices.md` | Security resources |
| `technical-spike.md` | Technical spike resources |
| `typescript-mcp-development.md` | TypeScript MCP development |
| `devops-oncall.md` | DevOps on-call resources |

---

## Workflows

### Feature Development Workflow

1. **Planning Phase**
   ```
   /breakdown-plan -> @planner -> /create-specification
   ```

2. **Implementation Phase**
   ```
   @tdd-red -> @tdd-green -> @tdd-refactor
   ```

3. **Review Phase**
   ```
   @address-comments -> /conventional-commit -> /my-pull-requests
   ```

### Testing Workflow

1. **Unit Testing**
   ```
   /javascript-typescript-jest -> @tdd-red -> @tdd-green
   ```

2. **E2E Testing**
   ```
   /playwright-generate-test -> @playwright-tester -> /playwright-explore-website
   ```

3. **Database Testing**
   ```
   /sql-code-review -> /postgresql-optimization
   ```

### Documentation Workflow

1. **Project Documentation**
   ```
   /create-readme -> /create-agentsmd -> /update-markdown-file-index
   ```

2. **Technical Documentation**
   ```
   /create-technical-spike -> @adr-generator -> /documentation-writer
   ```

3. **Code Documentation**
   ```
   /add-educational-comments -> /update-oo-component-documentation
   ```

### Security Workflow

1. **Security Review**
   ```
   @stackhawk-security-onboarding -> (security-and-owasp.instructions)
   ```

2. **Code Audit**
   ```
   /sql-code-review -> @gilfoyle -> @address-comments
   ```

### Architecture Workflow

1. **Architecture Planning**
   ```
   @arch -> /architecture-blueprint-generator -> @adr-generator
   ```

2. **API Design**
   ```
   @api-architect -> /create-specification -> /create-implementation-plan
   ```

### DevOps Workflow

1. **Containerization**
   ```
   /multi-stage-dockerfile -> (containerization-docker-best-practices.instructions)
   ```

2. **CI/CD**
   ```
   (github-actions-ci-cd-best-practices.instructions) -> /editorconfig
   ```

---

## VS Code Installation

### Installing Prompts

To use prompts in VS Code, they are automatically available in Copilot Chat when placed in `.github/prompts/`.

**Usage**: Open Copilot Chat and type `/` followed by the prompt name.

### Installing Instructions

Instructions in `.github/instructions/` are automatically applied based on the `applyTo` pattern in their frontmatter.

### Installing Agents

Agents in `.github/agents/` are available via the `@agent-name` syntax in Copilot Chat.

### VS Code Insiders Install Links

For individual resource installation from awesome-copilot:

```
vscode-insiders://github.copilot-chat/installPrompt?name=PROMPT_NAME&url=https://github.com/github/awesome-copilot/blob/main/prompts/PROMPT_NAME.prompt.md
```

Replace `PROMPT_NAME` with the desired prompt name (without extension).

---

## Project-Specific Recommendations

For this **Angular 20 ng-alain + Supabase** project:

### Daily Development
- Use `@tdd-red` -> `@tdd-green` -> `@tdd-refactor` for TDD
- Use `/playwright-generate-test` for E2E tests
- Apply `angular.instructions.md` for Angular best practices

### Database Work (Supabase)
- Use `/postgresql-code-review` for SQL review
- Use `/sql-optimization` for query optimization
- Follow RLS best practices from existing workflows

### Code Review
- Use `@address-comments` to handle PR feedback
- Use `@gilfoyle` for critical code review
- Apply `object-calisthenics.instructions.md` for clean code

### Documentation
- Use `/create-readme` for README generation
- Use `/documentation-writer` for technical docs
- Use `@adr-generator` for architecture decisions

---

## Source

All resources are sourced from [github/awesome-copilot](https://github.com/github/awesome-copilot).

## Maintenance

- **Last Updated**: 2025-11-27
- **Copilot Resources Version**: Latest from awesome-copilot
- **Project Tech Stack**: Angular 20.3.0, TypeScript 5.9.2, ng-alain 20.1.0, Supabase 2.84.0
