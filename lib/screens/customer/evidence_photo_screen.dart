import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class EvidencePhotoScreen extends StatelessWidget {
  final OrderModel order;

  const EvidencePhotoScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;
    final imageUrl = order.urlAnhMinhChung ?? 'https://picsum.photos/600/400';
    final completedTime = order.thoiGianHoanThanh ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ảnh minh chứng giao hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order details card
            Card(
              child: ListTile(
                title: Text('Mã đơn: ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Người nhận: ${order.tenNguoiNhan} - ${order.sdtNguoiNhan}'),
                trailing: const Icon(Icons.verified, color: Colors.green, size: 28),
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview (BM14)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Không thể tải ảnh minh chứng'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Thông tin xác nhận bàn giao (BM14)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Thời điểm chụp: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(completedTime)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 18, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Tọa độ GPS thực tế: ${(order.latChup ?? order.latGiao).toStringAsFixed(5)}, ${(order.lngChup ?? order.lngGiao).toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 18, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Địa chỉ: ${order.diaChiGiao}')),
                    ],
                  ),
                  if (order.maShipper.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('Mã Shipper thực hiện: ${order.maShipper}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
