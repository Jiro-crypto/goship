// ============================================================
// Dịch vụ quản lý số lần từ chối đơn hàng của Shipper (BR_cancelByShipper_02)
// Giới hạn tối đa 3 lần từ chối / 1 ngày, tự động reset khi sang ngày mới
// ============================================================
import 'package:shared_preferences/shared_preferences.dart';

class RejectCounterService {
  static const String _keyDate = 'reject_date';
  static const String _keyCount = 'reject_count';

  /// Kiểm tra xem Shipper có còn lượt từ chối đơn trong ngày hôm nay hay không (Tối đa 3 lần/ngày)
  static Future<bool> canReject() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().substring(0, 10); // Lấy chuỗi định dạng YYYY-MM-DD
    final String? savedDate = prefs.getString(_keyDate);
    final int count = prefs.getInt(_keyCount) ?? 0;

    // Nếu chưa lưu ngày hoặc đã bước sang ngày mới -> Tự động reset bộ đếm về 0
    if (savedDate == null || savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
      return true; // Được phép từ chối (lượt 1)
    }

    // Nếu cùng ngày, kiểm tra số lần đã từ chối có nhỏ hơn 3 hay không
    return count < 3;
  }

  /// Tăng số lần từ chối đơn lên 1 (gọi sau khi Shipper gửi lý do từ chối thành công)
  static Future<void> incrementRejectCount() async {
    final prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_keyCount) ?? 0;
    await prefs.setInt(_keyCount, current + 1);
  }

  /// Lấy số lần từ chối đã thực hiện trong ngày hôm nay (dùng để hiển thị lên UI)
  static Future<int> getTodayRejectCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String? savedDate = prefs.getString(_keyDate);

    if (savedDate != today) {
      return 0;
    }
    return prefs.getInt(_keyCount) ?? 0;
  }
}
