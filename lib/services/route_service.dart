import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  /// Fetches actual street route points between start and end coordinates using OSRM API.
  static Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'LogiRoute-App/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          return coords
              .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        }
      }
    } catch (e) {
      // Ignore and use fallback
    }

    // Interpolated fallback steps along straight line
    List<LatLng> points = [];
    int steps = 25;
    for (int i = 0; i <= steps; i++) {
      double lat = start.latitude + (end.latitude - start.latitude) * (i / steps);
      double lng = start.longitude + (end.longitude - start.longitude) * (i / steps);
      points.add(LatLng(lat, lng));
    }
    return points;
  }
}
