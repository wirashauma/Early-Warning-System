import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();

const isPlaceholder = (val?: string) => {
  if (!val) return true;
  const lower = val.toLowerCase();
  return (
    lower.includes("placeholder") ||
    lower.includes("your-") ||
    lower.includes("actual-supabase-anon-key")
  );
};

// Log prominent developer warnings on the client-side instead of throwing hard errors that crash the React render tree!
if (typeof window !== "undefined") {
  if (!supabaseUrl || isPlaceholder(supabaseUrl)) {
    console.error(
      "❌ [EWS Warning] NEXT_PUBLIC_SUPABASE_URL is missing or contains placeholder values. Please configure it in frontend/.env.local to enable real-time alert sirens and sensor online/offline status updates."
    );
  }

  if (!supabaseAnonKey || isPlaceholder(supabaseAnonKey)) {
    console.error(
      "❌ [EWS Warning] NEXT_PUBLIC_SUPABASE_ANON_KEY is missing or contains placeholder values. Please configure it in frontend/.env.local to enable real-time alert sirens and sensor online/offline status updates."
    );
  }
}

// We pass fallback strings if real credentials are missing to prevent NextJS client crashing,
// allowing the rest of the dashboard (SSE stream, charts, 3s polling) to work perfectly.
export const supabase = createClient(
  supabaseUrl && !isPlaceholder(supabaseUrl) ? supabaseUrl : "https://placeholder-project.supabase.co",
  supabaseAnonKey && !isPlaceholder(supabaseAnonKey) ? supabaseAnonKey : "placeholder-anon-key",
  {
    auth: {
      persistSession: false, // Client-side listeners don't require session persistence
    },
  }
);
