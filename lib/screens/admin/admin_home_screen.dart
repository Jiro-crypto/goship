import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_dispatchers.dart';
import '../../data/mock_orders.dart';
import '../../data/mock_shippers.dart';
import '../../models/dispatcher_model.dart';
import '../../models/order_model.dart';
import '../../models/shipper_model.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_map_monitor_screen.dart';
import 'admin_shipper_list_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color primaryColor = Colors.orange.shade800;

  // Track ngày hiện tại để reset BR_assignOrder_06
  final String currentDate =
      DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Chờ phân công (pending), Đang giao (delivering),
    //         Đã giao (delivered), Đã hủy (cancelled)
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================
  // AUTH
  // ===========================
  void _logout() async {
    final dispatcher = MockDispatchers.getCurrentDispatcher();
    dispatcher.isOnline = false;
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
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              const SizedBox(height: 10),
              // Alternative Flow MSG_AS_02
              if (activeShippers.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Hiện không có Shipper nào ở trạng thái hoạt động. "
                    "Vui lòng thử lại sau.",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: null, // BR_assignOrder_07: Disable
                  child: const Text("XÁC NHẬN PHÂN CÔNG"),
                )
              ] else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeShippers.length,
                    itemBuilder: (context, index) {
                      final shipper = activeShippers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: const Icon(Icons.motorcycle,
                              color: Colors.orange),
                        ),
                        title: Text(shipper.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Cách điểm lấy: ${shipper.distance} km"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
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
    final dispatcher = MockDispatchers.getCurrentDispatcher();

    setState(() {
      // BR_assignOrder_05: Đổi trạng thái tự động
      order.status = "delivering";
      order.maShipperAssigned = shipper.id;
      order.maDPVAssigned = dispatcher.maDPV;
      order.thoiGianPhanCong = DateTime.now();
      // BR_assignOrder_06: tracking cho DPV
      dispatcher.soDonDaPhanCongTrongNgay++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Phân công đơn cho ${shipper.name} thành công. Đã gửi thông báo đến Shipper (MSG_AS_01)."),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  // ===========================================================================
  // CHỨC NĂNG 2: HỦY ĐƠN ĐẶT GIAO HÀNG (UC013) – yêu cầu lý do bắt buộc
  // ===========================================================================
  void _showCancelDialog(OrderModel order) {
    if (order.status == "delivered") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Không thể hủy đơn hàng đã giao thành công. (MS_CancelDelivery_03)"),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();
    String selectedReason = "Khách hàng yêu cầu hủy";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text("Xác nhận hủy đơn",
              style: TextStyle(color: Colors.red)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chọn lý do hủy (BR_cancelByAdmin_01 - bắt buộc):"),
                const SizedBox(height: 8),
                ...[
                  "Khách hàng yêu cầu hủy",
                  "Địa chỉ không hợp lệ",
                  "Không có shipper nhận đơn",
                  "Phát hiện gian lận",
                  "Lý do khác"
                ].map((r) => RadioListTile<String>(
                      dense: true,
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      value: r,
                      groupValue: selectedReason,
                      onChanged: (v) =>
                          setDialog(() => selectedReason = v ?? selectedReason),
                    )),
                if (selectedReason == "Lý do khác")
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: "Nhập lý do cụ thể...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Không",
                    style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                final finalReason = selectedReason == "Lý do khác"
                    ? reasonController.text.trim()
                    : selectedReason;
                if (finalReason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng nhập lý do hủy đơn!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _processCancelOrder(order, finalReason);
              },
              child: const Text("Xác nhận hủy",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _processCancelOrder(OrderModel order, String reason) {
    if (order.status == "delivering") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Đơn hàng đang được giao – hệ thống đã gửi thông báo hủy tới Shipper! (MS_CancelDelivery_02)"),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }

    setState(() {
      order.status = "cancelled";
      order.lyDoHuy = reason;
      order.nguoiHuy = "ADMIN";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("Đã hủy đơn ${order.id}. Lý do: $reason (MC_CancelDelivery_04)"),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ===========================================================================
  // DRAWER
  // ===========================================================================
  Drawer _buildDrawer() {
    final DispatcherModel dpv = MockDispatchers.getCurrentDispatcher();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            accountName: Text(
              dpv.tenDPV,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("${dpv.email} • ${dpv.maDPV}"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  color: Colors.orange, size: 40),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: primaryColor),
            title: const Text("Dashboard thống kê"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: primaryColor),
            title: const Text("Giám sát Shipper (Bản đồ)"),
            subtitle: const Text("UC02 - Realtime"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminMapMonitorScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people, color: primaryColor),
            title: const Text("Quản lý Shipper"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminShipperListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: Text("Khu vực: ${dpv.khuVucQuanLy}"),
            subtitle: Text(dpv.caLamViec),
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in, color: primaryColor),
            title: Text(
                "Đã phân công hôm nay: ${dpv.soDonDaPhanCongTrongNgay} đơn"),
            subtitle: const Text("BR_assignOrder_06"),
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(Icons.circle,
                color: dpv.isOnline ? Colors.green : Colors.grey),
            title: const Text("Trạng thái Online"),
            subtitle:
                Text(dpv.isOnline ? "Đang trong ca" : "Ngoài giờ làm"),
            value: dpv.isOnline,
            activeColor: primaryColor,
            onChanged: (v) {
              setState(() => dpv.isOnline = v);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất",
                style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI BUILDING BLOCKS
  // ===========================================================================
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
      case "pending_acceptance":
        return Colors.orange.shade700;
      case "delivering":
        return Colors.blue.shade700;
      case "delivered":
        return Colors.green.shade700;
      case "cancelled":
        return Colors.red.shade700;
      case "failed":
        return Colors.deepOrange.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "pending":                  return "Chờ phân công";
      case "pending_acceptance":       return "Chờ Shipper nhận";
      case "waiting_delivery":         return "Chờ giao";
      case "delivering":               return "Đang giao";
      case "delivered":                return "Đã giao";
      case "cancelled":                return "Đã hủy";
      case "failed":                   return "Giao thất bại";
      default:                         return "Không rõ";
    }
  }

  Widget _buildOrderList(String filterStatus) {
    List<OrderModel> filteredList = MockOrders.orders;
    if (filterStatus != "all") {
      filteredList = MockOrders.orders
          .where((o) => o.status == filterStatus)
          .toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("Không có đơn hàng nào",
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final order = filteredList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Mã đơn: ${order.id}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status)
                              .withOpacity(0.15),
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

                  // Hiển thị Shipper được phân công
                  if (order.maShipperAssigned != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.assignment_ind,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text("Đã giao cho: ${order.maShipperAssigned}",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12)),
                      ],
                    ),
                  ],

                  // Hiển thị lý do hủy nếu đã huỷ
                  if (order.status == "cancelled" &&
                      order.lyDoHuy != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.cancel, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Lý do hủy: ${order.lyDoHuy}",
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Điểm lấy & điểm giao
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.store,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text("Lấy: ${order.pickupAddress}",
                              style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text("Giao: ${order.deliveryAddress}",
                              style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Phí ship: ${currencyFormatter.format(order.deliveryFee)}",
                    style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      if (order.status == "pending") ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showAssignBottomSheet(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.assignment_ind, size: 18),
                            label: const Text("PHÂN CÔNG"),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (order.status == "pending" ||
                          order.status == "delivering")
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(order),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text("Trang Điều Phối Viên",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            tooltip: "Giám sát Shipper (UC02)",
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminMapMonitorScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Làm mới",
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Đăng xuất",
            onPressed: _logout,
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.refresh),
        label: const Text("Reload"),
        onPressed: () => setState(() {}),
      ),
    );
  }
}
