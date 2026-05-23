import axios, { AxiosError } from "axios";
import { API_URL } from "@/constants";

const ACCESS_TOKEN_KEY = "ews_access_token";
const REFRESH_TOKEN_KEY = "ews_refresh_token";
const AUTH_USER_KEY = "ews_user_data";
const SERVER_API_URL = "http://127.0.0.1:4101/api";

const baseURL = typeof window !== "undefined" ? API_URL : SERVER_API_URL;

export const api = axios.create({
  baseURL,
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
    const originalRequest = error.config;
    
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

    // Map Backend Errors to Human Readable Messages
    const backendMessage = (error.response?.data as any)?.message;
    const errorMessage = Array.isArray(backendMessage) 
      ? backendMessage[0] 
      : backendMessage || error.message || "Terjadi kesalahan sistem.";

    return Promise.reject(new Error(errorMessage));
  }
);

export default api;