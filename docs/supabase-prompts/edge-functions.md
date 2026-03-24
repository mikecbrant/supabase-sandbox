# Edge Functions

Adapted from [Supabase official prompt](https://github.com/supabase/supabase/blob/master/examples/prompts/edge-functions.md).

## Overview

Supabase Edge Functions run on Deno Deploy — server-side TypeScript functions deployed at the edge.

## Guidelines

1. Use Web APIs and Deno core APIs instead of external dependencies (use `fetch` not Axios, use `WebSocket` API not `node-ws`)
2. Shared utilities go in `supabase/functions/_shared` with relative imports. Do NOT have cross-dependencies between Edge Functions.
3. Do NOT use bare specifiers. Always prefix with `npm:` or `jsr:`. E.g., `npm:@supabase/supabase-js` not `@supabase/supabase-js`
4. Always define a version for external imports: `npm:express@4.18.2`
5. Prefer `npm:` and `jsr:` over `deno.land/x`, `esm.sh`, and `unpkg.com`
6. Node built-in APIs available via `node:` specifier: `import process from "node:process"`
7. Use `Deno.serve()` — NEVER `import { serve } from "https://deno.land/std@.../http/server.ts"`
8. Pre-populated environment variables (no manual setup needed):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_DB_URL`
9. Set custom secrets: `supabase secrets set --env-file path/to/env-file`
10. A single Edge Function can handle multiple routes. Use Express or Hono. Each route must be prefixed with `/function-name`
11. File write operations ONLY permitted on `/tmp`
12. Use `EdgeRuntime.waitUntil(promise)` for background tasks without blocking response

## Creating a Function

```bash
npx supabase functions new my-function
```

## Example Templates

### Hello World

```tsx
interface reqPayload {
  name: string
}

Deno.serve(async (req: Request) => {
  const { name }: reqPayload = await req.json()
  const data = {
    message: `Hello ${name}!`,
  }

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json', Connection: 'keep-alive' },
  })
})
```

### Using npm packages

```tsx
import express from 'npm:express@4.18.2'

const app = express()

app.get(/(.*)/, (req, res) => {
  res.send('Welcome to Supabase')
})

app.listen(8000)
```

### Using Node built-in API

```tsx
import { randomBytes } from 'node:crypto'
import process from 'node:process'

const generateRandomString = (length) => {
  const buffer = randomBytes(length)
  return buffer.toString('hex')
}
```

### CORS handling

```tsx
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  // ... handler logic

  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
})
```

### Using Supabase Client with User Auth

```tsx
import { createClient } from "npm:@supabase/supabase-js@2"

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization")!

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data, error } = await supabase.from("todos").select("*")

  return new Response(JSON.stringify({ data, error }), {
    headers: { "Content-Type": "application/json" },
  })
})
```

## Deployment

```bash
npx supabase functions deploy my-function    # Deploy single function
npx supabase functions deploy                # Deploy all functions
npx supabase secrets set MY_SECRET=value     # Set secrets
npx supabase functions serve                 # Local dev server
```

## Calling from Client

```typescript
const { data, error } = await supabase.functions.invoke("my-function", {
  body: { name: "World" },
})
```
