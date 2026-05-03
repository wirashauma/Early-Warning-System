export type UserRole = "admin" | "user";

export type BackendUserRole = "ADMIN" | "USER";

export interface AppUser {
  id: string;
  name: string;
  email: string;
  avatar?: string | null;
  institution?: string | null;
  whatsappNumber?: string;
  role: UserRole;
}

export interface BackendAuthUser {
  id: string;
  name: string;
  email: string;
  avatar?: string | null;
  institution?: string | null;
  role: BackendUserRole;
}
