import 'package:shared_preferences/shared_preferences.dart';

/// PreferenceService - Dịch vụ quản lý SharedPreferences cục bộ.
///
/// SAU KHI MIGRATE SANG FIREBASE:
///   - Quản lý đơn hàng (Orders) → OrderRepository (Firestore)
///   - Quản lý hồ sơ người dùng → CustomerRepository / ShipperRepository (Firestore)
///   - Quản lý xác thực → AuthRepository (Firebase Auth)
///
/// PreferenceService CHỈ CÒN phụ trách:
///   - Trạng thái đăng nhập cục bộ (LoginKey)
///   - Lịch sử thao tác (Login history log)
///   - Bất kỳ cài đặt ứng dụng nào cần lưu offline (theme, language, etc.)
class PreferenceService {
  //=============================
  // KEYS
  //=============================
  static const String loginKey = "isLogin";
  static bool isSessionLogin = false;
  static const String historyKey = "history";

  //=============================
  // LOGIN
  //=============================
  static Future<void> setLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginKey, value);
  }

  //=============================
  // SESSION LOGIN
  //=============================
  static Future<void> setSessionLogin(bool value) async {
    isSessionLogin = value;
  }

  //=============================
  // CHECK LOGIN
  //=============================
  static Future<bool> isLogin() async {
    if (isSessionLogin) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(loginKey) ?? false;
  }

  //=============================
  // CLEAR LOGIN (LOGOUT)
  //=============================
  static Future<void> clearLogin() async {
    isSessionLogin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginKey, false);
  }

  //=============================
  // LOGIN HISTORY
  //=============================
  static Future<void> addHistory(String info) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(historyKey) ?? [];
    history.insert(0, "$info | ${DateTime.now()}");
    await prefs.setStringList(historyKey, history);
  }

  //=============================
  // GET HISTORY
  //=============================
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(historyKey) ?? [];
  }

  //=============================
  // CLEAR HISTORY
  //=============================
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(historyKey);
  }
}
