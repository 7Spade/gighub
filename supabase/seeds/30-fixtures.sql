
-- 30-fixtures.sql
-- 建議內容：大量 mock 或 UI 開發用資料（可選載入）。
-- 在開發中可以把這個檔案保留為可選（如果要快速填充大量資料），但平常 CI / 簡短測試可跳過以加快速度。

-- Example: create several demo tasks (bulk)
INSERT INTO tasks (id, blueprint_id, title, description, status)
SELECT gen_random_uuid(), '10000000-0000-0000-0000-000000000001'::uuid, 'Fixture task ' || n, 'Auto-generated fixture', 'pending'
FROM generate_series(1, 20) AS s(n)
ON CONFLICT DO NOTHING;

-- Example: create more demo accounts
INSERT INTO accounts (id, type, name, email)
SELECT gen_random_uuid(), 'user', 'Fixture User ' || n, 'fixture' || n || '@example.com'
FROM generate_series(1, 10) AS s(n)
ON CONFLICT DO NOTHING;

