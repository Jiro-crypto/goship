import '../models/user_model.dart';
import 'preference_service.dart';

class AuthService {
  /// ============================
  /// REGISTER MOCK USER IF NONE EXISTS
  /// ============================
  static Future<void> initMockUser() async {
    bool hasSavedUser = await PreferenceService.hasUser();
    if (!hasSavedUser) {
      UserModel defaultShipper = UserModel(
        fullName: "Shipper Pro",
        email: "shipper@goship.vn",
        phone: "0987654321",
        password: "password",
        avatar: "https://cdn-icons-png.flaticon.com/512/2922/2922506.png",
        gender: "Nam",
        city: "Hà Nội",
      );
      await PreferenceService.saveUser(defaultShipper);
    }
  }

  /// ============================
  /// REGISTER
  /// ============================
  static Future<bool> register(UserModel user) async {
    try {
      await PreferenceService.saveUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ============================
  /// LOGIN
  /// ============================
  static Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await initMockUser();

      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // Check current active user
      UserModel? current = await PreferenceService.getUser();
      if (current != null && current.email.trim().toLowerCase() == cleanEmail && current.password.trim() == cleanPassword) {
        if (rememberMe) await PreferenceService.setLogin(true);
        await PreferenceService.setSessionLogin(true);
        await PreferenceService.addHistory(cleanEmail);
        return true;
      }

      // Check registered users list
      List<UserModel> users = await PreferenceService.getUsersList();
      for (var u in users) {
        if (u.email.trim().toLowerCase() == cleanEmail && u.password.trim() == cleanPassword) {
          await PreferenceService.saveUser(u);
          if (rememberMe) await PreferenceService.setLogin(true);
          await PreferenceService.setSessionLogin(true);
          await PreferenceService.addHistory(cleanEmail);
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// ============================
  /// CURRENT USER
  /// ============================
  static Future<UserModel?> currentUser() async {
    return await PreferenceService.getUser();
  }

  /// ============================
  /// CHECK LOGIN
  /// ============================
  static Future<bool> isLogin() async {
    return await PreferenceService.isLogin();
  }

  /// ============================
  /// LOGOUT
  /// ============================
  static Future<void> logout() async {
    await PreferenceService.clearLogin();
  }

  /// ============================
  /// LOGIN HISTORY
  /// ============================
  static Future<List<String>> getHistory() async {
    return await PreferenceService.getHistory();
  }

  /// ============================
  /// CHECK IF EMAIL EXISTS
  /// ============================
  static Future<bool> isExistEmail(String email) async {
    try {
      await initMockUser();
      final cleanEmail = email.trim().toLowerCase();
      List<UserModel> users = await PreferenceService.getUsersList();
      return users.any((u) => u.email.trim().toLowerCase() == cleanEmail);
    } catch (e) {
      return false;
    }
  }
}
