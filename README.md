# Sprint Management

Internal Project & Sprint Management app for Double the Donation.

**Stack:** Next.js App Router · TypeScript · Tailwind · Supabase · Vercel

## Current phase

**Phase 1 — Auth shell:** email/password login + signup, session proxy, protected `/home` shell, sign out.

| Doc | Purpose |
|-----|---------|
| [docs/phase-0-setup.md](docs/phase-0-setup.md) | Link Supabase, Email provider, migrations, secrets |
| [docs/phase-1-auth.md](docs/phase-1-auth.md) | Local auth test (`.env.local`, Site URL, confirm-email) |

### Secrets (never commit)

Server / Cursor / Vercel:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Browser client (required for login/signup/sign-out in the browser):

- `NEXT_PUBLIC_SUPABASE_URL` (same value as `SUPABASE_URL`)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (same value as `SUPABASE_ANON_KEY`)

### Scripts

```bash
cp .env.example .env.local   # fill keys locally
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
