# Supabase Sandbox

Next.js + Supabase application sandbox. AI-primary development — most features built via Claude Code agents.

## Project Structure

```
src/
  app/          # Next.js App Router pages and layouts
  components/   # React components (shadcn/ui in components/ui/)
  lib/          # Utilities, Supabase client helpers
  types/        # Generated TypeScript types (supabase.ts)
supabase/
  config.toml   # Local Supabase config
  migrations/   # SQL migration files
docs/
  supabase-prompts/  # Reference: official Supabase AI prompts
```

## Common Commands

```bash
pnpm dev              # Start Next.js dev server
pnpm build            # Production build
pnpm lint             # ESLint
pnpm typecheck        # TypeScript type checking
pnpm supabase:types   # Regenerate types from Supabase DB

pnpm supabase:start   # Start local Supabase stack (needs Docker)
pnpm supabase:stop    # Stop local stack
pnpm supabase:reset   # Reset local DB and replay migrations
pnpm supabase:diff    # Diff local schema against migrations
pnpm supabase:migrations  # List migration status
pnpm supabase:status  # Show local Supabase status
npx supabase migration new <name>  # Create new migration file (no pnpm wrapper)
```

## Coding Conventions

### TypeScript / JavaScript
- Arrow functions for all function expressions
- Named exports only; group exports at end of file when multiple
- Constants: `DEFAULT_*` prefix for default values, `MAX_*`/`MIN_*` for limits
- Prefer `.catch()` chains over try/catch for promise error handling
- Single-pass collection operations: combine map/filter into one `.reduce()` or loop when practical
- No `any` — use `unknown` and narrow, or define proper types
- Prefer `const` over `let`; never `var`

### React / Next.js
- Server Components by default; only add `'use client'` when needed
- Use `@supabase/ssr` with `getAll`/`setAll` cookie pattern — never `@supabase/auth-helpers-nextjs`
- Import paths use `@/` alias (maps to `src/`)
- Colocate component-specific types in the same file

### SQL / Supabase
- See `docs/supabase-prompts/` for comprehensive patterns
- Key rules:
  - Always use `snake_case` for identifiers
  - Always add RLS policies when creating tables
  - Use `SECURITY INVOKER` for database functions (not `SECURITY DEFINER` unless required)
  - Set `search_path = ''` on all functions; fully qualify references (`public.table_name`)
  - Migration files: `supabase/migrations/<timestamp>_<descriptive_name>.sql`
  - Include comments on tables and columns for discoverability

## Agents

- **supabase** (`.claude/agents/supabase.md`): Supabase development — schema, migrations, RLS, auth, edge functions
- **github** (`.claude/agents/github.md`): PR review and response workflows

## Skills

- **git** — Git state analysis and commit preparation
- **review-pr** — Structured PR review
- **respond-pr** — Draft responses to PR comments
- **db-migration** — Create Supabase migration files
- **supabase-types** — Regenerate TypeScript types

## Environment

- Supabase project: `vzfwsisqwgjtlkelajnf`
- Env vars in `.env.local` (not committed):
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
