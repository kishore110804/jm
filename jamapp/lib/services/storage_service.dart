import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

// Manages file storage operations including profile image uploads and secure file management
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final ext = path.extension(filePath);
      final ref = _storage.ref().child('profile_images/$userId$ext');

      // Upload the file
      await ref.putFile(file);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      throw Exception('Failed to upload profile image: $e');
    }
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
