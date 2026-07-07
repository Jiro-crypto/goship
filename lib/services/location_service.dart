import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Kiểm tra và yêu cầu cấp quyền vị trí
  static Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem định vị thiết bị có đang mở hay không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Kiểm tra quyền truy cập vị trí của ứng dụng
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Lấy vị trí hiện tại của Shipper
  static Future<Position?> getCurrentLocation() async {
    bool hasPermission = await handlePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print("Error getting current location: $e");
      // Trả về vị trí cuối cùng được biết nếu gặp lỗi timeout hoặc lỗi khác
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Lắng nghe thay đổi vị trí theo thời gian thực khi Shipper di chuyển
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Cập nhật khi di chuyển từ 5 mét trở lên
      ),
    );
  }
}
