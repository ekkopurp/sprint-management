export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-3 px-6 py-24 font-sans">
      <p className="text-sm uppercase tracking-wide text-zinc-500">
        Double the Donation
      </p>
      <h1 className="text-3xl font-semibold tracking-tight text-zinc-900">
        Sprint Management
      </h1>
      <p className="max-w-md text-center text-zinc-600">
        Phase 0 foundation is in place (schema + Auth stubs). Google SSO and UI
        land in later phases — see{" "}
        <code className="rounded bg-zinc-100 px-1.5 py-0.5 text-sm">
          docs/phase-0-setup.md
        </code>
        .
      </p>
    </main>
  );
}
