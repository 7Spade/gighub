# 第一階段：任務系統生產級

> **Phase 1: Task System Production Level**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P1 |
| **預計週數** | 3-6 週（4 週） |
| **總任務數** | 16 |
| **前置條件** | P0 完成、現有任務系統 60% |
| **完成目標** | 任務系統達到生產水平，支援拖放、批量操作、Gantt 視圖 |

---

## 階段目標

1. ✅ 任務樹狀結構支援拖放排序
2. ✅ 表格視圖支援多欄排序與進階篩選
3. ✅ 批量操作支援完成、取消、刪除、指派
4. ✅ 工時記錄預估與實際
5. ✅ 任務模板功能
6. ✅ 簡化 Gantt 視圖

---

## 任務清單

### P1-T01: 拖放排序 POC

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 2 天 |
| **前置依賴** | P0 完成 |
| **負責角色** | 前端工程師 |

#### 描述
建立拖放排序的 Proof of Concept，驗證 CDK DragDrop 與 NzTreeView 整合可行性。

#### 執行步驟
1. 建立獨立 POC 元件
2. 整合 @angular/cdk/drag-drop
3. 測試與 NzTreeView 配合
4. 評估效能影響
5. 記錄技術發現與限制
6. 決定正式實作方案

#### 驗收標準
- [ ] POC 可展示基本拖放功能
- [ ] 確認與 NzTreeView 整合方案
- [ ] 效能可接受（無明顯卡頓）
- [ ] 技術方案文件已產出

#### 產出物
- `src/app/features/blueprint/ui/task/poc/drag-drop-poc.component.ts`
- `docs/technical-spikes/task-drag-drop-poc.md`

---

### P1-T02: 任務樹狀拖放實作

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 3 天 |
| **前置依賴** | P1-T01 |
| **負責角色** | 前端工程師 |

#### 描述
基於 POC 結果，正式實作任務樹狀結構的拖放排序功能。

#### 執行步驟
1. 更新 `TaskTreeComponent` 整合拖放
2. 實作拖放視覺回饋（highlight, placeholder）
3. 處理父子關係變更邏輯
4. 實作後端位置更新 API
5. 加入樂觀更新與錯誤回滾
6. 撰寫單元與 E2E 測試

#### 驗收標準
- [ ] 任務可拖放排序
- [ ] 可拖放至不同父節點
- [ ] 視覺回饋清晰
- [ ] 後端同步正確
- [ ] 錯誤時自動回滾
- [ ] 測試覆蓋主要場景

#### 產出物
- 更新 `src/app/features/blueprint/ui/task/task-tree/task-tree.component.ts`
- `src/app/features/blueprint/data-access/services/task-reorder.service.ts`
- `e2e/task/drag-drop.spec.ts`

---

### P1-T03: 表格視圖排序功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P0 完成 |
| **負責角色** | 前端工程師 |

#### 描述
增強任務表格視圖，支援多欄排序功能。

#### 執行步驟
1. 更新 ST 欄位配置啟用 `sort`
2. 實作多欄排序邏輯
3. 與後端排序參數整合
4. 保存排序偏好設定
5. 撰寫測試

#### 驗收標準
- [ ] 支援單欄排序
- [ ] 支援多欄排序（Shift+Click）
- [ ] 排序狀態持久化
- [ ] 與後端分頁排序整合

#### 產出物
- 更新 `src/app/features/blueprint/ui/task/task-table/task-table.component.ts`

---

### P1-T04: 表格視圖篩選功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T03 |
| **負責角色** | 前端工程師 |

#### 描述
增強任務表格視圖，支援進階篩選功能。

#### 執行步驟
1. 設計篩選 UI（狀態、優先級、指派人、日期範圍）
2. 實作 ST filter 配置
3. 與後端篩選參數整合
4. 保存篩選偏好設定
5. 撰寫測試

#### 驗收標準
- [ ] 支援狀態篩選
- [ ] 支援優先級篩選
- [ ] 支援指派人篩選
- [ ] 支援日期範圍篩選
- [ ] 篩選狀態持久化

#### 產出物
- 更新 `src/app/features/blueprint/ui/task/task-table/task-table.component.ts`
- `src/app/features/blueprint/ui/task/shared/task-filter/task-filter.component.ts`

---

### P1-T05: 批量選擇功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T04 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務批量選擇功能，為批量操作做準備。

#### 執行步驟
1. 在表格加入 checkbox 欄位
2. 實作全選/取消全選
3. 管理選擇狀態（Signal）
4. 顯示已選擇數量
5. 撰寫測試

