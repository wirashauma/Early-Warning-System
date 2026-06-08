import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as fs from 'node:fs';
import * as path from 'node:path';

interface PushMessageInput {
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null | undefined>;
}

interface PushTokenResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private app: admin.app.App | null = null;

  onModuleInit() {
    // Prioritas 1: Gunakan JSON langsung dari environment variable (untuk production/cloud hosting)
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
    if (serviceAccountJson) {
      try {
        const serviceAccount = JSON.parse(serviceAccountJson) as admin.ServiceAccount;
        if (!admin.apps.length) {
          this.app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: process.env.FIREBASE_PROJECT_ID,
          });
        } else {
          this.app = admin.app();
        }
        this.logger.log('Firebase Admin initialized successfully via FIREBASE_SERVICE_ACCOUNT_JSON env var.');
        return;
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(`Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: ${message}`);
        // Lanjut ke fallback (file path)
      }
    }

    // Prioritas 2: Gunakan file path (untuk development lokal)
    const credentialPath = this.resolveServiceAccountPath();

    if (!credentialPath) {
      this.logger.warn(
        'Firebase not initialized because service account path is not configured.',
      );
      return;
    }

    if (!fs.existsSync(credentialPath)) {
      this.logger.warn(
        `Firebase not initialized because service account file is missing at: ${credentialPath}`,
      );
      return;
    }

    try {
      if (!admin.apps.length) {
        this.app = admin.initializeApp({
          credential: admin.credential.cert(credentialPath),
          projectId: process.env.FIREBASE_PROJECT_ID,
        });
      } else {
        this.app = admin.app();
      }

      this.logger.log('Firebase Admin initialized successfully via service account file.');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to initialize Firebase Admin: ${message}`);
      this.app = null;
    }
  }

  isEnabled(): boolean {
    return this.app !== null;
  }

  async sendToTopic(
    topic: string,
    payload: PushMessageInput,
  ): Promise<string | null> {
    if (!this.app) {
      return null;
    }

    const data = Object.fromEntries(
      Object.entries(payload.data ?? {}).map(([key, value]) => [
        key,
        value == null ? '' : String(value),
      ]),
    );

    const message: admin.messaging.Message = {
      topic,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
      },
    };

    return this.app.messaging().send(message);
  }

  async sendToToken(
    token: string,
    payload: PushMessageInput,
  ): Promise<PushTokenResult> {
    if (!this.app) {
      return { success: false, error: 'Firebase Admin is not initialized.' };
    }

    const data = Object.fromEntries(
      Object.entries(payload.data ?? {}).map(([key, value]) => [
        key,
        value == null ? '' : String(value),
      ]),
    );

    const message: admin.messaging.Message = {
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
      },
    };

    try {
      const messageId = await this.app.messaging().send(message);
      return { success: true, messageId };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return { success: false, error: errorMessage };
    }
  }

  async subscribeTokenToTopic(token: string, topic: string) {
    if (!this.app) {
      return null;
    }

    return this.app.messaging().subscribeToTopic([token], topic);
  }

  private resolveServiceAccountPath(): string | null {
    const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
    const fallbackPath = path.resolve(
      process.cwd(),
      'config/firebase-service-account.json',
    );

    if (!configuredPath) {
      return fallbackPath;
    }

    return path.isAbsolute(configuredPath)
      ? configuredPath
      : path.resolve(process.cwd(), configuredPath);
  }
}
