import type { NextConfig } from "next";

function requireEnv(name: "NEXT_PUBLIC_API_URL") {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new Error(
      `[EWS] Missing required environment variable: ${name}. Configure it before running the app.`,
    );
  }

  return value;
}

const apiUrl = requireEnv("NEXT_PUBLIC_API_URL");

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${apiUrl}/:path*`,
      },
    ];
  },
};

export default nextConfig;