#### 驗收標準
- [ ] 可單選/多選任務
- [ ] 全選/取消全選功能
- [ ] 選擇數量正確顯示
- [ ] 選擇狀態在分頁間保持

#### 產出物
- 更新 `src/app/features/blueprint/ui/task/task-table/task-table.component.ts`
- `src/app/features/blueprint/ui/task/shared/task-selection.service.ts`

---

### P1-T06: 批量操作 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 2 天 |
| **前置依賴** | P1-T05 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務批量操作 UI，支援完成、取消、刪除、指派。

#### 執行步驟
1. 建立批量操作工具列元件
2. 實作批量完成操作
3. 實作批量取消操作
4. 實作批量刪除（含確認）
5. 實作批量指派（選擇指派人）
6. 撰寫測試

#### 驗收標準
- [ ] 批量完成功能正常
- [ ] 批量取消功能正常
- [ ] 批量刪除有確認對話框
- [ ] 批量指派可選擇指派人
- [ ] 操作結果有正確回饋

#### 產出物
- `src/app/features/blueprint/ui/task/shared/task-bulk-actions/task-bulk-actions.component.ts`
- 更新 `src/app/features/blueprint/data-access/stores/task.store.ts`

---

### P1-T07: 工時欄位資料模型

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P0 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
擴展任務資料模型，加入工時記錄欄位。

#### 執行步驟
1. 設計工時欄位：estimated_hours, actual_hours
2. 建立 Supabase Migration
3. 更新 TypeScript 類型定義
4. 更新前端模型
5. 撰寫測試

#### 驗收標準
- [ ] 資料表包含工時欄位
- [ ] TypeScript 類型已更新
- [ ] 前端模型已更新
- [ ] 現有測試通過

#### 產出物
- `supabase/migrations/xxx_add_task_work_hours.sql`
- 更新 `src/app/features/blueprint/domain/types/task.types.ts`

---

### P1-T08: 工時記錄 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 2 天 |
| **前置依賴** | P1-T07 |
| **負責角色** | 前端工程師 |

#### 描述
建立工時記錄 UI，支援預估工時和實際工時輸入。

#### 執行步驟
1. 更新任務表單加入工時欄位
2. 建立工時輸入元件（支援小時/天單位）
3. 實作工時統計顯示
4. 在表格和樹狀視圖顯示工時
5. 撰寫測試

#### 驗收標準
- [ ] 可輸入預估工時
- [ ] 可記錄實際工時
- [ ] 顯示工時進度（實際/預估）
- [ ] 支援小時/天單位切換

#### 產出物
- `src/app/features/blueprint/ui/task/shared/work-hours-input/work-hours-input.component.ts`
- 更新任務表單元件

---

### P1-T09: 任務模板資料模型

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P0 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
定義任務模板的資料模型。

#### 執行步驟
1. 設計 `task_templates` 資料表
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 建立 TypeScript 類型

#### 驗收標準
- [ ] 資料表已建立
- [ ] RLS 政策正確
- [ ] TypeScript 類型完整

#### 產出物
- `supabase/migrations/xxx_create_task_templates.sql`
- `src/app/features/blueprint/domain/types/task-template.types.ts`

---

### P1-T10: 任務模板功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 2 天 |
| **前置依賴** | P1-T09 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務模板功能，支援儲存和套用任務模板。

#### 執行步驟
1. 建立 `TaskTemplateService`
2. 實作「儲存為模板」功能
3. 實作「從模板建立」功能
4. 建立模板管理 UI
5. 撰寫測試

#### 驗收標準
- [ ] 可將任務儲存為模板
- [ ] 可從模板建立任務
- [ ] 模板可管理（編輯、刪除）
- [ ] 支援模板分類

#### 產出物
- `src/app/features/blueprint/data-access/services/task-template.service.ts`
- `src/app/features/blueprint/ui/task/template/task-template-list.component.ts`

---

### P1-T11: 任務匯入功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T10 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務匯入功能，支援 CSV/Excel 匯入。

#### 執行步驟
1. 設計匯入欄位映射
2. 實作 CSV 解析
3. 實作 Excel 解析（xlsx）
4. 建立匯入預覽 UI
5. 處理匯入錯誤
6. 撰寫測試

#### 驗收標準
- [ ] 支援 CSV 匯入
- [ ] 支援 Excel 匯入
- [ ] 預覽匯入資料
- [ ] 錯誤行標記與處理

#### 產出物
- `src/app/features/blueprint/ui/task/import/task-import.component.ts`
- `src/app/features/blueprint/data-access/services/task-import.service.ts`

