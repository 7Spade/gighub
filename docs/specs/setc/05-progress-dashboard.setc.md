# 第三階段：進度追蹤儀表板

> **Phase 3: Progress Tracking Dashboard**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P3 |
| **預計週數** | 11-13 週（3 週） |
| **總任務數** | 10 |
| **前置條件** | P2（日誌系統）完成 |
| **完成目標** | 進度追蹤儀表板完整實作，支援自動聚合、里程碑、圖表 |

---

## 階段目標

1. ✅ 進度自動從任務聚合計算
2. ✅ 里程碑可手動設定與追蹤
3. ✅ 儀表板圖表正確渲染
4. ✅ 支援日期範圍篩選
5. ✅ 工時統計視覺化

---

## 任務清單

### P3-T01: progress_milestones 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1 天 |
| **前置依賴** | P2 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立進度里程碑資料表。

#### 執行步驟
1. 設計 `progress_milestones` 資料表
   - id, workspace_id, name, description
   - target_date, completion_date
   - status (pending, achieved, missed)
   - linked_task_ids, completion_criteria
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 建立 TypeScript 類型

#### 驗收標準
- [ ] 資料表已建立
- [ ] 支援連結任務
- [ ] RLS 政策正確
- [ ] 類型定義完整

#### 產出物
- `supabase/migrations/xxx_create_progress_milestones.sql`
- `src/app/features/blueprint/domain/types/milestone.types.ts`

---

### P3-T02: 進度計算服務

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 2 天 |
| **前置依賴** | P3-T01 |
| **負責角色** | 前端工程師 |

#### 描述
實作進度自動計算邏輯。

#### 執行步驟
1. 建立 `ProgressCalculationService`
2. 實作任務完成率計算
3. 實作工時消耗率計算
4. 實作里程碑達成率計算
5. 實作趨勢分析（燃盡圖數據）
6. 撰寫單元測試

#### 驗收標準
- [ ] 任務完成率正確計算
- [ ] 工時統計正確
- [ ] 里程碑狀態自動更新
- [ ] 燃盡圖數據正確
- [ ] 測試覆蓋 ≥ 80%

#### 產出物
- `src/app/features/blueprint/data-access/services/progress-calculation.service.ts`
- `src/app/features/blueprint/data-access/services/progress-calculation.service.spec.ts`

---

### P3-T03: ProgressStore 實作

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1 天 |
| **前置依賴** | P3-T02 |
| **負責角色** | 前端工程師 |

#### 描述
實作進度追蹤 Store 層。

#### 執行步驟
1. 建立 `ProgressStore` 類別
2. 管理進度資料狀態
3. 管理里程碑資料
4. 提供圖表數據 computed signals
5. 撰寫測試

#### 驗收標準
- [ ] Store 正確管理狀態
- [ ] 圖表數據 signals 正確
- [ ] 支援日期範圍篩選
- [ ] 測試完整

#### 產出物
- `src/app/features/blueprint/data-access/stores/progress.store.ts`

---

### P3-T04: 儀表板框架

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P3-T03 |
| **負責角色** | 前端工程師 |

#### 描述
建立儀表板頁面框架。

#### 執行步驟
1. 建立 `DashboardComponent`
2. 設計儀表板佈局（Grid）
3. 建立卡片容器元件
4. 實作日期範圍選擇器
5. 實作重新整理功能
6. 撰寫測試

#### 驗收標準
- [ ] 儀表板佈局合理
- [ ] 響應式設計
- [ ] 日期範圍可選擇
- [ ] 可手動重新整理

#### 產出物
- `src/app/features/blueprint/ui/dashboard/dashboard.component.ts`
- `src/app/features/blueprint/ui/dashboard/dashboard-card/dashboard-card.component.ts`

---

### P3-T05: 進度圓餅圖

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1 天 |
| **前置依賴** | P3-T04 |
| **負責角色** | 前端工程師 |

#### 描述
建立任務進度圓餅圖元件。

#### 執行步驟
1. 建立 `TaskProgressPieComponent`
2. 整合 @delon/chart 或 ng2-charts
3. 顯示任務狀態分布
4. 支援點擊跳轉至對應任務
5. 撰寫測試

#### 驗收標準
- [ ] 圓餅圖正確渲染
- [ ] 數據與實際一致
- [ ] 支援點擊互動
- [ ] 圖例清晰

