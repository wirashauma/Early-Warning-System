export type UserRole = "admin" | "operator";

export interface AppUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
}
