import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../order_tracking_screen.dart';
import 'evidence_photo_screen.dart';
import 'invoice_screen.dart';
import '../../data/repositories/order_repository.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const CustomerOrderDetailScreen({super.key, required this.order});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy đơn *',
                hintText: 'Nhập lý do hủy...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập lý do hủy đơn')),
                    );
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await OrderRepository().cancelOrderByCustomer(
                      orderId: widget.order.orderId,
                      reason: reasonController.text.trim(),
                    );

                    Navigator.pop(ctx); // Đóng dialog
                    navigator.pop(true); // Đẩy về Trang chủ

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: Colors.red),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Lỗi khi hủy đơn: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
              ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Chờ phân công':
        color = Colors.orange;
        break;
      case 'Chờ nhận':
        color = Colors.indigo;
        break;
      case 'Chờ lấy hàng':
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
      case 'Giao thất bại':
        color = Colors.brown;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildInfoCard(String title, String name, String phone, {IconData icon = Icons.person}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                ),
                Icon(Icons.phone, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 4),
                Text(phone, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(String title, String address, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: OrderRepository().watchOrder(widget.order.orderId),
        initialData: widget.order,
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text("Đơn hàng không tồn tại."));
          }
          
          final statusName = order.status.displayName;
          final isDone = statusName == OrderStatus.delivered.displayName || statusName == OrderStatus.cancelled.displayName || statusName == OrderStatus.deliveryFailed.displayName;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mã đơn & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mã đơn: ${order.orderId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(statusName),
                  ],
                ),
                const SizedBox(height: 16),

                if (!isDone)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.blue.shade800, size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thời gian giao dự kiến:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('~${order.getEstimatedDeliveryMinutes()} phút', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (statusName == OrderStatus.cancelled.displayName && order.cancelReason != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lý do hủy đơn (${order.cancelledBy ?? "Không rõ"}):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 4),
                        Text(order.cancelReason!, style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),

                // Người gửi & Người nhận
                _buildInfoCard(
                  'Thông tin người gửi',
                  order.customerName,
                  order.customerPhone,
                  icon: Icons.store,
                ),
                _buildInfoCard('Thông tin người nhận', order.receiverName, order.receiverPhone, icon: Icons.person),

                // Địa chỉ
                _buildAddressCard('Địa chỉ lấy hàng', order.pickupAddress, Colors.blue, Icons.storefront),
                _buildAddressCard('Địa chỉ giao hàng', order.deliveryAddress, Colors.red, Icons.location_on),

                // Thông tin hàng hóa
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin hàng hóa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Danh mục:'),
                            Text(order.category.isNotEmpty ? order.category : 'Hàng hóa chung', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trọng lượng / Số lượng:'),
                            Text('${order.weight} kg / ${order.quantity} món', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (order.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Ghi chú: ${order.note}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Chi phí & Thanh toán
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chi tiết chi phí', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí vận chuyển (Khách trả):'),
                            Text(
                              currencyFormatter.format(order.shippingFee),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiền thu hộ COD (Shipper thu):'),
                            Text(
                              currencyFormatter.format(order.codAmount),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG GIÁ TRỊ ĐƠN HÀNG:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              currencyFormatter.format(order.shippingFee + order.codAmount),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút "Xem Hóa đơn"
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(order: order)));
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Xem Hóa đơn vận chuyển'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),

                const SizedBox(height: 12),

                // Nút "Theo dõi đơn" (chỉ hiện khi Đang giao)
                if (statusName == OrderStatus.delivering.displayName)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Theo dõi vị trí Shipper trên bản đồ', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                // Nút "Hủy đơn" (UC19) – chỉ hiện khi Chờ phân công hoặc Chờ nhận
                if (statusName == OrderStatus.waitingForAssignment.displayName || statusName == OrderStatus.waitingForAcceptance.displayName) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Hủy đơn hàng này', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],

                // Nút "Xem ảnh minh chứng" – chỉ hiện khi Đã giao
                if (statusName == OrderStatus.delivered.displayName && order.invoice != null && (order.invoice!.imageUrl?.isNotEmpty == true)) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EvidencePhotoScreen(order: order)),
                      );
                    },
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Xem ảnh minh chứng giao hàng', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }
}
