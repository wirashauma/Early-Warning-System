export interface ApiResponse<T> {
  status: 'success' | 'error';
  message: string;
  data?: T;
  meta?: any;
}

/**
 * Standard success response wrapper
 */
export function ok<T>(data: T, message = 'Operation successful'): ApiResponse<T> {
  return {
    status: 'success',
    message,
    data,
  };
}

/**
 * Standard error response wrapper (for manual usage if needed)
 */
export function error(message: string, data?: any): ApiResponse<null> {
  return {
    status: 'error',
    message,
    data,
  };
}
