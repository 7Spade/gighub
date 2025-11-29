
-- 21-tasks.sql
-- 建議內容：建立 tasks 的基本資料。Task 屬於某個 blueprint，並可有 parent_task_id（支援子任務）。

CREATE TABLE IF NOT EXISTS tasks (
	id UUID PRIMARY KEY,
	blueprint_id UUID NOT NULL,
	title TEXT NOT NULL,
	description TEXT,
	status TEXT DEFAULT 'pending',
	assignee_account_id UUID NULL,
	parent_task_id UUID NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

INSERT INTO tasks (id, blueprint_id, title, description, status, assignee_account_id)
VALUES
	('20000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'Initial planning', 'Kickoff and initial planning tasks', 'in_progress', '00000000-0000-0000-0000-000000000002'::uuid),
	('20000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'Prepare materials', 'Gather required materials and tools', 'pending', NULL)
ON CONFLICT (id) DO NOTHING;

-- 如果你遇到 42501 權限錯誤，通常是因為 RLS / policy 阻止非 privileged role 的 INSERT。請見 README 的建議：
-- 1) 使用具有足夠權限的連線 (例如 postgres superuser) 來執行 seeds，或
-- 2) 在 migrations 先不要建立會阻擋 seed 的 policy，把 policy 建在 seed 之後。


