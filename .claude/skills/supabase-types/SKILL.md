---
name: supabase-types
description: Regenerate TypeScript types from Supabase database schema. Use after running migrations or when types are out of sync with the database.
---

# /supabase-types — Regenerate TypeScript Types

1. Run `pnpm supabase:types`
2. Verify `src/types/supabase.ts` was updated and run `pnpm typecheck`
3. Summarize tables/views found in the generated types
