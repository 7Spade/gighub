# Avatar 欄位 Schema Cache 問題修復

## 問題描述

建立組織時出現錯誤：
```
Error: Could not find the 'avatar' column of 'accounts' in the schema cache
Code: PGRST204
```

## 根本原因

1. **遷移檔案已添加 `avatar` 欄位**：`supabase/migrations/20251130090000_add_avatar_to_accounts.sql` 已添加 `avatar` 欄位到 `accounts` 表
2. **PostgREST Schema Cache 未更新**：即使遷移已應用，PostgREST 的 schema cache 尚未刷新，導致無法識別新的 `avatar` 欄位
3. **程式碼使用新欄位**：程式碼嘗試使用 `avatar` 欄位，但 PostgREST cache 中只有 `avatar_url` 欄位

## 臨時解決方案（已實施）

修改所有插入到 `accounts` 表的服務，使用 `avatar_url` 欄位（資料庫中已存在且 PostgREST cache 中可識別）：

### 修改的檔案

1. **`src/app/shared/services/account/organization.service.ts`**
   - 將 `avatar: request.avatar || null` 改為 `avatar_url: request.avatar || null`

2. **`src/app/shared/services/account/user.service.ts`**
   - 將 `avatar: request.avatar || null` 改為 `avatar_url: request.avatar || null`

3. **`src/app/shared/services/account/bot.service.ts`**
   - 將 `avatar: request.avatar || null` 改為 `avatar_url: request.avatar || null`

## 永久解決方案

### 步驟 1：刷新 PostgREST Schema Cache

#### 方法 A：使用 Supabase Dashboard（推薦）

1. 登入 [Supabase Dashboard](https://app.supabase.com)
2. 選擇您的專案
3. 前往 **Settings** → **API**
4. 點擊 **Reload schema** 按鈕

#### 方法 B：重啟 Supabase 服務（本地開發）

```bash
# 停止 Supabase
supabase stop

# 重新啟動 Supabase
supabase start
```

#### 方法 C：使用 Supabase CLI（如果已安裝）

```bash
# 刷新 schema cache
supabase db reset
```

### 步驟 2：驗證 Schema Cache 已更新

1. 在 Supabase Dashboard 中檢查 `accounts` 表結構
2. 確認 `avatar` 欄位已存在
3. 測試建立組織功能是否正常

### 步驟 3：恢復使用 `avatar` 欄位（可選）

一旦 PostgREST schema cache 已更新，可以將程式碼改回使用 `avatar` 欄位：

```typescript
// 改回使用 avatar 欄位
avatar: request.avatar || null,
```

## 長期建議

1. **統一欄位命名**：考慮統一使用 `avatar` 或 `avatar_url`，避免同時存在兩個欄位
2. **自動化 Schema Cache 刷新**：在 CI/CD 流程中加入 schema cache 刷新步驟
3. **監控遷移狀態**：在應用遷移後自動檢查 schema cache 是否已更新

## 相關檔案

- 遷移檔案：`supabase/migrations/20251130090000_add_avatar_to_accounts.sql`
- 服務檔案：
  - `src/app/shared/services/account/organization.service.ts`
  - `src/app/shared/services/account/user.service.ts`
  - `src/app/shared/services/account/bot.service.ts`
- Repository：`src/app/core/infra/repositories/base.repository.ts`

## 測試驗證

修改後，請測試以下功能：
- ✅ 建立組織
- ✅ 建立用戶帳戶
- ✅ 建立 Bot 帳戶

所有功能應該可以正常運作，不再出現 `PGRST204` 錯誤。

