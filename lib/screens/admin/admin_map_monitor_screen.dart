import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../data/mock_shippers.dart';
import '../../models/shipper_model.dart';

/// ============================================================================
/// UC02 – Giám sát vị trí toàn bộ Shipper trên bản đồ theo thời gian thực
/// Shipper di chuyển theo tuyến đường thực (OSRM), không đi xuyên nhà dân.
/// ============================================================================
class AdminMapMonitorScreen extends StatefulWidget {
  const AdminMapMonitorScreen({super.key});

  @override
  State<AdminMapMonitorScreen> createState() => _AdminMapMonitorScreenState();
}

class _AdminMapMonitorScreenState extends State<AdminMapMonitorScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  final Color primaryColor = Colors.orange.shade800;
  final Random _random = Random();

  // Trung tâm TP.HCM
  final LatLng _hcmCenter = const LatLng(10.7769, 106.7009);
  bool _isAutoRefresh = true;
  ShipperModel? _selectedShipper;

  /// Lưu tuyến đường và bước hiện tại của mỗi shipper (key = shipper.id)
  final Map<String, List<LatLng>> _shipperRoutes = {};
  final Map<String, int> _shipperStepIndex = {};

  /// Danh sách các điểm đến ngẫu nhiên trong TP.HCM (địa điểm thật trên đường)
  final List<LatLng> _hotspots = const [
    LatLng(10.7769, 106.7009), // Chợ Bến Thành
    LatLng(10.7905, 106.6775), // Q.3 - Lê Văn Sỹ
    LatLng(10.8035, 106.6980), // Bình Thạnh - Điện Biên Phủ
    LatLng(10.7300, 106.7200), // Q.7 - Nguyễn Thị Thập
    LatLng(10.7719, 106.7038), // Q.1 - Hồ Tùng Mậu
    LatLng(10.7626, 106.6822), // Q.5 - Trần Hưng Đạo
    LatLng(10.8231, 106.6297), // Gò Vấp - Quang Trung
    LatLng(10.7550, 106.6650), // Q.10 - 3/2
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo tuyến đường đầu tiên cho mỗi shipper
    _initializeShipperRoutes();

    // Tick di chuyển 2 giây/lần theo route thực
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isAutoRefresh) _moveShippersAlongRoute();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Khởi tạo tuyến đường thực (OSRM) cho từng shipper đang active
  Future<void> _initializeShipperRoutes() async {
    for (var shipper in MockShippers.shippers.where((s) => s.isActive)) {
      await _generateNewRouteForShipper(shipper);
    }
    if (mounted) setState(() {});
  }

  /// Gọi OSRM để lấy tuyến đường thực từ vị trí hiện tại đến 1 hotspot ngẫu nhiên
  Future<void> _generateNewRouteForShipper(ShipperModel shipper) async {
    final startLat = shipper.currentLatitude;
    final startLng = shipper.currentLongitude;

    // Chọn 1 điểm đến ngẫu nhiên khác vị trí hiện tại
    final destination = _hotspots[_random.nextInt(_hotspots.length)];

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];

          // GeoJSON = [lng, lat] → LatLng(lat, lng)
          final routePoints =
              coordinates.map((c) => LatLng(c[1], c[0])).toList();

          _shipperRoutes[shipper.id] = routePoints;
          _shipperStepIndex[shipper.id] = 0;
          return;
        }
      }
    } catch (e) {
      debugPrint("OSRM error for ${shipper.id}: $e");
    }

    // Fallback: tuyến thẳng chim bay chia 30 bước
    _shipperRoutes[shipper.id] = _buildStraightPath(
        LatLng(startLat, startLng), destination, 30);
    _shipperStepIndex[shipper.id] = 0;
  }

  List<LatLng> _buildStraightPath(LatLng from, LatLng to, int steps) {
    final List<LatLng> pts = [];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      pts.add(LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      ));
    }
    return pts;
  }

  /// Mỗi tick: dịch shipper sang điểm kế tiếp trên route
  void _moveShippersAlongRoute() {
    if (!mounted) return;
    setState(() {
      for (var shipper in MockShippers.shippers) {
        if (!shipper.isActive) continue;

        final route = _shipperRoutes[shipper.id];
        if (route == null || route.isEmpty) continue;

        int step = _shipperStepIndex[shipper.id] ?? 0;

        // Đi ~2-3 điểm mỗi tick để chuyển động mượt hơn
        step += 2;

        if (step >= route.length) {
          // Đến cuối tuyến → sinh tuyến mới
          _generateNewRouteForShipper(shipper);
          continue;
        }

        final next = route[step];
        shipper.currentLatitude = next.latitude;
        shipper.currentLongitude = next.longitude;
        shipper.lastUpdate = DateTime.now();
        _shipperStepIndex[shipper.id] = step;
      }
    });
  }

  List<Marker> _buildShipperMarkers() {
    return MockShippers.shippers.where((s) => s.isActive).map((shipper) {
      final isSelected = _selectedShipper?.id == shipper.id;
      return Marker(
        point: LatLng(shipper.currentLatitude, shipper.currentLongitude),
        width: isSelected ? 80 : 60,
        height: isSelected ? 80 : 60,
        child: GestureDetector(
          onTap: () => _showShipperInfo(shipper),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.shade700 : primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child:
                    const Icon(Icons.motorcycle, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white,
                child: Text(
                  shipper.id,
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Vẽ polyline tuyến đường còn lại của mỗi shipper
  List<Polyline> _buildRoutePolylines() {
    final List<Polyline> polylines = [];
    for (var shipper in MockShippers.shippers.where((s) => s.isActive)) {
      final route = _shipperRoutes[shipper.id];
      final step = _shipperStepIndex[shipper.id] ?? 0;
      if (route == null || step >= route.length - 1) continue;

      polylines.add(
        Polyline(
          points: route.sublist(step),
          strokeWidth: 3,
          color: primaryColor.withValues(alpha: 0.55),
        ),
      );
    }
    return polylines;
  }

  void _showShipperInfo(ShipperModel shipper) {
    setState(() => _selectedShipper = shipper);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shipper.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Mã: ${shipper.id}",
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _infoRow(Icons.phone, "SĐT", shipper.phone),
              if (shipper.bienSoXe.isNotEmpty)
                _infoRow(
                    Icons.confirmation_number, "Biển số", shipper.bienSoXe),
              if (shipper.loaiPhuongTien.isNotEmpty)
                _infoRow(Icons.two_wheeler, "Phương tiện",
                    shipper.loaiPhuongTien),
              _infoRow(
                  Icons.gps_fixed,
                  "Vị trí",
                  "${shipper.currentLatitude.toStringAsFixed(5)}, "
                      "${shipper.currentLongitude.toStringAsFixed(5)}"),
              _infoRow(Icons.update, "Cập nhật",
                  "${DateTime.now().difference(shipper.lastUpdate).inSeconds}s trước"),
              _infoRow(
                  Icons.route,
                  "Bước hiện tại",
                  "${_shipperStepIndex[shipper.id] ?? 0}"
                      "/${_shipperRoutes[shipper.id]?.length ?? 0}"),
              _infoRow(
                  Icons.circle,
                  shipper.isActive ? "Đang hoạt động" : "Offline",
                  "",
                  color: shipper.isActive ? Colors.green : Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? primaryColor),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        MockShippers.shippers.where((s) => s.isActive).length;
    final offlineCount = MockShippers.shippers.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giám Sát Shipper (Realtime)",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _hcmCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.goship',
              ),
              // ⚠️ Polyline vẽ TRƯỚC marker để marker nổi lên trên
              PolylineLayer(polylines: _buildRoutePolylines()),
              MarkerLayer(markers: _buildShipperMarkers()),
            ],
          ),

          // Thẻ thống kê ở góc trên
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(Icons.motorcycle, "Online", "$activeCount",
                        Colors.green),
                    _statItem(Icons.person_off, "Offline", "$offlineCount",
                        Colors.grey),
                    _statItem(Icons.refresh, "Tick", "2s", primaryColor),
                    _statItem(Icons.map, "Zoom", "13x", Colors.blue),
                  ],
                ),
              ),
            ),
          ),

          // Nút bật/tắt auto refresh
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: "toggleRefresh",
              backgroundColor:
                  _isAutoRefresh ? Colors.green : Colors.grey,
              onPressed: () =>
                  setState(() => _isAutoRefresh = !_isAutoRefresh),
              tooltip: _isAutoRefresh
                  ? "Tạm dừng di chuyển"
                  : "Tiếp tục di chuyển",
              child: Icon(
                  _isAutoRefresh ? Icons.pause : Icons.play_arrow,
                  color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _mapController.move(_hcmCenter, 13),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
