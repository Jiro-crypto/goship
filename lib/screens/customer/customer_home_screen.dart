import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/order_repository.dart';
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
  late String _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthRepository().getCurrentUid() ?? '';
  }

  void _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openCreateOrderScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
    );
    // StreamBuilder tự động làm mới
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.waitingForAssignment:
      case OrderStatus.waitingForAcceptance:
      case OrderStatus.waitingForPickup:
        color = Colors.orange;
        break;
      case OrderStatus.delivering:
        color = Colors.blue;
        break;
      case OrderStatus.delivered:
        color = Colors.teal;
        break;
      case OrderStatus.deliveryFailed:
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    if (_currentUid.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Bạn chưa đăng nhập."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                child: const Text("Về trang Đăng nhập"),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<CustomerModel?>(
      stream: CustomerRepository().watchCustomer(_currentUid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData && userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = userSnapshot.data;
        final userName = user?.name.isNotEmpty == true ? user!.name : 'Khách hàng';

        return StreamBuilder<List<OrderModel>>(
          stream: OrderRepository().getOrdersByCustomer(_currentUid),
          builder: (context, ordersSnapshot) {
            final userOrders = ordersSnapshot.data ?? [];
            
            final totalOrders = userOrders.length;
            final deliveringOrders = userOrders.where((o) => o.status == OrderStatus.delivering).length;
            final completedOrders = userOrders.where((o) => o.status == OrderStatus.delivered).length;

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
              body: SingleChildScrollView(
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
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
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
                          _buildStatCard("TỔNG ĐƠN", "$totalOrders", Colors.blue, Icons.inventory_2),
                          const SizedBox(width: 10),
                          _buildStatCard("ĐANG GIAO", "$deliveringOrders", Colors.orange, Icons.local_shipping),
                          const SizedBox(width: 10),
                          _buildStatCard("HOÀN THÀNH", "$completedOrders", Colors.green, Icons.task_alt),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Danh sách đơn hàng
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text("Danh sách đơn hàng", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

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
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade50,
                                child: Icon(
                                  order.status == OrderStatus.delivering
                                      ? Icons.directions_bike
                                      : order.status == OrderStatus.delivered
                                          ? Icons.done_all
                                          : order.status == OrderStatus.cancelled
                                              ? Icons.cancel
                                              : Icons.access_time,
                                  color: primaryColor,
                                ),
                              ),
                              title: Row(
                                  children: [
                                    Expanded( // 1. Bọc Text trong Expanded để giới hạn chiều ngang
                                      child: Text(
                                        order.orderId, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis, // 2. Thêm dấu '...' nếu ID quá dài
                                      ),
                                    ),
                                    const SizedBox(width: 8), // 3. Thay Spacer() bằng SizedBox để tạo khoảng cách nhỏ gọn
                                    _buildStatusChip(order.status),
                                  ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Nhận: ${order.receiverName} - ${order.receiverPhone}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Đến: ${order.deliveryAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Phí ship: ${currencyFormatter.format(order.shippingFee)}',
                                        style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                      if (order.codAmount > 0)
                                        Text(
                                          'COD: ${currencyFormatter.format(order.codAmount)}',
                                          style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.bold),
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
            );
          }
        );
      }
    );
  }
}
