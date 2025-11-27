# 📦 模組範本目錄

> 可直接複製使用的程式碼範本

---

## 可用範本

| 範本 | 用途 | 使用時機 |
|------|------|----------|
| [feature.template.md](./feature.template.md) | 完整功能模組結構 | 建立新功能時 |
| [store.template.md](./store.template.md) | Signal Store 範本 | 建立狀態管理時 |
| [repository.template.md](./repository.template.md) | Repository 範本 | 建立資料存取層時 |
| [component.template.md](./component.template.md) | 元件範本 | 建立新元件時 |

---

## 使用方式

1. 選擇需要的範本
2. 複製範本內容
3. 將 `{feature}` / `{Feature}` 替換為實際名稱
4. 根據需求調整內容

---

## 命名規範

| 類型 | 檔案命名 | 類別命名 |
|------|----------|----------|
| Store | `{feature}.store.ts` | `{Feature}Store` |
| Repository | `{feature}.repository.ts` | `{Feature}Repository` |
| Service | `{feature}.service.ts` | `{Feature}Service` |
| Model | `{feature}.model.ts` | `{Feature}` |
| Interface | `{feature}.interface.ts` | `I{Feature}` 或 `{Feature}` |
| Enum | `{feature}-status.enum.ts` | `{Feature}Status` |
| Component | `{feature}-{type}.component.ts` | `{Feature}{Type}Component` |

---

**最後更新**: 2025-11-27
