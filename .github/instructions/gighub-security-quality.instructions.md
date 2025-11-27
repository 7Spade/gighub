---
description: 'GigHub 安全、品質保證與測試規範，涵蓋前端安全、程式碼品質、測試覆蓋率等標準'
applyTo: '**'
---

# GigHub 安全與品質指南

> 安全實踐、品質保證與測試規範

---

## 🔐 Security 全面策略

### 秘密管理與輪換

- 使用集中式金鑰管理
- 定期輪換金鑰
- 存取稽核與最小權限存取
- Build 時注入金鑰，不寫入程式碼
- `anon key` 不可放在程式碼中

### 軟體組件分析 (SCA)

- 定期掃描相依性漏洞
- 使用 SBOM (Software Bill of Materials)
- 建立升級與否決策略
- 定期執行 `npm audit`

### 靜態/動態安全測試

- SAST 集成在 PR 檢查
- DAST 在 staging 執行
- 回歸測試列入 CI 流程

### 威脅建模

- 定期對關鍵服務/邊界執行威脅建模
- 記錄風險與緩解措施

### 事件應變與稽核

- 建立事件分級、通報流程
- 回溯稽核機制與演練頻率

### 最小權限與 RBAC

- 服務/資料庫/存取皆採最小權限
- 角色化存取控制 (RBAC)

---

## 🔒 前端安全性最佳實踐

### XSS 防護

```typescript
// ❌ 禁止：直接使用 innerHTML
element.innerHTML = userInput;

// ✅ 正確：使用 Angular 的內建綁定（自動清理）
@Component({ template: `<div [textContent]="userContent"></div>` })
class MyComponent {
  userContent = userInput; // Angular 自動轉義
}

// ⚠️ 需要 HTML 渲染時，使用 DomSanitizer.sanitize()
// 注意：bypassSecurityTrustHtml() 會繞過安全檢查，僅用於已確認安全的內容
@Component({ template: `<div [innerHTML]="trustedHtml"></div>` })
class MyComponent {
  private readonly sanitizer = inject(DomSanitizer);

  // 使用 sanitize() 清理不信任的內容
  sanitizedContent = this.sanitizer.sanitize(SecurityContext.HTML, untrustedContent);

  // bypassSecurityTrustHtml 僅用於已確認安全的靜態內容
  trustedHtml = this.sanitizer.bypassSecurityTrustHtml(knownSafeHtml);
}
```

### CSRF 防護

- 使用 Angular 內建 CSRF 機制
- HttpClient 自動處理 CSRF token

### 內容安全策略 (CSP)

- 設定 CSP 標頭限制資源載入
- 使用 CSP Nonce 支援

### 敏感資料處理

```typescript
// ❌ 禁止：在日誌中輸出敏感資料
console.log('User token:', token);
console.log('Password:', password);

// ✅ 正確：只記錄必要資訊
console.log('User authenticated:', userId);
```

```typescript
// ❌ 禁止：在 URL 中傳遞敏感資料
router.navigate(['/api'], { queryParams: { token: authToken } });

// ✅ 正確：使用 Header
this.http.post('/api', data, { headers: { Authorization: `Bearer ${token}` } });
```

### JWT 安全管理

- Token 的安全儲存與傳輸
- 不將敏感資料存於前端 localStorage

### 輸入驗證

- 所有使用者輸入必須驗證與淨化
- 使用 Angular Forms 驗證
- API 錯誤不暴露內部細節

---

## 🔒 Compliance / 隱私與資料治理

### 隱私政策

- 定義 PII 類別、處理目的與使用者權利

### PII 處理

- 分級保護、最小蒐集
- 加密與匿名化策略

### 法規遵循

- 列出適用法規（如 GDPR, LGPD）
- 對應執行要點

### 資料保留政策

- 定義不同資料類型的保存期限
- 建立刪除流程

---

## 🔧 程式碼品質自動化檢查

### 程式碼複雜度

- 檢查圈複雜度
- 限制函數複雜度
- 認知複雜度限制

### 技術債務標記

```typescript
// 使用統一標記
// TECH_DEBT: 需要重構此函數以提升效能
```

### 重複程式碼檢測

- 偵測並消除重複程式碼

