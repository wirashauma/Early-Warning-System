import * as fs from 'node:fs';
import * as path from 'node:path';
import * as readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import * as admin from 'firebase-admin';

interface FcmMockPayload {
  title: string;
  body: string;
}

function resolveServiceAccountPath() {
  const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  const fallbackPath = path.resolve(process.cwd(), 'config/firebase-service-account.json');

  if (!configuredPath) {
    return fallbackPath;
  }

  return path.isAbsolute(configuredPath)
    ? configuredPath
    : path.resolve(process.cwd(), configuredPath);
}

function initFirebaseAdmin() {
  const serviceAccountPath = resolveServiceAccountPath();

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(
      `Service account file not found: ${serviceAccountPath}. Set FIREBASE_SERVICE_ACCOUNT_PATH or place config/firebase-service-account.json.`,
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccountPath),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
  }
}

async function askForToken() {
  const cli = readline.createInterface({ input, output });

  try {
    const token = await cli.question('Paste the FCM registration token: ');
    return token.trim();
  } finally {
    cli.close();
  }
}

async function main() {
  initFirebaseAdmin();

  const tokenArg = process.argv.slice(2).find((arg) => !arg.startsWith('--'));
  const token = (tokenArg?.trim() || (await askForToken())).trim();

  if (!token) {
    throw new Error('FCM registration token is required.');
  }

  const payload: FcmMockPayload = {
    title: 'Test EWS',
    body: 'Waspada kenaikan debit air di sektor hilir.',
  };

  const message: admin.messaging.Message = {
    token,
    notification: payload,
    data: {
      title: payload.title,
      body: payload.body,
      route: '/user/notifications',
      source: 'cli-test',
    },
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
    const messageId = await admin.messaging().send(message);
    console.log('Push notification sent successfully.');
    console.log(`Message ID: ${messageId}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('Failed to send push notification.');
    console.error(message);
    process.exitCode = 1;
  }
}

void main();
