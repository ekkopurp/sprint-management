import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAnonKey, getSupabaseUrl } from "@/lib/env";

const AUTH_PATHS = ["/login", "/signup", "/auth/callback"];

function isAuthPath(pathname: string): boolean {
  return AUTH_PATHS.some(
    (path) => pathname === path || pathname.startsWith(`${path}/`),
  );
}

function isProtectedPath(pathname: string): boolean {
  // /(app) route group URLs — Phase 1 home shell; Phase 2+ onboarding / w/*
  if (pathname === "/home" || pathname.startsWith("/home/")) return true;
  if (pathname === "/onboarding" || pathname.startsWith("/onboarding/"))
    return true;
  if (pathname === "/w" || pathname.startsWith("/w/")) return true;
  return false;
}

/**
 * Refresh the Supabase session cookie, then:
 * - redirect unauthenticated users away from protected /(app) routes
 * - redirect authenticated users away from login/signup
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const url = getSupabaseUrl();
  const anonKey = getSupabaseAnonKey();

  // Without env, skip auth guards so local builds / misconfig don't hard-crash proxy.
  if (!url || !anonKey) {
    return supabaseResponse;
  }

  const supabase = createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value),
        );
        supabaseResponse = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options),
        );
      },
    },
  });

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;

  if (!user && isProtectedPath(pathname)) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/login";
    redirectUrl.searchParams.set("next", pathname);
    return NextResponse.redirect(redirectUrl);
  }

  if (
    user &&
    isAuthPath(pathname) &&
    pathname !== "/auth/callback" &&
    !pathname.startsWith("/auth/callback/")
  ) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/home";
    redirectUrl.search = "";
    return NextResponse.redirect(redirectUrl);
  }

  return supabaseResponse;
}
