# 09-link-module.setc.md

## 1. 模組概述

### 業務價值
連結模組提供外部資源的集中管理：
- **資源整合**：整合外部系統連結
- **分類管理**：連結分類與標籤
- **快速存取**：一站式外部資源入口
- **預覽功能**：連結預覽與驗證

### 核心功能
1. **外部連結管理**：添加、編輯、刪除外部連結
2. **連結分類**：依類型分類連結
3. **連結預覽**：自動取得連結標題、描述、圖片
4. **連結驗證**：定期檢查連結有效性
5. **收藏功能**：個人收藏常用連結

### 在系統中的定位
連結模組作為藍圖的外部資源入口，補充內部文件管理。

---

## 2. 功能需求

### 使用者故事列表

#### LINK-001: 新增外部連結
**作為** 使用者
**我想要** 新增外部連結到藍圖
**以便於** 集中管理相關資源

**驗收標準**：
- [ ] 可輸入連結 URL
- [ ] 自動取得連結標題
- [ ] 可自訂連結名稱
- [ ] 可選擇連結分類
- [ ] 可添加描述說明

#### LINK-002: 連結分類管理
**作為** 使用者
**我想要** 分類管理連結
**以便於** 快速找到需要的連結

**驗收標準**：
- [ ] 預設分類：文件、設計、參考、其他
- [ ] 可自訂分類
- [ ] 可批次移動連結分類
- [ ] 顯示各分類連結數量

#### LINK-003: 連結預覽
**作為** 使用者
**我想要** 預覽連結內容
**以便於** 確認連結是否正確

**驗收標準**：
- [ ] 顯示連結標題與描述
- [ ] 顯示連結預覽圖
- [ ] 顯示連結網域
- [ ] 可手動刷新預覽

### 優先級與依賴關係

| 優先級 | 功能 | 依賴 |
|--------|------|------|
| P0 | 連結 CRUD | 藍圖系統 |
| P1 | 連結分類 | 連結 CRUD |
| P2 | 連結預覽 | 連結 CRUD |

---

## 3. 技術設計

### 資料模型

**links（連結主表）**:
```sql
CREATE TABLE links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blueprint_id UUID NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  title VARCHAR(500),
  description TEXT,
  category TEXT DEFAULT 'other',
  thumbnail_url TEXT,
  site_name VARCHAR(255),
  favicon_url TEXT,
  is_valid BOOLEAN DEFAULT true,
  last_checked_at TIMESTAMPTZ,
  sort_order INTEGER DEFAULT 0,
  created_by UUID NOT NULL REFERENCES accounts(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_links_blueprint_id ON links(blueprint_id);
CREATE INDEX idx_links_category ON links(category);
CREATE INDEX idx_links_created_by ON links(created_by);
```

### 前端元件結構

```
src/app/features/link/
├── link.routes.ts
├── data-access/
│   ├── stores/
│   │   └── link.store.ts
│   └── repositories/
│       └── link.repository.ts
├── domain/
│   └── interfaces/
│       └── link.interface.ts
└── ui/
    ├── link-list/
    │   └── link-list.component.ts
    ├── link-form/
    │   └── link-form.component.ts
    └── link-card/
        └── link-card.component.ts
```

---

## 4. 安全與權限

### RLS 政策

```sql
ALTER TABLE links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blueprint_members_can_view_links" ON links FOR SELECT
USING (is_blueprint_member(blueprint_id));

CREATE POLICY "blueprint_members_can_create_links" ON links FOR INSERT
WITH CHECK (is_blueprint_member(blueprint_id));

CREATE POLICY "link_owners_can_update" ON links FOR UPDATE
USING (
  created_by = get_user_account_id()
  OR get_user_role_in_blueprint(blueprint_id) IN ('owner', 'admin')
);
```

---

## 5. 測試規範

### 單元測試清單

```typescript
describe('LinkStore', () => {
  it('loadLinks_shouldReturnBlueprintLinks');
  it('createLink_shouldFetchPreviewAndCreate');
  it('updateLink_shouldModify');
  it('deleteLink_shouldSoftDelete');
});
```

---

## 6. 效能考量

### 效能目標

| 操作 | 目標時間 |
|------|----------|
| 載入連結列表 | < 150ms |
| 取得連結預覽 | < 3s |

---

## 7. 實作檢查清單

- [ ] 建立 links 資料表
- [ ] 設定 RLS 政策
- [ ] 實作 LinkRepository
- [ ] 實作 LinkStore
- [ ] 實作 link-list 元件
- [ ] 實作 link-form 元件
- [ ] 實作連結預覽服務
- [ ] 撰寫測試

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
