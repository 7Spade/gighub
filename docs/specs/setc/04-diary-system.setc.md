# 第二階段：日誌系統

> **Phase 2: Diary System**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P2 |
| **預計週數** | 9-10 週（2 週） |
| **總任務數** | 11 |
| **前置條件** | P1.5（檔案系統）完成 |
| **完成目標** | 日誌系統完整實作，支援照片、人員工時、任務關聯 |

---

## 階段目標

1. ✅ 日誌可上傳多張照片
2. ✅ 人員出勤與工時可記錄
3. ✅ 工作項目可關聯任務
4. ✅ 日誌可複製前一日內容
5. ✅ 月曆視圖正確顯示

---

## 任務清單

### P2-T01: 日誌資料模型擴展

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1 天 |
| **前置依賴** | P1.5 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
擴展日誌資料模型，支援照片和工作項目。

#### 執行步驟
1. 擴展 `diaries` 資料表
   - 加入 photo_ids (UUID[])
   - 加入 work_items (JSONB)
   - 加入 materials_used (JSONB)
   - 加入 weather_temperature (INTEGER)
2. 建立 Supabase Migration
3. 更新 RLS 政策
4. 更新 TypeScript 類型

#### 驗收標準
- [ ] 資料表已擴展
- [ ] TypeScript 類型已更新
- [ ] RLS 政策正確
- [ ] 現有資料相容

#### 產出物
- `supabase/migrations/xxx_extend_diaries_table.sql`
- 更新 `src/app/features/blueprint/domain/types/diary.types.ts`

---

### P2-T02: daily_attendance 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1 天 |
| **前置依賴** | P2-T01 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立每日出勤記錄資料表。

#### 執行步驟
1. 設計 `daily_attendance` 資料表
   - id, diary_id, worker_name, worker_type
   - check_in_time, check_out_time, hours_worked
   - overtime_hours, notes
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 建立 TypeScript 類型

#### 驗收標準
- [ ] 資料表已建立
- [ ] 支援多種工人類型
- [ ] RLS 政策正確
- [ ] 類型定義完整

#### 產出物
- `supabase/migrations/xxx_create_daily_attendance.sql`
- `src/app/features/blueprint/domain/types/attendance.types.ts`

---

### P2-T03: work_hours 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 0.5 天 |
| **前置依賴** | P2-T02 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立工時統計資料表（聚合資料）。

#### 執行步驟
1. 設計 `work_hours_summary` 視圖或資料表
2. 實作每日工時聚合
3. 實作每週/月工時聚合
4. 建立必要索引

#### 驗收標準
- [ ] 聚合邏輯正確
- [ ] 查詢效能良好
- [ ] 支援日/週/月範圍

#### 產出物
- `supabase/migrations/xxx_create_work_hours_summary.sql`

---

### P2-T04: DiaryService 擴展

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1 天 |
| **前置依賴** | P2-T03 |
| **負責角色** | 前端工程師 |

#### 描述
擴展 DiaryService 支援新功能。

#### 執行步驟
1. 更新 `DiaryService` 支援照片關聯
2. 加入出勤記錄管理
3. 加入工時統計查詢
4. 實作日誌複製功能
5. 撰寫單元測試

#### 驗收標準
- [ ] 照片關聯正確
- [ ] 出勤記錄 CRUD 完整
- [ ] 工時統計正確
- [ ] 複製功能正常
- [ ] 測試覆蓋 ≥ 80%

#### 產出物
- 更新 `src/app/features/blueprint/data-access/services/diary.service.ts`

---

### P2-T05: 日誌照片上傳整合

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P2-T04, P1.5 完成（檔案系統） |
| **負責角色** | 前端工程師 |

#### 描述
整合檔案系統，實作日誌照片上傳。

#### 執行步驟
1. 建立 `DiaryPhotoUploadComponent`
2. 整合 FileService 上傳照片
3. 實作照片預覽
4. 實作照片排序
5. 實作照片刪除
6. 撰寫測試

#### 驗收標準
- [ ] 可上傳多張照片
- [ ] 照片可預覽
- [ ] 照片可排序
- [ ] 照片可刪除
- [ ] 自動壓縮大圖

#### 產出物
- `src/app/features/blueprint/ui/diary/diary-photo-upload/diary-photo-upload.component.ts`

---

### P2-T06: 人員出勤 UI

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 2 天 |
| **前置依賴** | P2-T05 |
| **負責角色** | 前端工程師 |

#### 描述
建立人員出勤記錄 UI。

#### 執行步驟
1. 建立 `AttendanceListComponent`
2. 實作新增出勤記錄
3. 實作編輯出勤記錄
4. 實作工人類型選擇（自僱/外包/臨時）
5. 實作工時計算
6. 顯示工時統計
7. 撰寫測試

