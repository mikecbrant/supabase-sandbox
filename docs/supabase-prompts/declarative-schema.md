# Declarative Database Schema

Adapted from [Supabase official prompt](https://github.com/supabase/supabase/blob/master/examples/prompts/declarative-database-schema.md).

## Overview

Supabase supports a declarative schema approach where you define the desired state in SQL files, and the CLI generates migration diffs automatically.

## 1. Exclusive Use of Declarative Schema

- All schema modifications must be defined in `.sql` files in `supabase/schemas/`
- Do NOT create or modify files directly in `supabase/migrations/` (except for known caveats below)
- Migration files are generated automatically through the CLI

## 2. Schema Declaration

- For each entity (tables, views, functions), create or update a `.sql` file in `supabase/schemas/`
- Each file should represent the desired final state of the entity

## 3. Migration Generation

```bash
# Stop local Supabase before generating migrations
supabase stop

# Generate migration by diffing declared schema vs current state
supabase db diff -f <migration_name>
```

## 4. Schema File Organization

- Files are executed in lexicographic order — name files to ensure correct dependency order
- When adding new columns, append them to end of table definition to prevent unnecessary diffs

## 5. Rollback Procedures

1. Update `.sql` files in `supabase/schemas/` to reflect desired state
2. Generate a new migration: `supabase db diff -f <rollback_migration_name>`
3. Review generated migration carefully to avoid data loss

## 6. Known Caveats

The migra diff tool cannot track everything. Use versioned migrations instead for:

### Not tracked by diff
- DML statements (insert, update, delete)
- View ownership and grants
- Security invoker on views
- Materialized views
- Column type changes that require view recreation
- RLS `alter policy` statements
- Column privileges
- Schema privileges
- Comments
- Partitions
- `alter publication ... add table ...`
- `create domain` statements
- `grant` statement duplication from default privileges

## When to Use Declarative vs Imperative

| Approach | Use When |
|----------|----------|
| Declarative (`db diff`) | Initial schema setup, large restructures, keeping schema readable |
| Imperative (hand-written migrations) | Data migrations, complex alterations, production changes, any of the caveats above |

For this project, we primarily use hand-written migrations for precision and auditability. The declarative approach is useful for understanding the full desired schema state.
