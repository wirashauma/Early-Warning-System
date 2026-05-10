# Google Maps API - Troubleshooting Guide

## Error: `ApiTargetBlockedMapError`

This error occurs when the Google Maps API key is restricted and those restrictions are blocking your current request.

### Root Causes

1. **API Key Restrictions to Specific Domains**
   - Your production API key is restricted to specific domains (e.g., `yourdomain.com`)
   - Localhost is NOT included in the allowed list
   - Development requests from `localhost:3000` are blocked

2. **API Key Restrictions to HTTP Referrers**
   - Key is locked to specific HTTP referrers
   - `http://localhost:*` is not in the allowed list

3. **Mismatched API Key**
   - Wrong API key format or expired key
   - Key doesn't have proper permissions

---

## Solutions (Try These In Order)

### Solution 1: Unrestrict API Key (Fastest for Development)

⚠️ **WARNING:** Only do this for a development key, not your production key!

**Steps:**

1. Open Google Cloud Console: https://console.cloud.google.com/
2. Select your project: **EWS Application**
3. Go to **APIs & Services** → **Credentials**
4. Find and click your API key: `AIzaSyCwkMl4CNnsxhUPRfIxgcRw1KnRxeHp660`
5. Under "Key restrictions":
   - **Application restrictions**: Change from "HTTP referrers" to **None**
   - **API restrictions**: Keep as **"Restrict key"** with Maps APIs selected
6. Click **Save**
7. **Wait 5-15 minutes** for changes to propagate
8. Restart your dev server:
   ```bash
   cd frontend
   npm run dev
   ```

---

### Solution 2: Add localhost to API Key Referrers

If you want to keep restrictions but add development:

1. Google Cloud Console → **APIs & Services** → **Credentials**
2. Click your API key
3. Under "Key restrictions" → **HTTP referrers (web sites)**
4. Add these patterns:
   ```
   http://localhost:*
   http://127.0.0.1:*
   http://localhost:3000/*
   ```
5. Keep your production domain as well:
   ```
   https://yourdomain.com/*
   ```
6. Click **Save**
7. Restart dev server

---

### Solution 3: Use Separate Development API Key

This is the **RECOMMENDED** approach for development:

**Create a new development-only key:**

1. Google Cloud Console → **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **API Key**
3. Copy the new key
4. In your `frontend` folder, create `.env.local`:
   ```bash
   NEXT_PUBLIC_GOOGLE_MAPS_API_KEY="your_new_dev_key_here"
   ```
5. Restart dev server: `npm run dev`

**Note:** 
- `.env.local` overrides `.env` values
- `.env.local` is in `.gitignore`, won't be committed
- Production still uses the `.env` key

---

## Verification Steps

After making changes, verify the setup:

### 1. Check Console Logs
```bash
# Start dev server
cd frontend
npm run dev
```

Open `http://localhost:3000/user/map` or `/admin/dashboard` and check **Console** (F12):
- Look for: `[PublicGoogleSensorMap] API Key loaded: ✓ Present`
- If you see `✗ Missing` → Check `.env` or `.env.local`

### 2. Verify Current Host
In browser console, verify your origin:
```javascript
console.log(window.location.origin); // Should show http://localhost:3000
```

### 3. Test with Simple Map
Create a minimal test file to isolate the issue:

**`frontend/src/test-maps.html`** (temporary):
```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
</head>
<body>
  <div id="map" style="width: 400px; height: 300px;"></div>
  <script>
    const map = new google.maps.Map(document.getElementById('map'), {
      center: { lat: -0.95, lng: 100.37 },
      zoom: 12,
    });
    console.log("Map loaded successfully!");
  </script>
</body>
</html>
```

---

## API Key Permissions Checklist

Go to **APIs & Services** → **APIs & Credentials** → Select your key:

- ✅ **Maps JavaScript API** - REQUIRED
- ✅ **Maps Static API** - Recommended (for placeholders)
- ✅ **Geocoding API** - Optional (for address lookup)

---

## Common Mistakes

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Using production key with localhost restrictions | Create separate dev key or unrestrict for localhost |
| `NEXT_PUBLIC_` prefix missing | Must have `NEXT_PUBLIC_` prefix for client-side access |
| API key typo in `.env` | Double-check key matches exactly |
| Forgot to restart dev server | Always restart after `.env` changes |
| Using wrong Google Cloud project | Verify you're in **EWS Application** project |

---

## Contact Information

If you still get errors after trying these solutions:

1. **Check error message** in browser console carefully
2. **Note the exact error code**
3. **Verify** your current host matches restrictions
4. **Try Solution 2** (add localhost to referrers)
5. **As last resort**, use Solution 3 (separate dev key)

---

## Resources

- 📖 Google Maps Error Reference: https://developers.google.com/maps/documentation/javascript/error-messages
- 🔑 API Key Restrictions: https://cloud.google.com/docs/authentication/api-keys
- 🗺️ Maps JavaScript API Docs: https://developers.google.com/maps/documentation/javascript
