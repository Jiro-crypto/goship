import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/shipper_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/shipper_repository.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final Color primaryColor = Colors.orange.shade800;
  final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingForAssignment:
      case OrderStatus.waitingForAcceptance:
      case OrderStatus.waitingForPickup:
        return Colors.orange.shade700;
      case OrderStatus.delivering:
        return Colors.blue.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
      case OrderStatus.deliveryFailed:
      case OrderStatus.cancelled:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status) {
    return status.displayName;
  }

  String _getShipperName(String? shipperId, String? shipperName) {
    if (shipperId == null || shipperId.isEmpty) return "Chưa phân công";
    return "${shipperName ?? 'Không rõ'} ($shipperId)";
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  void _reassignShipper(OrderModel currentOrder) async {
    // Show loading if needed, or fetch directly
    final activeShippers = await ShipperRepository().getActiveShippers();

    if (activeShippers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có shipper hoạt động!")),
      );
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Chọn Shipper mới",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),
            ...activeShippers.map((s) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    child:
                        const Icon(Icons.motorcycle, color: Colors.orange),
                  ),
                  title: Text(s.name),
                  subtitle: Text("${s.phone}"),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      
                      try {
                        await OrderRepository().assignOrderToShipper(
                          orderId: currentOrder.orderId,
                          shipperId: s.uid,
                          dispatcherId: currentOrder.dispatcherId ?? 'Điều phối viên',
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Đã chuyển đơn cho ${s.name}"),
                              backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Lỗi khi chuyển đơn: $e"),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white),
                    child: const Text("Chọn"),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Chi tiết đơn ${widget.order.orderId}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: OrderRepository().watchOrder(widget.order.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            // Giữ lại màn hình cũ trong khi load
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            // Fallback về order truyền vào nếu bị lỗi hoặc bị xoá
          }

          final order = snapshot.data ?? widget.order;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trạng thái
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: _getStatusColor(order.status), size: 30),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Trạng thái hiện tại",
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13)),
                            Text(
                              _getStatusText(order.status),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Thông tin đơn
                _sectionCard("📦 Thông tin đơn hàng", [
                  _infoRow(Icons.confirmation_number, "Mã đơn", order.orderId),
                  _infoRow(Icons.person_outline, "Mã KH", order.customerId),
                  _infoRow(
                      Icons.access_time,
                      "Ngày tạo",
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(order.createdAt)),
                  _infoRow(Icons.category, "Danh mục",
                      order.category),
                  _infoRow(Icons.aspect_ratio, "Kích thước",
                      order.size),
                  _infoRow(Icons.scale, "Khối lượng",
                      "${order.weight} kg"),
                  _infoRow(Icons.numbers, "Số lượng",
                      "${order.quantity}"),
                ]),

                // Người gửi
                _sectionCard("🏪 Điểm lấy hàng", [
                  _infoRow(Icons.store, "Cửa hàng", order.customerName),
                  _infoRow(Icons.phone, "SĐT", order.customerPhone),
                  _infoRow(Icons.location_on, "Địa chỉ", order.pickupAddress),
                ]),

                // Người nhận
                _sectionCard("🎯 Điểm giao hàng", [
                  _infoRow(Icons.person, "Người nhận", order.receiverName),
                  _infoRow(Icons.phone, "SĐT", order.receiverPhone),
                  _infoRow(Icons.location_on, "Địa chỉ", order.deliveryAddress),
                ]),

                // Thanh toán
                _sectionCard("💰 Thanh toán", [
                  _infoRow(Icons.attach_money, "COD",
                      currencyFormatter.format(order.codAmount),
                      valueColor: Colors.green.shade700),
                  _infoRow(Icons.local_shipping, "Phí giao",
                      currencyFormatter.format(order.shippingFee)),
                  _infoRow(
                    Icons.summarize,
                    "Tổng thu",
                    currencyFormatter.format(order.codAmount + order.shippingFee),
                    valueColor: primaryColor,
                  ),
                ]),

                // Shipper
                _sectionCard("🏍️ Shipper phụ trách", [
                  _infoRow(Icons.badge, "Shipper",
                      _getShipperName(order.shipperId, order.shipperName)),
                  if (order.dispatcherId != null && order.dispatcherId!.isNotEmpty)
                    _infoRow(Icons.admin_panel_settings, "Điều phối viên",
                        order.dispatcherId!),
                ]),

                // Ghi chú
                if (order.note.isNotEmpty)
                  _sectionCard("📝 Ghi chú", [
                    Text(order.note,
                        style: const TextStyle(fontSize: 14, height: 1.4)),
                  ]),

                // Lý do hủy
                if (order.status == OrderStatus.cancelled && order.cancelReason != null)
                  _sectionCard("❌ Thông tin hủy đơn", [
                    _infoRow(Icons.person_off, "Người hủy",
                        order.cancelledBy ?? "Không rõ"),
                    _infoRow(
                        Icons.report, "Lý do", order.cancelReason ?? "Không có"),
                  ]),

                // Nút chuyển shipper
                if (order.status == OrderStatus.delivering || order.status == OrderStatus.waitingForPickup || order.status == OrderStatus.waitingForAcceptance) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _reassignShipper(order),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text("CHUYỂN SHIPPER KHÁC"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }
}
