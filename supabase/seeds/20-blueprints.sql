
-- 20-blueprints.sql
-- 建議內容：建立藍圖 (blueprints) 的最小範例資料。
-- 假設 migrations 已建立 `blueprints` 表，並有欄位 (id uuid, owner_account_id uuid, name text, metadata jsonb, created_at timestamptz)

CREATE TABLE IF NOT EXISTS blueprints (
	id UUID PRIMARY KEY,
	owner_account_id UUID NOT NULL,
	name TEXT NOT NULL,
	metadata JSONB DEFAULT '{}',
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

INSERT INTO blueprints (id, owner_account_id, name, metadata)
VALUES
	('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'Demo Blueprint', '{"version":1}')
ON CONFLICT (id) DO NOTHING;

-- 如果你的 schema 與此不同，請修改欄位名稱或改以 migrations 建 table，再只在 seed 中做 INSERT。


