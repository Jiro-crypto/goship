import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_orders.dart';
import '../models/order_model.dart';
import '../services/location_service.dart';
import 'order_detail_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    // 1. Xin quyền định vị GPS
    bool hasPermission = await LocationService.handlePermission();
    if (!hasPermission) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text("Cần quyền vị trí"),
            ],
          ),
          content: const Text(
            "Ứng dụng giao hàng cần quyền truy cập vị trí GPS chính xác để định vị và dẫn đường cho bạn. Vui lòng cấp quyền trong cài đặt thiết bị.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đồng ý"),
            )
          ],
        ),
      );
      return;
    }

    // 2. Chuyển trạng thái đơn thành 'delivering'
    setState(() {
      order.status = "delivering";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã nhận đơn hàng ${order.id}! Bắt đầu định vị Shipper..."),
        backgroundColor: Colors.orange.shade800,
      ),
    );

    // 3. Chuyển sang màn hình chi tiết đơn
    _navigateToDetail(order);
  }

  void _navigateToDetail(OrderModel order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
    // Reload state khi quay lại để cập nhật trạng thái đơn (nếu có đổi thành delivered)
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange.shade700;
      case "delivering":
        return Colors.blue.shade700;
      case "delivered":
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "pending":
        return "Đang chờ";
      case "delivering":
        return "Đang giao";
      case "delivered":
        return "Đã giao";
      default:
        return "Không rõ";
    }
  }

  Widget _buildOrderList(String filterStatus) {
    List<OrderModel> filteredList = MockOrders.orders;
    if (filterStatus != "all") {
      filteredList = MockOrders.orders.where((o) => o.status == filterStatus).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Không có đơn hàng nào",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final order = filteredList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToDetail(order),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mã đơn: ${order.id}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Địa chỉ lấy hàng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.store, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Lấy: ${order.pickupAddress}",
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Địa chỉ giao hàng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Giao: ${order.deliveryAddress}",
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Giá trị & Phí ship
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Phí giao hàng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            currencyFormatter.format(order.deliveryFee),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Tiền thu hộ (COD)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            currencyFormatter.format(order.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Nút hành động nếu đơn đang ở trạng thái pending
                  if (order.status == "pending") ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptOrder(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          "NHẬN ĐƠN HÀNG",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GoShip Shipper",
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          isScrollable: true,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Đang chờ"),
            Tab(text: "Đang giao"),
            Tab(text: "Đã giao"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("all"),
          _buildOrderList("pending"),
          _buildOrderList("delivering"),
          _buildOrderList("delivered"),
        ],
      ),
    );
  }
}
