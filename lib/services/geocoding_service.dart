import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Performs geocoding converting an address string into latitude & longitude coordinates.
  static Future<Map<String, double>?> geocodeAddress(String rawAddress) async {
    try {
      // 1. Clean address: remove parenthetical text like "(trước đây thuộc Phường 13, Quận 10)"
      String cleanedAddress = rawAddress.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

      Map<String, double>? result = await _fetchNominatim(cleanedAddress);
      if (result != null) return result;

      // 2. Fallback query: try street + city if detailed ward/district fails
      final parts = cleanedAddress.split(',');
      if (parts.length > 2) {
        final simplified = '${parts[0].trim()}, ${parts.last.trim()}';
        result = await _fetchNominatim(simplified);
        if (result != null) return result;
      }

      // Default fallback coordinates (HCMC centre - Sư Vạn Hạnh area)
      return {'lat': 10.7768, 'lng': 106.6708};
    } catch (e) {
      return {'lat': 10.7768, 'lng': 106.6708};
    }
  }

  static Future<Map<String, double>?> _fetchNominatim(String address) async {
    try {
      final queryAddress = address.toLowerCase().contains('việt nam') || address.toLowerCase().contains('vietnam')
          ? address
          : '$address, Việt Nam';
      final encodedAddress = Uri.encodeComponent(queryAddress);
      final url = '$_baseUrl?q=$encodedAddress&format=json&limit=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'LogiRoute-App/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat'].toString()),
            'lng': double.parse(data[0]['lon'].toString()),
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
