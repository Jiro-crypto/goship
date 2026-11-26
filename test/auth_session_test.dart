import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goship/data/repositories/auth_repository.dart';

/// User giả: reload() trả về thành công hoặc ném lỗi tuỳ kịch bản.
class _FakeUser implements User {
  _FakeUser({this.reloadError, this.reloadDelay});

  final Object? reloadError;
  final Duration? reloadDelay;
  int reloadCalls = 0;

  @override
  Future<void> reload() async {
    reloadCalls++;
    if (reloadDelay != null) await Future<void>.delayed(reloadDelay!);
    if (reloadError != null) throw reloadError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// FirebaseAuth giả: chỉ cài các hàm mà verifyCurrentUser dùng tới.
class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this._user);

  User? _user;
  int signOutCalls = 0;

  @override
  User? get currentUser => _user;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FirebaseAuthException _authError(String code) => FirebaseAuthException(code: code);

void main() {
  group('AuthRepository.verifyCurrentUser', () {
    test('chưa đăng nhập -> signedOut, không gọi signOut', () async {
      final auth = _FakeAuth(null);
      final status = await AuthRepository(auth: auth).verifyCurrentUser();

      expect(status, SessionStatus.signedOut);
      expect(auth.signOutCalls, 0);
    });

    test('tài khoản còn hoạt động -> valid, giữ phiên', () async {
      final user = _FakeUser();
      final auth = _FakeAuth(user);
      final status = await AuthRepository(auth: auth).verifyCurrentUser();

      expect(status, SessionStatus.valid);
      expect(user.reloadCalls, 1);
      expect(auth.signOutCalls, 0);
      expect(auth.currentUser, isNotNull);
    });

    for (final code in ['user-disabled', 'user-not-found', 'user-token-expired', 'invalid-user-token']) {
      test('máy chủ báo "$code" (Disable/Delete trên Console) -> invalid và tự đăng xuất', () async {
        final auth = _FakeAuth(_FakeUser(reloadError: _authError(code)));
        final status = await AuthRepository(auth: auth).verifyCurrentUser();

        expect(status, SessionStatus.invalid);
        expect(auth.signOutCalls, 1);
        expect(auth.currentUser, isNull);
      });
    }

    test('mất mạng -> unverified, KHÔNG đăng xuất', () async {
      final auth = _FakeAuth(_FakeUser(reloadError: _authError('network-request-failed')));
      final status = await AuthRepository(auth: auth).verifyCurrentUser();

      expect(status, SessionStatus.unverified);
      expect(auth.signOutCalls, 0);
      expect(auth.currentUser, isNotNull);
    });

    test('lỗi không xác định -> unverified, KHÔNG đăng xuất', () async {
      final auth = _FakeAuth(_FakeUser(reloadError: Exception('boom')));
      final status = await AuthRepository(auth: auth).verifyCurrentUser();

      expect(status, SessionStatus.unverified);
      expect(auth.signOutCalls, 0);
    });

    test('máy chủ phản hồi quá 8 giây -> unverified, không treo màn hình', () async {
      final auth = _FakeAuth(_FakeUser(reloadDelay: const Duration(seconds: 30)));
      final status = await AuthRepository(auth: auth).verifyCurrentUser();

      expect(status, SessionStatus.unverified);
      expect(auth.signOutCalls, 0);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
