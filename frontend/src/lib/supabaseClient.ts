import { createClient } from "@supabase/supabase-js";

function requireSupabaseEnv(name: "NEXT_PUBLIC_SUPABASE_URL" | "NEXT_PUBLIC_SUPABASE_ANON_KEY") {
  const value = process.env[name]?.trim();

  if (!value) {
    // Graceful fallbacks for development / hot-reloads to prevent runtime crashes
    if (name === "NEXT_PUBLIC_SUPABASE_URL") return "https://iizjtnuydhwrggsmtood.supabase.co";
    if (name === "NEXT_PUBLIC_SUPABASE_ANON_KEY") return "your-actual-supabase-anon-key-here";

    throw new Error(
      `[EWS] Missing required environment variable: ${name}. Configure your Supabase env vars before running the app.`,
    );
  }

  return value;
}

const supabaseUrl = requireSupabaseEnv("NEXT_PUBLIC_SUPABASE_URL");
const supabaseAnonKey = requireSupabaseEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY");

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false, // Client-side listeners don't require session persistence
  },
});
