# 第五階段：協作報表與上線

> **Phase 5: Collaboration, Reports & Launch**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P5 |
| **預計週數** | 16-19 週（4 週） |
| **總任務數** | 14 |
| **前置條件** | P4（品質驗收）完成 |
| **完成目標** | 協作功能、報表匯出、效能優化、上線準備 |

---

## 階段目標

1. ✅ 即時通知正確推送
2. ✅ 評論支援 @mention
3. ✅ 報表可匯出 PDF/Excel
4. ✅ 效能達標 (LCP < 2.5s)
5. ✅ 安全審計通過
6. ✅ 系統正式上線

---

## 任務清單

### P5-T01: notifications 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 1 天 |
| **前置依賴** | P4 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立通知系統資料表。

#### 執行步驟
1. 設計 `notifications` 資料表
   - id, user_id, type, title, content
   - is_read, read_at, created_at
   - related_entity_type, related_entity_id
   - action_url
2. 建立 Supabase Migration
3. 設定 RLS 政策（用戶只能看自己的通知）
4. 建立 TypeScript 類型

#### 驗收標準
- [ ] 資料表已建立
- [ ] RLS 政策正確
- [ ] 支援多種通知類型

#### 產出物
- `supabase/migrations/xxx_create_notifications.sql`
- `src/app/features/blueprint/domain/types/notification.types.ts`

---

### P5-T02: Supabase Realtime 整合

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 3 天 |
| **前置依賴** | P5-T01 |
| **負責角色** | 前端工程師 |

#### 描述
整合 Supabase Realtime 實作即時通知。

#### 執行步驟
1. 建立 `RealtimeService`
2. 訂閱 notifications 表變更
3. 訂閱任務狀態變更
4. 訂閱評論新增
5. 實作通知徽章更新
6. 實作桌面通知（Browser API）
7. 撰寫測試

#### 驗收標準
- [ ] 即時通知正確推送
- [ ] 任務更新即時反映
- [ ] 桌面通知可選擇啟用
- [ ] 離線時正確處理

#### 產出物
- `src/app/core/services/realtime.service.ts`
- `src/app/features/blueprint/ui/notification/notification-bell/notification-bell.component.ts`

---

### P5-T03: 評論系統

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T02 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務和日誌的評論功能。

#### 執行步驟
1. 建立 `comments` 資料表
2. 建立 `CommentService`
3. 建立 `CommentListComponent`
4. 實作評論 CRUD
5. 實作評論回覆（巢狀）
6. 整合 Realtime 即時更新
7. 撰寫測試

#### 驗收標準
- [ ] 可新增評論
- [ ] 可回覆評論
- [ ] 評論即時顯示
- [ ] 可編輯/刪除自己的評論

#### 產出物
- `supabase/migrations/xxx_create_comments.sql`
- `src/app/features/blueprint/ui/comment/comment-list/comment-list.component.ts`

---

### P5-T04: @mention 功能

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T03 |
| **負責角色** | 前端工程師 |

#### 描述
實作評論中的 @mention 功能。

#### 執行步驟
1. 建立 `MentionInputComponent`
2. 實作 @ 觸發下拉選單
3. 搜尋工作區成員
4. 插入 mention 標記
5. 觸發通知給被 mention 的人
6. 撰寫測試

#### 驗收標準
- [ ] @ 觸發選單正常
- [ ] 可搜尋成員
- [ ] mention 正確顯示
- [ ] 被 mention 者收到通知

#### 產出物
- `src/app/features/blueprint/ui/comment/mention-input/mention-input.component.ts`

---

### P5-T05: 報表匯出框架

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T04 |
| **負責角色** | 前端工程師 |

#### 描述
建立報表匯出框架，支援 PDF 和 Excel。

#### 執行步驟
1. 建立 `ReportExportService`
2. 整合 jspdf + html2canvas（PDF）
3. 整合 xlsx（Excel）
4. 建立報表模板系統
5. 實作匯出進度顯示
6. 撰寫測試

#### 驗收標準
- [ ] PDF 匯出正常
- [ ] Excel 匯出正常
- [ ] 支援模板定義
- [ ] 進度顯示正確

#### 產出物
- `src/app/features/blueprint/data-access/services/report-export.service.ts`

---

### P5-T06: 進度報表

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T05, P3 |
| **負責角色** | 前端工程師 |

#### 描述
實作專案進度報表。

#### 執行步驟
1. 設計進度報表模板
2. 整合儀表板資料
3. 實作 PDF 匯出
4. 實作 Excel 匯出
5. 加入圖表嵌入
6. 撰寫測試

#### 驗收標準
- [ ] 報表包含進度摘要
- [ ] 包含圖表
- [ ] PDF/Excel 都可匯出
- [ ] 格式美觀

#### 產出物
- `src/app/features/blueprint/ui/report/progress-report/progress-report.component.ts`

---

### P5-T07: 日誌報表

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T05, P2 |
| **負責角色** | 前端工程師 |

#### 描述
實作施工日誌彙總報表。

#### 執行步驟
1. 設計日誌報表模板
2. 整合日誌資料（日期範圍）
3. 包含出勤統計
4. 包含工作項目統計
5. 實作 PDF/Excel 匯出
6. 撰寫測試

#### 驗收標準
- [ ] 報表包含日誌彙總
- [ ] 包含出勤統計
- [ ] 支援日期範圍
- [ ] 格式符合業界標準

#### 產出物
- `src/app/features/blueprint/ui/report/diary-report/diary-report.component.ts`

---

### P5-T08: 品質報表

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T05, P4 |
| **負責角色** | 前端工程師 |

