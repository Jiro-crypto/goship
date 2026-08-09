import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class InvoiceScreen extends StatelessWidget {
  final OrderModel order;

  const InvoiceScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final primaryColor = Colors.orange.shade800;
    final invoiceId = 'HD-${order.orderId}';
    final transactionId = order.invoice?.transactionId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn vận chuyển', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bill Header Card (BM12)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 50, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text('HÓA ĐƠN VẬN CHUYỂN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Mã HD: $invoiceId', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mã đơn hàng:'),
                        Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái thanh toán:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đã thanh toán',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phương thức thanh toán:'),
                        Text('Chuyển khoản Ngân hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (transactionId != null && transactionId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã giao dịch:'),
                          Text(transactionId, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí vận chuyển:'),
                        Text(currencyFormatter.format(order.shippingFee)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiền thu hộ COD:'),
                        Text(
                          currencyFormatter.format(order.codAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG GIÁ TRỊ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          currencyFormatter.format(order.shippingFee + order.codAmount),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Completed confirmation badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đã hoàn tất thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                        SizedBox(height: 2),
                        Text('Hóa đơn đã được xác nhận thanh toán khi đặt đơn thành công.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
