/**
 * Empty authenticated shell after login.
 * Workspaces / backlog / board arrive in later phases.
 */
export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col gap-3">
      <h1 className="text-xl font-semibold tracking-tight text-[var(--ink)]">
        Home
      </h1>
      <p className="max-w-lg text-sm leading-relaxed text-[var(--muted)]">
        You are signed in. Workspace onboarding, backlog, and the sprint board
        land in later phases — this shell is the Phase 1 auth checkpoint.
      </p>
    </main>
  );
}
