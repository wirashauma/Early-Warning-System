import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  turbopack: {
    root: path.resolve(__dirname),
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "images.unsplash.com",
      },
      {
        // Google profile photos from Google Sign-In (Firebase Auth)
        protocol: "https",
        hostname: "lh3.googleusercontent.com",
      },
      {
        // Google profile photos (alternate CDN)
        protocol: "https",
        hostname: "*.googleusercontent.com",
      },
    ],
  },
  async headers() {
    return [
      {
        // Terapkan ke semua routes
        source: "/(.*)",
        headers: [
          {
            // WAJIB untuk Firebase Google Sign-In popup.
            // "same-origin" memblokir komunikasi dengan popup Firebase (firebaseapp.com).
            // "same-origin-allow-popups" mengizinkan popup yang dibuka oleh halaman ini (Firebase Auth).
            key: "Cross-Origin-Opener-Policy",
            value: "same-origin-allow-popups",
          },
          {
            // Izinkan embedding resource dari Firebase/Google untuk Auth dan FCM
            key: "Cross-Origin-Embedder-Policy",
            value: "unsafe-none",
          },
        ],
      },
    ];
  },
  async rewrites() {
    let backendUrl = process.env.BACKEND_API_URL || "http://127.0.0.1:4101";
    backendUrl = backendUrl.replace(/\/$/, "");
    if (backendUrl.endsWith("/api")) {
      backendUrl = backendUrl.slice(0, -4);
    }
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
