# Repository Guidelines

## Project Structure & Module Organization
- `supabase/functions/*`: Edge Functions (Deno, TypeScript). Shared utils in `_shared/`.
- `supabase/migrations/`: SQL migrations (timestamped). See `supabase/MIGRATIONS.md`.
- `tests/`: SQL test suites executed against the local database.
- `types/`: Generated database types (e.g., `types/database.ts`).
- `scripts/`: Helper scripts for diagnostics and CI tasks.
- `docs/`, `examples/`: Reference material and sample apps.

## Build, Test, and Development Commands
- Setup: `npm run setup` (start services, generate types).
- Dev loop: `npm run dev` (Supabase + functions serve).
- Database: `npm run db:start|stop|reset|status|diff`.
- Functions: `npm run functions:serve|new|deploy`.
- Types: `npm run types:generate` (watch: `npm run types:watch`).
- Linting: `npm run lint:functions` (Deno), `npm run lint:sql` (SQLFluff).
- Functions tests: `npm run test:functions` (watch/coverage variants available).
- DB suites: `npm run test:rls|test:profiles|test:storage-buckets|test:storage`.

## Coding Style & Naming Conventions
- TypeScript (Deno): format with `deno fmt`; lint with `deno lint`.
  - Defaults: 2‑space indent, 100‑col width, semicolons on.
  - Prefer `std/*` imports via `deno.json` mappings.
- SQL (PostgreSQL): `sqlfluff` with lower‑case keywords, 4‑space indent, trailing commas.
- Migrations: `YYYYMMDDHHMMSS_snake_case.sql` and idempotent SQL (`IF [NOT] EXISTS`).
- Functions: folder kebab‑case; entry `index.ts`; tests alongside as `test.ts`.

## Testing Guidelines
- Deno tests auto‑discover `*test.ts` or `*_test.ts` in `supabase/functions/`.
  - Run: `npm run test:functions`. Integration: `RUN_INTEGRATION_TESTS=true npm run test:functions`.
- Database suites live in `tests/` and run via Supabase CLI (see npm scripts).
- Aim for meaningful coverage on critical paths; keep tests independent and seed via `supabase/seed.sql` if needed.

## Commit & Pull Request Guidelines
- Prefer Conventional Commit‑style prefixes: `feat:`, `fix:`, `chore:`, `docs:`.
- PRs include: description, linked issues, and testing notes/screenshots when relevant.
- Ensure `npm run lint:functions`, `npm run lint:sql`, and all tests pass locally.
- For migrations, describe backward compatibility and rollback strategy.

## Security & Configuration Tips
- Use `.env` (see `.env.example`); never commit secrets.
- Update types after schema changes: `npm run types:generate`.
- Local services/config: `supabase/config.toml`.
