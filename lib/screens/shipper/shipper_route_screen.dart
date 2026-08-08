import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../models/order_model.dart';

class ShipperRouteScreen extends StatefulWidget {
  final OrderModel order;
  const ShipperRouteScreen({super.key, required this.order});

  @override
  State<ShipperRouteScreen> createState() => _ShipperRouteScreenState();
}

class _ShipperRouteScreenState extends State<ShipperRouteScreen> {
  final MapController _mapController = MapController();
  Timer? _simulationTimer;
  int _simulationStep = 0;
  LatLng? _currentShipperPosition;
  
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  List<LatLng> _routePoints = [];
  
  bool _isLoadingRoute = true;
  String _etaText = "Đang tính toán...";
  String _distanceText = "Đang tính toán...";

  @override
  void initState() {
    super.initState();

    // Validate MSG_VR_04: Chỉ xem được khi đang giao
    if (widget.order.status != 'delivering') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chức năng xem tuyến đường chỉ khả dụng khi đơn ở trạng thái Đang giao."), 
            backgroundColor: Colors.red,
          ), 
        );
        Navigator.pop(context);
      });
      return; 
    }

    _fetchRouteFromOSRM();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  // GỌI API OSRM ĐỂ LẤY TUYẾN ĐƯỜNG THỰC TẾ
  Future<void> _fetchRouteFromOSRM() async {
    // API OSRM yêu cầu tọa độ gửi lên theo thứ tự: Kinh độ (Lng), Vĩ độ (Lat)
    final startLng = widget.order.pickupLongitude;
    final startLat = widget.order.pickupLatitude;
    final endLng = widget.order.deliveryLongitude;
    final endLat = widget.order.deliveryLatitude;

    final url = 'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final List coordinates = route['geometry']['coordinates'];
        
        // Trích xuất ETA (giây) và Quãng đường (mét) từ JSON
        final double durationSeconds = (route['duration'] as num).toDouble();
        final double distanceMeters = (route['distance'] as num).toDouble();

        setState(() {
          // Parse tọa độ GeoJSON (Lng, Lat) thành LatLng (Lat, Lng) của flutter_map
          _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
          
          _etaText = "${(durationSeconds / 60).ceil()} phút";
          _distanceText = "${(distanceMeters / 1000).toStringAsFixed(1)} km";
          
          _isLoadingRoute = false;
          _currentShipperPosition = _routePoints[0];
          
          _initStaticMarkersAndPolylines();
          _startShipperSimulation();
        });
      } else {
        _handleRoutingFallback();
      }
    } catch (e) {
      _handleRoutingFallback();
    }
  }

  // Nếu API lỗi (mất mạng/chặn kết nối), fallback về đường thẳng chim bay
  void _handleRoutingFallback() {
    setState(() { 
      _routePoints = [
        LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
        LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
      ];
      _etaText = "Không xác định";
      _distanceText = "N/A";
      _isLoadingRoute = false;
      _currentShipperPosition = _routePoints[0];
      
      _initStaticMarkersAndPolylines();
      _startShipperSimulation();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Không thể kết nối máy chủ OSRM, đang hiển thị đường chim bay."), backgroundColor: Colors.orange),
    );
  }

  void _initStaticMarkersAndPolylines() {
    _markers
      ..clear()
      ..add(
        Marker(
          point: LatLng(widget.order.pickupLatitude, widget.order.pickupLongitude),
          child: const Icon(Icons.store, color: Colors.orange, size: 32),
        ),
      )
      ..add(
        Marker(
          point: LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      );

    _updateRoutePolylines();
    _updateShipperMarker();
  }

  void _startShipperSimulation() {
    // Vì OSRM trả về rất nhiều điểm (vài trăm điểm), ta cho Shipper nhảy vài điểm mỗi nhịp để demo không bị quá lâu
    int stepJump = (_routePoints.length / 20).ceil(); // Đảm bảo hoàn thành sau khoảng 20 nhịp
    if (stepJump < 1) stepJump = 1;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;

      setState(() {
        if (_simulationStep < _routePoints.length - 1) {
          _simulationStep += stepJump;
          if (_simulationStep >= _routePoints.length) {
            _simulationStep = _routePoints.length - 1;
          }
          _currentShipperPosition = _routePoints[_simulationStep];

          _updateShipperMarker();
          _updateRoutePolylines();
          _focusCameraOnShipper();
          
          if (_simulationStep == _routePoints.length - 1) {
            _simulationTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bạn đã đến điểm giao hàng!"),
                backgroundColor: Colors.green,
              )
            );
          }
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
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.navigation, color: Colors.blue, size: 24),
        ),
      ),
    );
  }

  void _updateRoutePolylines() {
    List<LatLng> pointsTraveled = _routePoints.sublist(0, _simulationStep + 1);
    
    _polylines
      ..clear()
      ..add(
        Polyline(
          points: _routePoints,
          color: Colors.orange.shade800,
          strokeWidth: 4.0,
        ),
      )
      ..add(
        Polyline(
          points: pointsTraveled,
          color: Colors.blue.withOpacity(0.4),
          strokeWidth: 5.0,
        ),
      );
  }

  void _focusCameraOnShipper() {
    if (_currentShipperPosition == null) return;
    _mapController.move(_currentShipperPosition!, 16.0); // Zoom gần để giống màn hình dẫn đường (Navigation)
  }


  @override
  Widget build(BuildContext context) {
    if (widget.order.status != 'delivering') {
      return const Scaffold(); 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dẫn đường (OSRM API)"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _focusCameraOnShipper,
            tooltip: "Vị trí của tôi",
          ),
        ],
      ),
      body: _isLoadingRoute 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange.shade800),
                const SizedBox(height: 16),
                Text("Đang tải dữ liệu đường đi từ máy chủ OSRM...", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
        : Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _routePoints[0],
                  initialZoom: 16.0,
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
              
              // Card thông tin nổi (ETA, Khoảng cách)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Quãng đường:", style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              _distanceText, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Thời gian dự kiến (ETA):", style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              _etaText, 
                              style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Đến: ${widget.order.deliveryAddress}", 
                                maxLines: 2, 
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              )
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