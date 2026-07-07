import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_orders.dart';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // Các địa chỉ mặc định để Khách hàng chọn đặt hàng nhanh
  String selectedShop = "Gong Cha Hồ Tùng Mậu";
  String selectedReceiverAddress = "252 Lê Văn Sỹ, Phường 1, Quận 3, TP. HCM";

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _placeNewOrder() {
    // Kế thừa đơn hàng số 1 trong mock data để làm đơn đang giao
    final order = MockOrders.orders[0];
    
    setState(() {
      order.status = "delivering"; // Bắt đầu giao đơn
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đặt hàng thành công! Mã đơn: ${order.id}. Đang kết nối Shipper..."),
        backgroundColor: Colors.green.shade800,
      ),
    );

    // Chuyển thẳng tới màn hình theo dõi vị trí Shipper
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(order: order),
      ),
    ).then((_) {
      // Reload lại giao diện khi quay về
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "GoShip Khách Hàng",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Banner chào mừng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Xin chào, Khách Hàng!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hôm nay bạn muốn giao hàng đi đâu?",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Các dịch vụ giao hàng chính (Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dịch vụ của chúng tôi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildServiceItem(
                        icon: Icons.flatware,
                        label: "Giao Đồ Ăn",
                        color: Colors.red.shade100,
                        iconColor: Colors.red.shade800,
                      ),
                      _buildServiceItem(
                        icon: Icons.local_shipping,
                        label: "Giao Siêu Tốc",
                        color: Colors.orange.shade100,
                        iconColor: Colors.orange.shade800,
                      ),
                      _buildServiceItem(
                        icon: Icons.shopping_bag,
                        label: "Đi Chợ Hộ",
                        color: Colors.green.shade100,
                        iconColor: Colors.green.shade800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. Form đặt đơn hàng nhanh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          "Đặt Đơn Giao Hàng Nhanh (Demo)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Điểm lấy hàng
                    TextFormField(
                      initialValue: selectedShop,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Cửa hàng lấy hàng",
                        prefixIcon: const Icon(Icons.store, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Điểm giao hàng
                    TextFormField(
                      initialValue: selectedReceiverAddress,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Địa chỉ nhận của bạn (TP. HCM)",
                        prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nút bấm đặt đơn
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _placeNewOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ĐẶT GIAO HÀNG NGAY",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 4. Lịch sử / Danh sách đơn hàng hiện tại
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Đơn hàng hiện tại",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...MockOrders.orders.map((order) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(order: order),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: order.status == "delivering"
                                ? Colors.blue.shade50
                                : order.status == "delivered"
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            order.status == "delivering"
                                ? Icons.directions_bike
                                : order.status == "delivered"
                                    ? Icons.done_all
                                    : Icons.access_time,
                            color: order.status == "delivering"
                                ? Colors.blue.shade800
                                : order.status == "delivered"
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                          ),
                        ),
                        title: Text(
                          "Đơn hàng ${order.id}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          order.status == "delivering"
                              ? "Shipper đang giao hàng"
                              : order.status == "delivered"
                                  ? "Đã giao thành công"
                                  : "Đang tìm Shipper...",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
