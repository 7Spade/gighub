
-- 22-diary.sql
-- 建議內容：施工日誌 (diary) 的範例資料

CREATE TABLE IF NOT EXISTS diary (
	id UUID PRIMARY KEY,
	blueprint_id UUID NOT NULL,
	work_date DATE NOT NULL,
	summary TEXT,
	work_hours NUMERIC,
	worker_count INTEGER,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

INSERT INTO diary (id, blueprint_id, work_date, summary, work_hours, worker_count)
VALUES
	('22000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, '2025-11-01', 'Site inspection and planning', 6.5, 4),
	('22000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, '2025-11-02', 'Material delivery', 3, 2)
ON CONFLICT (id) DO NOTHING;


