# Database Functions

Reference for creating PostgreSQL functions in Supabase.

## Default Template

```sql
create or replace function public.my_function(p_user_id uuid, p_name text)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.my_table (user_id, name)
  values (p_user_id, p_name);
end;
$$;

comment on function public.my_function is 'Description of what this function does';
```

## Key Rules

### Security

- **Default to `SECURITY INVOKER`** — runs as the calling user, respects RLS
- Only use `SECURITY DEFINER` when the function must bypass RLS (e.g., admin operations, triggers that need elevated access)
- When using `SECURITY DEFINER`, add `-- SECURITY DEFINER: reason` comment explaining why

### Search Path

- **Always set `search_path = ''`** on every function
- **Fully qualify all object references**: `public.table_name`, `auth.uid()`, `extensions.uuid_generate_v4()`
- This prevents search path injection attacks

### Parameters

- Prefix parameters with `p_` to avoid ambiguity with column names: `p_user_id`, `p_name`
- Use explicit types, not `anyelement` or similar
- Provide defaults where sensible: `p_limit integer default 10`

### Return Types

```sql
-- Return a single value
returns uuid

-- Return a row
returns public.my_table

-- Return multiple rows
returns setof public.my_table

-- Return a custom type
returns table (id bigint, name text, total numeric)

-- Return nothing
returns void

-- Return JSON
returns jsonb
```

## Common Patterns

### RPC Function (called from client)

```sql
create or replace function public.get_user_dashboard(p_user_id uuid)
returns table (
  profile_name text,
  total_orders bigint,
  last_order_at timestamptz
)
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return query
  select
    p.display_name,
    count(o.id),
    max(o.created_at)
  from public.profiles p
  left join public.orders o on o.user_id = p.user_id
  where p.user_id = p_user_id
  group by p.display_name;
end;
$$;
```

### Trigger Function

```sql
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer  -- SECURITY DEFINER: trigger needs to update regardless of RLS
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger tr_example_updated_at
  before update on public.example
  for each row
  execute function public.handle_updated_at();
```

### Function with Error Handling

```sql
create or replace function public.transfer_balance(
  p_from_user uuid,
  p_to_user uuid,
  p_amount numeric
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  update public.wallets set balance = balance - p_amount
  where user_id = p_from_user and balance >= p_amount;

  if not found then
    raise exception 'Insufficient balance';
  end if;

  update public.wallets set balance = balance + p_amount
  where user_id = p_to_user;
end;
$$;
```
