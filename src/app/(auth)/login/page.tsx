import { Suspense } from "react";
import { LoginForm } from "@/components/auth/login-form";

export default function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  return (
    <div>
      <h2 className="mb-6 text-lg font-medium text-[var(--ink)]">Sign in</h2>
      <Suspense fallback={<LoginForm nextPath="/home" />}>
        <LoginFormFromParams searchParams={searchParams} />
      </Suspense>
    </div>
  );
}

async function LoginFormFromParams({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const params = await searchParams;
  const nextPath =
    params.next && params.next.startsWith("/") ? params.next : "/home";

  return <LoginForm nextPath={nextPath} />;
}
