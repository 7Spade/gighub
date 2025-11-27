# 01-foundation-layer.setc.md

## 1. 模組概述

### 業務價值
基礎層是整個 GigHub 系統的根基，負責：
- **用戶身份識別**：管理所有使用者的帳戶資訊
- **組織架構管理**：支援企業級多組織、多團隊協作
- **認證與授權**：確保系統安全存取
- **Bot 帳戶支援**：支援自動化任務執行

### 核心功能
1. **帳戶管理**：支援 USER / ORGANIZATION / BOT 三種帳戶類型
2. **組織管理**：組織的建立、成員邀請、權限設定
3. **團隊管理**：組織下的團隊劃分與成員管理
4. **認證服務**：Email/第三方登入、密碼重設

### 在系統中的定位
基礎層是三層架構的最底層，為容器層和業務層提供身份認證和組織上下文。

```
問：涉及用戶身份、組織、Bot、認證嗎？
├── 是 → 在基礎層處理
└── 否 → 繼續往下層判斷
```

---

## 2. 功能需求

### 使用者故事列表

#### GH-001: 用戶註冊
- **ID**: GH-001
- **優先級**: P0 (最高)
- **描述**: 作為新用戶，我希望能夠註冊帳號以使用系統。
- **驗收標準**:
  - [ ] 可使用 Email 註冊
  - [ ] 可使用第三方帳號 (Google/GitHub) 註冊
  - [ ] 註冊後需驗證 Email
  - [ ] 密碼需符合安全強度要求（至少 8 字元，包含大小寫字母和數字）
  - [ ] 註冊成功後自動登入
  - [ ] 顯示歡迎導覽

#### GH-002: 用戶登入
- **ID**: GH-002
- **優先級**: P0 (最高)
- **描述**: 作為已註冊用戶，我希望能夠登入系統。
- **驗收標準**:
  - [ ] 可使用 Email + 密碼登入
  - [ ] 可使用第三方帳號登入
  - [ ] 登入失敗顯示明確錯誤訊息
  - [ ] 支援「記住我」功能
  - [ ] 連續登入失敗 5 次鎖定帳號 15 分鐘

#### GH-003: 密碼重設
- **ID**: GH-003
- **優先級**: P1
- **描述**: 作為忘記密碼的用戶，我希望能夠重設密碼。
- **驗收標準**:
  - [ ] 可輸入 Email 請求重設
  - [ ] 收到重設連結郵件
  - [ ] 連結有效期限 1 小時
  - [ ] 可設定新密碼
  - [ ] 重設成功後舊 Session 失效

#### GH-004: 個人資料管理
- **ID**: GH-004
- **優先級**: P2
- **描述**: 作為用戶，我希望能夠管理我的個人資料。
- **驗收標準**:
  - [ ] 可修改顯示名稱
  - [ ] 可上傳頭像
  - [ ] 可修改密碼（需輸入舊密碼）
  - [ ] 可綁定/解綁第三方帳號
  - [ ] 可查看登入記錄

#### GH-005: 建立組織
- **ID**: GH-005
- **優先級**: P0 (最高)
- **描述**: 作為用戶，我希望能夠建立組織。
- **驗收標準**:
  - [ ] 可輸入組織名稱、描述
  - [ ] 可上傳組織 Logo
  - [ ] 建立者自動成為擁有者
  - [ ] 組織建立後可設定基本資料
  - [ ] 可選擇訂閱方案（免費/付費）

#### GH-006: 邀請成員加入組織
- **ID**: GH-006
- **優先級**: P0 (最高)
- **描述**: 作為組織擁有者/管理員，我希望能夠邀請成員。
- **驗收標準**:
  - [ ] 可透過 Email 邀請
  - [ ] 可設定邀請的角色（admin/member）
  - [ ] 邀請連結有效期限 7 天
  - [ ] 被邀請者收到 Email 通知
  - [ ] 接受邀請後自動加入組織
  - [ ] 可查看待處理的邀請

#### GH-007: 建立團隊
- **ID**: GH-007
- **優先級**: P1
- **描述**: 作為組織管理員，我希望能夠建立團隊。
- **驗收標準**:
  - [ ] 可輸入團隊名稱、描述
  - [ ] 可設定團隊領導者
  - [ ] 可新增團隊成員（需為組織成員）
  - [ ] 可設定團隊角色（leader/member）
  - [ ] 團隊可關聯多個藍圖

