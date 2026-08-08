import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../data/mock_orders.dart';

class PreferenceService {
  //=============================
  // KEYS
  //=============================
  static const String loginKey = "isLogin";
  static bool isSessionLogin = false;
  static const String userKey = "user";
  static const String usersListKey = "registered_users_list";
  static const String historyKey = "history";
  static const String ordersKey = "persistent_user_orders";

  static final List<OrderModel> _initialMockOrders = List.from(mockOrders);

  //=============================
  // ORDERS PERSISTENCE
  //=============================
  static Future<List<OrderModel>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? rawList = prefs.getStringList(ordersKey);

    if (rawList == null || rawList.isEmpty) {
      // First time: Save initial mock orders into SharedPreferences
      await saveAllOrders(_initialMockOrders);
      return List<OrderModel>.from(mockOrders);
    }

    try {
      List<OrderModel> savedOrders = [];
      for (var str in rawList) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is Map<String, dynamic>) {
            savedOrders.add(OrderModel.fromJson(decoded));
          }
        } catch (itemErr) {
          // Skip corrupt item safely
        }
      }

      if (savedOrders.isNotEmpty) {
        mockOrders.clear();
        mockOrders.addAll(savedOrders);
      }
      return List<OrderModel>.from(mockOrders);
    } catch (e) {
      return List<OrderModel>.from(mockOrders);
    }
  }

  static Future<void> saveOrder(OrderModel order) async {
    List<OrderModel> orders = await getOrders();
    int existingIndex = orders.indexWhere((o) => o.orderId == order.orderId);
    if (existingIndex >= 0) {
      orders[existingIndex] = order;
    } else {
      orders.insert(0, order);
    }
    await saveAllOrders(orders);
  }

  static Future<void> saveAllOrders(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();

    // Snapshot list before touching mockOrders to prevent aliasing bug
    final ordersCopy = List<OrderModel>.from(orders);

    mockOrders
      ..clear()
      ..addAll(ordersCopy);

    List<String> rawList = ordersCopy.map((o) => jsonEncode(o.toJson())).toList();
    await prefs.setStringList(ordersKey, rawList);
  }

  //=============================
  // SAVE USER
  //=============================
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    // Save current active user
    await prefs.setString(userKey, jsonEncode(user.toJson()));

    // Also save to all registered users list
    List<UserModel> users = await getUsersList();
    users.removeWhere((u) => u.email.trim().toLowerCase() == user.email.trim().toLowerCase());
    users.add(user);

    List<String> rawList = users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(usersListKey, rawList);
  }

  //=============================
  // GET USERS LIST
  //=============================
  static Future<List<UserModel>> getUsersList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? rawList = prefs.getStringList(usersListKey);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    return rawList.map((str) => UserModel.fromJson(jsonDecode(str))).toList();
  }

  //=============================
  // GET CURRENT ACTIVE USER
  //=============================
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString(userKey);
    if (json == null) {
      return null;
    }
    return UserModel.fromJson(jsonDecode(json));
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
    return prefs.containsKey(userKey) || (prefs.getStringList(usersListKey)?.isNotEmpty ?? false);
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
