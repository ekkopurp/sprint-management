import { createClient } from "@supabase/supabase-js";
import {
  getSupabaseServiceRoleKey,
  getSupabaseUrl,
} from "@/lib/env";

/**
 * Service-role client — server only, rare (invites, admin RPCs).
 * Never import from Client Components or expose SUPABASE_SERVICE_ROLE_KEY.
 */
export function createAdminClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServiceRoleKey();
  if (!url || !key) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
