# Row Level Security (RLS) Policies

Adapted from [Supabase official prompt](https://github.com/supabase/supabase/blob/master/examples/prompts/database-rls-policies.md).

## Core Rules

- **Enable RLS on every table**: `alter table public.table_name enable row level security;`
- **Default deny**: with RLS enabled and no policies, no rows are accessible
- **One policy per operation**: don't use `FOR ALL` — create separate policies for SELECT, INSERT, UPDATE, DELETE
- **Descriptive names**: use double-quoted names that explain the policy

## Policy Syntax by Operation

### SELECT (uses USING only)

```sql
create policy "Users can read own data"
  on public.table_name for select
  to authenticated
  using (user_id = auth.uid());
```

### INSERT (uses WITH CHECK only)

```sql
create policy "Users can insert own data"
  on public.table_name for insert
  to authenticated
  with check (user_id = auth.uid());
```

### UPDATE (uses both USING and WITH CHECK)

```sql
create policy "Users can update own data"
  on public.table_name for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

### DELETE (uses USING only)

```sql
create policy "Users can delete own data"
  on public.table_name for delete
  to authenticated
  using (user_id = auth.uid());
```

## Supabase Roles

- **`anon`**: unauthenticated requests (public API key)
- **`authenticated`**: logged-in users
- **`service_role`**: admin access (bypasses RLS — never expose to client)

Always specify the role with `TO`:

```sql
-- Public read access
create policy "Anyone can read public posts"
  on public.posts for select
  to anon, authenticated
  using (published = true);
```

## Auth Helper Functions

### `auth.uid()`

Returns the authenticated user's UUID. Use for owner-based policies:

```sql
using (user_id = auth.uid())
```

### `auth.jwt()`

Access JWT claims for role-based or metadata-based policies:

```sql
-- Check app metadata (set by server, secure)
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)

-- Check user metadata (user-editable, less secure)
using (
  (select auth.jwt() -> 'user_metadata' ->> 'team_id') = team_id::text
)
```

### MFA Enforcement

Use `auth.jwt()` to enforce multi-factor authentication:

```sql
create policy "Require MFA for updates"
  on public.profiles
  as restrictive
  for update
  to authenticated
  using (
    (select auth.jwt() ->> 'aal') = 'aal2'
  );
```

## Syntax Notes

- `for ...` must come after table name but before roles
- `to ...` must come after `for ...`
- Use double apostrophes in SQL strings: `'Night''s watch'`
- Policy names in double quotes
- Always use `auth.uid()` not `current_user`

## Common Patterns

### Team-based access

```sql
create policy "Team members can read team data"
  on public.team_data for select
  to authenticated
  using (
    team_id in (
      select team_id from public.team_members
      where user_id = auth.uid()
    )
  );
```

### Public read, authenticated write

```sql
create policy "Anyone can read"
  on public.articles for select
  to anon, authenticated
  using (true);

create policy "Authors can insert"
  on public.articles for insert
  to authenticated
  with check (author_id = auth.uid());
```

### Soft delete protection

```sql
create policy "Users can read non-deleted items"
  on public.items for select
  to authenticated
  using (deleted_at is null and user_id = auth.uid());
```

## Performance

- **Index columns used in policies**: `create index idx_table_user_id on public.table_name (user_id);`
- **Wrap auth functions in SELECT**: `(select auth.uid())` instead of `auth.uid()` — prevents re-evaluation per row
- **Minimize joins** in policy conditions — use subqueries with `exists` instead
- **Specify roles** explicitly — avoids evaluating policies for roles that don't apply

```sql
-- Good: uses (select ...) wrapper and exists
create policy "Team members can read"
  on public.documents for select
  to authenticated
  using (
    exists (
      select 1 from public.team_members
      where team_members.team_id = documents.team_id
        and team_members.user_id = (select auth.uid())
    )
  );
```

## Anti-patterns

- **`using (true)`** on non-public tables — exposes all data
- **`FOR ALL`** — combine separate operation-specific policies instead
- **`RESTRICTIVE`** policies — prefer `PERMISSIVE` (default), restrictive policies are AND'd together and can be confusing
- **Complex joins in policies** without indexes — causes full table scans
- **Using `current_user`** — use `auth.uid()` instead
