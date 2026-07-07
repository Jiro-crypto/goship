import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class PreferenceService {
  //=============================
  // KEY
  //=============================
  static const String loginKey = "isLogin";
  static bool isSessionLogin = false;
  static const String userKey = "user";
  static const String historyKey = "history";

  //=============================
  // SAVE USER
  //=============================
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
    print("===== SAVE USER =====");
    print("Name     : ${user.fullName}");
    print("Email    : ${user.email}");
    print("Password : ${user.password}");
    print("=====================");
  }

  //=============================
  // GET USER
  //=============================
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString(userKey);
    if (json == null) {
      return null;
    }
    UserModel user = UserModel.fromJson(jsonDecode(json));
    print("===== LOAD USER =====");
    print("Name     : ${user.fullName}");
    print("Email    : ${user.email}");
    print("=====================");
    return user;
  }

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
  // PROFILE
  //=============================
  static Future<Map<String, String>> getProfile() async {
    UserModel? user = await getUser();
    if (user == null) {
      return {};
    }
    return {
      "fullName": user.fullName,
      "email": user.email,
      "phone": user.phone,
      "avatar": user.avatar,
      "gender": user.gender,
      "city": user.city,
    };
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
  // HAS USER
  //=============================
  static Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userKey);
  }

  //=============================
  // CLEAR HISTORY
  //=============================
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(historyKey);
  }

  //=============================
  // UPDATE USER
  //=============================
  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }
}
