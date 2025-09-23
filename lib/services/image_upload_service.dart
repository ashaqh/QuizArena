import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  /// Pick an image from gallery or camera
  static Future<XFile?> pickImageFromDevice({
    ImageSource source = ImageSource.gallery,
  }) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to Firebase Storage and return download URL
  static Future<String> uploadImageToFirebase(XFile imageFile) async {
    try {
      // Check if user is authenticated
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to upload images');
      }

      print('Uploading image for user: ${currentUser.uid}');

      final String fileName = '${_uuid.v4()}.jpg';
      final String filePath = 'quiz_images/$fileName';

      final Reference ref = _storage.ref().child(filePath);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Upload error details: $e');
      print('Error type: ${e.runtimeType}');

      if (e.toString().contains('unauthorized') ||
          e.toString().contains('permission')) {
        throw Exception(
          'Upload failed: Please check Firebase Storage security rules. User may not have upload permissions.',
        );
      }

      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage
  static Future<void> deleteImageFromFirebase(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log error but don't throw - deletion is not critical
      print('Failed to delete image: $e');
    }
  }
}
