# GitHub Copilot VS Code 使用指南

本文件詳細說明如何在 VS Code 中使用 GitHub Copilot，包括 prompts、instructions、agents 的使用方式，以及如何搭配 MCP (Model Context Protocol) 實現智能切換與自動化工作流程。

## 📚 目錄

1. [環境準備](#環境準備)
2. [Copilot 基本使用](#copilot-基本使用)
3. [Prompts 使用方式（含示範）](#prompts-使用方式含示範)
4. [Instructions 自動套用機制（含示範）](#instructions-自動套用機制含示範)
5. [Agents 切換與使用（含示範）](#agents-切換與使用含示範)
6. [MCP 整合與自動化（含示範）](#mcp-整合與自動化含示範)
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

---

## Prompts 使用方式（含示範）

### 什麼是 Prompts？

Prompts 是預定義的任務指令，存放在 `.github/prompts/` 目錄中，以 `.prompt.md` 結尾。

### 📌 示範 1: 使用 `/create-readme` 產生 README

**輸入指令：**
```
/create-readme
```

**Copilot 回應範例：**
```markdown
# 專案名稱

## 📋 專案描述
這是一個基於 Angular 20 和 ng-alain 框架的企業級應用程式...

## 🚀 快速開始
### 安裝依賴
npm install

### 啟動開發伺服器
npm start

## 📁 專案結構
src/
├── app/
│   ├── core/        # 核心服務
│   ├── features/    # 功能模組
│   └── shared/      # 共用元件
...
```

---

### 📌 示範 2: 使用 `/javascript-typescript-jest` 產生測試

**步驟 1：選取要測試的函式**
```typescript
// user.service.ts
export function calculateAge(birthDate: Date): number {
  const today = new Date();
  const age = today.getFullYear() - birthDate.getFullYear();
  return age;
}
```

**步驟 2：輸入指令**
```
/javascript-typescript-jest
```

**Copilot 回應範例：**
```typescript
// user.service.spec.ts
import { calculateAge } from './user.service';

describe('calculateAge', () => {
  it('should return correct age for a past date', () => {
    const birthDate = new Date('1990-01-15');
    const age = calculateAge(birthDate);
    expect(age).toBeGreaterThan(30);
  });

  it('should return 0 for current year birth', () => {
    const birthDate = new Date();
    birthDate.setMonth(0, 1);
    const age = calculateAge(birthDate);
    expect(age).toBe(0);
  });

  it('should handle leap year dates', () => {
    const birthDate = new Date('2000-02-29');
    const age = calculateAge(birthDate);
    expect(typeof age).toBe('number');
  });
});
```

---

### 📌 示範 3: 使用 `/sql-optimization` 最佳化 SQL

**輸入指令：**
```
/sql-optimization

SELECT * FROM users WHERE name LIKE '%john%' AND status = 'active'
ORDER BY created_at DESC
```

**Copilot 回應範例：**
```sql
-- 🔧 最佳化建議：

-- 1. 避免使用 SELECT *，只選取需要的欄位
-- 2. LIKE '%john%' 無法使用索引，考慮全文檢索
-- 3. 建議加入適當的索引

-- 最佳化後的查詢：
SELECT id, name, email, created_at
FROM users
WHERE status = 'active'
  AND name ILIKE '%john%'  -- PostgreSQL 不區分大小寫
ORDER BY created_at DESC
LIMIT 100;  -- 加入分頁限制

-- 建議的索引：
CREATE INDEX idx_users_status_created ON users(status, created_at DESC);
```

---

### 📌 示範 4: 使用 `/conventional-commit` 產生 commit 訊息

**輸入指令：**
```
/conventional-commit

修改了登入功能，新增了記住我選項，修正了密碼驗證的 bug
```

**Copilot 回應範例：**
```
feat(auth): add remember me option to login

- Add "Remember Me" checkbox to login form
- Store user preference in localStorage
- Fix password validation regex pattern
- Update login service to handle remember me state

Closes #123
```

---

### 📌 示範 5: 使用 `/playwright-generate-test` 產生 E2E 測試

**輸入指令：**
```
/playwright-generate-test

測試用戶登入流程：
1. 打開登入頁面
2. 輸入帳號密碼
3. 點擊登入
4. 驗證跳轉到首頁
```

**Copilot 回應範例：**
```typescript
// e2e/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Login Flow', () => {
  test('should login successfully with valid credentials', async ({ page }) => {
    // 1. 打開登入頁面
    await page.goto('/login');
    await expect(page).toHaveTitle(/登入/);

    // 2. 輸入帳號密碼
    await page.fill('[data-testid="username"]', 'testuser');
    await page.fill('[data-testid="password"]', 'password123');

    // 3. 點擊登入
    await page.click('[data-testid="login-button"]');

    // 4. 驗證跳轉到首頁
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('[data-testid="welcome-message"]')).toBeVisible();
  });

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[data-testid="username"]', 'wronguser');
    await page.fill('[data-testid="password"]', 'wrongpass');
    await page.click('[data-testid="login-button"]');

    await expect(page.locator('.error-message')).toContainText('帳號或密碼錯誤');
  });
});
```

---

## Instructions 自動套用機制（含示範）

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

### 📌 示範 6: Instructions 自動套用效果

**情境：開啟 `.ts` 檔案後詢問 Copilot**

**你的輸入：**
```
幫我建立一個用戶服務
```

**沒有 Instructions 時的回應：**
```typescript
// 可能產生各種風格的程式碼
class UserService {
  getUser(id) {
    return fetch('/api/user/' + id);
  }
}
```

**有 `angular.instructions.md` 自動套用時的回應：**
```typescript
// 遵循 Angular 最佳實踐和專案規範
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { User } from '@shared/models/user.model';

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = '/api/users';

  getUser(id: string): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }
}
```

**差異說明：**
- ✅ 使用 `inject()` 而非建構函式注入（Angular 最新推薦）
- ✅ 使用 `Observable` 和 RxJS
- ✅ 使用路徑別名 `@shared`
- ✅ 正確的型別定義
- ✅ 使用 `providedIn: 'root'`

---

### 📌 示範 7: 安全審查 Instructions 效果

**情境：開啟任意檔案，`security-and-owasp.instructions.md` 自動套用**

**你的輸入：**
```
審查這段登入程式碼

async function login(username, password) {
  const query = `SELECT * FROM users WHERE username='${username}' AND password='${password}'`;
  const result = await db.query(query);
  return result;
}
```

**Copilot 回應（套用 OWASP 指引）：**
```
⚠️ 安全性問題檢測：

1. **SQL 注入漏洞 (A03:2021)**
   - 直接拼接使用者輸入到 SQL 查詢
   - 風險：攻擊者可執行任意 SQL 指令

2. **明文密碼儲存 (A02:2021)**
   - 直接比對密碼，暗示密碼以明文儲存
   - 風險：資料外洩時密碼直接暴露

3. **缺少輸入驗證 (A03:2021)**
   - 未驗證 username 和 password 格式

✅ 修正後的程式碼：

async function login(username: string, password: string): Promise<User | null> {
  // 輸入驗證
  if (!username || !password) {
    throw new Error('Username and password are required');
  }

  // 使用參數化查詢防止 SQL 注入
  const query = 'SELECT id, username, password_hash FROM users WHERE username = $1';
  const result = await db.query(query, [username]);

  if (result.rows.length === 0) {
    return null;
  }

  const user = result.rows[0];

  // 使用 bcrypt 驗證密碼雜湊
  const isValid = await bcrypt.compare(password, user.password_hash);

  if (!isValid) {
    return null;
  }

  return { id: user.id, username: user.username };
}
```

---

## Agents 切換與使用（含示範）

### 什麼是 Agents？

Agents 是專門化的 AI 助手，各自具有特定的專業領域和行為模式，存放在 `.github/agents/` 目錄。

### 📌 示範 8: 使用 `@tdd-red` 撰寫失敗測試

**輸入指令：**
```
@tdd-red 為購物車的 addItem 功能撰寫測試
```

**Copilot 回應：**
```typescript
// cart.service.spec.ts
describe('CartService', () => {
  describe('addItem', () => {
    it('should add a new item to empty cart', () => {
      const cart = new CartService();
      const item = { id: '1', name: 'Apple', price: 100 };

      cart.addItem(item);

      expect(cart.items).toHaveLength(1);
      expect(cart.items[0]).toEqual(item);
    });

    it('should increase quantity when adding existing item', () => {
      const cart = new CartService();
      const item = { id: '1', name: 'Apple', price: 100 };

      cart.addItem(item);
      cart.addItem(item);

      expect(cart.items).toHaveLength(1);
      expect(cart.items[0].quantity).toBe(2);
    });

    it('should update total price after adding item', () => {
      const cart = new CartService();

      cart.addItem({ id: '1', name: 'Apple', price: 100 });
      cart.addItem({ id: '2', name: 'Banana', price: 50 });

      expect(cart.totalPrice).toBe(150);
    });

    it('should throw error when adding invalid item', () => {
      const cart = new CartService();

      expect(() => cart.addItem(null)).toThrow('Invalid item');
    });
  });
});

// ❌ 這些測試目前會失敗，因為 CartService 尚未實作
// 下一步：使用 @tdd-green 來實作功能
```

---

### 📌 示範 9: 使用 `@tdd-green` 讓測試通過

**輸入指令：**
```
@tdd-green 實作 CartService 讓上面的測試通過
```

**Copilot 回應：**
```typescript
// cart.service.ts
export interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity?: number;
}

export class CartService {
  private _items: CartItem[] = [];

  get items(): CartItem[] {
    return [...this._items];
  }

  get totalPrice(): number {
    return this._items.reduce((sum, item) => {
      return sum + item.price * (item.quantity || 1);
    }, 0);
  }

  addItem(item: CartItem): void {
    if (!item) {
      throw new Error('Invalid item');
    }

    const existingItem = this._items.find(i => i.id === item.id);

    if (existingItem) {
      existingItem.quantity = (existingItem.quantity || 1) + 1;
    } else {
      this._items.push({ ...item, quantity: 1 });
    }
  }
}

// ✅ 所有測試現在應該通過
// 下一步：使用 @tdd-refactor 來重構程式碼
```

---

### 📌 示範 10: 使用 `@tdd-refactor` 重構程式碼

**輸入指令：**
```
@tdd-refactor 重構 CartService，改善程式碼品質
```

**Copilot 回應：**
```typescript
// cart.service.ts - 重構後
import { signal, computed } from '@angular/core';

export interface CartItem {
  readonly id: string;
  readonly name: string;
  readonly price: number;
  readonly quantity: number;
}

export class CartService {
  // 使用 Angular Signals 進行狀態管理
  private readonly _items = signal<CartItem[]>([]);

  // 公開的唯讀 signals
  readonly items = this._items.asReadonly();

  readonly totalPrice = computed(() =>
    this._items().reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

  readonly itemCount = computed(() =>
    this._items().reduce((count, item) => count + item.quantity, 0)
  );

  addItem(item: Omit<CartItem, 'quantity'> | null): void {
    this.validateItem(item);

    this._items.update(items => {
      const existingIndex = items.findIndex(i => i.id === item!.id);

      if (existingIndex >= 0) {
        // 使用不可變更新
        return items.map((i, index) =>
          index === existingIndex
            ? { ...i, quantity: i.quantity + 1 }
            : i
        );
      }

      return [...items, { ...item!, quantity: 1 }];
    });
  }

  private validateItem(item: unknown): asserts item is Omit<CartItem, 'quantity'> {
    if (!item || typeof item !== 'object') {
      throw new Error('Invalid item');
    }
  }
}

// ✅ 重構改進：
// - 使用 Angular Signals 進行響應式狀態管理
// - 使用 readonly 確保不可變性
// - 抽取驗證邏輯到獨立方法
// - 新增 itemCount computed signal
// - 使用 type guard 進行型別安全驗證
```

---

### 📌 示範 11: 使用 `@gilfoyle` 進行毒舌程式碼審查

**輸入指令：**
```
@gilfoyle 審查這段程式碼

function getData() {
  var data = [];
  for (var i = 0; i < 100; i++) {
    data.push(fetch('/api/item/' + i));
  }
  return data;
}
```

**Copilot 回應（Gilfoyle 風格）：**
```
*調整眼鏡*

好吧，讓我數數這段程式碼的問題...

1. **使用 `var`？這是 2015 年嗎？**
   用 `const` 和 `let`，這是基本素養。

2. **100 個並行 fetch 請求？**
   恭喜，你剛剛發動了 DDoS 攻擊自己的伺服器。

3. **沒有 await？**
   你知道 fetch 返回 Promise 嗎？你現在拿到的是一堆未解決的 Promise。

4. **沒有錯誤處理？**
   任何一個請求失敗，你的應用就崩潰了。很棒。

這是一個不那麼愚蠢的版本：

async function getData(): Promise<Item[]> {
  const BATCH_SIZE = 10;
  const results: Item[] = [];

  for (let i = 0; i < 100; i += BATCH_SIZE) {
    const batch = Array.from({ length: BATCH_SIZE }, (_, j) =>
      fetch(`/api/item/${i + j}`)
        .then(res => res.json())
        .catch(() => null)
    );

    const batchResults = await Promise.all(batch);
    results.push(...batchResults.filter(Boolean));
  }

  return results;
}

或者更好，直接用一個支援分頁的 API 端點，而不是發送 100 個請求。
但我猜你沒想過這個。

*回去喝咖啡*
```

---

### 📌 示範 12: 使用 `@adr-generator` 產生架構決策記錄

**輸入指令：**
```
@adr-generator 記錄選擇 Supabase 作為後端服務的決策
```

**Copilot 回應：**
```markdown
# ADR-001: 選擇 Supabase 作為後端即服務 (BaaS)

## 狀態
已接受

## 背景
我們需要為 Angular 應用程式選擇一個後端解決方案，需求包括：
- 即時資料同步
- 使用者認證
- 檔案儲存
- PostgreSQL 資料庫
- 快速開發迭代

## 決策
選擇 **Supabase** 作為後端即服務平台。

## 考慮的選項

### 選項 1: Supabase
- ✅ 開源且可自託管
- ✅ 基於 PostgreSQL
- ✅ 內建即時訂閱
- ✅ Row Level Security (RLS)
- ✅ 豐富的 SDK 支援
- ⚠️ 較新的平台

### 選項 2: Firebase
- ✅ 成熟穩定
- ✅ Google 支援
- ❌ NoSQL 資料庫
- ❌ 廠商鎖定

### 選項 3: 自建後端
- ✅ 完全控制
- ❌ 開發時間長
- ❌ 需要維護基礎設施

## 後果
### 正面
- 快速原型開發
- 減少後端開發時間
- 內建安全機制

### 負面
- 平台依賴
- 需要學習 Supabase 特定 API

## 參考
- https://supabase.com/docs
- 專案需求文件 PRD-001
```

---

## MCP 整合與自動化（含示範）

### 什麼是 MCP (Model Context Protocol)？

MCP 是一種協定，允許 Copilot 與外部工具和服務進行通訊，實現更智能的上下文感知和自動化工作流程。

### 📌 示範 13: 使用 `/typescript-mcp-server-generator` 產生 MCP 伺服器

**輸入指令：**
```
/typescript-mcp-server-generator 建立一個 Supabase 資料庫操作的 MCP 伺服器
```

**Copilot 回應：**
```typescript
// supabase-mcp-server.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

const server = new McpServer({
  name: 'supabase-mcp',
  version: '1.0.0',
});

// 註冊工具：查詢資料表
server.registerTool(
  'query_table',
  {
    title: 'Query Supabase Table',
    description: 'Query data from a Supabase table',
    inputSchema: {
      table: z.string().describe('Table name'),
      select: z.string().optional().describe('Columns to select'),
      filter: z.record(z.string()).optional().describe('Filter conditions'),
    },
  },
  async ({ table, select, filter }) => {
    let query = supabase.from(table).select(select || '*');

    if (filter) {
      Object.entries(filter).forEach(([key, value]) => {
        query = query.eq(key, value);
      });
    }

    const { data, error } = await query;

    if (error) {
      return { content: [{ type: 'text', text: `Error: ${error.message}` }], isError: true };
    }

    return {
      content: [{ type: 'text', text: JSON.stringify(data, null, 2) }],
    };
  }
);

// 啟動伺服器
const transport = new StdioServerTransport();
await server.connect(transport);
```

---

### 📌 示範 14: 使用 `@typescript-mcp-expert` 設定 MCP 連接

**輸入指令：**
```
@typescript-mcp-expert 如何在 VS Code 中設定剛才產生的 MCP 伺服器？
```

**Copilot 回應：**
```
## MCP 伺服器設定步驟

### 1. 建立 MCP 設定檔

在專案根目錄建立 `.vscode/mcp.json`：

{
  "servers": {
    "supabase": {
      "command": "npx",
      "args": ["tsx", "./supabase-mcp-server.ts"],
      "env": {
        "SUPABASE_URL": "${env:SUPABASE_URL}",
        "SUPABASE_ANON_KEY": "${env:SUPABASE_ANON_KEY}"
      }
    }
  }
}

### 2. 設定環境變數

在 `.env` 檔案中加入：

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

### 3. 啟用 MCP 功能

在 VS Code 設定中啟用：

{
  "github.copilot.chat.experimental.mcp": {
    "enabled": true
  }
}

### 4. 使用 MCP 工具

在 Copilot Chat 中，MCP 工具會自動可用：

@workspace 使用 query_table 工具查詢 users 資料表

Copilot 會自動呼叫 MCP 伺服器並返回結果。
```

---

## 工作流程推薦

### 🚀 功能開發完整示範

```
步驟 1: 規劃
/breakdown-plan 實作用戶個人資料編輯功能

步驟 2: TDD 紅燈 - 寫測試
@tdd-red 為個人資料編輯功能撰寫測試

步驟 3: TDD 綠燈 - 實作
@tdd-green 實作功能讓測試通過

步驟 4: TDD 重構
@tdd-refactor 重構並優化程式碼

步驟 5: E2E 測試
/playwright-generate-test 產生端對端測試

步驟 6: 程式碼審查
@gilfoyle 審查完成的程式碼

步驟 7: 提交
/conventional-commit 產生 commit 訊息
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
