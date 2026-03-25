# Database Migrations

Reference for creating and managing Supabase migrations.

## File Naming

```
supabase/migrations/<YYYYMMDDHHmmss>_<descriptive_name>.sql
```

Generate timestamp: `date +%Y%m%d%H%M%S`

Examples:
- `20240315143022_create_user_profiles.sql`
- `20240315150000_add_rls_to_orders.sql`
- `20240316090000_create_get_user_role_function.sql`

## Migration Template

```sql
-- Migration: <description>
-- Created: <date>

-- Create table
create table public.example (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete cascade not null,
  name text not null,
  created_at timestamptz default now() not null
);

comment on table public.example is 'Description of the table';

-- Enable RLS (REQUIRED for every table)
alter table public.example enable row level security;

-- RLS policies (at least one per table)
create policy "Users can read own data"
  on public.example for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can insert own data"
  on public.example for insert
  to authenticated
  with check (user_id = auth.uid());

-- Indexes
create index idx_example_user_id on public.example (user_id);
```

## Rules

1. **Every `create table` must be followed by `alter table ... enable row level security`**
2. **Every table must have at least one RLS policy**
3. **Never modify existing migration files** — always create a new migration
4. **Make migrations idempotent** where possible:
   - `create table if not exists`
   - `create or replace function`
   - `drop policy if exists` before `create policy` (for policy updates)
5. **Include rollback comments** for non-obvious changes:
   ```sql
   -- Rollback: drop table if exists public.example cascade;
   ```
6. **One logical change per migration** — don't mix unrelated schema changes
7. **Add indexes** for columns used in RLS policies, joins, and frequent queries

## Testing Migrations Locally

```bash
# Reset local DB and replay all migrations
pnpm supabase:reset

# Check migration status
pnpm supabase:migrations

# Diff local schema against remote
pnpm supabase:diff
```

## Generating Types After Migration

```bash
pnpm supabase:types
```

This regenerates `src/types/supabase.ts` from the remote schema.
