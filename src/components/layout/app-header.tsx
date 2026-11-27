import { Suspense } from "react";
import { createClient } from "@/lib/supabase/server";
import { SignOutButton } from "@/components/auth/sign-out-button";

async function UserMenu() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const label =
    (user?.user_metadata?.display_name as string | undefined) ||
    user?.email ||
    "Signed in";

  return (
    <div className="flex items-center gap-3">
      <span className="hidden max-w-[16rem] truncate text-sm text-[var(--muted)] sm:inline">
        {label}
      </span>
      <SignOutButton />
    </div>
  );
}

export function AppHeader() {
  return (
    <header className="border-b border-[var(--border)] bg-white">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4 sm:px-6">
        <div className="flex items-baseline gap-3">
          <span className="text-sm font-semibold tracking-tight text-[var(--ink)]">
            Sprint Management
          </span>
          <span className="hidden text-xs text-[var(--muted)] sm:inline">
            Double the Donation
          </span>
        </div>
        <Suspense
          fallback={
            <div className="h-8 w-24 animate-pulse rounded-md bg-[var(--surface-2)]" />
          }
        >
          <UserMenu />
        </Suspense>
      </div>
    </header>
  );
}
