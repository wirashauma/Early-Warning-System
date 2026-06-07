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
    ],
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
