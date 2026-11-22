/**
 * Env mapping: Cursor/Vercel secrets use SUPABASE_* without NEXT_PUBLIC_.
 * Browser clients need a public URL/anon key — prefer NEXT_PUBLIC_* when set,
 * otherwise fall back to SUPABASE_* (works for server).
 *
 * For Phase 1 browser auth (login/signup/sign-out), set both:
 *   NEXT_PUBLIC_SUPABASE_URL
 *   NEXT_PUBLIC_SUPABASE_ANON_KEY
 * (same values as SUPABASE_URL / SUPABASE_ANON_KEY). See docs/phase-1-auth.md.
 *
 * Auth v1: email + password. Enable Email in Supabase Dashboard
 * (Authentication → Providers → Email). Google SSO is deferred.
 */
export function getSupabaseUrl(): string {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL ?? "";
  return url;
}

export function getSupabaseAnonKey(): string {
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
    process.env.SUPABASE_ANON_KEY ??
    "";
  return key;
}

/** Server-only. Never import this into client components. */
export function getSupabaseServiceRoleKey(): string {
  return process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
}