---

### P1-T12: 任務匯出功能

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T11 |
| **負責角色** | 前端工程師 |

#### 描述
實作任務匯出功能，支援 CSV/Excel 匯出。

#### 執行步驟
1. 設計匯出欄位
2. 實作 CSV 匯出
3. 實作 Excel 匯出
4. 支援篩選後匯出
5. 撰寫測試

#### 驗收標準
- [ ] 支援 CSV 匯出
- [ ] 支援 Excel 匯出
- [ ] 支援匯出篩選後結果
- [ ] 匯出包含完整資訊

#### 產出物
- `src/app/features/blueprint/ui/task/export/task-export.component.ts`
- `src/app/features/blueprint/data-access/services/task-export.service.ts`

---

### P1-T13: Gantt 視圖評估

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T02 |
| **負責角色** | 技術架構師 |

#### 描述
評估 Gantt 視圖實作方案，決定使用第三方庫或自建簡化版。

#### 執行步驟
1. 評估 ngx-gantt 庫
2. 評估 dhtmlx-gantt 庫
3. 評估自建簡化版可行性
4. 比較授權、功能、效能
5. 產出評估報告與建議

#### 驗收標準
- [ ] 評估報告完成
- [ ] 明確推薦方案
- [ ] 授權問題已確認
- [ ] 整合難度已評估

#### 產出物
- `docs/technical-spikes/gantt-evaluation.md`

---

### P1-T14: Gantt 視圖實作

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 4 天 |
| **前置依賴** | P1-T13 |
| **負責角色** | 前端工程師 |

#### 描述
基於評估結果，實作 Gantt 視圖。

#### 執行步驟
1. 整合選定的 Gantt 方案
2. 實作任務時間軸顯示
3. 實作任務依賴連線
4. 實作縮放與導航
5. 整合任務編輯功能
6. 撰寫測試

#### 驗收標準
- [ ] Gantt 圖正確顯示任務
- [ ] 支援時間軸縮放
- [ ] 支援任務依賴顯示
- [ ] 可點擊進入任務詳情
- [ ] 效能可接受

#### 產出物
- `src/app/features/blueprint/ui/task/task-gantt/task-gantt.component.ts`
- 相關樣式與設定檔

---

### P1-T15: 視圖切換整合

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 1 天 |
| **前置依賴** | P1-T14 |
| **負責角色** | 前端工程師 |

#### 描述
整合三種視圖（樹狀、表格、Gantt）的切換功能。

#### 執行步驟
1. 更新 `TaskListComponent` 支援三種視圖
2. 實作視圖切換按鈕
3. 保存視圖偏好設定
4. 確保資料在視圖間同步
5. 撰寫測試

#### 驗收標準
- [ ] 三種視圖可自由切換
- [ ] 視圖偏好持久化
- [ ] 資料在視圖間同步
- [ ] 切換動畫流暢

#### 產出物
- 更新 `src/app/features/blueprint/ui/task/task-list/task-list.component.ts`

---

### P1-T16: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P1 |
| **預估工時** | 3 天 |
| **前置依賴** | P1-T01 ~ P1-T15 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試，驗證所有 P1 功能正確整合。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 手動測試主要流程
4. 效能基準測試
5. 修復發現的問題
6. 更新測試報告

#### 驗收標準
- [ ] 所有單元測試通過
- [ ] 所有 E2E 測試通過
- [ ] 手動測試無重大問題
- [ ] 拖放效能良好
- [ ] Gantt 效能可接受
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p1-test-report.md`

---

## 階段完成檢查清單

- [ ] P1-T01: 拖放排序 POC
- [ ] P1-T02: 任務樹狀拖放實作
- [ ] P1-T03: 表格視圖排序功能
- [ ] P1-T04: 表格視圖篩選功能
- [ ] P1-T05: 批量選擇功能
- [ ] P1-T06: 批量操作 UI
- [ ] P1-T07: 工時欄位資料模型
- [ ] P1-T08: 工時記錄 UI
- [ ] P1-T09: 任務模板資料模型
- [ ] P1-T10: 任務模板功能
- [ ] P1-T11: 任務匯入功能
- [ ] P1-T12: 任務匯出功能
- [ ] P1-T13: Gantt 視圖評估
- [ ] P1-T14: Gantt 視圖實作
- [ ] P1-T15: 視圖切換整合
- [ ] P1-T16: 階段測試與整合驗證

---

## 下一階段

完成 P1 後，進入 [第 1.5 階段：檔案系統](./03-file-system.setc.md)
