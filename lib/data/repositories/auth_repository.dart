import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase login error code: ${e.code} | ${e.message}');
      return false;
    } catch (e) {
      // WORKAROUND: Một số phiên bản firebase_auth Flutter gặp lỗi
      // "type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'"
      // khi parse kết quả trả về từ platform channel, dù xác thực đã THÀNH CÔNG.
      // Ta kiểm tra currentUser: nếu không null nghĩa là đăng nhập đã thành công thực sự.
      if (_auth.currentUser != null) {
        print('Login succeeded despite Pigeon serialization error (known flutter firebase_auth bug): $e');
        return true;
      }
      print('Login unknown error: $e');
      return false;
    }
  }

  // Đăng ký khách hàng
  Future<bool> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCred.user!.uid;

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
      print('Register error: $e');
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Kiểm tra đăng nhập
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Lấy UID hiện tại
  String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }

  // Lấy email hiện tại
  String? getCurrentEmail() {
    return _auth.currentUser?.email;
  }

  // Stream lắng nghe thay đổi trạng thái auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}