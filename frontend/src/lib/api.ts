import axios, { AxiosError } from "axios";
import { API_URL } from "@/constants";

const ACCESS_TOKEN_KEY = "ews_access_token";
const REFRESH_TOKEN_KEY = "ews_refresh_token";
const AUTH_USER_KEY = "ews_user_data";

export const api = axios.create({
  baseURL: API_URL,
  timeout: 15_000,
  headers: {
    "Content-Type": "application/json",
  },
});

// 1. REQUEST INTERCEPTOR: Attach Bearer Token
api.interceptors.request.use(
  (config) => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem(ACCESS_TOKEN_KEY);
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 2. RESPONSE INTERCEPTOR: Global Error Handling & Auth Guard
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    // Handle 401 Unauthorized
    if (error.response?.status === 401) {
      if (typeof window !== "undefined" && !window.location.pathname.includes("/login")) {
        console.warn("Session expired or unauthorized. Redirecting to login...");
        
        // Optional: Attempt Token Refresh logic here if needed
        
        localStorage.removeItem(ACCESS_TOKEN_KEY);
        localStorage.removeItem(REFRESH_TOKEN_KEY);
        localStorage.removeItem(AUTH_USER_KEY);
        
        // Only redirect if not already on public pages
        const isPublicPage = ["/login", "/register", "/", "/emergency"].includes(window.location.pathname);
        if (!isPublicPage) {
          window.location.href = "/login?expired=true";
        }
      }
    }

    const extractBackendMessage = async () => {
      const responseData = error.response?.data as unknown;

      if (typeof Blob !== "undefined" && responseData instanceof Blob) {
        try {
          const text = await responseData.text();

          if (text) {
            try {
              const parsed = JSON.parse(text) as { message?: string | string[] };
              const parsedMessage = parsed?.message;

              if (Array.isArray(parsedMessage)) {
                return parsedMessage[0];
              }

              if (typeof parsedMessage === "string") {
                return parsedMessage;
              }
            } catch {
              return text;
            }
          }
        } catch {
          // fall through to the generic handler below
        }
      }

      const backendMessage = (responseData as any)?.message;
      return Array.isArray(backendMessage) ? backendMessage[0] : backendMessage;
    };

    // Map Backend Errors to Human Readable Messages
    const backendMessage = await extractBackendMessage();
    const errorMessage = Array.isArray(backendMessage) 
      ? backendMessage[0] 
      : backendMessage || error.message || "Terjadi kesalahan sistem.";

    return Promise.reject(new Error(errorMessage));
  }
);

export default api;