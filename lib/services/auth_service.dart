import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập
  static Future<bool> login(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Lưu trạng thái đăng nhập (có thể dùng SharedPreferences)
      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // Đăng ký (khách hàng)
  static Future<bool> registerCustomer(String email, String password, String name, String phone) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      String uid = userCred.user!.uid;
      
      // Lưu thông tin vào Firestore
      await _firestore.collection('customers').doc(uid).set({
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  // Đăng xuất
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Kiểm tra đăng nhập
  static Future<bool> isLogin() async {
    return _auth.currentUser != null;
  }

  // Lấy user hiện tại
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Lấy UID
  static String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }
}