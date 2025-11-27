# 📐 技術規範標準

> **目的**: 定義專案的技術規範與編碼標準，確保程式碼品質一致性

---

## 📑 目錄

- [架構治理規範](#架構治理規範)
- [API 標準](#api-標準)
- [組件標準](#組件標準)
- [安全標準](#安全標準)
- [測試標準](#測試標準)
- [效能標準](#效能標準)
- [SETC 任務鏈](#setc-任務鏈)

---

## 📋 規範清單

| 規範 | 說明 | 連結 |
|------|------|------|
| 架構治理規範 | 架構設計原則與禁止事項 | [architecture-governance.md](./architecture-governance.md) |
| API 標準 | RESTful API 設計規範 | [api-standards.md](./api-standards.md) |
| 組件標準 | Angular 組件開發規範 | [component-standards.md](./component-standards.md) |
| 安全標準 | 安全開發規範 | [security-standards.md](./security-standards.md) |
| 測試標準 | 測試策略與覆蓋率 | [testing-standards.md](./testing-standards.md) |
| 效能標準 | 效能基準與優化 | [performance-standards.md](./performance-standards.md) |
| 命名規範 | 命名慣例與規則 | [naming-standards.md](./naming-standards.md) |
| 狀態管理標準 | Signal 狀態管理規範 | [state-management-standards.md](./state-management-standards.md) |

---

## 🏗️ 架構治理規範

### 核心原則

1. **Standalone Components**: 禁止建立 NgModule
2. **分層架構**: routes → shared → core（嚴禁循環依賴）
3. **Signal 優先**: 使用 Signals 取代 RxJS state
4. **Repository 模式**: 所有 API 呼叫必須經過 Repository 層

### 禁止事項

| 禁止 | 原因 | 替代方案 |
|------|------|----------|
| 在 Component 使用 HttpClient | 違反分層原則 | 使用 Repository 封裝 |
| 使用 localStorage | 無抽象層 | 使用 StorageService |
| 建立 NgModule | 過時模式 | 使用 Standalone Component |
| 循環依賴 | 架構混亂 | 重新設計模組邊界 |
| Fat Components > 500 行 | 難以維護 | 拆分為多個組件 |

詳見 [架構治理規範](./architecture-governance.md)

---

## 🔌 API 標準

### 端點命名

```
GET    /api/v1/{resources}         # 列表
GET    /api/v1/{resources}/{id}    # 單一
POST   /api/v1/{resources}         # 建立
PATCH  /api/v1/{resources}/{id}    # 更新
DELETE /api/v1/{resources}/{id}    # 刪除
```

### 回應格式

```typescript
// 成功
{
  "data": {...},
  "meta": { "total": 100, "page": 1, "pageSize": 20 }
}

// 錯誤
{
  "error": {
    "code": "TASK401",
    "message": "任務狀態衝突",
    "details": {...}
  }
}
```

詳見 [API 標準](./api-standards.md)

---

## 🧩 組件標準

### 檔案結構

```
component-name/
├── component-name.component.ts    # 組件邏輯
├── component-name.component.html  # 模板（可選內聯）
├── component-name.component.scss  # 樣式（可選內聯）
└── component-name.component.spec.ts  # 測試
```

### 程式碼範本

```typescript
import { Component, inject, signal, computed, ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'app-component-name',
  standalone: true,
  imports: [],
  templateUrl: './component-name.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ComponentNameComponent {
  private readonly service = inject(SomeService);
  
  // Signal 狀態
  private readonly items = signal<Item[]>([]);
  
  // Computed 衍生狀態
  readonly itemCount = computed(() => this.items().length);
}
```

詳見 [組件標準](./component-standards.md)

---

## 🔒 安全標準

### RLS 政策

所有資料表必須啟用 RLS：

```sql
-- 啟用 RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- 建立政策
CREATE POLICY "policy_name" ON table_name
  FOR SELECT/INSERT/UPDATE/DELETE
  USING (condition);
```

### 輸入驗證

```typescript
// 前端驗證
const schema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

// 後端驗證（Supabase Edge Function）
if (!isValidInput(data)) {
  throw new Error('Invalid input');
}
```

詳見 [安全標準](./security-standards.md)

---

## 🧪 測試標準

### 覆蓋率要求

| 層級 | 覆蓋率 | 重點 |
|------|--------|------|
| Store | 100% | 狀態變更、computed |
| Service | 80%+ | API、錯誤處理 |
| Component | 60%+ | 關鍵交互 |
| Utils | 100% | 純函數 |

### 測試命名

```typescript
describe('TaskStore', () => {
  it('should load tasks successfully', () => {...});
  it('should handle error when API fails', () => {...});
});
```

詳見 [測試標準](./testing-standards.md)

---

## ⚡ 效能標準

### 前端指標

| 指標 | 目標 | 測量 |
|------|------|------|
| FCP | < 1.5s | Lighthouse |
| LCP | < 2.5s | Lighthouse |
| INP | < 200ms | Web Vitals |
| CLS | < 0.1 | Web Vitals |

### 後端指標

| 指標 | 目標 | 告警閾值 |
|------|------|----------|
| API P50 | < 200ms | > 500ms |
| API P95 | < 500ms | > 1s |
| DB Query | < 100ms | > 300ms |

詳見 [效能標準](./performance-standards.md)

---

## 📋 SETC 任務鏈

**SETC** (Serialized Executable Task Chain) 是序列化可執行任務鏈，用於定義功能開發的詳細步驟。

### SETC 索引

| 編號 | 任務 | 狀態 |
|------|------|------|
| 01 | [帳戶體系強化](./setc/01-account-blueprint-enhancement.setc.md) | 📋 規劃中 |
| 02 | [任務系統生產化](./setc/02-task-system-production.setc.md) | 📋 規劃中 |
| 03 | [檔案系統](./setc/03-file-system.setc.md) | 📋 規劃中 |
| 04 | [日誌系統](./setc/04-diary-system.setc.md) | 📋 規劃中 |
| 05 | [進度儀表板](./setc/05-progress-dashboard.setc.md) | 📋 規劃中 |
| 06 | [品質驗收](./setc/06-quality-inspection.setc.md) | 📋 規劃中 |
| 07 | [協作報表上線](./setc/07-collaboration-reports-launch.setc.md) | 📋 規劃中 |

詳見 [SETC 目錄](./setc/README.md)

---

## 📚 參考資源

- [Agent 開發指南](../agent/README.md)
- [系統架構設計](../architecture/system-architecture.md)
- [PRD 文件](../prd/construction-site-management.md)

---

**最後更新**: 2025-11-27  
**維護者**: 開發團隊
