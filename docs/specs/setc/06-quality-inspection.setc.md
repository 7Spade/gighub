# 第四階段：品質驗收系統

> **Phase 4: Quality Inspection System**

---

## 階段資訊

| 屬性 | 值 |
|------|-----|
| **階段編號** | P4 |
| **預計週數** | 14-15 週（2 週） |
| **總任務數** | 9 |
| **前置條件** | P3（進度追蹤）完成 |
| **完成目標** | 品質驗收系統完整實作，支援動態表單、缺失追蹤、簽核 |

---

## 階段目標

1. ✅ 檢驗表單可動態配置
2. ✅ 照片可標註位置
3. ✅ 缺失可追蹤複驗
4. ✅ 簽核記錄完整
5. ✅ 驗收報告可匯出

---

## 任務清單

### P4-T01: quality_inspections 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 1 天 |
| **前置依賴** | P3 完成 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立品質檢驗記錄資料表。

#### 執行步驟
1. 設計 `quality_inspections` 資料表
   - id, workspace_id, task_id
   - inspection_type, inspection_date
   - inspector_id, status (pending, passed, failed, re_inspection)
   - notes, photo_ids
2. 建立 Supabase Migration
3. 設定 RLS 政策
4. 建立 TypeScript 類型

#### 驗收標準
- [ ] 資料表已建立
- [ ] 支援任務關聯
- [ ] RLS 政策正確
- [ ] 類型定義完整

#### 產出物
- `supabase/migrations/xxx_create_quality_inspections.sql`
- `src/app/features/blueprint/domain/types/inspection.types.ts`

---

### P4-T02: inspection_items 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 1 天 |
| **前置依賴** | P4-T01 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立檢驗項目明細資料表。

#### 執行步驟
1. 設計 `inspection_items` 資料表
   - id, inspection_id, category
   - item_name, item_description
   - expected_value, actual_value
   - is_passed, defect_description
   - defect_photos, severity
2. 建立 Supabase Migration
3. 設定 RLS 政策

#### 驗收標準
- [ ] 資料表已建立
- [ ] 支援缺失記錄
- [ ] 支援照片關聯

#### 產出物
- `supabase/migrations/xxx_create_inspection_items.sql`

---

### P4-T03: inspection_templates 資料表

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 0.5 天 |
| **前置依賴** | P4-T02 |
| **負責角色** | 後端/資料庫 |

#### 描述
建立檢驗表單模板資料表。

#### 執行步驟
1. 設計 `inspection_templates` 資料表
   - id, name, description
   - category (水電/結構/裝修等)
   - items_schema (JSONB - SF Schema)
   - is_default, is_public
2. 建立 Supabase Migration
3. 建立預設模板

#### 驗收標準
- [ ] 資料表已建立
- [ ] 支援 SF Schema 存儲
- [ ] 預設模板可用

#### 產出物
- `supabase/migrations/xxx_create_inspection_templates.sql`

---

### P4-T04: 檢驗表單 SF Schema

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 2 天 |
| **前置依賴** | P4-T03 |
| **負責角色** | 前端工程師 |

#### 描述
實作動態檢驗表單，使用 @delon/form SF。

#### 執行步驟
1. 建立 `InspectionFormComponent`
2. 從模板載入 SF Schema
3. 實作動態欄位渲染
4. 實作檢驗項目評分
5. 實作缺失標記
6. 撰寫測試

#### 驗收標準
- [ ] 表單從模板動態生成
- [ ] 支援多種欄位類型
- [ ] 缺失標記功能正常
- [ ] 資料正確儲存

#### 產出物
- `src/app/features/blueprint/ui/inspection/inspection-form/inspection-form.component.ts`

---

### P4-T05: 檢驗照片標註

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 2 天 |
| **前置依賴** | P4-T04 |
| **負責角色** | 前端工程師 |

#### 描述
實作照片標註功能，標記缺失位置。

#### 執行步驟
1. 建立 `PhotoAnnotationComponent`
2. 實作 Canvas 繪圖
3. 支援矩形、圓形、箭頭標記
4. 支援文字標註
5. 儲存標註資料
6. 撰寫測試

