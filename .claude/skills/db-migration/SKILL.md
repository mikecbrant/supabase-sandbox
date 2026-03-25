---
name: db-migration
description: Create Supabase migration files. Use when creating tables, modifying schema, adding RLS policies, or writing database functions.
---

# /db-migration — Create Supabase Migration

1. Read `docs/supabase-prompts/migrations.md` for file conventions
2. Read additional reference docs as needed (`rls-policies.md`, `database-functions.md`, `sql-style-guide.md`)
3. Ask what the migration should do (if not clear from context)
4. Run `pnpm supabase:migration:new <name>` to create the migration file, then write the SQL
5. After creation, run `pnpm supabase:reset`, `pnpm supabase:lint`, and `pnpm supabase:types`
6. Notify user when complete
