import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class ShipperRouteScreen extends StatelessWidget {
  final OrderModel order;
  const ShipperRouteScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Validate BR_viewRoute_01 / MSG_VR_04: Chỉ xem được khi đang giao
    if (order.status != 'delivering') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chức năng xem tuyến đường chỉ khả dụng khi đơn ở trạng thái Đang giao.")), // MSG_VR_04
        );
        Navigator.pop(context);
      });
      return const Scaffold(); 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bản đồ tuyến đường"),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Stack(
        children: [
          // Giao diện mô phỏng Open Street Maps tĩnh
          Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 100, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Mô phỏng Bản đồ Tuyến đường", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  // Nút giả lập đi sai tuyến đường để test MSG_VR_01
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã cập nhật lại tuyến đường tối ưu."), backgroundColor: Colors.blue), // MSG_VR_01
                      );
                    },
                    child: const Text("Giả lập đi sai tuyến (Tính lại)"),
                  )
                ],
              ),
            ),
          ),
          
          // Card thông tin nổi (ETA, Khoảng cách)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Thời gian dự kiến (ETA):", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("15 phút", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(child: Text(order.deliveryAddress, maxLines: 2, overflow: TextOverflow.ellipsis)),
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