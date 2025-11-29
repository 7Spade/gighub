
-- 10-auth.sql
-- 建議內容：建立 application-layer 的 accounts/profiles 範例資料。
-- 注意：不要直接修改 Supabase 的 internal auth.users 表（包含密碼、hash）除非你非常清楚風險。
-- 推薦流程：seed accounts/profiles，並透過 Supabase Admin API 或手動流程建立真實 auth users（有密碼與 hash）。

-- Example: accounts table (若 migrations 已建立此表)
CREATE TABLE IF NOT EXISTS accounts (
	id UUID PRIMARY KEY,
	type TEXT NOT NULL,
	name TEXT,
	email TEXT,
	parent_account_id UUID NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert a few sample accounts (idempotent)
INSERT INTO accounts (id, type, name, email)
VALUES
	('00000000-0000-0000-0000-000000000001'::uuid, 'organization', 'Demo Organization', 'org@example.com'),
	('00000000-0000-0000-0000-000000000002'::uuid, 'user', 'Alice', 'alice@example.com'),
	('00000000-0000-0000-0000-000000000003'::uuid, 'bot', 'ImportBot', NULL)
ON CONFLICT (id) DO NOTHING;

-- Teams: a team can be modelled either as a separate table or as account.type='team' with parent_account_id
-- Example: create a team as an account referencing the organization
INSERT INTO accounts (id, type, name, parent_account_id)
VALUES
	('00000000-0000-0000-0000-000000000010'::uuid, 'team', 'Demo Team', '00000000-0000-0000-0000-000000000001'::uuid)
ON CONFLICT (id) DO NOTHING;

-- Note: To create real authentication users, run a short script that calls Supabase Admin API with service_role key.
-- Example (outside SQL): use supabase-js or curl to create users securely in local dev.


