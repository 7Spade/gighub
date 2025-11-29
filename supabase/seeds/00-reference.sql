-- 00-reference.sql
-- 建議內容：放置系統級的參考資料（enums / lookup / roles / account types）
-- 目的：Idempotent 插入（可重複執行），避免改變 schema（schema 應由 migrations 處理）

-- 注意事項：如果你的 DB 有 RLS（Row Level Security）或嚴格 policy，請用具有足夠權限的帳號執行 seeds，或暫時在 migrations 中延後建立 policy。

-- Example: account_types lookup
CREATE TABLE IF NOT EXISTS account_types (
	id TEXT PRIMARY KEY,
	description TEXT NOT NULL
);

INSERT INTO account_types (id, description)
VALUES
	('user', '個人使用者'),
	('organization', '組織'),
	('bot', '機器人'),
	('team', '團隊')
ON CONFLICT (id) DO NOTHING;

-- Example: roles
CREATE TABLE IF NOT EXISTS roles (
	id TEXT PRIMARY KEY,
	name TEXT NOT NULL
);

INSERT INTO roles (id, name)
VALUES
	('owner', 'Owner'),
	('admin', 'Admin'),
	('member', 'Member')
ON CONFLICT (id) DO NOTHING;

-- 如果你有 policy 需要在 seed 前暫時關閉，請參考 README 中建議的流程或使用 superuser 連線執行 seeds。


