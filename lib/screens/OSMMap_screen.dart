import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';
import '../models/shipper_model.dart';
import '../data/repositories/shipper_repository.dart';
import '../services/route_service.dart';

class OSMMapScreen extends StatefulWidget {
  final OrderModel? order;
  final LatLng? currentPosition;
  final List<LatLng>? routePoints;
  // Shipper có thể được truyền từ màn hình cha (OrderTrackingScreen)
  // hoặc sẽ được load trực tiếp từ Firebase theo shipperId trong order
  final ShipperModel? shipper;

  const OSMMapScreen({
    super.key,
    this.order,
    this.currentPosition,
    this.routePoints,
    this.shipper,
  });

  @override
  State<OSMMapScreen> createState() => _OSMMapScreenState();
}

class _OSMMapScreenState extends State<OSMMapScreen> {
  LatLng? _shipperPosition;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;

  ShipperModel? _shipper;
  StreamSubscription<ShipperModel?>? _shipperSub;

  @override
  void initState() {
    super.initState();
    _shipper = widget.shipper;
    _loadRouteAndLocation();
    _listenToShipperLocation();
  }

  @override
  void dispose() {
    _shipperSub?.cancel();
    super.dispose();
  }

  /// Lắng nghe cập nhật vị trí GPS thực tế của Shipper từ Firebase
  void _listenToShipperLocation() {
    final shipperId = widget.order?.shipperId;
    if (shipperId == null || shipperId.isEmpty) return;

    _shipperSub = ShipperRepository().watchShipperLocation(shipperId).listen((shipperData) {
      if (!mounted) return;
      setState(() {
        _shipper = shipperData;
        // Nếu có GPS thực từ Firebase, cập nhật vị trí marker
        if (shipperData?.currentLat != null && shipperData?.currentLng != null) {
          _shipperPosition = LatLng(shipperData!.currentLat!, shipperData.currentLng!);
        }
      });
    });
  }

  Future<void> _loadRouteAndLocation() async {
    final order = widget.order;
    final pickupPoint = order != null && (order.pickupLat ?? 0) != 0
        ? LatLng(order.pickupLat!, order.pickupLng!)
        : const LatLng(10.7719, 106.7038);
    final deliveryPoint = order != null && (order.deliveryLat ?? 0) != 0
        ? LatLng(order.deliveryLat!, order.deliveryLng!)
        : const LatLng(10.7905, 106.6775);

    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _routePoints = widget.routePoints!;
    } else {
      _routePoints = await RouteService.getRoutePoints(pickupPoint, deliveryPoint);
    }

    setState(() {
      // Ưu tiên: GPS Firebase > vị trí truyền vào > simulation > pickup
      if (widget.shipper?.currentLat != null) {
        _shipperPosition = LatLng(widget.shipper!.currentLat!, widget.shipper!.currentLng!);
      } else if (widget.currentPosition != null) {
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
    final pickupPoint = order != null && (order.pickupLat ?? 0) != 0
        ? LatLng(order.pickupLat!, order.pickupLng!)
        : const LatLng(10.7719, 106.7038);
    final deliveryPoint = order != null && (order.deliveryLat ?? 0) != 0
        ? LatLng(order.deliveryLat!, order.deliveryLng!)
        : const LatLng(10.7905, 106.6775);

    // Lấy tên shipper: ưu tiên stream Firebase, sau đó dùng denormalized data trong order
    final shipperName = _shipper?.name
        ?? order?.shipperName
        ?? "Chưa phân công";
    final hasRealGps = _shipper?.currentLat != null;

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
                  // Marker Shipper (GPS thực tế hoặc simulation)
                  if (_shipperPosition != null)
                    Marker(
                      point: _shipperPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                          border: Border.all(
                            color: hasRealGps ? Colors.green : Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_bike,
                          color: hasRealGps ? Colors.green : Colors.blue,
                          size: 34,
                        ),
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
          // Bottom Info Card
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
                          decoration: BoxDecoration(
                            color: hasRealGps ? Colors.green.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasRealGps ? Icons.gps_fixed : Icons.gps_not_fixed,
                                size: 12,
                                color: hasRealGps ? Colors.green : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasRealGps ? 'GPS Thực tế' : 'Đang di chuyển',
                                style: TextStyle(
                                  color: hasRealGps ? Colors.green : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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
                              'Giao tới: ${order.deliveryAddress}',
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