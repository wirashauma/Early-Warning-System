import { NextResponse } from 'next/server';

export const runtime = 'nodejs';

export function GET() {
  const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  };

  const script = `
    importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
    importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

    firebase.initializeApp(${JSON.stringify(firebaseConfig)});
    const messaging = firebase.messaging();

    const resolveNotificationOptions = (payload) => ({
      body: payload.data?.body || payload.data?.message || payload.notification?.body || 'Cek dashboard untuk detail.',
      icon: '/favicon.ico',
      badge: '/favicon.ico',
      data: {
        url: payload.data?.route || '/user/dashboard',
      },
    });

    // Background FCM messages are handled by the service worker so notifications still appear when the tab is closed.
    messaging.onBackgroundMessage((payload) => {
      console.log('[firebase-messaging-sw.js] Background payload received', payload);

      const notificationTitle = payload.data?.title || payload.notification?.title || 'Peringatan EWS Flood Guard';
      const notificationOptions = resolveNotificationOptions(payload);

      return self.registration.showNotification(notificationTitle, notificationOptions);
    });

    self.addEventListener('notificationclick', (event) => {
      event.notification.close();

      event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
          const targetUrl = event.notification.data?.url || '/user/dashboard';
          const existingClient = windowClients.find((client) => 'focus' in client && 'navigate' in client);

          if (existingClient) {
            return existingClient.navigate(targetUrl).then((client) => client?.focus());
          }

          return clients.openWindow(targetUrl);
        }),
      );
    });
  `;

  return new NextResponse(script, {
    headers: {
      'Content-Type': 'application/javascript; charset=utf-8',
      'Cache-Control': 'no-store, max-age=0',
    },
  });
}
