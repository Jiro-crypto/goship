import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadEvidence(String orderId, File imageFile) async {
    try {
      String fileName = 'evidence/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Upload error: $e");
      rethrow;
    }
  }
}