# Firebase Storage Security Rules Configuration

## Important Setup for Image Upload Feature

The image upload functionality requires proper Firebase Storage security rules. Please configure your Firebase Storage rules in the Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Storage → Rules
4. Update the rules as follows:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read access to all files (for displaying images in quiz)
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Allow write access to quiz images only for authenticated users
    match /quiz_images/{imageId} {
      allow write: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

## Alternative Rules (More Restrictive)

If you want more security, you can use these rules that only allow file operations for the user who uploaded the file:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read access to all files
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Only allow users to upload/delete their own files
    match /quiz_images/{userId}/{imageId} {
      allow write, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Note: If using the second option, you'll need to modify the `ImageUploadService` to include the user ID in the path.

## Features Enabled

With these rules configured, your app will support:
- ✅ Device image upload (camera/gallery)
- ✅ Image URL input
- ✅ Cloud storage for cross-device sync
- ✅ Responsive image sizing
- ✅ Proper error handling and loading states