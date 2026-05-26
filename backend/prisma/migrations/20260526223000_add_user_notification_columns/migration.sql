-- Add missing user notification preference columns used by backend auth/notifications services
ALTER TABLE "users"
ADD COLUMN IF NOT EXISTS "notification_flood" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS "notification_status" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS "notification_email" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS "notification_read_at" TIMESTAMP(3);
