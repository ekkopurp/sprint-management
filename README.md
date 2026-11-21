# Sprint Management

Internal Project & Sprint Management app for Double the Donation.

**Stack:** Next.js App Router · TypeScript · Tailwind · Supabase · Vercel

## Phase 0

Foundation only: App Router scaffold, Supabase migrations (schema + RLS), Auth/env stubs for email + password. No product UI yet.

Setup steps for linking your existing Supabase project, enabling Email auth, running migrations, and adding secrets:

→ **[docs/phase-0-setup.md](docs/phase-0-setup.md)**

### Secrets (never commit)

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

### Scripts

```bash
npm install
npm run dev
npm run build
```

### Migrations

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

Or run `supabase/migrations/20261119200000_phase0_foundation.sql` in the Supabase SQL Editor.
