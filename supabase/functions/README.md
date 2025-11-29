# Supabase Edge Functions

> 此資料夾放置 Supabase Edge Functions（Deno Runtime 無伺服器函式），包含函式程式碼、相依套件與部署腳本。

---

## 📁 目錄結構

```
supabase/functions/
├── README.md                          # 本文件 - Functions 說明
├── _shared/                           # 共用程式碼與工具
│   ├── cors.ts                        # CORS 處理工具
│   ├── supabase-client.ts             # Supabase Client 初始化
│   ├── auth.ts                        # 認證相關工具
│   └── response.ts                    # 標準回應格式
├── hello-world/                       # 範例函式
│   └── index.ts                       # 函式進入點
├── send-notification/                 # 通知發送函式
│   └── index.ts                       # 函式進入點
├── webhook-handler/                   # Webhook 處理函式
│   └── index.ts                       # 函式進入點
└── scheduled-cleanup/                 # 排程清理函式
    └── index.ts                       # 函式進入點
```

---

## 📋 規劃檔案清單

### 共用模組 (`_shared/`)

| 檔案名稱 | 說明 | 狀態 |
|---------|------|------|
| `cors.ts` | CORS 標頭處理，支援 preflight 請求 | 待建立 |
| `supabase-client.ts` | Supabase Client 初始化與設定 | 待建立 |
| `auth.ts` | JWT 驗證與使用者認證工具 | 待建立 |
| `response.ts` | 標準化 API 回應格式 | 待建立 |

### 業務函式

| 函式名稱 | 說明 | 觸發方式 | 狀態 |
|---------|------|---------|------|
| `hello-world` | 測試用範例函式 | HTTP | 待建立 |
| `send-notification` | 發送推播/郵件通知 | HTTP / Database Webhook | 待建立 |
| `webhook-handler` | 外部 Webhook 處理 | HTTP | 待建立 |
| `scheduled-cleanup` | 定時清理過期資料 | Cron | 待建立 |

---

## 🚀 開發指令

### 本地開發

```bash
# 啟動本地 Supabase（含 Functions）
supabase start

# 啟動單一函式的開發伺服器
supabase functions serve hello-world --env-file ./supabase/.env.local

# 啟動所有函式
supabase functions serve --env-file ./supabase/.env.local
```

### 部署

```bash
# 部署單一函式
supabase functions deploy hello-world --project-ref <project-id>

# 部署所有函式
supabase functions deploy --project-ref <project-id>
```

### 測試

```bash
# 呼叫本地函式
curl -i --location --request POST 'http://localhost:54321/functions/v1/hello-world' \
  --header 'Authorization: Bearer <anon-key>' \
  --header 'Content-Type: application/json' \
  --data '{"name":"World"}'
```

---

## 📝 開發規範

### 函式結構

每個函式應遵循以下結構：

```typescript
// supabase/functions/example-function/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

serve(async (req) => {
  // 處理 CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { data } = await req.json()
    
    // 業務邏輯
    
    return new Response(
      JSON.stringify({ success: true, data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### 環境變數

- 不在程式碼中硬編碼機密資訊
- 使用 `Deno.env.get('VAR_NAME')` 讀取環境變數
- 本地開發使用 `.env.local` 檔案
- 生產環境透過 Supabase Dashboard 設定

---

## 🔗 相關連結

| 目錄 | 說明 |
|------|------|
| [`../docs/`](../docs/README.md) | 文件與指南 |
| [`../migrations/`](../migrations/README.md) | 資料庫遷移 |
| [`../tests/`](../tests/README.md) | 測試檔案 |

---

## 📚 參考資源

- [Supabase Edge Functions 官方文件](https://supabase.com/docs/guides/functions)
- [Deno 標準函式庫](https://deno.land/std)

---

**最後更新**: 2025-11-29
