import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/location_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  Position? _currentShipperPosition;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _initMapMarkers();
    if (widget.order.status == "delivering") {
      _startShipperTracking();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _initMapMarkers() {
    _markers.clear();
    // 1. Thêm marker Lấy hàng
    _markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
        infoWindow: InfoWindow(
          title: "Điểm Lấy Hàng",
          snippet: widget.order.pickupAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    // 2. Thêm marker Giao hàng
    _markers.add(
      Marker(
        markerId: const MarkerId("delivery"),
        position: LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
        infoWindow: InfoWindow(
          title: "Điểm Giao Hàng",
          snippet: widget.order.deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Vẽ đường line nối 2 điểm mặc định
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route_direct"),
        points: [
          LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
          LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
        ],
        color: Colors.blue.shade300,
        width: 4,
        patterns: [PatternItem.dash(10), PatternItem.gap(10)],
      ),
    );
  }

  Future<void> _startShipperTracking() async {
    // Lấy vị trí hiện tại tức thời trước
    Position? pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      _updateShipperLocationOnMap(pos);
    }

    // Lắng nghe thay đổi vị trí GPS theo thời gian thực
    _locationSubscription = LocationService.getLocationStream().listen(
      (Position position) {
        _updateShipperLocationOnMap(position);
      },
      onError: (err) {
        print("Lỗi luồng định vị GPS: $err");
      },
    );
  }

  void _updateShipperLocationOnMap(Position position) {
    if (!mounted) return;

    setState(() {
      _currentShipperPosition = position;

      // Cập nhật marker vị trí Shipper
      _markers.removeWhere((m) => m.markerId.value == "shipper");
      _markers.add(
        Marker(
          markerId: const MarkerId("shipper"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(
            title: "Vị trí của bạn (Shipper)",
            snippet: "Tọa độ: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      // Cập nhật polyline di chuyển từ Shipper -> Điểm lấy -> Điểm giao
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route_shipper"),
          points: [
            LatLng(position.latitude, position.longitude),
            LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
            LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
          ],
          color: Colors.orange.shade800,
          width: 5,
        ),
      );
    });

    // Di chuyển Camera để focus cả 3 điểm nếu MapController sẵn sàng
    _fitCameraBounds();
  }

  void _fitCameraBounds() {
    if (_mapController == null) return;

    double minLat = widget.order.pickupLatitude;
    double maxLat = widget.order.pickupLatitude;
    double minLng = widget.order.pickupLongitude;
    double maxLng = widget.order.pickupLongitude;

    // So sánh thêm với điểm giao hàng
    if (widget.order.deliveryLatitude < minLat) minLat = widget.order.deliveryLatitude;
    if (widget.order.deliveryLatitude > maxLat) maxLat = widget.order.deliveryLatitude;
    if (widget.order.deliveryLongitude < minLng) minLng = widget.order.deliveryLongitude;
    if (widget.order.deliveryLongitude > maxLng) maxLng = widget.order.deliveryLongitude;

    // So sánh thêm với vị trí shipper
    if (_currentShipperPosition != null) {
      if (_currentShipperPosition!.latitude < minLat) minLat = _currentShipperPosition!.latitude;
      if (_currentShipperPosition!.latitude > maxLat) maxLat = _currentShipperPosition!.latitude;
      if (_currentShipperPosition!.longitude < minLng) minLng = _currentShipperPosition!.longitude;
      if (_currentShipperPosition!.longitude > maxLng) maxLng = _currentShipperPosition!.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        50, // padding
      ),
    );
  }

  void _completeDelivery() {
    setState(() {
      widget.order.status = "delivered";
    });
    _locationSubscription?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Giao hàng thành công! Đã hoàn thành đơn."),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _acceptOrderDirectly() async {
    bool hasPermission = await LocationService.handlePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng cấp quyền vị trí!")),
      );
      return;
    }

    setState(() {
      widget.order.status = "delivering";
    });
    _startShipperTracking();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn: ${order.id}"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Google Maps View
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(order.pickupLatitude, order.pickupLongitude),
                    zoom: 13.5,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentShipperPosition != null) {
                      _fitCameraBounds();
                    }
                  },
                ),
                if (order.status == "delivering")
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "GPS Đang Hoạt Động",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),

          // 2. Chi tiết đơn hàng (Bottom Panel)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên người gửi & nhận
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Đơn hàng: ${order.id}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == "pending"
                                ? Colors.orange.withOpacity(0.15)
                                : order.status == "delivering"
                                    ? Colors.blue.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status == "pending"
                                ? "Đang Chờ"
                                : order.status == "delivering"
                                    ? "Đang Giao"
                                    : "Đã Giao",
                            style: TextStyle(
                              color: order.status == "pending"
                                  ? Colors.orange.shade800
                                  : order.status == "delivering"
                                      ? Colors.blue.shade800
                                      : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Người gửi
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.store, color: Colors.orange.shade800, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Người gửi: ${order.senderName}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text("SĐT: ${order.senderPhone}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("Địa chỉ: ${order.pickupAddress}", style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Người nhận
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_pin_circle, color: Colors.red, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Người nhận: ${order.receiverName}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text("SĐT: ${order.receiverPhone}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("Địa chỉ: ${order.deliveryAddress}", style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Tiền hàng & Phí ship
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Phí ship (Shipper nhận)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              currencyFormatter.format(order.deliveryFee),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Tiền COD (Thu hộ)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              currencyFormatter.format(order.price),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nút bấm tương tác
                    if (order.status == "pending")
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _acceptOrderDirectly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            "NHẬN ĐƠN HÀNG NÀY",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ),
                      )
                    else if (order.status == "delivering")
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _completeDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.done_all, color: Colors.white),
                          label: const Text(
                            "HOÀN THÀNH GIAO HÀNG",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              "Đơn hàng này đã giao thành công!",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
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
