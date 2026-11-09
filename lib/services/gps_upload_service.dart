// ============================================================
// Dịch vụ gửi tọa độ vị trí GPS của Shipper lên máy chủ định kỳ (UC07)
// Tự động định kỳ gửi GPS mỗi 180 giây khi Shipper đang thực hiện giao hàng
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GpsUploadService {
  static Timer? _uploadTimer;
  static String? _currentOrderId;
  static String? _currentShipperId;

  /// Bắt đầu gửi tín hiệu định vị GPS định kỳ lên hệ thống
  /// Gọi khi Shipper nhấn "BẮT ĐẦU GIAO HÀNG"
  static void startUploading(String orderId, String shipperId) {
    _currentOrderId = orderId;
    _currentShipperId = shipperId;
    
    // Hủy timer cũ nếu đang chạy
    _uploadTimer?.cancel();

    // Gửi ngay tọa độ vị trí đầu tiên
    _sendLocationPayload();

    // Thiết lập gửi định kỳ mỗi 180 giây
    _uploadTimer = Timer.periodic(const Duration(seconds: 180), (timer) {
      _sendLocationPayload();
    });
  }

  /// Dừng gửi vị trí GPS (gọi khi hoàn thành giao hàng, báo giao thất bại hoặc rời màn hình)
  static void stopUploading() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    _currentOrderId = null;
    _currentShipperId = null;
  }

  /// Hàm nội bộ thực hiện lấy vị trí hiện tại và gửi gói tin lên API server
  static Future<void> _sendLocationPayload() async {
    if (_currentOrderId == null || _currentShipperId == null) return;

    try {
      // Lấy vị trí GPS hiện tại của Shipper
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 180),
      );

      // Gửi request API giả lập lên server (Endpoint backend thực tế)
      final url = Uri.parse('https://api.goship.vn/v1/shipper/location');
      
      // Request payload
      final bodyData = jsonEncode({
        'shipperId': _currentShipperId,
        'orderId': _currentOrderId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Tạm thời mô phỏng gửi http post request (bắt catch lỗi nếu chưa có API thật)
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      ).timeout(const Duration(seconds: 3));

    } catch (e) {
      // Nếu không có mạng hoặc lỗi server, bỏ qua âm thầm để không ngắt trải nghiệm người dùng
    }
  }
}
