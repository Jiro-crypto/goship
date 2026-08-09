import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock_orders.dart';
import '../../data/mock_shippers.dart';
import '../../models/order_model.dart';
import '../../models/shipper_model.dart';
import '../../services/route_service.dart';

class AdminShipperTrackingScreen extends StatefulWidget {
  const AdminShipperTrackingScreen({super.key});

  @override
  State<AdminShipperTrackingScreen> createState() =>
      _AdminShipperTrackingScreenState();
}

class _AdminShipperTrackingScreenState
    extends State<AdminShipperTrackingScreen> {
  final Color primaryColor = Colors.orange.shade800;
  final MapController _mapController = MapController();

  final LatLng _defaultCenter = const LatLng(10.7769, 106.7009);

  // Vị trí hiện tại của shipper
  final Map<String, LatLng> _shipperPositions = {};

  // Lộ trình đầy đủ theo đường thật cho từng shipper (SP-XXX -> danh sách điểm)
  final Map<String, List<LatLng>> _shipperRoutes = {};

  // Vị trí thứ mấy trong route (index)
  final Map<String, int> _shipperRouteIndex = {};

  // Trạng thái tải route
  final Map<String, bool> _routeLoading = {};

  Timer? _locationTimer;
  ShipperModel? _selectedShipper;
  bool _showAllShippers = true;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initAndLoadRoutes();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Khởi tạo vị trí + load route thật từ OSRM cho các shipper đang giao
  Future<void> _initAndLoadRoutes() async {
    final random = Random();

    for (final s in MockShippers.shippers) {
      if (!s.isActive) continue;

      // Lấy đơn đang giao (nếu có)
      final order = _getCurrentOrder(s.id);

      if (order != null) {
        // Shipper có đơn: đặt vị trí gần điểm lấy hàng và load route thật
        final startLat = order.latLay + (random.nextDouble() - 0.5) * 0.008;
        final startLng = order.lngLay + (random.nextDouble() - 0.5) * 0.008;
        _shipperPositions[s.id] = LatLng(startLat, startLng);
        _routeLoading[s.id] = true;
      } else {
        // Shipper rảnh: đặt vị trí random quanh trung tâm HCM
        final latOffset = (random.nextDouble() - 0.5) * 0.05;
        final lngOffset = (random.nextDouble() - 0.5) * 0.05;
        _shipperPositions[s.id] = LatLng(
          _defaultCenter.latitude + latOffset,
          _defaultCenter.longitude + lngOffset,
        );
      }
    }

    setState(() {
      _isInitializing = false;
    });

    // Load route thật cho từng shipper có đơn (parallel)
    for (final s in MockShippers.shippers) {
      if (s.isActive) {
        final order = _getCurrentOrder(s.id);
        if (order != null) {
          _loadRouteForShipper(s.id, order);
        }
      }
    }

    _startLocationSimulation();
  }

  // Gọi OSRM API lấy tuyến đường: shipper -> điểm lấy -> điểm giao
  Future<void> _loadRouteForShipper(String shipperId, OrderModel order) async {
    try {
      final shipperPos = _shipperPositions[shipperId]!;
      final pickup = LatLng(order.latLay, order.lngLay);
      final delivery = LatLng(order.latGiao, order.lngGiao);

      // Đoạn 1: shipper -> điểm lấy
      final leg1 = await RouteService.getRoutePoints(shipperPos, pickup);
      // Đoạn 2: điểm lấy -> điểm giao
      final leg2 = await RouteService.getRoutePoints(pickup, delivery);

      final fullRoute = <LatLng>[];
      fullRoute.addAll(leg1);
      if (leg2.isNotEmpty) {
        // Bỏ điểm đầu của leg2 để không trùng điểm cuối leg1
        fullRoute.addAll(leg2.skip(1));
      }

      if (!mounted) return;
      setState(() {
        _shipperRoutes[shipperId] = fullRoute;
        _shipperRouteIndex[shipperId] = 0;
        _routeLoading[shipperId] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading[shipperId] = false;
      });
    }
  }

  // Timer di chuyển shipper theo route (2 giây tiến 1 điểm)
  void _startLocationSimulation() {
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      setState(() {
        for (final s in MockShippers.shippers) {
          if (!s.isActive) continue;

          final route = _shipperRoutes[s.id];
          if (route == null || route.isEmpty) continue;

          final idx = _shipperRouteIndex[s.id] ?? 0;
          if (idx < route.length - 1) {
            final nextIdx = idx + 1;
            _shipperRouteIndex[s.id] = nextIdx;
            _shipperPositions[s.id] = route[nextIdx];
          }
          // Khi tới cuối route thì dừng (đã đến nơi)
        }
      });
    });
  }

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);

    return 2 * r * atan2(sqrt(h), sqrt(1 - h));
  }

  // Tính tổng độ dài route còn lại từ vị trí hiện tại
  double _remainingRouteKm(String shipperId) {
    final route = _shipperRoutes[shipperId];
    final idx = _shipperRouteIndex[shipperId] ?? 0;
    if (route == null || route.length < 2 || idx >= route.length - 1) return 0;

    double total = 0;
    for (int i = idx; i < route.length - 1; i++) {
      total += _distanceKm(route[i], route[i + 1]);
    }
    return total;
  }

  OrderModel? _getCurrentOrder(String shipperId) {
    try {
      return MockOrders.orders.firstWhere(
        (o) => o.maShipper == shipperId && o.status == "delivering",
      );
    } catch (_) {
      return null;
    }
  }

  int _deliveringCount(String shipperId) {
    return MockOrders.orders
        .where((o) => o.maShipper == shipperId && o.status == "delivering")
        .length;
  }

  void _focusShipper(ShipperModel shipper) {
    final pos = _shipperPositions[shipper.id];
    if (pos == null) return;

    setState(() {
      _selectedShipper = shipper;
      _showAllShippers = false;
    });

    _mapController.move(pos, 15);
  }

  void _showAll() {
    setState(() {
      _selectedShipper = null;
      _showAllShippers = true;
    });

    _mapController.move(_defaultCenter, 12);
  }

  Widget _buildShipperMarker(ShipperModel shipper, bool isSelected) {
    return GestureDetector(
      onTap: () => _focusShipper(shipper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              shipper.name.split(" ").last,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.motorcycle,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    final targets = _showAllShippers
        ? MockShippers.shippers.where((s) => s.isActive).toList()
        : (_selectedShipper != null ? [_selectedShipper!] : <ShipperModel>[]);

    for (final shipper in targets) {
      final pos = _shipperPositions[shipper.id];
      if (pos == null) continue;

      markers.add(
        Marker(
          point: pos,
          width: 80,
          height: 70,
          child: _buildShipperMarker(
            shipper,
            _selectedShipper?.id == shipper.id,
          ),
        ),
      );
    }

    // Marker điểm lấy/giao của shipper đang chọn
    if (_selectedShipper != null) {
      final order = _getCurrentOrder(_selectedShipper!.id);
      if (order != null) {
        markers.add(
          Marker(
            point: LatLng(order.latLay, order.lngLay),
            width: 50,
            height: 50,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );

        markers.add(
          Marker(
            point: LatLng(order.latGiao, order.lngGiao),
            width: 50,
            height: 50,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  // Vẽ polyline route thật cho shipper đang chọn (nếu ở chế độ chọn 1)
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    if (_selectedShipper != null) {
      // Chế độ 1 shipper: vẽ chi tiết đã đi + chưa đi
      final route = _shipperRoutes[_selectedShipper!.id];
      final idx = _shipperRouteIndex[_selectedShipper!.id] ?? 0;

      if (route != null && route.length >= 2) {
        // Phần đã đi qua (nét liền, xám nhạt)
        if (idx > 0) {
          polylines.add(
            Polyline(
              points: route.sublist(0, idx + 1),
              strokeWidth: 4,
              color: Colors.grey.shade400,
            ),
          );
        }

        // Phần còn lại (nét liền cam đậm)
        if (idx < route.length - 1) {
          polylines.add(
            Polyline(
              points: route.sublist(idx),
              strokeWidth: 5,
              color: primaryColor,
            ),
          );
        }
      }
    } else if (_showAllShippers) {
      // Chế độ tất cả: vẽ route mờ cho từng shipper
      for (final s in MockShippers.shippers) {
        if (!s.isActive) continue;
        final route = _shipperRoutes[s.id];
        final idx = _shipperRouteIndex[s.id] ?? 0;
        if (route != null && route.length >= 2 && idx < route.length - 1) {
          polylines.add(
            Polyline(
              points: route.sublist(idx),
              strokeWidth: 3,
              color: Colors.blue.shade400.withValues(alpha: 0.6),
            ),
          );
        }
      }
    }

    return polylines;
  }

  Widget _buildShipperListPanel() {
    final activeShippers =
        MockShippers.shippers.where((s) => s.isActive).toList();

    return Container(
      height: 130,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Đang theo dõi ${activeShippers.length} shipper",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_selectedShipper != null)
                  TextButton.icon(
                    onPressed: _showAll,
                    icon: const Icon(Icons.public, size: 16),
                    label: const Text("Xem tất cả"),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: activeShippers.length,
              itemBuilder: (context, index) {
                final shipper = activeShippers[index];
                final isSelected = _selectedShipper?.id == shipper.id;
                final delivering = _deliveringCount(shipper.id);
                final loading = _routeLoading[shipper.id] == true;

                return GestureDetector(
                  onTap: () => _focusShipper(shipper),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.motorcycle,
                                size: 14,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shipper.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "📞 ${shipper.phone}",
                          style: const TextStyle(fontSize: 10),
                        ),
                        if (loading)
                          Row(
                            children: [
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Đang tải tuyến...",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          )
                        else
                          Text(
                            delivering > 0
                                ? "🚚 $delivering đơn đang giao"
                                : "⏸ Rảnh",
                            style: TextStyle(
                              fontSize: 10,
                              color: delivering > 0
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedShipperInfo() {
    if (_selectedShipper == null) return const SizedBox.shrink();

    final shipper = _selectedShipper!;
    final order = _getCurrentOrder(shipper.id);
    final shipperPos = _shipperPositions[shipper.id];
    final loading = _routeLoading[shipper.id] == true;

    double? distanceToPickup;
    double? distanceToDelivery;
    double? remainingKm;

    if (order != null && shipperPos != null) {
      distanceToPickup =
          _distanceKm(shipperPos, LatLng(order.latLay, order.lngLay));
      distanceToDelivery =
          _distanceKm(shipperPos, LatLng(order.latGiao, order.lngGiao));
      remainingKm = _remainingRouteKm(shipper.id);
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    child: Icon(Icons.motorcycle, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipper.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "${shipper.id} • ${shipper.phone}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 4),
                        Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (loading)
                Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text("Đang tải lộ trình từ OSRM...",
                        style: TextStyle(fontSize: 12)),
                  ],
                )
              else if (order != null) ...[
                Row(
                  children: [
                    Icon(Icons.assignment, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      "Đơn đang giao: ${order.orderId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Tới điểm lấy (thẳng): ${distanceToPickup?.toStringAsFixed(2) ?? '-'} km",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Tới điểm giao (thẳng): ${distanceToDelivery?.toStringAsFixed(2) ?? '-'} km",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.route, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Quãng đường còn lại theo tuyến: ${remainingKm?.toStringAsFixed(2) ?? '-'} km",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Shipper hiện đang rảnh, không có đơn đang giao",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đang gọi ${shipper.phone}..."),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text("Gọi"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final pos = _shipperPositions[shipper.id];
                        if (pos != null) {
                          _mapController.move(pos, 16);
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text("Định vị"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildShipperListPanel(),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 12,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.goship',
                  ),
                  PolylineLayer(polylines: _buildPolylines()),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          zoom + 1,
                        );
                      },
                      child: const Icon(Icons.add, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          zoom - 1,
                        );
                      },
                      child: const Icon(Icons.remove, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "recenter",
                      backgroundColor: primaryColor,
                      onPressed: _showAll,
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend(Colors.blue.shade600, "Shipper"),
                        _legend(Colors.orange.shade700, "Điểm lấy"),
                        _legend(Colors.red.shade700, "Điểm giao"),
                        _legend(primaryColor, "Lộ trình"),
                        _legend(Colors.grey.shade400, "Đã đi qua"),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSelectedShipperInfo(),
            ],
          ),
        ),
      ],
    );
  }
}
