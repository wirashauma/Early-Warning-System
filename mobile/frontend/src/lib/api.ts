import axios from "axios";
import { API_URL } from "@/constants";

const SERVER_API_URL = "http://127.0.0.1:4101/api";
const baseURL = typeof window !== "undefined" ? API_URL : SERVER_API_URL;

export const api = axios.create({
  baseURL,
  timeout: 10_000,
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const message =
      error?.response?.data?.message ??
      error?.message ??
      "Terjadi kesalahan saat memproses permintaan.";
    return Promise.reject(new Error(message));
  },
);
