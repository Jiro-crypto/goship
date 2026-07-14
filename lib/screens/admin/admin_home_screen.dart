import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_orders.dart';
import '../../data/mock_shippers.dart';
import '../../models/order_model.dart';
import '../../models/shipper_model.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color primaryColor = Colors.orange.shade800;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Chờ phân công (pending), Đang giao (delivering), Đã giao (delivered), Đã hủy (cancelled)
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

  // ===========================================================================
  // CHỨC NĂNG 1: PHÂN CÔNG ĐƠN HÀNG (UC01)
  // ===========================================================================
  void _showAssignBottomSheet(OrderModel order) {
    List<ShipperModel> activeShippers = MockShippers.getActiveShippers();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chọn Shipper Phân Công",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 10),
              // Alternative Flow: Không còn Shipper Active (MSG_AS_02)
              if (activeShippers.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Hiện không có Shipper nào ở trạng thái hoạt động. Vui lòng thử lại sau.", // MSG_AS_02
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: null, // Nút bị Disable theo rule
                  child: const Text("XÁC NHẬN PHÂN CÔNG"),
                )
              ] else ...[
                // Main Flow: Hiển thị danh sách Shipper Active
                Expanded(
                  child: ListView.builder(
                    itemCount: activeShippers.length,
                    itemBuilder: (context, index) {
                      final shipper = activeShippers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: const Icon(Icons.motorcycle, color: Colors.orange),
                        ),
                        title: Text(shipper.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Cách điểm lấy: ${shipper.distance} km"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx); // Đóng Bottom Sheet
                            _confirmAssignShipper(order, shipper);
                          },
                          child: const Text("Chọn"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmAssignShipper(OrderModel order, ShipperModel shipper) {
    setState(() {
      order.status = "delivering"; // BR_assignOrder_05: Đổi trạng thái tự động
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Phân công đơn cho ${shipper.name} thành công. Đã gửi thông báo đến Shipper."), // MSG_AS_01
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  // ===========================================================================
  // CHỨC NĂNG 2: HỦY ĐƠN ĐẶT GIAO HÀNG (UC013)
  // ===========================================================================
  void _showCancelDialog(OrderModel order) {
    // Error Situation: Đơn đã giao (Thành công) thì không được hủy
    if (order.status == "delivered") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Không thể hủy đơn hàng đã giao thành công."), // MS_CancelDelivery_03
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Hiển thị MS_CancelDelivery_01
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy đơn", style: TextStyle(color: Colors.red)),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này khỏi hệ thống không? Khách hàng sẽ nhận được thông báo hủy."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Không", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _processCancelOrder(order);
            },
            child: const Text("Xác nhận hủy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processCancelOrder(OrderModel order) {
    // Alternative Flow: Hủy khi đơn Đang giao
    if (order.status == "delivering") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Đơn hàng đang được giao, hệ thống đã gửi thông báo hủy tới Shipper!"), // MS_CancelDelivery_02
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }

    setState(() {
      order.status = "cancelled"; // Cập nhật trạng thái thành Đã Hủy
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Đã hủy đơn thành công. Đơn được gỡ khỏi luồng phân công."), // MS_CancelDelivery_04 / MSG_AS_05
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ===========================================================================
  // GIAO DIỆN (UI) THÀNH PHẦN
  // ===========================================================================
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending": return Colors.orange.shade700;
      case "delivering": return Colors.blue.shade700;
      case "delivered": return Colors.green.shade700;
      case "cancelled": return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "pending": return "Chờ phân công";
      case "delivering": return "Đang giao";
      case "delivered": return "Đã giao";
      case "cancelled": return "Đã hủy";
      default: return "Không rõ";
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
            Text("Không có đơn hàng nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mã đơn: ${order.id}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                // Thông tin địa chỉ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.store, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Lấy: ${order.pickupAddress}", style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Giao: ${order.deliveryAddress}", style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Nút hành động cho Điều phối viên
                Row(
                  children: [
                    // Nút phân công (Chỉ hiện khi đơn chờ phân công)
                    if (order.status == "pending") ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAssignBottomSheet(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.assignment_ind, size: 18),
                          label: const Text("PHÂN CÔNG"),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    
                    // Nút Hủy (Chỉ hiện khi Đang giao hoặc Chờ phân công)
                    if (order.status == "pending" || order.status == "delivering")
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(order),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text("HỦY ĐƠN"),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Điều Phối Viên", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          isScrollable: true,
          tabs: const [
            Tab(text: "Chờ phân công"),
            Tab(text: "Đang giao"),
            Tab(text: "Đã giao"),
            Tab(text: "Đã hủy"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("pending"),
          _buildOrderList("delivering"),
          _buildOrderList("delivered"),
          _buildOrderList("cancelled"),
        ],
      ),
    );
  }
}