import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_orders.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/preference_service.dart';
import 'create_order_screen.dart';
import 'customer_order_detail_screen.dart';
import 'profile_screen.dart';
import '../login_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final String currentUserId = 'KH-001';
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final u = await PreferenceService.getUser();
    await PreferenceService.getOrders();
    if (!mounted) return;
    setState(() {
      _user = u;
    });
  }

  List<OrderModel> get _userOrders {
    if (_user == null) return mockOrders;
    final userEmail = _user!.email.trim().toLowerCase();
    final userPhone = _user!.phone.trim();

    return mockOrders.where((o) {
      final maKH = o.maKH.trim().toLowerCase();
      if (userEmail.isNotEmpty && maKH == userEmail) return true;
      if (userPhone.isNotEmpty && (maKH == userPhone || o.senderPhone.trim() == userPhone)) return true;
      // Default demo accounts fallback
      if (userEmail == 'customer@goship.vn' && (maKH == 'kh-001' || maKH == 'khachhang')) return true;
      return false;
    }).toList();
  }

  int get _totalOrders => _userOrders.length;
  int get _deliveringOrders => _userOrders.where((o) => o.trangThaiDon == 'Đang giao').length;
  int get _completedOrders => _userOrders.where((o) => o.trangThaiDon == 'Đã giao').length;

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openCreateOrderScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
    );
    if (result == true || result == null) {
      _loadUser();
      setState(() {});
    }
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Chờ phân công':
        color = Colors.orange;
        break;
      case 'Chờ giao':
        color = Colors.blue;
        break;
      case 'Đang giao':
        color = Colors.green;
        break;
      case 'Đã giao':
        color = Colors.teal;
        break;
      case 'Đã hủy':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;
    final userOrders = _userOrders;
    final userName = _user?.fullName.isNotEmpty == true ? _user!.fullName : 'Mina';

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
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadUser();
            },
            tooltip: "Hồ sơ cá nhân",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUser();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner chào mừng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                    Text(
                      "Xin chào, $userName!",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Giao hàng nhanh chóng - An toàn - Tiết kiệm",
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _openCreateOrderScreen,
                        icon: const Icon(Icons.add_circle, color: Colors.orange),
                        label: const Text(
                          "ĐẶT ĐƠN VẬN CHUYỂN MỚI",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Thống kê tổng quan đơn hàng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildStatCard("TỔNG ĐƠN", "$_totalOrders", Colors.blue, Icons.inventory_2),
                    const SizedBox(width: 10),
                    _buildStatCard("ĐANG GIAO", "$_deliveringOrders", Colors.orange, Icons.local_shipping),
                    const SizedBox(width: 10),
                    _buildStatCard("HOÀN THÀNH", "$_completedOrders", Colors.green, Icons.task_alt),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Danh sách đơn hàng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Danh sách đơn hàng", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        _loadUser();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (userOrders.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("Bạn chưa có đơn hàng nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openCreateOrderScreen,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text("Tạo đơn ngay", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: userOrders.length,
                  itemBuilder: (context, index) {
                    final order = userOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerOrderDetailScreen(order: order),
                            ),
                          );
                          _loadUser();
                          setState(() {});
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade50,
                          child: Icon(
                            order.trangThaiDon == 'Đang giao'
                                ? Icons.directions_bike
                                : order.trangThaiDon == 'Đã giao'
                                    ? Icons.done_all
                                    : order.trangThaiDon == 'Đã hủy'
                                        ? Icons.cancel
                                        : Icons.access_time,
                            color: primaryColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            _buildStatusChip(order.trangThaiDon),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Nhận: ${order.tenNguoiNhan} - ${order.sdtNguoiNhan}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('Đến: ${order.diaChiGiao}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tiền thu COD: ${currencyFormatter.format(order.phiShip > 0 ? order.phiShip : 25000.0)}',
                                  style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