#### 驗收標準
- [ ] 可新增出勤記錄
- [ ] 可編輯出勤記錄
- [ ] 工時自動計算
- [ ] 統計正確顯示
- [ ] 支援批量輸入

#### 產出物
- `src/app/features/blueprint/ui/diary/attendance-list/attendance-list.component.ts`
- `src/app/features/blueprint/ui/diary/attendance-form/attendance-form.component.ts`

---

### P2-T07: 工作項目關聯任務

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P2-T06 |
| **負責角色** | 前端工程師 |

#### 描述
實作工作項目與任務的關聯功能。

#### 執行步驟
1. 建立 `WorkItemsComponent`
2. 實作任務選擇器
3. 關聯任務時顯示任務資訊
4. 實作進度回報（任務完成百分比）
5. 同步更新任務狀態
6. 撰寫測試

#### 驗收標準
- [ ] 可關聯現有任務
- [ ] 可記錄任務進度
- [ ] 進度同步至任務系統
- [ ] 未關聯任務可手動輸入

#### 產出物
- `src/app/features/blueprint/ui/diary/work-items/work-items.component.ts`
- `src/app/features/blueprint/ui/diary/task-selector/task-selector.component.ts`

---

### P2-T08: 日誌複製功能

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1 天 |
| **前置依賴** | P2-T07 |
| **負責角色** | 前端工程師 |

#### 描述
實作日誌複製前一日內容功能。

#### 執行步驟
1. 在 DiaryService 加入 copyFromPrevious 方法
2. 複製天氣、人員、工作項目
3. 清除照片（需重新上傳）
4. 更新 UI 加入複製按鈕
5. 撰寫測試

#### 驗收標準
- [ ] 可複製前一日日誌
- [ ] 天氣/人員/項目正確複製
- [ ] 照片不複製（提示重新上傳）
- [ ] 日期自動設為今日

#### 產出物
- 更新 `src/app/features/blueprint/data-access/services/diary.service.ts`
- 更新日誌表單 UI

---

### P2-T09: 月曆視圖

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P2-T08 |
| **負責角色** | 前端工程師 |

#### 描述
建立日誌月曆視圖。

#### 執行步驟
1. 建立 `DiaryCalendarComponent`
2. 整合 ng-zorro-antd Calendar
3. 在有日誌的日期顯示標記
4. 點擊日期開啟日誌
5. 顯示天氣圖示
6. 撰寫測試

#### 驗收標準
- [ ] 月曆正確顯示
- [ ] 有日誌的日期有標記
- [ ] 點擊可開啟/新增日誌
- [ ] 天氣圖示正確顯示

#### 產出物
- `src/app/features/blueprint/ui/diary/diary-calendar/diary-calendar.component.ts`

---

### P2-T10: 日誌列表與視圖切換

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 1 天 |
| **前置依賴** | P2-T09 |
| **負責角色** | 前端工程師 |

#### 描述
整合日誌列表和月曆視圖切換。

#### 執行步驟
1. 更新 `DiaryListComponent`
2. 加入視圖切換（列表/月曆）
3. 保存視圖偏好
4. 確保資料同步
5. 撰寫測試

#### 驗收標準
- [ ] 視圖可切換
- [ ] 偏好持久化
- [ ] 資料正確同步

#### 產出物
- 更新 `src/app/features/blueprint/ui/diary/diary-list/diary-list.component.ts`

---

### P2-T11: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P2 |
| **預估工時** | 2 天 |
| **前置依賴** | P2-T01 ~ P2-T10 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 測試照片上傳流程
4. 測試出勤記錄流程
5. 測試任務關聯
6. 測試日誌複製
7. 效能測試
8. 更新測試報告

#### 驗收標準
- [ ] 所有測試通過
- [ ] 照片上傳正常
- [ ] 出勤記錄正確
- [ ] 任務關聯同步
- [ ] 月曆顯示正確
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p2-test-report.md`
- `e2e/diary/diary-management.spec.ts`

---

## 階段完成檢查清單

- [ ] P2-T01: 日誌資料模型擴展
- [ ] P2-T02: daily_attendance 資料表
- [ ] P2-T03: work_hours 資料表
- [ ] P2-T04: DiaryService 擴展
- [ ] P2-T05: 日誌照片上傳整合
- [ ] P2-T06: 人員出勤 UI
- [ ] P2-T07: 工作項目關聯任務
- [ ] P2-T08: 日誌複製功能
- [ ] P2-T09: 月曆視圖
- [ ] P2-T10: 日誌列表與視圖切換
- [ ] P2-T11: 階段測試與整合驗證

---

## 下一階段

完成 P2 後，進入 [第三階段：進度追蹤儀表板](./05-progress-dashboard.setc.md)