### SonarQube 整合

- 整合 SonarQube 進行程式碼品質分析

### Pre-commit Hooks

- 提交前自動執行檢查（lint、test、format）

### 程式碼審查檢查清單

```
□ 沒有使用 @Input/@Output 裝飾器
□ 沒有使用 constructor 注入
□ 沒有使用 any 類型
□ 沒有直接呼叫 Supabase（應透過 Repository）
□ 沒有內聯樣式
□ 使用 OnPush 變更檢測策略
□ Subscription 有正確清理
□ 檔案大小在限制內
```

---

## 🧪 測試規範

### 測試命名

```typescript
// 格式：MethodName_Condition_ExpectedResult
it('loadTasks_whenBlueprintIdValid_shouldReturnTasks', () => { ... });
it('updateStatus_whenNoPermission_shouldThrowError', () => { ... });
```

### 覆蓋率目標

| 層級 | 目標 | 重點 |
|------|------|------|
| Store | 100% | 狀態變更、computed signals |
| Service | 80%+ | API 呼叫、錯誤處理 |
| Component | 60%+ | 關鍵交互、表單提交 |
| Utils | 100% | 純函數、邊界條件 |

### 測試分類

| 類型 | 說明 |
|------|------|
| 單元測試 | 使用 Jasmine + Karma |
| 整合測試 | 關鍵業務流程 |
| E2E 測試 | Playwright/Cypress |
| 快照測試 | 防止非預期的 UI 變更 |

### TestBed 配置

```typescript
TestBed.configureTestingModule({
  imports: [TaskComponent],
  providers: [
    { provide: TaskRepository, useValue: mockRepository },
  ],
});
```

### Mock 策略

- 統一的 Mock 資料與服務策略
- 使用 `provideHttpClientTesting` mock HTTP 請求
- 測試隔離：確保測試間相互獨立

---

## 📈 Observability / SRE

### 指標 (Metrics)

- 定義關鍵 SLI/SLO（API 延遲、錯誤率、可用性）
- 設定收集與保存策略

### 分佈式追蹤

- 使用 OpenTelemetry 追蹤跨服務呼叫
- 定義 trace 標準與採樣策略

### 日誌格式與保存

- 統一結構化日誌（JSON）
- 定義保留週期與存取權限

### 告警策略

- 根據 SLO 設定告警分級
- 建立抑制與回復流程

---

## ⚡ 效能與可擴展性

### 效能目標

| 指標 | 目標 |
|------|------|
| FCP | < 1.5s |
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| API P50 | < 200ms |
| API P95 | < 500ms |
| API P99 | < 1s |

### 效能測試流程

- 建立負載/壓力/效能測試流程
- 自動化腳本（CI 時段化執行）

### 快取策略

- 定義快取層（CDN / Redis）
- 失效策略與一致性保證
- Stale-While-Revalidate 模式

### 容量規劃

- 預估流量
- 設定 auto-scaling 規則
- 成本/效能平衡指標

---

## 🔧 前端監控與可觀察性

### 錯誤追蹤

- 使用 Sentry 等工具追蹤生產環境錯誤

### 效能監控

- 監控應用效能指標（FCP, LCP, CLS）

### 使用者行為分析

- 分析使用者使用模式

### 日誌等級管理

- 不同環境使用不同日誌等級

### Source Map 管理

- 生產環境 Source Map 的安全管理

---

## 🚀 CI/CD 與 DevOps

### 自動化建置流程

- 完整的自動化建置與測試流程

### 品質門檻

- 設定必須通過的品質門檻
- 測試覆蓋率門檻

### 自動化部署

- 自動化部署流程避免人為錯誤

### 回滾機制

- 快速回滾到前一版本的機制

### 環境一致性

- 確保開發、測試、生產環境一致

---

## 📘 文件與知識管理

### ADR (Architecture Decision Records)

- 記錄重要架構決策及其背景

### API 文件自動生成

- 使用 Compodoc 自動生成 API 文件

### 變更日誌

- 維護結構化的變更日誌（CHANGELOG.md）

### 故障排除指南

- 常見問題的故障排除文件

### 新人入職指南

- 新成員快速上手的完整指南

---

**最後更新**: 2025-11-27
