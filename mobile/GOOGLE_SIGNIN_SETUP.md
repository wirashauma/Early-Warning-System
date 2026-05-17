# Google Sign-In Setup Guide untuk Mobile EWS App

## Persiapan

Implementasi Google Sign-In di mobile app sudah lengkap. Sekarang Anda perlu:

### 1. **Setup Firebase Console**

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project EWS Anda (atau buat baru jika belum ada)
3. Go to **Project Settings** → **Service Accounts**

### 2. **Android Setup**

#### Step 1: Generate google-services.json

1. Di Firebase Console, pilih **Android** dalam **Your apps**
2. Atau tambah Android app jika belum ada:
   - **Android Package Name**: `com.ews.mobile`
   - **App nickname**: `EWS Mobile`
   - **Debug signing certificate SHA-1**: Dapatkan dengan menjalankan:
     ```bash
     cd mobile/android
     ./gradlew signingReport
     ```
   - Cari `SHA1` di output

3. Download `google-services.json`
4. Letakkan di: `mobile/android/app/google-services.json`

#### Step 2: Configure Build

File sudah di-update:
- `mobile/android/build.gradle.kts` - ditambah Google Services plugin
- `mobile/android/app/build.gradle.kts` - ditambah `com.google.gms.google-services`

### 3. **iOS Setup**

#### Step 1: Generate GoogleService-Info.plist

1. Di Firebase Console, pilih **iOS** dalam **Your apps**
2. Atau tambah iOS app jika belum ada:
   - **iOS Bundle ID**: `com.ews.mobile`
   - **App Store ID**: Biarkan kosong
   - **Team ID**: Jika punya Apple Developer account

3. Download `GoogleService-Info.plist`
4. Buka Xcode:
   ```bash
   cd mobile/ios
   open Runner.xcworkspace
   ```
5. Di Xcode, right-click **Runner** → **Add Files to "Runner"**
6. Select `GoogleService-Info.plist` yang sudah didownload
7. Pastikan **Copy items if needed** dicheck
8. Pastikan file ditambah ke target **Runner**

#### Step 2: Update Flutter Firebase Options

Edit `mobile/lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',        // dari google-services.json
  appId: 'YOUR_ANDROID_APP_ID',         // dari google-services.json
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // dari google-services.json
  projectId: 'YOUR_PROJECT_ID',         // dari google-services.json
  storageBucket: 'YOUR_STORAGE_BUCKET', // dari google-services.json
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',            // dari GoogleService-Info.plist
  appId: 'YOUR_IOS_APP_ID',              // dari GoogleService-Info.plist
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // dari GoogleService-Info.plist
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  iosBundleId: 'com.ews.mobile',
);
```

### 4. **Backend Configuration (Sudah Setup)**

✅ Backend sudah punya:
- `POST /auth/google-login` endpoint di `backend/src/auth/auth.controller.ts`
- Firebase Admin SDK verification di `backend/src/auth/auth.service.ts`
- Environment variable `FIREBASE_SERVICE_ACCOUNT_KEY` atau Firebase credentials

### 5. **Frontend Web Configuration (Sudah Setup)**

✅ Web sudah punya:
- Firebase initialization di `frontend/src/lib/firebase.ts`
- Google login di `frontend/src/hooks/useAuth.ts`
- Backend integration untuk idToken verification

## Mobile Implementation (Completed ✅)

### Files Created/Updated:

1. **`mobile/lib/models/auth_service.dart`** ✅
   - Added `loginWithGoogle()` method
   - Integrated with `GoogleSignIn` package
   - Sends idToken to backend `/auth/google-login`
   - Stores JWT tokens from backend

2. **`mobile/lib/models/auth_provider.dart`** ✅
   - Added `loginWithGoogle()` wrapper method
   - State management for Google login

3. **`mobile/lib/screens/login.dart`** ✅
   - Added Google Sign-In button
   - Added `_handleGoogleLogin()` method
   - Divider sebelum Google button

4. **`mobile/lib/screens/register_screen.dart`** ✅
   - Added Google Sign-In option untuk register
   - Added `_handleGoogleRegister()` method

5. **`mobile/lib/widgets/auth_widgets.dart`** ✅
   - Added `GoogleSignInButton` widget

6. **`mobile/lib/main.dart`** ✅
   - Added Firebase initialization
   - Added `firebase_options.dart` import

7. **`mobile/pubspec.yaml`** ✅
   - Added `google_sign_in: ^6.2.0` dependency

8. **`mobile/lib/firebase_options.dart`** ✅
   - Created Firebase configuration template

9. **`mobile/android/build.gradle.kts`** ✅
   - Added `com.google.gms.google-services` plugin

10. **`mobile/android/app/build.gradle.kts`** ✅
    - Added `com.google.gms.google-services` plugin

## Testing

### Unit Testing Checklist:

- [ ] User tap "Masuk dengan Google" button
- [ ] Google Sign-In popup muncul
- [ ] User memilih akun Google
- [ ] App mendapatkan idToken dari Firebase
- [ ] idToken dikirim ke backend `/auth/google-login`
- [ ] Backend verify dan create/get user
- [ ] Access token & refresh token disimpan
- [ ] User redirect ke dashboard
- [ ] Dashboard tampil data user dengan benar

### For Registration:

- [ ] User tap "Masuk dengan Google" di register screen
- [ ] Same flow as login
- [ ] User otomatis register + login sekaligus

## Integration dengan Web

### Web Flow:
1. User click "Login dengan Google" di web
2. Firebase `signInWithPopup()` → get idToken
3. Send idToken ke backend
4. Backend verify & return tokens
5. Frontend store tokens in localStorage

### Mobile Flow (Sekarang sama):
1. User click "Masuk dengan Google" di mobile
2. `GoogleSignIn.signIn()` → get idToken  
3. Send idToken ke backend (sama endpoint `/auth/google-login`)
4. Backend verify & return tokens
5. Mobile store tokens in `ApiService`

### Backend (Already supports both):
- Same endpoint `/auth/google-login`
- Verify Firebase idToken dari mana pun (web/mobile)
- Return same token structure ke web & mobile

## Environment Variables

Pastikan backend punya:
```env
# backend/.env
FIREBASE_SERVICE_ACCOUNT_KEY=<base64 encoded JSON>
# atau
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=xxx
FIREBASE_PRIVATE_KEY=xxx
FIREBASE_CLIENT_EMAIL=xxx
```

## Next Steps

1. ✅ Get `google-services.json` dari Firebase Console
2. ✅ Get `GoogleService-Info.plist` dari Firebase Console
3. ✅ Update `mobile/lib/firebase_options.dart` dengan credentials
4. ✅ Run `flutter pub get` untuk install dependencies
5. ✅ Test di Android emulator atau iOS simulator
6. ✅ Test di physical device setelah configure signing certificate

## Troubleshooting

### Error: "Configuration Error"
- Pastikan `google-services.json` sudah ada di `mobile/android/app/`
- Pastikan `GoogleService-Info.plist` sudah di Xcode

### Error: "Network Error" saat Google login
- Check internet connection
- Check backend running di `http://10.0.2.2:3001/api` (Android emulator)
- For iOS, use `http://localhost:3001/api` jika run di simulator

### Error: "Invalid idToken"
- Check Firebase project ID di mobile dan backend sama
- Check backend punya Firebase credentials terverifikasi

## Documentation

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Auth Integration](https://pub.dev/packages/firebase_auth)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
