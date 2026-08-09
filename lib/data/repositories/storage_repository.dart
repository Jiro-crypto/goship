import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload ảnh minh chứng
  Future<String> uploadEvidenceImage({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'evidence/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload evidence error: $e');
      rethrow;
    }
  }

  // Upload ảnh cuộc gọi khi giao thất bại
  Future<String> uploadCallScreenshot({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'call_screenshots/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload call screenshot error: $e');
      rethrow;
    }
  }

  // Xóa ảnh (nếu cần)
  Future<void> deleteImage(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Delete image error: $e');
    }
  }
}