import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import 'payment_success_screen.dart';
import 'customer_home_screen.dart';

class PaymentQRScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentQRScreen({super.key, required this.order});

  @override
  State<PaymentQRScreen> createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  Timer? _timer;
  int _secondsLeft = 15;
  bool _isCancelled = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTimeOut() {
    if (_isCancelled || _isProcessing) return;
    setState(() {
      _isCancelled = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Hết thời gian!'),
          ],
        ),
        content: const Text(
          'Đã hết 15 giây thanh toán. Đơn hàng chưa được tạo thành công và đã tự động hủy.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Về trang chủ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() async {
    if (_isCancelled || _secondsLeft <= 0) return;
    _timer?.cancel();
    setState(() => _isProcessing = true);

    try {
      // Gọi repository để lưu lên Firebase thực tế
      OrderModel newOrder = await OrderRepository().createOrder(
        receiverName: widget.order.receiverName,
        receiverPhone: widget.order.receiverPhone,
        pickupAddress: widget.order.pickupAddress,
        deliveryAddress: widget.order.deliveryAddress,
        codAmount: widget.order.codAmount,
        shippingFee: widget.order.shippingFee,
        weight: widget.order.weight,
        category: widget.order.category,
        size: widget.order.size,
        quantity: widget.order.quantity,
        note: widget.order.note,
        pickupLat: widget.order.pickupLat,
        pickupLng: widget.order.pickupLng,
        deliveryLat: widget.order.deliveryLat,
        deliveryLng: widget.order.deliveryLng,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(order: newOrder),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo đơn hàng: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;
    final totalAmount = widget.order.shippingFee > 0 ? widget.order.shippingFee : 25000.0;
    
    // Yêu cầu gán cứng URL hình ảnh QR:
    const String qrUrl = "https://scontent.fsgn5-15.fna.fbcdn.net/v/t1.15752-9/763331742_1705026093880141_6903147646147597855_n.jpg?_nc_cat=102&_nc_map=urlgen_bucketless&ccb=1-7&_nc_sid=9f807c&_nc_ohc=EiaDhme49DoQ7kNvwGGdZ5Q&_nc_oc=AdpeVRherTYXIXauCbQwOP1LyFn-QMntmvnRqjbwAlq-koVP74gvDkLHpk_RvIPag2W68F8zZf5GpkulzSjctV5S&_nc_ad=z-m&_nc_cid=0&_nc_zt=23&_nc_ht=scontent.fsgn5-15.fna&_nc_ss=7a22e&oh=03_Q7cD6AEG3k2BLOxyU1J3tEjVOV9EvWYspcie_fvzOCYOwZPjjg&oe=6A9FE92C";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán Chuyển khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Countdown Timer Widget
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: _secondsLeft <= 5 ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _secondsLeft <= 5 ? Colors.red : Colors.orange),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: _secondsLeft <= 5 ? Colors.red : primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Thời gian thanh toán còn lại: ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                  Text(
                    '00:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _secondsLeft <= 5 ? Colors.red : primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Invoice Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái:', style: TextStyle(color: Colors.grey)),
                        const Text('Tạm tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền cần trả:', style: TextStyle(color: Colors.grey)),
                        Text(
                          currencyFormatter.format(totalAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. QR Code Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('QUÉT MÃ QR ĐỂ THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrUrl,
                      width: 230,
                      height: 230,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 100, color: primaryColor),
                            const Text('Vietcombank - LogiRoute', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Text('Ngân hàng: Vietcombank', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('STK: 9999999999 - LOGIROUTE GOSHIP'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Confirm Payment Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isCancelled || _secondsLeft <= 0 || _isProcessing) ? null : _confirmPayment,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'XÁC NHẬN ĐÃ THANH TOÁN',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
