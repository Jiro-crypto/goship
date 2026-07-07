import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _simulationTimer;
  int _simulationStep = 0;
  LatLng? _currentShipperPosition;
  String _trackingStatusText = "Đang tìm Shipper...";

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Lộ trình giả lập di chuyển của Shipper tại TP.HCM
  late List<LatLng> _routePoints;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo lộ trình từ Nhà thờ Đức Bà -> Gong Cha Q1 -> Lê Văn Sỹ Q3
    _routePoints = [
      const LatLng(10.7797, 106.6990), // Xuất phát: Nhà thờ Đức Bà
      const LatLng(10.7760, 106.7015), // Trên đường đến quán
      LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude), // Trạm 1: Gong Cha Q1 (Lấy hàng)
      const LatLng(10.7765, 106.6945), // Ngã tư Pasteur/Nguyễn Thị Minh Khai
      const LatLng(10.7812, 106.6885), // Đường Trần Quốc Thảo
      const LatLng(10.7865, 106.6820), // Ngã tư Kỳ Đồng/Lê Văn Sỹ
      LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude), // Trạm cuối: 252 Lê Văn Sỹ (Giao hàng)
    ];

    _currentShipperPosition = _routePoints[0];
    _initStaticMarkersAndPolylines();
    
    if (widget.order.status == "delivering") {
      _startShipperSimulation();
    } else {
      _trackingStatusText = widget.order.status == "delivered" 
          ? "Đơn hàng đã hoàn thành giao!" 
          : "Đơn hàng đang chờ xử lý";
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _initStaticMarkersAndPolylines() {
    // 1. Marker điểm lấy hàng
    _markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
        infoWindow: InfoWindow(
          title: "Địa điểm lấy hàng",
          snippet: widget.order.pickupAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    // 2. Marker điểm giao hàng
    _markers.add(
      Marker(
        markerId: const MarkerId("delivery"),
        position: LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
        infoWindow: InfoWindow(
          title: "Địa chỉ của bạn",
          snippet: widget.order.deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Vẽ đường hướng dẫn tĩnh ban đầu
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("static_guideline"),
        points: [
          LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
          LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
        ],
        color: Colors.grey.shade400,
        width: 3,
        patterns: [PatternItem.dash(10), PatternItem.gap(10)],
      ),
    );

    // Thêm marker shipper tại điểm xuất phát
    _updateShipperMarker();
  }

  void _startShipperSimulation() {
    _trackingStatusText = "Shipper đang di chuyển đến nhà hàng lấy món...";
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      setState(() {
        if (_simulationStep < _routePoints.length - 1) {
          _simulationStep++;
          _currentShipperPosition = _routePoints[_simulationStep];

          // Cập nhật trạng thái hiển thị dựa trên vị trí shipper
          if (_simulationStep == 2) {
            _trackingStatusText = "Shipper đã đến quán Gong Cha và đang nhận món...";
          } else if (_simulationStep > 2 && _simulationStep < _routePoints.length - 1) {
            _trackingStatusText = "Shipper đã nhận hàng và đang trên đường giao tới bạn...";
          } else if (_simulationStep == _routePoints.length - 1) {
            _trackingStatusText = "Shipper đã đến nơi! Vui lòng nhận hàng.";
            widget.order.status = "delivered"; // Hoàn thành đơn
            _simulationTimer?.cancel();
          }

          _updateShipperMarker();
          _updateRoutePolylines();
          _focusCameraOnShipper();
        }
      });
    });
  }

  void _updateShipperMarker() {
    if (_currentShipperPosition == null) return;
    
    _markers.removeWhere((m) => m.markerId.value == "shipper");
    _markers.add(
      Marker(
        markerId: const MarkerId("shipper"),
        position: _currentShipperPosition!,
        infoWindow: InfoWindow(
          title: "Shipper của bạn",
          snippet: _trackingStatusText,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  void _updateRoutePolylines() {
    _polylines.removeWhere((p) => p.polylineId.value == "shipper_path");
    
    // Vẽ vạch di chuyển thực tế từ xuất phát -> Vị trí shipper hiện tại
    List<LatLng> pointsTraveled = _routePoints.sublist(0, _simulationStep + 1);
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("shipper_path"),
        points: pointsTraveled,
        color: Colors.orange.shade800,
        width: 5,
      ),
    );
  }

  void _focusCameraOnShipper() {
    if (_mapController == null || _currentShipperPosition == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentShipperPosition!, 14.5),
    );
  }

  void _fitAllMarkers() {
    if (_mapController == null) return;
    
    double minLat = widget.order.pickupLatitude;
    double maxLat = widget.order.pickupLatitude;
    double minLng = widget.order.pickupLongitude;
    double maxLng = widget.order.pickupLongitude;

    if (widget.order.deliveryLatitude < minLat) minLat = widget.order.deliveryLatitude;
    if (widget.order.deliveryLatitude > maxLat) maxLat = widget.order.deliveryLatitude;
    if (widget.order.deliveryLongitude < minLng) minLng = widget.order.deliveryLongitude;
    if (widget.order.deliveryLongitude > maxLng) maxLng = widget.order.deliveryLongitude;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text("Theo dõi đơn: ${widget.order.id}"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitAllMarkers,
            tooltip: "Thu phóng toàn cảnh",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Google Maps View
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _routePoints[0],
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _fitAllMarkers();
                    });
                  },
                ),
                // Trạng thái GPS
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.order.status == "delivering" ? Icons.directions_bike : Icons.done_all, 
                          color: primaryColor, 
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.order.status == "delivering" ? "Shipper đang di chuyển" : "Đã giao hàng",
                          style: TextStyle(
                            color: Colors.grey.shade800, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Giao diện thông tin đơn hàng & Shipper (Bottom Panel)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh trạng thái hoạt động của Shipper
                    Text(
                      _trackingStatusText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: widget.order.status == "delivered" 
                          ? 1.0 
                          : (_simulationStep + 1) / _routePoints.length,
                      color: primaryColor,
                      backgroundColor: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Thông tin Shipper giả lập cực ngầu
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(
                            "https://cdn-icons-png.flaticon.com/512/2922/2922506.png",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Shipper: Nguyễn Văn Minh",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                                  const SizedBox(width: 4),
                                  const Text("4.9 | Biển số: 59-X1 999.88", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Nút gọi điện thoại Shipper
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đang gọi điện thoại cho Shipper: 0987654321")),
                            );
                          },
                          icon: const Icon(Icons.phone, color: Colors.green),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Lộ trình đơn hàng
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Từ: ${widget.order.pickupAddress}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Đến: ${widget.order.deliveryAddress}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tiền thu hộ: ${currencyFormatter.format(widget.order.price)}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          "Phí ship: ${currencyFormatter.format(widget.order.deliveryFee)}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
