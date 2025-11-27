# API 標準規範

> **目的**: 定義專案 RESTful API 的設計標準與規範

---

## 📋 目錄

- [端點命名規範](#端點命名規範)
- [HTTP 方法使用](#http-方法使用)
- [請求格式](#請求格式)
- [回應格式](#回應格式)
- [錯誤處理](#錯誤處理)
- [分頁與篩選](#分頁與篩選)
- [版本控制](#版本控制)

---

## 🔗 端點命名規範

### 資源命名

使用複數名詞命名資源：

```
✅ /api/v1/tasks
✅ /api/v1/blueprints
✅ /api/v1/users

❌ /api/v1/task
❌ /api/v1/getTask
❌ /api/v1/createBlueprint
```

### 巢狀資源

```
GET    /api/v1/blueprints/{id}/tasks          # 藍圖下的任務
GET    /api/v1/tasks/{id}/attachments         # 任務的附件
POST   /api/v1/blueprints/{id}/members        # 添加藍圖成員
```

### 查詢操作

```
GET    /api/v1/tasks/search?q=keyword         # 搜尋
GET    /api/v1/tasks/count                    # 計數
GET    /api/v1/tasks/{id}/stats               # 統計
```

---

## 📝 HTTP 方法使用

| 方法 | 用途 | 冪等 | 安全 |
|------|------|------|------|
| GET | 讀取資源 | ✅ | ✅ |
| POST | 建立資源 | ❌ | ❌ |
| PUT | 完整更新 | ✅ | ❌ |
| PATCH | 部分更新 | ✅ | ❌ |
| DELETE | 刪除資源 | ✅ | ❌ |

### 使用範例

```
GET    /api/v1/tasks                 # 列表
GET    /api/v1/tasks/{id}            # 單一資源
POST   /api/v1/tasks                 # 建立
PATCH  /api/v1/tasks/{id}            # 部分更新
DELETE /api/v1/tasks/{id}            # 刪除
```

---

## 📤 請求格式

### Headers

```http
Content-Type: application/json
Authorization: Bearer <token>
Accept-Language: zh-TW
X-Request-ID: <uuid>
```

### Body (JSON)

```json
{
  "title": "任務標題",
  "description": "任務描述",
  "priority": "high",
  "dueDate": "2025-12-31T23:59:59Z",
  "assigneeId": "uuid-string"
}
```

### 命名慣例

- 使用 camelCase
- 日期使用 ISO 8601 格式
- ID 使用 UUID 字串

---

## 📥 回應格式

### 成功回應

```json
{
  "data": {
    "id": "uuid-string",
    "title": "任務標題",
    "status": "in_progress",
    "createdAt": "2025-01-01T00:00:00Z",
    "updatedAt": "2025-01-01T00:00:00Z"
  }
}
```

### 列表回應

```json
{
  "data": [
    { "id": "1", "title": "任務 1" },
    { "id": "2", "title": "任務 2" }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

### HTTP 狀態碼

| 狀態碼 | 說明 | 使用場景 |
|--------|------|----------|
| 200 | OK | 成功讀取或更新 |
| 201 | Created | 成功建立資源 |
| 204 | No Content | 成功刪除 |
| 400 | Bad Request | 請求格式錯誤 |
| 401 | Unauthorized | 未認證 |
| 403 | Forbidden | 無權限 |
| 404 | Not Found | 資源不存在 |
| 409 | Conflict | 狀態衝突 |
| 422 | Unprocessable | 驗證失敗 |
| 500 | Internal Error | 伺服器錯誤 |

---

## ⚠️ 錯誤處理

### 錯誤回應格式

```json
{
  "error": {
    "code": "TASK401",
    "message": "任務狀態衝突",
    "details": {
      "currentStatus": "completed",
      "requestedStatus": "in_progress"
    },
    "traceId": "uuid-string"
  }
}
```

### 錯誤碼格式

```
{模組代碼}{錯誤類型}{序號}

模組代碼：
10 - AUTH（認證）
20 - ACCOUNT（帳戶）
30 - BLUEPRINT（藍圖）
40 - TASK（任務）
50 - FILE（檔案）
60 - DIARY（日誌）
70 - QA（品質驗收）

錯誤類型：
1 - 驗證錯誤
2 - 權限錯誤
3 - 資源不存在
4 - 狀態衝突
5 - 超過限制
9 - 系統錯誤
```

### 常見錯誤碼

| 錯誤碼 | HTTP | 說明 |
|--------|------|------|
| AUTH101 | 401 | Token 無效 |
| AUTH102 | 401 | Session 過期 |
| ACCOUNT201 | 403 | 無權存取組織 |
| TASK301 | 404 | 任務不存在 |
| TASK401 | 409 | 任務狀態衝突 |
| FILE551 | 400 | 檔案大小超限 |

---

## 📄 分頁與篩選

### 分頁參數

```
GET /api/v1/tasks?page=1&pageSize=20
```

| 參數 | 預設值 | 最大值 | 說明 |
|------|--------|--------|------|
| page | 1 | - | 頁碼 |
| pageSize | 20 | 100 | 每頁數量 |

### 排序

```
GET /api/v1/tasks?sort=createdAt&order=desc
GET /api/v1/tasks?sort=-createdAt        # 簡寫
```

### 篩選

```
GET /api/v1/tasks?status=in_progress
GET /api/v1/tasks?status=in_progress,pending  # 多值
GET /api/v1/tasks?dueDateGte=2025-01-01       # 範圍
GET /api/v1/tasks?assigneeId=uuid             # 關聯
```

### 搜尋

```
GET /api/v1/tasks/search?q=關鍵字
GET /api/v1/tasks/search?q=關鍵字&fields=title,description
```

---

## 🔢 版本控制

### URL 版本

```
/api/v1/tasks
/api/v2/tasks
```

### 版本策略

1. **主版本號**: 有破壞性變更時遞增
2. **向後相容**: 新增欄位不變更版本
3. **棄用週期**: 舊版本至少維護 6 個月

### 棄用標示

```http
Deprecation: true
Sunset: Sat, 01 Jul 2025 00:00:00 GMT
Link: </api/v2/tasks>; rel="successor-version"
```

---

## 📚 相關文檔

- [錯誤處理指南](../guides/error-handling.md)
- [資料模型](../reference/data-model.md)
- [技術規範](./README.md)

---

**最後更新**: 2025-11-27  
**維護者**: 開發團隊