#### 描述
實作品質驗收彙總報表。

#### 執行步驟
1. 設計品質報表模板
2. 整合檢驗資料
3. 包含缺失統計
4. 包含簽核記錄
5. 實作 PDF/Excel 匯出
6. 撰寫測試

#### 驗收標準
- [ ] 報表包含檢驗彙總
- [ ] 包含缺失清單
- [ ] 簽核記錄完整
- [ ] 可作為官方驗收文件

#### 產出物
- `src/app/features/blueprint/ui/report/quality-report/quality-report.component.ts`

---

### P5-T09: 效能優化

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 3 天 |
| **前置依賴** | P5-T08 |
| **負責角色** | 前端工程師 |

#### 描述
執行效能優化，確保達到 Core Web Vitals 標準。

#### 執行步驟
1. 執行 Lighthouse 審計
2. 優化首頁載入（LCP < 2.5s）
3. 優化互動延遲（FID < 100ms）
4. 優化視覺穩定性（CLS < 0.1）
5. 實作圖片懶載入
6. 優化 bundle 大小
7. 實作 Service Worker 快取
8. 撰寫效能測試

#### 驗收標準
- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1
- [ ] Lighthouse 分數 > 90
- [ ] 首次載入 < 3s（3G）

#### 產出物
- `docs/performance/optimization-report.md`

---

### P5-T10: 安全審計

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T09 |
| **負責角色** | 安全工程師 |

#### 描述
執行安全審計，確保系統安全性。

#### 執行步驟
1. 執行 npm audit
2. 檢查 RLS 政策完整性
3. 檢查 API 端點安全
4. 檢查 XSS/CSRF 防護
5. 檢查敏感資料處理
6. 執行滲透測試
7. 修復發現的問題
8. 更新安全報告

#### 驗收標準
- [ ] npm audit 無高危漏洞
- [ ] RLS 政策通過審計
- [ ] 無 XSS/CSRF 漏洞
- [ ] 敏感資料正確處理

#### 產出物
- `docs/security/audit-report.md`

---

### P5-T11: 文件完善

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T10 |
| **負責角色** | 技術文件 |

#### 描述
完善系統文件。

#### 執行步驟
1. 完成 README 更新
2. 完成 API 文件
3. 完成部署指南
4. 完成使用者手冊
5. 完成開發者指南
6. 更新 CHANGELOG

#### 驗收標準
- [ ] README 完整
- [ ] API 文件完整
- [ ] 部署指南可執行
- [ ] 使用者手冊清晰

#### 產出物
- `README.md` 更新
- `docs/deployment/` 目錄
- `docs/user-guide/` 目錄

---

### P5-T12: UAT 測試

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 3 天 |
| **前置依賴** | P5-T11 |
| **負責角色** | QA/PM |

#### 描述
執行使用者驗收測試。

#### 執行步驟
1. 準備 UAT 環境
2. 準備測試案例
3. 邀請目標用戶參與
4. 記錄回饋
5. 修復發現的問題
6. 重新測試

#### 驗收標準
- [ ] 所有主要功能通過
- [ ] 使用者體驗良好
- [ ] 無阻塞性問題
- [ ] 獲得 stakeholder 簽核

#### 產出物
- `docs/uat/uat-report.md`

---

### P5-T13: 上線準備

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 2 天 |
| **前置依賴** | P5-T12 |
| **負責角色** | DevOps |

#### 描述
完成上線前準備工作。

#### 執行步驟
1. 配置生產環境
2. 設定 CI/CD Pipeline
3. 配置監控（Sentry/Datadog）
4. 配置備份策略
5. 準備回滾計畫
6. 執行上線演練

#### 驗收標準
- [ ] 生產環境已配置
- [ ] CI/CD 正常運作
- [ ] 監控已啟用
- [ ] 備份策略已實施

#### 產出物
- `docs/deployment/production-setup.md`
- `.github/workflows/deploy-production.yml`

---

### P5-T14: 正式上線

| 屬性 | 值 |
|------|-----|
| **階段** | P5 |
| **預估工時** | 1 天 |
| **前置依賴** | P5-T13 |
| **負責角色** | 全團隊 |

#### 描述
執行正式上線。

#### 執行步驟
1. 執行上線檢查清單
2. 部署至生產環境
3. 執行冒煙測試
4. 監控系統狀態
5. 確認用戶可存取
6. 慶祝上線！🎉

#### 驗收標準
- [ ] 系統正常運作
- [ ] 用戶可正常存取
- [ ] 無重大錯誤
- [ ] 監控正常

#### 產出物
- `docs/deployment/launch-checklist.md`
- `docs/post-launch/monitoring-guide.md`

---

## 階段完成檢查清單

- [ ] P5-T01: notifications 資料表
- [ ] P5-T02: Supabase Realtime 整合
- [ ] P5-T03: 評論系統
- [ ] P5-T04: @mention 功能
- [ ] P5-T05: 報表匯出框架
- [ ] P5-T06: 進度報表
- [ ] P5-T07: 日誌報表
- [ ] P5-T08: 品質報表
- [ ] P5-T09: 效能優化
- [ ] P5-T10: 安全審計
- [ ] P5-T11: 文件完善
- [ ] P5-T12: UAT 測試
- [ ] P5-T13: 上線準備
- [ ] P5-T14: 正式上線

---

## 專案完成

恭喜！完成 P5 後，施工現場管理系統 MVP 版本正式上線！

### 後續規劃

1. **v1.1** - Bug 修復與效能調優
2. **v1.2** - 根據用戶回饋增加功能
3. **v2.0** - Git-like 分支功能、財務系統、人力資源
