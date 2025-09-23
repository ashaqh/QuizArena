# 🔥 Firestore Index Setup Guide

## Required Indexes for QuizArena Dashboard

When you first run the app and try to view the dashboard, you might see Firestore index errors. This is normal and expected! Here's how to fix them:

### 📋 **Step-by-Step Index Creation:**

1. **Run the app** and try to view the Stats tab
2. **Check the debug console** for error messages containing Firestore index URLs
3. **Click the URLs** in the error messages - they will automatically create the indexes
4. **Wait 1-2 minutes** for the indexes to build
5. **Restart the app** and try again

### 🔗 **Common Index URLs:**

If you see errors, the URLs will look like this:
```
https://console.firebase.google.com/v1/r/project/YOUR-PROJECT/firestore/indexes?create_composite=...
```

### 📊 **Required Indexes:**

The dashboard needs these composite indexes:

**1. Game History Query:**
- Collection: `gameHistory`
- Fields: `userId` (Ascending), `playedAt` (Descending)

**2. Game History with Role Filter:**
- Collection: `gameHistory` 
- Fields: `userId` (Ascending), `role` (Ascending), `playedAt` (Descending)

**3. Leaderboards Query:**
- Collection: `leaderboards`
- Fields: `category` (Ascending), `score` (Descending)

### 🛠️ **Manual Index Creation:**

If the automatic URLs don't work, create indexes manually in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database** → **Indexes** → **Composite**
4. Click **Create Index**
5. Set up the indexes as described above

### ⚡ **Temporary Workaround:**

The app includes fallback logic that sorts data in memory when indexes are missing. This works but is less efficient for large datasets.

### 🚀 **Once Indexes are Ready:**

After creating the indexes:
- ✅ Dashboard loads instantly
- ✅ Game history shows properly sorted
- ✅ Filtering by host/player works
- ✅ Pagination works efficiently
- ✅ No more error messages

### 🔧 **Troubleshooting:**

**Q: Index URLs not working?**
A: Copy the URL and try in an incognito browser window

**Q: Still seeing errors?**
A: Wait 5-10 minutes for indexes to fully build

**Q: App crashes on stats tab?**
A: Check that you're signed in - dashboard requires authentication

---

💡 **Pro Tip:** Once you set up indexes for one Firebase project, future deployments of the same app structure will need the same indexes.