#### 產出物
- `src/app/features/blueprint/ui/dashboard/task-progress-pie/task-progress-pie.component.ts`

---

### P3-T06: 里程碑時間軸

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 2 天 |
| **前置依賴** | P3-T04 |
| **負責角色** | 前端工程師 |

#### 描述
建立里程碑時間軸元件。

#### 執行步驟
1. 建立 `MilestoneTimelineComponent`
2. 使用 ng-zorro Timeline 或自建
3. 顯示過去/即將到來的里程碑
4. 顯示達成/未達成狀態
5. 支援新增/編輯里程碑
6. 撰寫測試

#### 驗收標準
- [ ] 時間軸正確顯示
- [ ] 狀態標記清晰
- [ ] 可新增里程碑
- [ ] 可編輯里程碑

#### 產出物
- `src/app/features/blueprint/ui/dashboard/milestone-timeline/milestone-timeline.component.ts`
- `src/app/features/blueprint/ui/dashboard/milestone-form/milestone-form.component.ts`

---

### P3-T07: 工作項目統計

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P3-T04 |
| **負責角色** | 前端工程師 |

#### 描述
建立工作項目統計元件。

#### 執行步驟
1. 建立 `WorkStatsComponent`
2. 顯示工時統計
3. 顯示人員出勤統計
4. 支援日/週/月切換
5. 整合圖表（柱狀圖）
6. 撰寫測試

#### 驗收標準
- [ ] 工時統計正確
- [ ] 人員出勤統計正確
- [ ] 日/週/月切換正常
- [ ] 圖表渲染正確

#### 產出物
- `src/app/features/blueprint/ui/dashboard/work-stats/work-stats.component.ts`

---

### P3-T08: 燃盡圖

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P3-T05 |
| **負責角色** | 前端工程師 |

#### 描述
建立專案燃盡圖元件。

#### 執行步驟
1. 建立 `BurndownChartComponent`
2. 計算理想燃盡線
3. 計算實際燃盡線
4. 顯示雙線圖
5. 顯示剩餘工時預測
6. 撰寫測試

#### 驗收標準
- [ ] 理想線正確計算
- [ ] 實際線與數據一致
- [ ] 預測功能正常
- [ ] 圖表互動流暢

#### 產出物
- `src/app/features/blueprint/ui/dashboard/burndown-chart/burndown-chart.component.ts`

---

### P3-T09: 資源使用熱力圖

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 2 天 |
| **前置依賴** | P3-T07 |
| **負責角色** | 前端工程師 |

#### 描述
建立資源使用熱力圖元件。

#### 執行步驟
1. 建立 `ResourceHeatmapComponent`
2. 設計熱力圖資料結構（人員 x 日期）
3. 實作熱力圖渲染
4. 顯示工時強度
5. 支援點擊檢視詳情
6. 撰寫測試

#### 驗收標準
- [ ] 熱力圖正確渲染
- [ ] 顏色標度清晰
- [ ] 可識別工時高峰
- [ ] 點擊可查看詳情

#### 產出物
- `src/app/features/blueprint/ui/dashboard/resource-heatmap/resource-heatmap.component.ts`

---

### P3-T10: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P3 |
| **預估工時** | 2 天 |
| **前置依賴** | P3-T01 ~ P3-T09 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 測試進度計算正確性
4. 測試里程碑功能
5. 測試所有圖表
6. 效能測試（大量資料）
7. 響應式測試
8. 更新測試報告

#### 驗收標準
- [ ] 所有測試通過
- [ ] 進度計算正確
- [ ] 圖表渲染正確
- [ ] 大量資料效能可接受
- [ ] 行動裝置顯示正常
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p3-test-report.md`
- `e2e/dashboard/progress-dashboard.spec.ts`

---

## 階段完成檢查清單

- [ ] P3-T01: progress_milestones 資料表
- [ ] P3-T02: 進度計算服務
- [ ] P3-T03: ProgressStore 實作
- [ ] P3-T04: 儀表板框架
- [ ] P3-T05: 進度圓餅圖
- [ ] P3-T06: 里程碑時間軸
- [ ] P3-T07: 工作項目統計
- [ ] P3-T08: 燃盡圖
- [ ] P3-T09: 資源使用熱力圖
- [ ] P3-T10: 階段測試與整合驗證

---

## 下一階段

完成 P3 後，進入 [第四階段：品質驗收系統](./06-quality-inspection.setc.md)
