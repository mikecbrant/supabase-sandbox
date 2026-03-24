# SQL Style Guide

Reference for SQL conventions when working with Supabase/PostgreSQL.

## General

- Use lowercase for SQL keywords (e.g., `select`, `from`, `where`) for readability in code, though uppercase is also acceptable — be consistent within a file
- Use `snake_case` for all identifiers: tables, columns, functions, triggers, indexes
- Prefer descriptive names: `user_profiles` not `up`, `created_at` not `ca`

## Data Types

- Use `text` over `varchar` unless a length constraint is genuinely required
- Use `timestamptz` (not `timestamp`) for all time columns
- Use `bigint generated always as identity primary key` as the default PK pattern
- Use `uuid` for foreign keys that reference auth.users or where globally unique IDs are needed
- Use `jsonb` over `json` (supports indexing, faster reads)
- Use `boolean` (not `integer` 0/1)

## Table Structure

```sql
create table public.example (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete cascade not null,
  name text not null,
  description text,
  status text not null default 'active',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

comment on table public.example is 'Description of what this table stores';
comment on column public.example.status is 'One of: active, inactive, archived';
```

## Naming Conventions

| Entity | Convention | Example |
|--------|-----------|---------|
| Tables | Plural nouns | `user_profiles`, `order_items` |
| Columns | Singular descriptive | `user_id`, `created_at`, `is_active` |
| Boolean columns | `is_` or `has_` prefix | `is_active`, `has_subscription` |
| Timestamps | `*_at` suffix | `created_at`, `updated_at`, `deleted_at` |
| Foreign keys | `<referenced_table_singular>_id` | `user_id`, `order_id` |
| Indexes | `idx_<table>_<columns>` | `idx_users_email` |
| Constraints | `<table>_<columns>_<type>` | `users_email_unique` |
| Functions | `verb_noun` | `get_user_role`, `update_balance` |
| Triggers | `tr_<table>_<event>` | `tr_users_after_insert` |

## Query Style

- Use `between` for range checks instead of `>=` and `<=`
- Use `like` or `ilike` for pattern matching
- Avoid aliases in `where` conditions; use full column names
- Use explicit `join` syntax (never implicit joins in `where`)
- Qualify column names with table name/alias when joining

```sql
-- Good
select
  u.id,
  u.email,
  p.display_name
from public.users u
join public.profiles p on p.user_id = u.id
where u.created_at between '2024-01-01' and '2024-12-31'
  and p.display_name like '%search%';
```

## Comments

- Add `comment on table` for every table
- Add `comment on column` for non-obvious columns (skip `id`, `created_at` if usage is standard)
- Add `comment on function` for database functions
