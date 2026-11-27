# Phase 1 — Auth shell (local test)

Email + password via Supabase Auth. Google SSO is deferred.

## 1. Env (`.env.local`)

```bash
cp .env.example .env.local
```

Fill from Supabase → **Project Settings → API**:

| Variable | Notes |
|----------|--------|
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | `anon` `public` key |
| `SUPABASE_SERVICE_ROLE_KEY` | `service_role` (server only; not used by login UI) |
| `NEXT_PUBLIC_SUPABASE_URL` | **Required for browser auth** — same as `SUPABASE_URL` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | **Required for browser auth** — same as `SUPABASE_ANON_KEY` |

Never commit `.env.local`. Server helpers also fall back from `SUPABASE_*` when public aliases are absent; the **browser** client needs the `NEXT_PUBLIC_*` pair.

## 2. Supabase Auth URL settings (Erin)

In Supabase → **Authentication → URL Configuration**:

1. **Site URL:** `http://localhost:3000` for local (or your Vercel URL in production).
2. **Redirect URLs** allow-list (add both local and prod as needed):
   - `http://localhost:3000/auth/callback`
   - `https://YOUR_VERCEL_HOST/auth/callback`

Email provider should already be enabled (Phase 0).

### Confirm email

- **Confirm email ON:** after signup, check inbox → confirmation link hits `/auth/callback` → then sign in (or session is established if the link completes exchange).
- **Confirm email OFF** (local frictionless): signup returns a session immediately and redirects to `/home`.

## 3. Run

```bash
npm install
npm run dev
```

Open `http://localhost:3000` → redirects to `/login`.

### Smoke checklist

1. **Sign up** at `/signup` with email + password.
2. Confirm email if required, then **sign in** at `/login`.
3. Land on `/home` (empty authenticated shell + nav + email).
4. Visit `/home` while signed out → redirected to `/login`.
5. **Sign out** → back to `/login`; `/home` stays protected.

## 4. Routes

| Path | Access |
|------|--------|
| `/` | Redirects by session → `/home` or `/login` |
| `/login`, `/signup` | Public (signed-in users redirected to `/home`) |
| `/auth/callback` | Public — email confirmation code exchange |
| `/home` | Authenticated shell (proxy-protected) |
