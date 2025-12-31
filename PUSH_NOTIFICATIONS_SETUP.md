# 🔔 Push Notifications Setup Guide

## ✅ What Has Been Fixed

### 1. **FCM Token Management** ✓
- FCM tokens are now saved to Firestore when users log in
- Tokens automatically update when they refresh
- Stored in `users/{userId}` collection with field `fcmToken`

### 2. **Notification Service Enhanced** ✓
- All notifications (likes, retweets, replies, follows, messages, mentions) now have `sendPush: true` flag
- Metadata properly structured for Cloud Functions

### 3. **Cloud Functions Created** ✓
- New `functions/` directory with Firebase Cloud Functions
- Automatic push notification sending when notifications are created
- Token validation and error handling

---

## 🚀 Setup Instructions

### Step 1: Install Firebase CLI (if not installed)
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Initialize Firebase (if needed)
```bash
cd D:\apps\twitter_clone_app
firebase init
```
Select:
- ✅ Functions: Configure Cloud Functions
- Use existing project: `android-main-activity`
- Language: JavaScript
- Use ESLint: No (optional)
- Install dependencies: Yes

### Step 4: Install Cloud Function Dependencies
```bash
cd functions
npm install
```

### Step 5: Deploy Cloud Functions
```bash
firebase deploy --only functions
```

This will deploy the `sendPushNotification` function that triggers whenever a new notification is created in Firestore.

---

## 📱 How It Works Now

### When a User Performs an Action:

**Example: User A likes User B's tweet**

1. **Notification Created** → `NotificationService.notifyLike()` creates a document in `notifications` collection
   ```javascript
   {
     to: "userB_uid",
     from: "userA_uid", 
     type: "like",
     title: "New like",
     body: "User A liked your tweet",
     sendPush: true,  // ← Triggers Cloud Function
     meta: {...}
   }
   ```

2. **Cloud Function Triggered** → `sendPushNotification` function executes automatically

3. **Get Recipient's FCM Token** → Reads from `users/userB_uid/fcmToken`

4. **Send Push Notification** → Firebase sends push to User B's device via FCM

5. **In-App Notification** → NotificationController shows snackbar in User B's app

6. **Notification Screen** → User B can view all notifications

---

## 🧪 Testing Push Notifications

### Test 1: Check FCM Token is Saved
1. Run the app: `flutter run`
2. Log in with a user
3. Check Firebase Console → Firestore → `users/{userId}`
4. Verify `fcmToken` field exists

### Test 2: Test with Another User
1. Open app on two devices (or use emulator + physical device)
2. Log in as User A on Device 1
3. Log in as User B on Device 2
4. From Device 1 (User A):
   - Like User B's tweet
   - Retweet User B's tweet
   - Reply to User B's tweet
   - Follow User B
   - Send message to User B
5. Device 2 (User B) should receive push notifications

### Test 3: Background vs Foreground
- **App in Foreground** → Local notification shows
- **App in Background** → System push notification shows
- **Tap Notification** → Opens notification screen

---

## 🔧 Troubleshooting

### No Push Notifications Received?

**1. Check FCM Token Exists**
```
Firebase Console → Firestore → users → {userId} → Check 'fcmToken' field
```

**2. Check Cloud Function is Deployed**
```bash
firebase functions:list
```
Should show: `sendPushNotification`

**3. Check Cloud Function Logs**
```bash
firebase functions:log
```
Look for errors or "Successfully sent push notification" messages

**4. Check Android Permissions**
- Open: `android/app/src/main/AndroidManifest.xml`
- Verify notification permissions are present

**5. Test Token Manually**
Use Firebase Console → Cloud Messaging → Send test message
- Paste FCM token from Firestore
- Send test notification

### Common Issues:

❌ **"No FCM token found for user"**
- User needs to log in again to get token saved
- Check if `FirebaseApi().initNotifications()` is called

❌ **"Push notifications disabled for user"**
- Check Firestore: `users/{userId}/pushNotifications` should be `true` or missing (defaults to true)

❌ **Cloud Function not triggering**
- Verify function is deployed: `firebase deploy --only functions`
- Check Firestore rules allow function to read user documents

---

## 🎯 What Notifications Trigger Push?

| Action | Notification Type | Push Sent |
|--------|------------------|-----------|
| Like Tweet | `like` | ✅ Yes |
| Retweet | `retweet` | ✅ Yes |
| Reply to Tweet | `reply` | ✅ Yes |
| Follow User | `follow` | ✅ Yes |
| Send Message | `message` | ✅ Yes |
| Mention (@username) | `mention` | ✅ Yes |

---

## 📊 Monitor Notifications

### Firebase Console
1. Go to: Cloud Firestore → `notifications` collection
2. Check fields:
   - `sendPush: true` → Push should be sent
   - `pushSent: true` → Push was successfully sent
   - `pushSentAt: timestamp` → When push was sent
   - `pushError: "..."` → If there was an error

### Cloud Function Logs
```bash
firebase functions:log --only sendPushNotification
```

---

## 🔐 Security Notes

### Firestore Security Rules
Ensure your Firestore rules allow:
- Users can read their own `fcmToken`
- Cloud Functions can read user documents
- Users can write notifications for others

Example rule:
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

match /notifications/{notificationId} {
  allow read: if request.auth.uid == resource.data.to;
  allow create: if request.auth != null;
}
```

---

## 🎉 Success Indicators

You'll know push notifications are working when:

1. ✅ FCM token appears in Firestore after login
2. ✅ Cloud Function logs show "Successfully sent push notification"
3. ✅ User receives system notification on their device
4. ✅ Tapping notification opens the notification screen
5. ✅ Notification count badge updates on app icon

---

## 💡 Next Steps

1. **Deploy Cloud Functions:**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

2. **Test the app:**
   ```bash
   flutter run
   ```

3. **Monitor logs:**
   ```bash
   firebase functions:log
   ```

4. **Test notifications with multiple users!**

---

## 📞 Need Help?

- Check Cloud Function logs: `firebase functions:log`
- Verify FCM tokens in Firestore Console
- Test with Firebase Console's Cloud Messaging tool
- Ensure both devices have internet connection
- Make sure app has notification permissions enabled

**Your notification system is now complete! 🚀**