#### GH-008: 管理組織成員權限
- **ID**: GH-008
- **優先級**: P1
- **描述**: 作為組織擁有者，我希望能夠管理成員權限。
- **驗收標準**:
  - [ ] 可查看所有成員列表
  - [ ] 可修改成員角色
  - [ ] 可移除成員（擁有者除外）
  - [ ] 可轉移擁有者權限
  - [ ] 成員權限變更即時生效

### 優先級與依賴關係

```
GH-001 (用戶註冊) ─┐
                   ├── GH-003 (密碼重設)
GH-002 (用戶登入) ─┼── GH-004 (個人資料管理)
                   ├── GH-005 (建立組織) ─── GH-006 (邀請成員)
                   │                         │
                   └─────────────────────────┼── GH-007 (建立團隊)
                                             └── GH-008 (管理權限)
```

---

## 3. 技術設計

### 資料模型

#### accounts 帳戶主表

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| type | TEXT | 帳戶類型: USER / ORGANIZATION / BOT |
| email | VARCHAR(255) | 電子郵件 (USER 類型必填) |
| display_name | VARCHAR(255) | 顯示名稱 |
| avatar_url | TEXT | 頭像 URL |
| settings | JSONB | 帳戶設定 |
| metadata | JSONB | 其他元數據 |
| created_at | TIMESTAMPTZ | 建立時間 |
| updated_at | TIMESTAMPTZ | 更新時間 |
| deleted_at | TIMESTAMPTZ | 軟刪除時間 |

#### organization_members 組織成員表

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| organization_id | UUID | 組織 ID (FK → accounts) |
| account_id | UUID | 帳戶 ID (FK → accounts) |
| role | TEXT | 角色: owner / admin / member |
| joined_at | TIMESTAMPTZ | 加入時間 |
| invited_by | UUID | 邀請者 ID |

#### teams 團隊表

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| organization_id | UUID | 所屬組織 ID |
| name | VARCHAR(255) | 團隊名稱 |
| description | TEXT | 團隊描述 |
| created_at | TIMESTAMPTZ | 建立時間 |

#### team_members 團隊成員表

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| team_id | UUID | 團隊 ID |
| account_id | UUID | 帳戶 ID |
| role | TEXT | 角色: leader / member |
| joined_at | TIMESTAMPTZ | 加入時間 |

### API 設計

#### 認證相關 API (Supabase Auth)
```typescript
// 註冊
supabase.auth.signUp({ email, password, options })

// 登入
supabase.auth.signInWithPassword({ email, password })

// 第三方登入
supabase.auth.signInWithOAuth({ provider: 'google' })

// 登出
supabase.auth.signOut()

// 密碼重設
supabase.auth.resetPasswordForEmail(email)
```

#### 組織 API
```typescript
// 建立組織
POST /rest/v1/accounts
Body: { type: 'ORGANIZATION', display_name: '組織名稱', ... }

// 取得組織成員
GET /rest/v1/organization_members?organization_id=eq.{id}

// 邀請成員
POST /rest/v1/organization_members
Body: { organization_id, account_id, role }
```

### 前端元件結構

```
src/app/
├── core/
│   ├── facades/
│   │   └── account/
│   │       └── workspace-context.facade.ts  # 工作區上下文 Facade
│   └── services/
│       ├── auth/
│       │   └── auth.service.ts              # 認證服務
│       └── organization/
│           └── organization.service.ts       # 組織服務
│
└── routes/
    ├── passport/                             # 登入相關頁面
    │   ├── login/
    │   ├── register/
    │   └── lock/
    └── account/                              # 帳戶管理頁面
        ├── settings/
        └── center/
```

### 狀態管理

```typescript
// WorkspaceContextFacade - 工作區上下文管理
@Injectable({ providedIn: 'root' })
export class WorkspaceContextFacade {
  // 當前上下文
  readonly currentContext = signal<WorkspaceContext | null>(null);
  
  // 上下文類型: USER | ORGANIZATION | TEAM | BOT
  readonly contextType = computed(() => this.currentContext()?.type);
  
  // 權限列表
  readonly permissions = signal<string[]>([]);
  
  // 切換上下文
  switchContext(context: WorkspaceContext): void { ... }
}
```

---

## 4. 安全與權限

### RLS 政策

#### accounts 表
```sql
-- SELECT: 用戶可查看自己的帳戶和所屬組織
CREATE POLICY "users_can_view_own_account" ON accounts FOR SELECT
USING (
  id = get_user_account_id()
  OR is_org_member(id)
);

-- UPDATE: 只能修改自己的帳戶
CREATE POLICY "users_can_update_own_account" ON accounts FOR UPDATE
USING (id = get_user_account_id());
```

