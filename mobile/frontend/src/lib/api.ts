import axios from "axios";
import { API_URL } from "@/constants";

export const api = axios.create({
  baseURL: API_URL,
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
