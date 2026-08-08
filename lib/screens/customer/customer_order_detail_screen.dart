import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../order_tracking_screen.dart';
import 'evidence_photo_screen.dart';
import 'invoice_screen.dart';
import '../../services/preference_service.dart';

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

                  widget.order.trangThaiDon = 'Đã hủy';
                  widget.order.status = 'cancelled';
                  widget.order.lyDoHuy = reasonController.text.trim();
                  widget.order.nguoiHuy = 'KhachHang';

                  await PreferenceService.saveOrder(widget.order);

                  Navigator.pop(ctx); // Đóng dialog
                  navigator.pop(true); // Đẩy về Trang chủ

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: Colors.red),
                  );
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
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
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mã đơn & Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã đơn: ${order.orderId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.thoiGianTao)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                _buildStatusChip(order.trangThaiDon),
              ],
            ),
            const SizedBox(height: 16),

            if (order.trangThaiDon == 'Đã hủy' && order.lyDoHuy != null)
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
                    const Text('Lý do hủy đơn:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 4),
                    Text(order.lyDoHuy!, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),

            // Người gửi & Người nhận
            _buildInfoCard(
              'Thông tin người gửi',
              (order.senderName.contains('Store') || order.senderName.contains('Gong Cha') || order.senderName.contains('Pizza') || order.senderName.contains('Zara'))
                  ? 'Mina'
                  : order.senderName,
              (order.senderPhone == '19001000' || order.senderPhone.length < 10)
                  ? '0987654321'
                  : order.senderPhone,
              icon: Icons.store,
            ),
            _buildInfoCard('Thông tin người nhận', order.tenNguoiNhan, order.sdtNguoiNhan, icon: Icons.person),

            // Địa chỉ
            _buildAddressCard('Địa chỉ lấy hàng', order.diaChiLay, Colors.blue, Icons.storefront),
            _buildAddressCard('Địa chỉ giao hàng', order.diaChiGiao, Colors.red, Icons.location_on),

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
                        Text(order.danhMucHang ?? 'Hàng hóa chung', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trọng lượng / Số lượng:'),
                        Text('${order.khoiLuong} kg / ${order.soLuong ?? 1} món', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (order.ghiChu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Ghi chú: ${order.ghiChu}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
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
                        const Text('Tiền thu COD:'),
                        Text(
                          currencyFormatter.format(order.phiShip > 0 ? order.phiShip : (order.tienCOD > 0 ? order.tienCOD : 25000.0)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG THU COD:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormatter.format(order.phiShip > 0 ? order.phiShip : (order.tienCOD > 0 ? order.tienCOD : 25000.0)),
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
            if (order.trangThaiDon == 'Đang giao')
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

            // Nút "Hủy đơn" (UC19) – chỉ hiện khi Chờ phân công hoặc Chờ giao
            if (order.trangThaiDon == 'Chờ phân công' || order.trangThaiDon == 'Chờ giao') ...[
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
            if (order.trangThaiDon == 'Đã giao') ...[
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
      ),
    );
  }
}
