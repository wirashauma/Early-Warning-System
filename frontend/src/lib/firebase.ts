import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getMessaging, getToken, isSupported } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

export const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({
  prompt: 'select_account'
});

// Fungsi untuk meminta izin notifikasi dan mengambil FCM Token
export const requestForToken = async () => {
  try {
    // Pastikan kode berjalan di browser dan browser mendukung notifikasi
    if (typeof window !== 'undefined' && await isSupported()) {
      const messaging = getMessaging(app);
      const permission = await Notification.requestPermission();
      
      if (permission === 'granted') {
        const serviceWorkerRegistration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
        const currentToken = await getToken(messaging, {
          // VAPID public key dipakai oleh browser saat meminta token FCM web.
          vapidKey: process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY,
          serviceWorkerRegistration,
        });
        
        if (currentToken) {
          return currentToken;
        } else {
          console.warn('Gagal mendapatkan token FCM. Pastikan VAPID Key benar.');
        }
      } else {
        console.warn('Izin notifikasi ditolak oleh pengguna.');
      }
    }
  } catch (err) {
    console.error('Terjadi kesalahan saat mengambil token FCM: ', err);
  }
  return null;
};

export default app;