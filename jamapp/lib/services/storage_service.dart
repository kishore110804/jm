import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';


// Manages file storage operations including profile image uploads and secure file management
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String filePath, String userId) async {
    // Create a reference to the location where image will be stored
    final Reference ref = _storage.ref().child('profile_images').child(userId);

    // Upload the file
    final UploadTask uploadTask = ref.putFile(File(filePath));

    // Wait until the file is uploaded and get download URL
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      // List all files with the user's ID prefix
      final ListResult result =
          await _storage.ref().child('profile_images').listAll();

      // Find and delete matching files
      for (var item in result.items) {
        if (item.name.startsWith(userId)) {
          await item.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting profile image: $e');
      }
      // Don't throw - this is a cleanup operation that shouldn't break the flow
    }
  }
}
