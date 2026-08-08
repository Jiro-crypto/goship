import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';
import '../models/shipper_model.dart';
import '../data/mock_shippers.dart';
import '../services/route_service.dart';

class OSMMapScreen extends StatefulWidget {
  final OrderModel? order;
  final LatLng? currentPosition;
  final List<LatLng>? routePoints;

  const OSMMapScreen({
    super.key,
    this.order,
    this.currentPosition,
    this.routePoints,
  });

  @override
  State<OSMMapScreen> createState() => _OSMMapScreenState();
}

class _OSMMapScreenState extends State<OSMMapScreen> {
  LatLng? _shipperPosition;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteAndLocation();
  }

  Future<void> _loadRouteAndLocation() async {
    final order = widget.order;
    final pickupPoint = order != null && order.latLay != 0
        ? LatLng(order.latLay, order.lngLay)
        : const LatLng(10.7719, 106.7038);
    final deliveryPoint = order != null && order.latGiao != 0
        ? LatLng(order.latGiao, order.lngGiao)
        : const LatLng(10.7905, 106.6775);

    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _routePoints = widget.routePoints!;
    } else {
      _routePoints = await RouteService.getRoutePoints(pickupPoint, deliveryPoint);
    }

    setState(() {
      if (widget.currentPosition != null) {
        _shipperPosition = widget.currentPosition;
      } else if (_routePoints.isNotEmpty) {
        _shipperPosition = _routePoints[(_routePoints.length * 0.4).floor()];
      } else {
        _shipperPosition = pickupPoint;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = widget.order;
    final pickupPoint = order != null && order.latLay != 0
        ? LatLng(order.latLay, order.lngLay)
        : const LatLng(10.7719, 106.7038);
    final deliveryPoint = order != null && order.latGiao != 0
        ? LatLng(order.latGiao, order.lngGiao)
        : const LatLng(10.7905, 106.6775);

    String shipperName = "Chưa phân công";
    if (order != null && order.maShipper.isNotEmpty) {
      final found = MockShippers.shippers.firstWhere(
        (s) => s.id == order.maShipper || s.name == order.maShipper,
        orElse: () => ShipperModel(id: order.maShipper, name: order.maShipper, phone: "0901234567", isActive: true, distance: 1.0),
      );
      shipperName = found.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order != null ? 'Theo dõi Shipper (${order.orderId})' : 'Bản đồ OpenStreetMap',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _shipperPosition ?? pickupPoint,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.goship',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.orange.shade800,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Marker Shipper
                  if (_shipperPosition != null)
                    Marker(
                      point: _shipperPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                        ),
                        child: const Icon(Icons.directions_bike, color: Colors.blue, size: 34),
                      ),
                    ),
                  // Marker Lấy hàng
                  Marker(
                    point: pickupPoint,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.storefront, color: Colors.orange, size: 36),
                  ),
                  // Marker Giao hàng
                  Marker(
                    point: deliveryPoint,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 38),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bike, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shipper: $shipperName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Đang di chuyển', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    if (order != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Giao tới: ${order.diaChiGiao}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}