import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/shipper_repository.dart';
import '../../services/preference_service.dart';
import '../login_screen.dart';
import 'shipper_order_detail_screen.dart';

class ShipperHomeScreen extends StatefulWidget {
  const ShipperHomeScreen({super.key});

  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color primaryColor = Colors.orange.shade800;

  // Lấy shipperId từ Firebase Auth
  String get _shipperId => FirebaseAuth.instance.currentUser?.uid ?? '';

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
    await AuthRepository().logout();
    await PreferenceService.clearLogin();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // HÀM HIỂN THỊ TRẠNG THÁI (UI Badge) - dùng OrderStatus.displayName
  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.waitingForAcceptance: color = Colors.orange; break;
      case OrderStatus.waitingForPickup: color = Colors.blue; break;
      case OrderStatus.delivering: color = Colors.cyan.shade700; break;
      case OrderStatus.delivered: color = Colors.green; break;
      case OrderStatus.deliveryFailed: color = Colors.deepOrange; break;
      case OrderStatus.cancelled: color = Colors.grey.shade600; break;
      default: color = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.displayName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildOrderList(String filterStatus) {
    // Xác định stream Firebase tương ứng với mỗi tab
    Stream<List<OrderModel>> stream;

    if (_shipperId.isEmpty) {
      // Demo mode (chưa đăng nhập Firebase): hiển thị đơn chờ nhận không có shipper
      stream = OrderRepository().getOrdersByStatus(OrderStatus.waitingForAcceptance);
    } else if (filterStatus == 'history') {
      // Lịch sử: lấy đơn của shipper này có trạng thái hoàn tất
      stream = OrderRepository().getOrdersByShipperHistory(_shipperId);
    } else {
      final statusMap = {
        'pending_acceptance': OrderStatus.waitingForAcceptance,
        'waiting_delivery': OrderStatus.waitingForPickup,
        'delivering': OrderStatus.delivering,
      };
      final orderStatus = statusMap[filterStatus];
      if (orderStatus != null) {
        stream = OrderRepository().getOrdersByShipper(_shipperId, status: orderStatus);
      } else {
        stream = OrderRepository().getOrdersByShipper(_shipperId);
      }
    }

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            if (order.status == OrderStatus.waitingForAcceptance) {
              return OrderAcceptanceCard(
                order: order,
                shipperId: _shipperId,
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
                    Expanded(
                      child: Text("Mã đơn: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    _buildStatusBadge(order.status),
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
                      "Tiền COD: ${currencyFormatter.format(order.codAmount)}",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ShipperOrderDetailScreen(order: order)),
                  );
                },
              ),
            );
          },
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
        iconTheme: const IconThemeData(color: Colors.white),
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
          _buildOrderList("history"),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENT: Card Đếm Ngược 600s & Form Từ chối (UC014)
// ============================================================================
class OrderAcceptanceCard extends StatefulWidget {
  final OrderModel order;
  final String shipperId;

  const OrderAcceptanceCard({
    super.key,
    required this.order,
    required this.shipperId,
  });

  @override
  State<OrderAcceptanceCard> createState() => _OrderAcceptanceCardState();
}

class _OrderAcceptanceCardState extends State<OrderAcceptanceCard> {
  // BR_receiveOrder: Đếm ngược 600 giây để Shipper tiếp nhận hoặc từ chối đơn hàng
  int _timeLeft = 600;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // UC03: Shipper nhận đơn → cập nhật Firebase
  void _acceptOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _timer?.cancel();

    try {
      await OrderRepository().acceptOrder(widget.order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận tiếp nhận đơn hàng thành công."), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi nhận đơn: $e"), backgroundColor: Colors.red),
      );
      setState(() => _isProcessing = false);
    }
  }

  // UC03: Timeout 600s → gọi handleOrderTimeout() trên Firebase
  void _handleTimeout() async {
    if (_isProcessing || widget.shipperId.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final autoAccepted = await OrderRepository().handleOrderTimeout(
        orderId: widget.order.orderId,
        shipperId: widget.shipperId,
        shipperName: widget.order.shipperName ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(autoAccepted
              ? "Đã quá 1 phút, đơn hàng đã được tự động nhận."
              : "Đã quá 1 phút, đơn hàng bị tự động từ chối (chưa đủ 3 lần hôm nay)."),
          backgroundColor: autoAccepted ? Colors.orange : Colors.red,
        ),
      );
    } catch (e) {
      // Xử lý lỗi âm thầm
    }
  }

  // UC17: Từ chối đơn hàng → rejectOrder() trên Firebase
  void _showRejectDialog() async {
    String selectedReason = "Xe hỏng / Gặp tai nạn";
    final TextEditingController otherReasonController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Xác nhận từ chối?"),
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("HỦY BỎ", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // BR_cancelByShipper_01: Bắt buộc nhập lý do nếu chọn 'Lý do khác'
                    if (selectedReason == "Lý do khác" && otherReasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập lý do cụ thể!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final finalReason = selectedReason == "Lý do khác"
                        ? otherReasonController.text.trim()
                        : selectedReason;

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(dialogCtx);
                    _timer?.cancel();
                    setState(() => _isProcessing = true);

                    try {
                      // UC17: Ghi rejection_log + reset đơn về 'Chờ phân công'
                      final log = await OrderRepository().rejectOrder(
                        orderId: widget.order.orderId,
                        shipperId: widget.shipperId,
                        shipperName: widget.order.shipperName ?? '',
                        reason: finalReason,
                      );

                      // UC03: Cũng tăng dailyRejectionCount trên Firebase
                      await ShipperRepository().updateShipperRejectionCount(widget.shipperId);

                      // Đọc số lần từ chối hôm nay để hiển thị
                      final shipperData = await ShipperRepository().getShipperById(widget.shipperId);
                      final count = shipperData?.dailyRejectionCount ?? 1;

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Đã từ chối đơn hàng thành công. Đã từ chối $count/3 lần hôm nay."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Lỗi khi từ chối đơn: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("GỬI LÝ DO", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTimer = "${(_timeLeft ~/ 600).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}";
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
                  child: Text(formattedTimer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Lấy: ${widget.order.pickupAddress}", maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text("Giao: ${widget.order.deliveryAddress}", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(currencyFormatter.format(widget.order.codAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _showRejectDialog,
                    child: const Text("TỪ CHỐI", style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _isProcessing ? null : _acceptOrder,
                    child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}