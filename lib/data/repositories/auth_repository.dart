import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  // Cho phép truyền FirebaseAuth giả vào khi viết test; mặc định dùng instance thật.
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

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
    // Bước 1: Tạo tài khoản trên Firebase Authentication
    User? user;
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCred.user;
    } on FirebaseAuthException catch (e) {
      print('Register auth error code: ${e.code} | ${e.message}');
      return false;
    } catch (e) {
      // WORKAROUND: Lỗi Pigeon của firebase_auth (xem hàm login) có thể xảy ra
      // dù tài khoản đã được tạo THÀNH CÔNG. Kiểm tra currentUser để xác nhận.
      user = _auth.currentUser;
      if (user == null) {
        print('Register unknown error: $e');
        return false;
      }
      print('Register succeeded despite Pigeon serialization error (known flutter firebase_auth bug): $e');
    }

    if (user == null) {
      print('Register error: user is null after createUserWithEmailAndPassword');
      return false;
    }

    // Bước 2: Lưu thông tin khách hàng vào Firestore
    final String uid = user.uid;
    try {
      await _firestore.collection('customers').doc(uid).set({
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'address': '',
        'avatar': '',
        'gender': '',
        'city': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      // Ví dụ: permission-denied khi Firestore Security Rules không cho phép ghi
      print('Register Firestore error code: ${e.code} | ${e.message}');
      return false;
    } catch (e) {
      print('Register Firestore unknown error: $e');
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

  /// Các mã lỗi cho biết tài khoản / phiên đăng nhập không còn hợp lệ trên máy chủ.
  static const Set<String> _invalidSessionCodes = {
    'user-not-found', // Tài khoản đã bị xoá trên Firebase Console
    'user-disabled', // Tài khoản đã bị vô hiệu hoá (Disable)
    'user-token-expired', // Token bị thu hồi (vd: đổi mật khẩu ở nơi khác)
    'invalid-user-token',
    'user-mismatch',
  };

  /// Hỏi lại máy chủ Firebase xem phiên đăng nhập hiện tại còn hợp lệ không.
  ///
  /// Firebase Auth lưu phiên trên máy và token có hạn tới 1 giờ, nên khi tài khoản
  /// bị Disable / Delete trên Console, app sẽ không tự biết. Hàm này gọi
  /// `reload()` để buộc kiểm tra với máy chủ; nếu tài khoản không còn hợp lệ thì
  /// đăng xuất luôn (authStateChanges sẽ phát `null`).
  ///
  /// Lỗi mạng (offline) không bị coi là phiên hết hạn, để người dùng vẫn xem
  /// được dữ liệu đã cache khi mất kết nối.
  Future<SessionStatus> verifyCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return SessionStatus.signedOut;

    try {
      // Giới hạn thời gian chờ để không treo màn hình khi mạng chập chờn.
      await user.reload().timeout(const Duration(seconds: 8));
      return _auth.currentUser == null ? SessionStatus.invalid : SessionStatus.valid;
    } on FirebaseAuthException catch (e) {
      if (_invalidSessionCodes.contains(e.code)) {
        await _auth.signOut();
        return SessionStatus.invalid;
      }
      // network-request-failed, too-many-requests, ... -> giữ phiên hiện tại.
      return SessionStatus.unverified;
    } catch (_) {
      return SessionStatus.unverified;
    }
  }
}


/// Kết quả kiểm tra phiên đăng nhập với máy chủ.
enum SessionStatus {
  /// Tài khoản còn hoạt động.
  valid,

  /// Tài khoản đã bị xoá / vô hiệu hoá / token bị thu hồi -> đã tự đăng xuất.
  invalid,

  /// Chưa đăng nhập từ trước.
  signedOut,

  /// Không kiểm tra được (thường do mất mạng) -> tạm giữ phiên hiện tại.
  unverified,
}
