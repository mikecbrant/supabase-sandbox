# Next.js + Supabase Auth

Adapted from [Supabase official prompt](https://github.com/supabase/supabase/blob/master/examples/prompts/nextjs-supabase-auth.md).

## Overview

1. Install `@supabase/supabase-js` and `@supabase/ssr` packages
2. Set up environment variables
3. Write two utility `createClient` functions (browser + server)
4. Hook up Proxy to refresh auth tokens

## Critical Rules

**MUST use:**
- `@supabase/ssr` package
- ONLY `getAll()` and `setAll()` for cookie handling

**MUST NEVER use:**
- `get`, `set`, or `remove` individual cookie methods (DEPRECATED — breaks application)
- `@supabase/auth-helpers-nextjs` (DEPRECATED — breaks application)

```typescript
// NEVER generate this pattern — it breaks auth
{
  cookies: {
    get(name: string) { ... },     // BREAKS APPLICATION
    set(name: string, value) { ... }, // BREAKS APPLICATION
    remove(name: string) { ... }   // BREAKS APPLICATION
  }
}

// ALWAYS use this pattern
{
  cookies: {
    getAll() {
      return cookieStore.getAll()
    },
    setAll(cookiesToSet) {
      cookiesToSet.forEach(({ name, value, options }) =>
        cookieStore.set(name, value, options)
      )
    }
  }
}
```

## Browser Client

```typescript
// src/lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!
  )
}
```

## Server Client

```typescript
// src/lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Called from Server Component — can be ignored
            // if proxy is refreshing user sessions.
          }
        },
      },
    }
  )
}
```

## Proxy Implementation

```typescript
// proxy.ts (project root — Next.js requirement)
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function proxy(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // CRITICAL: Do NOT add code between createServerClient and auth.getUser()
  // Doing so can cause random session termination
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (
    !user &&
    !request.nextUrl.pathname.startsWith('/login') &&
    !request.nextUrl.pathname.startsWith('/auth')
  ) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // IMPORTANT: Return supabaseResponse as-is to preserve cookies
  // If creating a new response:
  // 1. Pass request: NextResponse.next({ request })
  // 2. Copy cookies: newResponse.cookies.setAll(supabaseResponse.cookies.getAll())
  // 3. Return the new response
  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

## Usage in Server Components

```typescript
import { createClient } from "@/lib/supabase/server"

export default async function Page() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return <p>Not logged in</p>

  const { data: items } = await supabase.from("items").select("*")
  return <ul>{items?.map(item => <li key={item.id}>{item.name}</li>)}</ul>
}
```

## Verification Checklist

- [ ] No imports from `@supabase/auth-helpers-nextjs`
- [ ] Only `getAll()` and `setAll()` used for cookies
- [ ] No individual `get()`, `set()`, or `remove()` cookie calls
- [ ] Server client created per-request (not global)
- [ ] `getUser()` called in proxy immediately after client creation
- [ ] supabaseResponse returned as-is (cookies preserved)
