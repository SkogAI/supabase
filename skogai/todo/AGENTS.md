# AGENTS.md

Agent guidance for working with this Supabase backend project.

## Build/Lint/Test Commands

```bash
# Database operations
npm run db:start && npm run types:generate  # Start dev environment
npm run test:rls                           # Test RLS policies (run after schema changes)

# Edge Functions (Deno TypeScript)
npm run functions:serve                    # Start local function server
npm run lint:functions && npm run format:functions  # Lint and format Deno code
npm run test:functions                     # Test all functions
cd supabase/functions/<function-name> && deno test --allow-all test.ts  # Test single function

# SQL and validation
npm run lint:sql                          # Validate SQL syntax
supabase db execute --file tests/storage_test_suite.sql  # Test storage policies
```

## Code Style Guidelines

- **TypeScript**: Strict mode enabled, explicit types required for function signatures
- **Deno formatting**: 2 spaces, line width 100, semicolons required, double quotes
- **SQL**: snake_case for tables/columns, timestamped migrations (YYYYMMDDHHMMSS_description.sql)
- **Imports**: Use import maps from `deno.json`, prefer `@supabase/supabase-js` and `std/` imports
- **Error handling**: Always use try-catch in edge functions, return structured JSON errors
- **RLS**: All public tables MUST have RLS enabled with service_role, authenticated, and anon policies
- **Environment**: Access secrets via `Deno.env.get()`, never hardcode credentials
- **CORS**: Include CORS headers in edge functions for browser compatibility
- **Testing**: Create `test.ts` files alongside functions, use descriptive test names