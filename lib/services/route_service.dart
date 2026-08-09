// ============================================================
// Dịch vụ lấy thông tin tuyến đường chung cho cả Khách hàng & Shipper (OSRM API)
// Cung cấp tọa độ điểm đi, ETA thời gian di chuyển và tổng quãng đường thực tế
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Class chứa toàn bộ thông tin tuyến đường từ OSRM API
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isSuccess;

  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isSuccess,
  });

  int get durationMinutes => (durationSeconds / 60).ceil();
  double get distanceKm => distanceMeters / 1000;
}

class RouteService {
  /// Lấy thông tin tuyến đường đầy đủ (tọa độ điểm, ETA thực tế, khoảng cách) từ OSRM API
  static Future<RouteInfo> getRouteInfo(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'LogiRoute-App/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords
              .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();

          final double duration = (route['duration'] as num).toDouble();
          final double distance = (route['distance'] as num).toDouble();

          return RouteInfo(
            points: points,
            distanceMeters: distance,
            durationSeconds: duration,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      // Bắt exception mất mạng hoặc quá thời gian kết nối
    }

    // Fallback: Tạo danh sách điểm tọa độ theo đường thẳng nếu mất mạng
    List<LatLng> fallbackPoints = [];
    int steps = 25;
    for (int i = 0; i <= steps; i++) {
      double lat = start.latitude + (end.latitude - start.latitude) * (i / steps);
      double lng = start.longitude + (end.longitude - start.longitude) * (i / steps);
      fallbackPoints.add(LatLng(lat, lng));
    }

    return RouteInfo(
      points: fallbackPoints,
      distanceMeters: 0.0,
      durationSeconds: 0.0,
      isSuccess: false,
    );
  }

  /// Tương thích ngược: Lấy danh sách điểm tọa độ
  static Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final info = await getRouteInfo(start, end);
    return info.points;
  }
}
