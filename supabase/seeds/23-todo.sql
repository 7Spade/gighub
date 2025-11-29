
-- 23-todo.sql
-- 建議內容：待辦事項 (todo) 的簡單範例

CREATE TABLE IF NOT EXISTS todos (
	id UUID PRIMARY KEY,
	title TEXT NOT NULL,
	completed BOOLEAN DEFAULT false,
	assigned_account_id UUID NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

INSERT INTO todos (id, title, completed, assigned_account_id)
VALUES
	('23000000-0000-0000-0000-000000000001'::uuid, 'Set up site perimeter', false, '00000000-0000-0000-0000-000000000002'::uuid),
	('23000000-0000-0000-0000-000000000002'::uuid, 'Order cement', true, NULL)
ON CONFLICT (id) DO NOTHING;


