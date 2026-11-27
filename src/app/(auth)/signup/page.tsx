import { SignupForm } from "@/components/auth/signup-form";

export default function SignupPage() {
  return (
    <div>
      <h2 className="mb-6 text-lg font-medium text-[var(--ink)]">
        Create an account
      </h2>
      <SignupForm />
    </div>
  );
}
