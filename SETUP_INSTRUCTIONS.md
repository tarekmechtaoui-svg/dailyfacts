# OneSignal Push Notifications Setup

## Problem
OneSignal shows `"enabled": false, "status": "NO_PERMISSION"` even after granting notification permission because Firebase Cloud Messaging (FCM) is not properly configured.

## Solution

### Step 1: Configure Firebase

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `dailyfacts-f40be`
3. **Add Android App** (if not already added):
   - Click the Android icon or "Add app"
   - Enter package name: `com.dailyfacts.app`
   - Download `google-services.json`

4. **Place google-services.json**:
   ```
   android/app/google-services.json
   ```

### Step 2: Enable Firebase Cloud Messaging (FCM)

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging**
2. Under **Cloud Messaging API (Legacy)**, ensure it's enabled
3. Copy the **Server Key** (you'll need this for OneSignal)

### Step 3: Configure OneSignal Dashboard

1. Go to your OneSignal dashboard: https://app.onesignal.com/
2. Select your app
3. Go to **Settings** → **Platforms** → **Google Android (FCM)**
4. Paste your Firebase **Server Key**
5. Save changes

### Step 4: Verify Configuration

After completing the above steps:

1. Clean and rebuild your app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Check logs for:
   ```
   "type":"AndroidPush","enabled":true,"token":"<FCM_TOKEN>","status":"SUBSCRIBED"
   ```

3. Your Player ID should now be a valid UUID (not `local-xxxx`)

### Step 5: Test Notifications

1. In OneSignal dashboard, go to **Messages** → **New Push**
2. Send a test notification
3. It should arrive on your device

## Key Points

- **google-services.json is mandatory** for OneSignal to work on Android
- Without FCM configuration, OneSignal cannot obtain a push token
- The `firebase_core` dependency alone is not enough - you need the actual Firebase project configuration
- Make sure Cloud Messaging API is enabled in Firebase Console

## Troubleshooting

If notifications still don't work:

1. **Check package name matches** in:
   - `android/app/build.gradle` (`applicationId`)
   - Firebase Console
   - `google-services.json`

2. **Verify Firebase Server Key** is correctly entered in OneSignal dashboard

3. **Check Android permissions** in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

4. **Enable verbose logging** in your app and check for FCM registration errors

5. **Ensure you're testing on a real device** with Google Play Services (not an emulator without Play Services)
