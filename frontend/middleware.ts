import { NextRequest, NextResponse } from "next/server";

const PUBLIC_ROUTES = new Set([
  "/",
  "/login",
  "/register",
  "/dashboard",
  "/map",
  "/emergency",
  "/education",
]);

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. Tentukan apakah route ini publik secara eksplisit atau prefix-based
  const isPublicRoute = 
    PUBLIC_ROUTES.has(pathname) || 
    pathname.startsWith("/dashboard") ||
    pathname.startsWith("/map") ||
    pathname.startsWith("/emergency") ||
    pathname.startsWith("/education");

  // 2. Ambil token dari cookies (disimpan oleh flow login di client)
  const accessToken = request.cookies.get("ews_access_token")?.value;

  // 3. Logika Proteksi: Jika mencoba akses halaman privat tanpa token, lempar ke login
  if (!accessToken && !isPublicRoute) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // 4. Logika Redirect: Jika sudah login tapi mencoba ke halaman login/register, lempar ke dashboard admin/user
  // (Optional, tapi disarankan untuk UX yang lebih baik)
  if (accessToken && (pathname === "/login" || pathname === "/register")) {
    return NextResponse.redirect(new URL("/", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - firebase-messaging-sw.js (FCM Service Worker — must be publicly accessible)
     * - Static asset extensions (png, jpg, svg, etc.)
     */
    "/((?!api|_next/static|_next/image|favicon\\.ico|firebase-messaging-sw\\.js|.*\\.(?:png|jpg|jpeg|gif|webp|svg|ico|mp3|woff|woff2)$).*)",
  ],
};
