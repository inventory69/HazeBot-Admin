# 🔔 Firebase Push Notifications Setup

This guide explains how to set up Firebase Cloud Messaging (FCM) for push notifications in the HazeBot Admin app.

## 📋 Overview

The notification system uses:
- **Firebase Cloud Messaging (FCM)** for push notifications
- **Backend:** Python with `firebase-admin` SDK
- **Frontend:** Flutter with `firebase_messaging` and `flutter_local_notifications`
- **Permission Strategy:** Ask on first tickets visit or when enabling notifications

## 🔧 Firebase Console Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select existing project
3. Follow the wizard (Analytics optional)

### 2. Add Android App

1. In Project Overview, click **Android icon** (⚙️)
2. Register app with:
   - **Android package name:** `xyz.hzwd.hazebot.admin`
   - **App nickname:** `HazeBot Admin` (optional)
   - **Debug signing certificate:** Not required for FCM
3. Download **`google-services.json`**
4. Place it in: `HazeBot-Admin/android/app/google-services.json`

⚠️ **Important:** Add to `.gitignore` (already configured)

### 3. Generate Firebase Admin SDK Key

For the **backend** (Python Flask API):

1. Go to **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"**
3. Download the JSON file
4. Rename to `firebase-credentials.json`
5. Place in: `HazeBot/firebase-credentials.json` (project root)

⚠️ **Security:** Never commit this file! It's in `.gitignore`.

### 4. Enable Cloud Messaging API

1. Go to **Project Settings** → **Cloud Messaging**
2. Note the **Server key** (not needed for Admin SDK, but useful for debugging)
3. Ensure **Cloud Messaging API** is enabled

## 📱 Android Configuration

Already configured in the codebase:

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### build.gradle.kts
```kotlin
defaultConfig {
    minSdk = 21  // Required for FCM
}
```

### Google Services Plugin
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## 🔐 Environment Variables (Backend)

No additional ENV variables needed! The backend automatically:
- Looks for `firebase-credentials.json` in project root
- Initializes Firebase Admin SDK on first notification send
- Falls back gracefully if file not found

## 🧪 Testing

### Test Permission Request

1. **First Tickets Visit:**
   - Open app → Navigate to Tickets tab
   - Dialog appears: "📬 Enable Notifications?"
   - Click "Enable" → System permission dialog appears
   - Grant permission

2. **Settings Screen:**
   - Open Profile menu → Notifications
   - Toggle any notification type
   - If permission not granted, system dialog appears

### Test Notification Delivery

1. **Create Test Ticket:**
   ```bash
   # In HazeBot directory
   python start_with_api.py
   ```
   - Create a ticket via Discord or API
   - Admin/Mod should receive "New Ticket" notification

2. **Test Mentions:**
   - Send message with `<@USER_ID>` in ticket
   - Mentioned user receives notification

3. **Background/Foreground:**
   - **Foreground:** Local notification appears at top
   - **Background:** System notification in notification tray
   - **Terminated:** Tap notification → Opens app → Navigates to ticket

### Debug FCM Token

In Notification Settings screen, scroll down to see:
```
🔑 FCM Token: [your-device-token]
```

Copy this and test with Firebase Console:
1. **Cloud Messaging** → **Send test message**
2. Paste FCM token
3. Send notification

## 🛠️ Troubleshooting

### "Permission denied" errors

**Symptom:** Notifications don't appear
**Fix:** Check Android system settings:
- Settings → Apps → HazeBot Admin → Notifications → Enabled

### "FCM token not registered"

**Symptom:** Backend logs show token registration failure
**Fix:**
1. Check `firebase-credentials.json` exists in HazeBot root
2. Restart Flask API: `python start_with_api.py`
3. Re-login in app

### "google-services.json not found" build error

**Symptom:** Android build fails
**Fix:**
1. Download from Firebase Console (see step 2 above)
2. Place in `android/app/google-services.json`
3. Rebuild: `flutter build apk`

### Notifications work in foreground but not background

**Symptom:** Only foreground notifications appear
**Fix:**
1. Check battery optimization settings (disable for app)
2. Ensure app has notification permission
3. Check Android logs: `adb logcat | grep FCM`

## 📚 Notification Types

| Type | Trigger | User | Admin/Mod |
|------|---------|------|-----------|
| `ticket_new_messages` | New message in ticket | Own tickets | All tickets |
| `ticket_mentions` | Mentioned in message | ✅ | ✅ |
| `ticket_created` | New ticket created | ❌ | ✅ |
| `ticket_assigned` | Ticket assigned | ✅ | ✅ |

## 🔄 Permission Flow

```
1. User opens app
   ↓
2. No auto-permission request
   ↓
3a. User opens Tickets → Dialog appears → Request permission
   OR
3b. User enables notification in Settings → Request permission
   ↓
4. Permission granted → FCM token generated
   ↓
5. Token registered with backend → User receives notifications
```

## 📝 File Locations

```
HazeBot/
  firebase-credentials.json          # Backend Firebase Admin SDK key (gitignored)
  Utils/notification_service.py      # Backend notification logic
  Data/notification_tokens.json      # FCM tokens by user_id
  Data/notification_settings.json    # User preferences

HazeBot-Admin/
  android/app/google-services.json   # Android Firebase config (gitignored)
  lib/services/notification_service.dart
  lib/screens/settings/notification_settings_screen.dart
  lib/utils/notification_navigation.dart
```

## 🎯 Next Steps

1. ✅ Add `firebase-credentials.json` to HazeBot root
2. ✅ Add `google-services.json` to android/app/
3. ✅ Build and test on Android device
4. ⬜ Optional: Add iOS support (requires Apple Developer account)

---

## 🔗 Next Steps

- 🔨 [Building Guide](BUILDING.md) - Build for all platforms with Firebase
- 🧪 [Development Guide](DEVELOPMENT.md) - Development workflows
- 🏠 [Documentation Index](README.md) - All documentation

**Related Resources:**
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging) - Official FCM documentation
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging) - Flutter plugin docs
- 🤖 [HazeBot Backend](https://github.com/inventory69/HazeBot) - Backend notification setup

---

## 🆘 Getting Help

- **Firebase Issues:** Check troubleshooting section above
- **Flutter Questions:** [Flutter Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- **Project Questions:** Open an issue on [GitHub](https://github.com/YOUR_USERNAME/HazeBot-Admin/issues)
