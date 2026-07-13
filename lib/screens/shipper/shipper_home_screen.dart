import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../data/mock_orders.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';
import 'shipper_order_detail_screen.dart';

// Biến toàn cục để giả lập đếm số lần từ chối trong ngày (BR_cancelByShipper_02)
int demoDailyRejectCount = 0;

class ShipperHomeScreen extends StatefulWidget {
  const ShipperHomeScreen({super.key});

  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color primaryColor = Colors.orange.shade800;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _refreshScreen() {
    setState(() {}); 
  }

  void _simulateIncomingOrder() {
    final newOrder = OrderModel(
      id: "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      senderName: "Kho tổng LogiRoute",
      senderPhone: "19001234",
      receiverName: "Nguyễn Văn Khách",
      receiverPhone: "0909123456",
      pickupAddress: "123 Đường Lấy Hàng, Quận 1, TP.HCM",
      deliveryAddress: "456 Đường Giao, Quận 7, TP.HCM",
      price: 350000.0,
      deliveryFee: 15000.0,
      status: "pending_acceptance",
      pickupLatitude: 10.7769,
      pickupLongitude: 106.7009,
      deliveryLatitude: 10.7300,
      deliveryLongitude: 106.7200,
    );

    setState(() {
      MockOrders.orders.insert(0, newOrder);
      _tabController.animateTo(0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bạn có 1 đơn hàng mới vừa được phân công"),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // HÀM HIỂN THỊ TRẠNG THÁI (UI Badge)
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending_acceptance': color = Colors.orange; text = "Chờ nhận"; break;
      case 'waiting_delivery': color = Colors.blue; text = "Chờ giao"; break;
      case 'delivering': color = Colors.cyan.shade700; text = "Đang giao"; break;
      case 'delivered': color = Colors.green; text = "Đã giao"; break;
      case 'failed': color = Colors.deepOrange; text = "Giao thất bại"; break;
      case 'cancelled': color = Colors.grey.shade600; text = "Đã bị hủy"; break;
      default: color = Colors.black; text = "Không rõ";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildOrderList(String filterStatus) {
    // Lịch sử sẽ gộp cả 3 trạng thái: Đã giao, Giao thất bại, Đã bị hủy
    List<OrderModel> filteredList = MockOrders.orders.where((o) {
      if (filterStatus == 'history') {
        return o.status == 'delivered' || o.status == 'failed' || o.status == 'cancelled';
      }
      return o.status == filterStatus;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("Không có đơn hàng nào.", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final order = filteredList[index];

        if (order.status == 'pending_acceptance') {
          return OrderAcceptanceCard(
            order: order,
            onRefresh: _refreshScreen,
          );
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mã đơn: ${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusBadge(order.status), // Gọi hàm hiển thị Status
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text("📍 Lấy: ${order.pickupAddress}"),
                Text("🚚 Giao: ${order.deliveryAddress}"),
                const SizedBox(height: 8),
                Text(
                  "Tiền COD: ${currencyFormatter.format(order.price)}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShipperOrderDetailScreen(order: order)),
              );
              _refreshScreen(); 
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GoShip Shipper", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), // Đổi màu icon đăng xuất thành trắng
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white, 
          unselectedLabelColor: Colors.white70, 
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Đơn mới"),
            Tab(text: "Chờ giao"),
            Tab(text: "Đang giao"),
            Tab(text: "Lịch sử"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("pending_acceptance"),
          _buildOrderList("waiting_delivery"),   
          _buildOrderList("delivering"),         
          _buildOrderList("history"), // Thay vì chỉ 'delivered', ta dùng 'history'
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateIncomingOrder,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_alert),
        label: const Text("Demo nhận đơn"),
      ),
    );
  }
}

// ============================================================================
// COMPONENT: Card Đếm Ngược 60s & Form Từ chối (UC014)
// ============================================================================
class OrderAcceptanceCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onRefresh;

  const OrderAcceptanceCard({super.key, required this.order, required this.onRefresh});

  @override
  State<OrderAcceptanceCard> createState() => _OrderAcceptanceCardState();
}

class _OrderAcceptanceCardState extends State<OrderAcceptanceCard> {
  int _timeLeft = 60; // Set lại thành 60 giây như yêu cầu
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _autoAcceptOrder();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _acceptOrder() {
    _timer?.cancel();
    widget.order.status = "waiting_delivery";
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Xác nhận tiếp nhận đơn hàng thành công."), backgroundColor: Colors.green),
    );
    widget.onRefresh();
  }

  void _autoAcceptOrder() {
    widget.order.status = "waiting_delivery";
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã quá 1 phút, đơn hàng đã được tự động nhận."), backgroundColor: Colors.orange),
    );
    widget.onRefresh();
  }

  // Luồng xử lý TỪ CHỐI ĐƠN HÀNG (UC014)
  void _showRejectDialog() {
    // BR_cancelByShipper_02: Giới hạn tối đa 3 đơn/ngày
    if (demoDailyRejectCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể từ chối vì bạn đã từ chối quá 3 lần trong ngày hôm nay!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedReason = "Xe hỏng / Gặp tai nạn";
    TextEditingController otherReasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder( // Để setState hoạt động bên trong Dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Xác nhận từ chối?"), // MS_DeniedOrder_01
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Vui lòng chọn lý do từ chối đơn hàng này:"),
                  RadioListTile(
                    title: const Text("Xe hỏng / Gặp tai nạn"),
                    value: "Xe hỏng / Gặp tai nạn",
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Khu vực đang bị phong tỏa/Ngập lụt"),
                    value: "Khu vực đang bị phong tỏa/Ngập lụt",
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Lý do khác"),
                    value: "Lý do khác",
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val.toString()),
                  ),
                  if (selectedReason == "Lý do khác")
                    TextField(
                      controller: otherReasonController,
                      decoration: const InputDecoration(
                        hintText: "Nhập lý do cụ thể...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Đóng dialog, đếm ngược vẫn chạy
                  child: const Text("HỦY BỎ", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // BR_cancelByShipper_01: Bắt buộc nhập lý do
                    if (selectedReason == "Lý do khác" && otherReasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập lý do cụ thể!"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
                    Navigator.pop(context); // Đóng Dialog
                    _timer?.cancel(); // Dừng bộ đếm
                    demoDailyRejectCount++; // Tăng biến đếm

                    widget.order.status = "cancelled"; 
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đơn hàng bạn giao đã bị shipper từ chối. Đã từ chối $demoDailyRejectCount/3 lần."), backgroundColor: Colors.red),
                    );
                    widget.onRefresh();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("GỬI LÝ DO", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.orange.shade300, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ĐƠN HÀNG MỚI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                  child: Text("00:${_timeLeft.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Lấy: ${widget.order.pickupAddress}", maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text("Giao: ${widget.order.deliveryAddress}", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text("${widget.order.price} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            ),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _showRejectDialog, child: const Text("TỪ CHỐI", style: TextStyle(color: Colors.red)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _acceptOrder, child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white)))),
              ],
            )
          ],
        ),
      ),
    );
  }
}