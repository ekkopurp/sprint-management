export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-full flex-1 flex-col bg-[var(--surface)]">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col justify-center px-6 py-16">
        <div className="mb-10">
          <p className="text-xs font-medium uppercase tracking-[0.14em] text-[var(--muted)]">
            Double the Donation
          </p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-[var(--ink)]">
            Sprint Management
          </h1>
        </div>
        {children}
      </div>
    </div>
  );
}
