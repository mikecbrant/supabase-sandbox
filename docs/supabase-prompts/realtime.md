# Realtime

Adapted from [Supabase official prompt](https://github.com/supabase/supabase/blob/master/examples/prompts/use-realtime.md).

## Core Rules

### DO
- Use `broadcast` with database triggers for real-time database changes
- Use `broadcast` for custom events and complex payloads
- Use `presence` only for ephemeral state (online status, cursors)
- Default to `private: true` for database-triggered channels
- Always clean up subscriptions on unmount
- Set auth before subscribing to private channels
- Add indexes on columns used in RLS policies for `realtime.messages`

### DON'T
- Use `postgres_changes` (deprecated — use broadcast with triggers instead)
- Subscribe to the same channel multiple times
- Forget to call `supabase.removeChannel()` on cleanup
- Use public channels for sensitive data

## Function Selection

| Use Case | Function | When |
|----------|----------|------|
| `broadcast` | DB changes via triggers | Real-time updates from database changes |
| `broadcast` | Custom events | Chat messages, notifications, live updates |
| `presence` | Ephemeral state only | Online indicators, typing status, cursors |

## Channel Naming

- Pattern: `scope:entity:id` (e.g., `room:123:messages`)
- Event pattern: `entity_action` (e.g., `message_created`)

## Client Setup

```typescript
const supabase = createClient(url, key, {
  realtime: {
    params: {
      log_level: 'info',  // Enable for debugging
    },
  },
})
```

## React Integration Pattern

```typescript
useEffect(() => {
  const channelRef = { current: null }

  // Prevent duplicate subscriptions
  if (channelRef.current?.state === 'subscribed') return

  const channel = supabase.channel('room:123:messages', {
    config: { private: true }
  })
  channelRef.current = channel

  // Set auth before subscribing
  supabase.realtime.setAuth().then(() => {
    channel
      .on('broadcast', { event: 'message_created' }, handleMessage)
      .subscribe()
  })

  return () => {
    if (channelRef.current) {
      supabase.removeChannel(channelRef.current)
      channelRef.current = null
    }
  }
}, [roomId])
```

## Database Triggers

### Using `realtime.broadcast_changes` (recommended for DB changes)

```sql
-- Generic trigger for any table
create or replace function notify_table_changes()
returns trigger
language plpgsql
security definer
as $$
begin
  perform realtime.broadcast_changes(
    TG_TABLE_NAME || ':' || coalesce(new.id, old.id)::text,
    TG_OP,
    TG_OP,
    TG_TABLE_NAME,
    TG_TABLE_SCHEMA,
    new,
    old
  );
  return coalesce(new, old);
end;
$$;

-- Attach to a table
create trigger messages_broadcast_trigger
  after insert or update or delete on messages
  for each row execute function notify_table_changes();
```

### Using `realtime.send` (for custom messages)

```sql
create or replace function notify_custom_event()
returns trigger
language plpgsql
security definer
as $$
begin
  perform realtime.send(
    'room:' || new.room_id::text,
    'status_changed',
    jsonb_build_object('id', new.id, 'status', new.status),
    false
  );
  return new;
end;
$$;
```

### Conditional Broadcasting

```sql
-- Only broadcast significant changes
if TG_OP = 'UPDATE' and old.status is distinct from new.status then
  perform realtime.broadcast_changes(
    'room:' || new.room_id::text,
    TG_OP, TG_OP, TG_TABLE_NAME, TG_TABLE_SCHEMA, new, old
  );
end if;
```

## Authorization (RLS for Realtime)

Private channels require RLS policies on `realtime.messages`:

```sql
-- Read access
create policy "room_members_can_read" on realtime.messages
  for select to authenticated
  using (
    topic like 'room:%' and
    exists (
      select 1 from room_members
      where user_id = auth.uid()
        and room_id = split_part(topic, ':', 2)::uuid
    )
  );

-- Write access
create policy "room_members_can_write" on realtime.messages
  for insert to authenticated
  with check (
    topic like 'room:%' and
    exists (
      select 1 from room_members
      where user_id = auth.uid()
        and room_id = split_part(topic, ':', 2)::uuid
    )
  );

-- Required index for performance
create index idx_room_members_user_room
  on room_members(user_id, room_id);
```

Client-side auth:

```typescript
const channel = supabase
  .channel('room:123:messages', { config: { private: true } })
  .on('broadcast', { event: 'message_created' }, handleMessage)

await supabase.realtime.setAuth()
await channel.subscribe()
```

## Error Handling

Supabase Realtime handles reconnection automatically with exponential backoff:

```typescript
channel.subscribe((status, err) => {
  switch (status) {
    case 'SUBSCRIBED':
      console.log('Connected')
      break
    case 'CHANNEL_ERROR':
      console.error('Error:', err)
      // Client retries automatically
      break
    case 'CLOSED':
      console.log('Channel closed')
      break
  }
})
```

## Migration from postgres_changes

```typescript
// OLD (deprecated)
const channel = supabase
  .channel('changes')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'messages' }, callback)

// NEW (recommended)
const channel = supabase
  .channel(`messages:${room_id}:changes`, { config: { private: true } })
  .on('broadcast', { event: 'INSERT' }, callback)
  .on('broadcast', { event: 'UPDATE' }, callback)
  .on('broadcast', { event: 'DELETE' }, callback)
```

Then add a database trigger (see above) and RLS policies on `realtime.messages`.

## Performance

- Use one channel per logical scope (`room:123`, not `user:456:room:123`)
- Shard high-volume topics: `chat:shard:1`, `chat:shard:2`
- Configure connection pool size in Realtime Settings dashboard
