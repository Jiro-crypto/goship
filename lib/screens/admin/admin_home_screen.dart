import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../models/shipper_model.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';
import 'admin_order_detail_screen.dart';
import 'admin_shipper_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_shipper_tracking_screen.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/shipper_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color primaryColor = Colors.orange.shade800;

  int _currentIndex = 0;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
  // CHỨC NĂNG 1: PHÂN CÔNG ĐƠN HÀNG
  // ===========================================================================
  void _showAssignBottomSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<List<ShipperModel>>(
              stream: ShipperRepository().watchActiveShippers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeShippers = snapshot.data!;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Chọn Shipper Phân Công",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "Đơn: ${order.orderId}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    if (activeShippers.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmAssignShipper(order, activeShippers.first);
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(
                            "Gợi ý nhanh: ${activeShippers.first.name}",
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(),
                    if (activeShippers.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 60,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Hiện không có Shipper nào đang Online. Vui lòng thử lại sau.",
                              style: TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: activeShippers.length,
                          itemBuilder: (context, index) {
                            final shipper = activeShippers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      primaryColor.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.motorcycle,
                                    color: Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  shipper.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text("📞 ${shipper.phone}"),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              }
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAssignShipper(OrderModel order, ShipperModel shipper) async {
    try {
      final dispatcherId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_dispatcher';

      await OrderRepository().assignOrderToShipper(
        orderId: order.orderId,
        // Ưu tiên dùng uid (document ID thực tế trên Firestore)
        shipperId: shipper.uid.isNotEmpty ? shipper.uid : shipper.shipperId,
        dispatcherId: dispatcherId,
        // Truyền thẳng thông tin shipper — không cần đọc lại Firestore
        shipperName: shipper.name,
        shipperPhone: shipper.phone,
        shipperLicensePlate: shipper.licensePlate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Phân công đơn cho ${shipper.name} thành công. Chờ tài xế xác nhận."),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi phân công: $e"), backgroundColor: Colors.red),
      );
    }
  }


  // ===========================================================================
  // CHỨC NĂNG 2: HỦY ĐƠN
  // ===========================================================================
  void _showCancelDialog(OrderModel order) {
    if (order.status == OrderStatus.delivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Không thể hủy đơn hàng đã giao thành công."),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy đơn", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bạn có chắc chắn muốn hủy đơn hàng này không? Vui lòng nhập lý do hủy:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Nhập lý do hủy đơn...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Không", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập lý do hủy đơn!")),
                );
                return;
              }
              Navigator.pop(ctx);
              _processCancelOrder(order, reasonController.text.trim());
            },
            child: const Text("Xác nhận hủy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processCancelOrder(OrderModel order, String reason) async {
    if (order.status == OrderStatus.delivering) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Đơn hàng đang được giao, hệ thống sẽ báo ngay tới Shipper!"),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }

    try {
      await OrderRepository().cancelOrderByDispatcher(
        orderId: order.orderId,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Đã hủy đơn thành công."),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi hủy đơn: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ===========================================================================
  // UI HELPERS (Dùng Enum Status)
  // ===========================================================================
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingForAssignment:
        return Colors.orange.shade700;
      case OrderStatus.waitingForAcceptance:
      case OrderStatus.waitingForPickup:
      case OrderStatus.delivering:
        return Colors.blue.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
      case OrderStatus.deliveryFailed:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderList(List<OrderStatus> validStatuses) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderRepository().getOrdersByStatuses(validStatuses),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Đã có data là List<OrderModel> từ Repository
        List<OrderModel> orders = snapshot.data!;
        // Sắp xếp giảm dần theo thời gian tạo trong Ram
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Thanh Tìm kiếm (Search by ID, Phone, Name...)
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          orders = orders.where((o) {
            return o.orderId.toLowerCase().contains(q) ||
                o.receiverName.toLowerCase().contains(q) ||
                o.receiverPhone.toLowerCase().contains(q) ||
                o.deliveryAddress.toLowerCase().contains(q);
          }).toList();
        }

        if (orders.isEmpty) {
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index]);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOrderDetailScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mã đơn: ${order.orderId}",
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
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "🕒 ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    "${order.receiverName} - ${order.receiverPhone}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    "COD: ${currencyFormatter.format(order.codAmount)} | Phí: ${currencyFormatter.format(order.shippingFee)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (order.shipperId != null && order.shipperId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.motorcycle, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      "Shipper: ${order.shipperName ?? order.shipperId}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.status == OrderStatus.waitingForAssignment) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAssignBottomSheet(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.assignment_ind, size: 18),
                        label: const Text("PHÂN CÔNG"),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (order.status == OrderStatus.waitingForAssignment ||
                      order.status == OrderStatus.waitingForAcceptance ||
                      order.status == OrderStatus.waitingForPickup ||
                      order.status == OrderStatus.delivering)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text("HỦY ĐƠN"),
                      ),
                    ),
                  if (order.status == OrderStatus.delivered || 
                      order.status == OrderStatus.cancelled || 
                      order.status == OrderStatus.deliveryFailed)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminOrderDetailScreen(order: order),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text("XEM CHI TIẾT"),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Tìm theo mã đơn, tên khách, SĐT...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersPage() {
    return Column(
      children: [
        _buildSearchBar(),
        Container(
          color: primaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            isScrollable: true,
            tabs: const [
              Tab(text: "Chờ phân công"),
              Tab(text: "Đang xử lý/Giao"),
              Tab(text: "Đã giao"),
              Tab(text: "Đã hủy/Thất bại"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Đơn vừa được tạo, đang chờ Admin phân
              _buildOrderList([OrderStatus.waitingForAssignment]),
              
              // Tab 2: Admin đã phân nhưng Shipper chưa nhận, đang đến lấy, hoặc đang đi giao
              _buildOrderList([
                OrderStatus.waitingForAcceptance,
                OrderStatus.waitingForPickup,
                OrderStatus.delivering
              ]),
              
              // Tab 3: Giao thành công
              _buildOrderList([OrderStatus.delivered]),
              
              // Tab 4: Gộp các trường hợp gãy luồng
              _buildOrderList([OrderStatus.cancelled, OrderStatus.deliveryFailed]),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOrdersPage(),
      const AdminDashboardScreen(),
      const AdminShipperTrackingScreen(),
      const AdminShipperListScreen(),
    ];

    final titles = [
      "Trang Điều Phối Viên",
      "Thống kê Dashboard",
      "Theo dõi Shipper",
      "Quản lý Shipper",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Đơn hàng"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Thống kê"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Theo dõi"),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: "Shipper"),
        ],
      ),
    );
  }
}