#### 驗收標準
- [ ] 可在照片上標記
- [ ] 支援多種標記形狀
- [ ] 標記可編輯/刪除
- [ ] 標記資料正確儲存

#### 產出物
- `src/app/features/blueprint/ui/inspection/photo-annotation/photo-annotation.component.ts`

---

### P4-T06: 缺失追蹤功能

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 2 天 |
| **前置依賴** | P4-T05 |
| **負責角色** | 前端工程師 |

#### 描述
實作缺失追蹤與複驗流程。

#### 執行步驟
1. 建立 `DefectTrackingComponent`
2. 顯示缺失清單
3. 實作複驗功能
4. 記錄複驗歷史
5. 支援缺失關閉
6. 撰寫測試

#### 驗收標準
- [ ] 缺失清單正確顯示
- [ ] 可發起複驗
- [ ] 複驗歷史完整
- [ ] 缺失可關閉

#### 產出物
- `src/app/features/blueprint/ui/inspection/defect-tracking/defect-tracking.component.ts`

---

### P4-T07: 簽核流程

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 2 天 |
| **前置依賴** | P4-T06 |
| **負責角色** | 前端工程師 |

#### 描述
實作檢驗簽核流程。

#### 執行步驟
1. 建立 `inspection_signatures` 資料表
2. 建立 `SignatureComponent`
3. 實作電子簽名（手寫或選擇）
4. 實作簽核鏈
5. 記錄簽核時間戳
6. 撰寫測試

#### 驗收標準
- [ ] 簽核功能正常
- [ ] 支援手寫簽名
- [ ] 簽核鏈完整
- [ ] 不可篡改已簽核記錄

#### 產出物
- `supabase/migrations/xxx_create_inspection_signatures.sql`
- `src/app/features/blueprint/ui/inspection/signature/signature.component.ts`

---

### P4-T08: 驗收報告匯出

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 1.5 天 |
| **前置依賴** | P4-T07 |
| **負責角色** | 前端工程師 |

#### 描述
實作驗收報告 PDF 匯出。

#### 執行步驟
1. 設計報告模板
2. 整合 PDF 生成庫（jspdf 或 pdfmake）
3. 匯出檢驗詳情
4. 匯出照片與標註
5. 匯出簽核記錄
6. 撰寫測試

#### 驗收標準
- [ ] PDF 正確生成
- [ ] 包含完整資訊
- [ ] 照片標註正確顯示
- [ ] 簽核記錄完整

#### 產出物
- `src/app/features/blueprint/ui/inspection/inspection-report/inspection-report.service.ts`

---

### P4-T09: 階段測試與整合驗證

| 屬性 | 值 |
|------|-----|
| **階段** | P4 |
| **預估工時** | 2 天 |
| **前置依賴** | P4-T01 ~ P4-T08 |
| **負責角色** | QA/全端 |

#### 描述
執行完整的階段測試。

#### 執行步驟
1. 執行所有單元測試
2. 執行所有 E2E 測試
3. 測試動態表單
4. 測試照片標註
5. 測試缺失追蹤流程
6. 測試簽核流程
7. 測試報告匯出
8. 更新測試報告

#### 驗收標準
- [ ] 所有測試通過
- [ ] 動態表單功能正常
- [ ] 照片標註正確儲存
- [ ] 缺失追蹤流程完整
- [ ] 簽核不可篡改
- [ ] PDF 匯出正確
- [ ] 測試覆蓋率 ≥ 80%

#### 產出物
- `docs/test-reports/p4-test-report.md`
- `e2e/inspection/quality-inspection.spec.ts`

---

## 階段完成檢查清單

- [ ] P4-T01: quality_inspections 資料表
- [ ] P4-T02: inspection_items 資料表
- [ ] P4-T03: inspection_templates 資料表
- [ ] P4-T04: 檢驗表單 SF Schema
- [ ] P4-T05: 檢驗照片標註
- [ ] P4-T06: 缺失追蹤功能
- [ ] P4-T07: 簽核流程
- [ ] P4-T08: 驗收報告匯出
- [ ] P4-T09: 階段測試與整合驗證

---

## 下一階段

完成 P4 後，進入 [第五階段：協作報表與上線](./07-collaboration-reports-launch.setc.md)
