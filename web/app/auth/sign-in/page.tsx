import { Suspense } from "react";
import type { Metadata } from "next";
import { SiteShell } from "@/components/site-shell";
import { SignInForm } from "./sign-in-form";

export const metadata: Metadata = {
  title: "Sign in — CityScout"
};

export default function SignInPage() {
  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="max-w-md space-y-4">
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Account</p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            Sign in.
          </h1>
          <p className="text-base leading-7 text-city-muted">
            Use your email to sign in or create an account. We&apos;ll send you a link — no
            password required.
          </p>
        </div>
      </section>

      <div className="max-w-md pb-12">
        <Suspense>
          <SignInForm />
        </Suspense>
      </div>
    </SiteShell>
  );
}
