import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';
import '../models/shipper_model.dart';
import '../data/mock_shippers.dart';
import '../services/route_service.dart';
import '../services/preference_service.dart';
import 'OSMMap_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _simulationTimer;
  int _simulationStep = 0;
  LatLng? _currentShipperPosition;
  String _trackingStatusText = "Shipper đã nhận đơn và lấy hàng tại điểm lấy!";
  bool _isLoadingRoute = true;

  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initRouteAndMap();
  }

  Future<void> _initRouteAndMap() async {
    final pickupPoint = widget.order.latLay != 0
        ? LatLng(widget.order.latLay, widget.order.lngLay)
        : const LatLng(10.7719, 106.7038);
    final deliveryPoint = widget.order.latGiao != 0
        ? LatLng(widget.order.latGiao, widget.order.lngGiao)
        : const LatLng(10.7905, 106.6775);

    // Dùng RouteService dùng chung lấy tuyến đường thực tế từ OSRM
    final RouteInfo routeInfo = await RouteService.getRouteInfo(pickupPoint, deliveryPoint);
    _routePoints = routeInfo.points;

    if (!mounted) return;

    if (!routeInfo.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể kết nối máy chủ OSRM, đang hiển thị đường chim bay."), 
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Resume simulation step based on real elapsed time since assignment
    if (_routePoints.isNotEmpty) {
      final int totalSteps = _routePoints.length;
      final DateTime startTime = widget.order.thoiGianPhanCong ?? widget.order.thoiGianTao;
      final int elapsedSec = DateTime.now().difference(startTime).inSeconds;
      final int calculatedStep = (elapsedSec / 1.5).floor();

      if (calculatedStep >= totalSteps - 1) {
        _simulationStep = totalSteps - 1;
        widget.order.trangThaiDon = "Đã giao";
        widget.order.status = "delivered";
        PreferenceService.saveOrder(widget.order);
        _trackingStatusText = "Shipper đã đến nơi! Vui lòng nhận hàng.";
      } else {
        _simulationStep = calculatedStep < 0 ? 0 : calculatedStep;
      }
    }

    setState(() {
      _isLoadingRoute = false;
      if (_routePoints.isNotEmpty) {
        _currentShipperPosition = _routePoints[_simulationStep];
      } else {
        _currentShipperPosition = pickupPoint;
      }
      _initStaticMarkersAndPolylines(pickupPoint, deliveryPoint);
    });

    if (_simulationStep < _routePoints.length - 1) {
      _startShipperSimulation();
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _initStaticMarkersAndPolylines(LatLng pickupPoint, LatLng deliveryPoint) {
    _markers
      ..clear()
      ..add(
        Marker(
          point: pickupPoint,
          width: 40,
          height: 40,
          child: const Icon(Icons.storefront, color: Colors.orange, size: 36),
        ),
      )
      ..add(
        Marker(
          point: deliveryPoint,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 38),
        ),
      );

    _polylines
      ..clear()
      ..add(
        Polyline(
          points: _routePoints,
          color: Colors.orange.shade800,
          strokeWidth: 5.0,
        ),
      );

    _updateShipperMarker();
  }

  void _startShipperSimulation() {
    if (_routePoints.isEmpty) return;

    if (_simulationStep == 0) {
      _trackingStatusText = "Shipper đã nhận đơn và lấy hàng tại điểm lấy!";
    } else if (_simulationStep < _routePoints.length - 1) {
      _trackingStatusText = "Shipper đã nhận hàng và đang trên đường giao tới bạn...";
    }

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;

      setState(() {
        if (_simulationStep < _routePoints.length - 1) {
          _simulationStep++;
          _currentShipperPosition = _routePoints[_simulationStep];

          if (_simulationStep > 0 && _simulationStep < _routePoints.length - 1) {
            _trackingStatusText = "Shipper đã nhận hàng và đang trên đường giao tới bạn...";
          } else if (_simulationStep == _routePoints.length - 1) {
            _trackingStatusText = "Shipper đã đến nơi! Vui lòng nhận hàng.";
            widget.order.trangThaiDon = "Đã giao";
            widget.order.status = "delivered";
            _simulationTimer?.cancel();
            PreferenceService.saveOrder(widget.order);
          }

          _updateShipperMarker();
          _focusCameraOnShipper();
        }
      });
    });
  }

  void _updateShipperMarker() {
    if (_currentShipperPosition == null) return;

    _markers.removeWhere((m) => m.key == const Key('shipper_marker'));
    _markers.add(
      Marker(
        key: const Key('shipper_marker'),
        point: _currentShipperPosition!,
        width: 46,
        height: 46,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: const Icon(Icons.directions_bike, color: Colors.blue, size: 32),
        ),
      ),
    );
  }

  void _focusCameraOnShipper() {
    if (_currentShipperPosition == null) return;
    _mapController.move(_currentShipperPosition!, 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;
    final order = widget.order;
    final pickupPoint = order.latLay != 0 ? LatLng(order.latLay, order.lngLay) : const LatLng(10.7719, 106.7038);

    // Lookup actual assigned Shipper info
    String shipperName = "Nguyễn Văn An";
    String shipperPhone = "0901234567";
    if (order.maShipper.isNotEmpty) {
      final found = MockShippers.shippers.firstWhere(
        (s) => s.id == order.maShipper || s.name == order.maShipper,
        orElse: () => ShipperModel(id: order.maShipper, name: order.maShipper, phone: "0901234567", isActive: true, distance: 1.0),
      );
      shipperName = found.name;
      shipperPhone = found.phone;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Theo dõi đơn: ${order.orderId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingRoute
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Interactive Map view
                SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentShipperPosition ?? pickupPoint,
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.goship',
                          ),
                          PolylineLayer(polylines: _polylines),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
                          ),
                          child: Text(
                            order.trangThaiDon,
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tracking Info & Shipper card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status text banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _trackingStatusText,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              if (_simulationStep < _routePoints.length - 1 && _routePoints.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "⏱️ Dự kiến giao trong: ~${widget.order.getEstimatedDeliveryMinutes(currentStep: _simulationStep, totalSteps: _routePoints.length)} phút",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Shipper Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person, color: Colors.blue, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Shipper: $shipperName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      const Text('⭐ 4.9 | Biển số: 59-X1 999.88', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 26),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đang gọi cho Shipper $shipperName: $shipperPhone')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Launch full OSM Map Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OSMMapScreen(
                                    order: order,
                                    currentPosition: _currentShipperPosition,
                                    routePoints: _routePoints,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map, color: Colors.white),
                            label: const Text('Xem vị trí Shipper thực tế trên bản đồ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Route details summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.storefront, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Từ: ${order.diaChiLay}', style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Đến: ${order.diaChiGiao}', style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}