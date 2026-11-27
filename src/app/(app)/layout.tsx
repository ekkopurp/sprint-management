import { AppHeader } from "@/components/layout/app-header";

/**
 * Authenticated shell. Route protection lives in src/proxy.ts.
 * Phase 2 will add workspace switcher / onboarding here.
 */
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-full flex-1 flex-col bg-[var(--surface)]">
      <AppHeader />
      <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col px-4 py-8 sm:px-6">
        {children}
      </div>
    </div>
  );
}
