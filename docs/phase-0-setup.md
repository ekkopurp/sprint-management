# Phase 0 setup — link Supabase, Google SSO, migrations

This repo scaffolds Next.js (App Router + TypeScript + Tailwind) and ships SQL under `supabase/migrations/`. Erin already has a Supabase project — **do not paste keys into chat**. Add secrets in Cursor / Vercel dashboards only.

## 1. Link your existing Supabase project

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project.
2. **Project Settings → API** — note:
   - Project URL
   - `anon` `public` key
   - `service_role` key (server only)
3. Optional CLI link (from this repo):

```bash
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
```

## 2. Enable Google SSO (Auth v1 — Google only)

1. Supabase → **Authentication → Providers → Google** → enable.
2. Create OAuth credentials in [Google Cloud Console](https://console.cloud.google.com/) (OAuth client, Web application).
3. Authorized redirect URI (hosted):

   `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`

4. Paste Client ID / Client Secret into the Google provider form in Supabase.
5. Under **Authentication → URL Configuration**, set Site URL to your app (local `http://localhost:3000` or the Vercel URL) and add redirect allow-list entries for `/auth/callback` once Phase 1 lands.

App code expects Google OAuth (`signInWithOAuth({ provider: 'google' })` in Phase 1). Do not enable magic-link / email+password as the primary UX for v1.

## 3. Apply migrations

### Option A — Supabase CLI (preferred)

```bash
npx supabase db push
```

That applies `supabase/migrations/20261119200000_phase0_foundation.sql` to the linked project.

### Option B — SQL Editor

1. Open Supabase → **SQL Editor**.
2. Paste the full contents of `supabase/migrations/20261119200000_phase0_foundation.sql`.
3. Run once. If re-running, drop/recreate is destructive — prefer CLI migration history on a fresh schema.

### What the migration creates

- Enums: roles, invite status, ticket type (includes `integration`), priority (`high|medium|low`), size, sprint status
- Tables: profiles, workspaces, members, invites, kanban_stages, sprints, epics, tickets, tags, comments, `workspace_links` (groundwork only), counters
- Soft-archive via `archived_at` / `deleted_at` on comments
- `profiles` row on `auth.users` insert
- Default kanban stages on workspace create (To Do → … → Done; **only Done** has `is_done`)
- Multiple concurrent `active` sprints allowed (no unique constraint)
- RLS helpers + policies (`view` can insert comments)
- Points sync from size: XS/S/M/L/XL → 2/8/21/34/55; **no due date** column

## 4. Secrets to add (Cursor + Vercel)

Use these **exact names** (avoid `NEXT_PUBLIC_` in Cursor secret names):

| Secret name | Where it comes from |
|-------------|---------------------|
| `SUPABASE_URL` | Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Project Settings → API → `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Project Settings → API → `service_role` (server only) |

Optional public aliases for the browser bundle on Vercel (same values as URL/anon):

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

The app maps `SUPABASE_*` → public clients in `src/lib/env.ts` when public aliases are absent (server). For browser auth in Phase 1, set the `NEXT_PUBLIC_*` pair on Vercel as well.

**Never commit** `.env` or real keys. `.env.example` documents the shape only.

## 5. Local app smoke

```bash
cp .env.example .env.local
# fill SUPABASE_* from the dashboard (locally only)
npm install
npm run dev
```

You should see the Phase 0 placeholder page. Login UI is Phase 1.

## 6. Erin checklist

- [ ] Google provider enabled in Supabase Auth
- [ ] Migration applied (`db push` or SQL Editor)
- [ ] `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` added in Cursor secrets
- [ ] Same three (plus optional `NEXT_PUBLIC_*`) on the Vercel project when deploying
- [ ] Confirm creating a workspace (once Phase 2 UI exists) seeds seven stages with Done = terminal