#### organization_members 表
```sql
-- SELECT: 組織成員可查看同組織成員
CREATE POLICY "org_members_can_view" ON organization_members FOR SELECT
USING (is_org_member(organization_id));

-- INSERT: 組織管理員可邀請成員
CREATE POLICY "org_admins_can_invite" ON organization_members FOR INSERT
WITH CHECK (
  get_user_role_in_org(organization_id) IN ('owner', 'admin')
);
```

### 權限檢查點
1. **登入驗證**：所有 API 請求必須攜帶有效 Token
2. **組織存取**：檢查用戶是否為組織成員
3. **角色權限**：檢查用戶在組織中的角色

### 資料隔離策略
- 使用 Supabase Auth 提供的 `auth.uid()` 識別當前用戶
- 使用 Helper Function `get_user_account_id()` 取得帳戶 ID
- 組織資料透過 RLS 自動過濾，只返回用戶有權存取的資料

---

## 5. 測試規範

### 單元測試清單

#### AuthService
- [ ] `signUp_withValidEmail_shouldCreateAccount`
- [ ] `signUp_withInvalidEmail_shouldThrowError`
- [ ] `signIn_withCorrectCredentials_shouldReturnSession`
- [ ] `signIn_withWrongPassword_shouldThrowError`
- [ ] `signIn_afterFiveFailures_shouldLockAccount`
- [ ] `resetPassword_withValidEmail_shouldSendEmail`

#### OrganizationService
- [ ] `createOrganization_asUser_shouldCreateWithOwnerRole`
- [ ] `inviteMember_asOwner_shouldSendInvitation`
- [ ] `inviteMember_asMember_shouldThrowUnauthorized`
- [ ] `removeMember_asOwner_shouldRemove`
- [ ] `removeMember_removeSelf_shouldThrowError`

### 整合測試場景
- [ ] 完整註冊流程（Email → 驗證 → 登入）
- [ ] 第三方登入流程（Google OAuth → 帳戶建立）
- [ ] 組織邀請流程（邀請 → 接受 → 加入）
- [ ] 權限變更即時生效測試

### E2E 測試案例
```typescript
describe('用戶註冊', () => {
  it('should_registerNewUser_withValidEmail', async () => {
    // 填寫註冊表單
    // 提交並驗證成功訊息
    // 檢查自動登入狀態
  });
});

describe('組織管理', () => {
  it('should_createOrganization_andBecomeOwner', async () => {
    // 建立組織
    // 驗證擁有者角色
    // 檢查組織出現在列表
  });
});
```

---

## 6. 效能考量

### 效能目標
- 登入回應時間 < 500ms
- 組織列表載入 < 200ms
- 成員列表載入 < 300ms

### 優化策略
1. **Session 快取**：登入後快取 Session 資訊於本地
2. **組織列表快取**：使用 IndexedDB 快取常用組織列表
3. **權限預載**：登入時預載用戶所有權限資訊

### 監控指標
- 登入成功率
- 平均登入耗時
- 密碼重設請求量
- 組織建立數量/天

---

## 7. 實作檢查清單

### 資料表建立
- [ ] accounts 表建立完成
- [ ] organization_members 表建立完成
- [ ] teams 表建立完成
- [ ] team_members 表建立完成
- [ ] organization_bots 表建立完成
- [ ] team_bots 表建立完成

### RLS 政策設定
- [ ] accounts RLS 政策設定
- [ ] organization_members RLS 政策設定
- [ ] teams RLS 政策設定
- [ ] team_members RLS 政策設定

### Helper Functions
- [ ] `get_user_account_id()` 實作
- [ ] `is_org_member()` 實作
- [ ] `is_team_member()` 實作
- [ ] `get_user_role_in_org()` 實作

### Repository 實作
- [ ] AuthRepository 實作
- [ ] AccountRepository 實作
- [ ] OrganizationRepository 實作
- [ ] TeamRepository 實作

### Store 實作
- [ ] AuthStore 實作
- [ ] AccountStore 實作
- [ ] WorkspaceContextFacade 實作

### 元件開發
- [ ] 登入頁面
- [ ] 註冊頁面
- [ ] 個人設定頁面
- [ ] 組織管理頁面
- [ ] 團隊管理頁面

### 測試撰寫
- [ ] 單元測試完成
- [ ] 整合測試完成
- [ ] E2E 測試完成

### 文件更新
- [ ] API 文件更新
- [ ] 元件文件更新

---

**文件版本**: v1.0
**最後更新**: 2025-11-28
**維護者**: 專案架構師
