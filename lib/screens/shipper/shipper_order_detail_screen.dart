import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/order_model.dart';
import '../../models/invoice_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/shipper_repository.dart';
import '../../services/location_service.dart';
import '../../services/gps_upload_service.dart';
import 'shipper_route_screen.dart';

// ============================================================
// Màn hình Chi tiết Đơn hàng dành cho Shipper
// Hỗ trợ: Bắt đầu giao hàng, Gửi GPS định kỳ (UC07), Chụp ảnh minh chứng (UC08)
// Hoàn thành đơn hàng (UC09) và Báo cáo giao thất bại (UC18)
// ============================================================
class ShipperOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const ShipperOrderDetailScreen({super.key, required this.order});

  @override
  State<ShipperOrderDetailScreen> createState() => _ShipperOrderDetailScreenState();
}

class _ShipperOrderDetailScreenState extends State<ShipperOrderDetailScreen> {
  // Trạng thái đánh dấu Shipper đã đính kèm ảnh minh chứng hay chưa (BR_confirmShipping_01)
  bool _isEvidenceCaptured = false;
  String? _capturedPhotoUrl;
  double? _capturedLat;
  double? _capturedLng;

  // Lấy shipperId từ Firebase Auth
  String get _shipperId => FirebaseAuth.instance.currentUser?.uid ?? widget.order.shipperId ?? '';

  @override
  void dispose() {
    // Tự động hủy gửi GPS khi Shipper thoát khỏi màn hình chi tiết
    GpsUploadService.stopUploading();
    super.dispose();
  }

  // UC04: Bắt đầu giao hàng & kích hoạt gửi vị trí GPS định kỳ (UC07)
  void _startDelivering() async {
    // 1. Kiểm tra xem quyền GPS và dịch vụ vị trí trên máy đã được bật chưa
    bool hasPermission = await LocationService.handlePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng bật GPS và cấp quyền vị trí để bắt đầu giao hàng!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Cập nhật trạng thái lên Firebase: Chờ giao → Đang giao
      await OrderRepository().startDelivery(widget.order.orderId);

      // 2. Bắt đầu gửi tín hiệu định vị GPS định kỳ mỗi 5 giây
      GpsUploadService.startUploading(widget.order.orderId, _shipperId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã bắt đầu giao đơn hàng. Đang định kỳ gửi GPS lên hệ thống (mỗi 5s)."),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi bắt đầu giao hàng: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // UC08: Chụp ảnh minh chứng giao hàng thực tế (kèm dấu thời gian & tọa độ GPS)
  void _captureEvidence() async {
    // Lấy vị trí GPS thực tế thời điểm bấm chụp ảnh
    final Position? pos = await LocationService.getCurrentLocation();

    setState(() {
      _isEvidenceCaptured = true;
      // Gán URL ảnh minh chứng (sau này sẽ dùng StorageRepository để upload thực)
      _capturedPhotoUrl = "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800";
      if (pos != null) {
        _capturedLat = pos.latitude;
        _capturedLng = pos.longitude;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã đính kèm ảnh minh chứng thành công (kèm timestamp & tọa độ GPS thực)."),
        backgroundColor: Colors.green,
      ),
    );
  }

  // UC09: Chuyển trạng thái khi giao hàng thành công
  void _completeOrderSuccess() async {
    if (!_isEvidenceCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn phải đính kèm ảnh minh chứng trước khi hoàn tất giao hàng!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dừng gửi định vị GPS
    GpsUploadService.stopUploading();

    try {
      // Cập nhật trạng thái lên Firebase: Đang giao → Đã giao
      await OrderRepository().confirmDeliverySuccess(
        orderId: widget.order.orderId,
        confirmLat: _capturedLat ?? widget.order.deliveryLat ?? 0,
        confirmLng: _capturedLng ?? widget.order.deliveryLng ?? 0,
      );

      // Ghi Invoice lên Firebase
      final invoice = InvoiceModel(
        invoiceId: 'INV-${widget.order.orderId}',
        imageUrl: _capturedPhotoUrl,
        confirmedAt: DateTime.now(),
        paymentStatus: 'Đã thanh toán',
        paymentMethod: 'Chuyển khoản Ngân hàng',
        photoLat: _capturedLat,
        photoLng: _capturedLng,
        confirmLat: _capturedLat,
        confirmLng: _capturedLng,
      );
      await OrderRepository().updateInvoice(widget.order.orderId, invoice);

      // Cập nhật GPS cuối cùng lên Firestore cho shipper
      if (_capturedLat != null && _shipperId.isNotEmpty) {
        await ShipperRepository().updateLocation(
          shipperId: _shipperId,
          lat: _capturedLat!,
          lng: _capturedLng!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xác nhận giao hàng thành công! Đã ghi nhận lịch sử giao hàng."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi xác nhận giao hàng: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // UC015: Báo cáo Giao hàng thất bại (Hiển thị Form)
  void _showFailedDeliveryDialog() {
    String selectedReason = "Khách hàng từ chối nhận";
    bool isCallHistoryUploaded = false; // Trạng thái up ảnh danh sách cuộc gọi

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Báo cáo giao hàng thất bại", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 10),
                  const Text("Vui lòng chọn lý do giao hàng không thành công:"),
                  RadioListTile(
                    title: const Text("Khách hàng từ chối nhận"),
                    value: "Khách hàng từ chối nhận",
                    groupValue: selectedReason,
                    onChanged: (val) => setSheetState(() => selectedReason = val.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Không thể liên lạc được với khách hàng"),
                    value: "Không thể liên lạc được với khách hàng",
                    groupValue: selectedReason,
                    onChanged: (val) => setSheetState(() => selectedReason = val.toString()),
                  ),

                  // Alternative Flow: Buộc up ảnh lịch sử cuộc gọi nếu không liên lạc được (BR_deliveryFailed_02)
                  if (selectedReason == "Không thể liên lạc được với khách hàng") ...[
                    const Divider(),
                    const Text("Yêu cầu bắt buộc:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const Text("Vui lòng đính kèm ảnh chụp màn hình danh sách cuộc gọi nhỡ tới SĐT người nhận.", style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        setSheetState(() => isCallHistoryUploaded = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã tải lên ảnh lịch sử cuộc gọi thành công."), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isCallHistoryUploaded ? Colors.green.shade50 : Colors.grey.shade200,
                          border: Border.all(color: isCallHistoryUploaded ? Colors.green : Colors.grey, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Center(
                          child: isCallHistoryUploaded
                              ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text("Đã tải ảnh lên", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file, color: Colors.grey), SizedBox(width: 8), Text("Bấm để tải ảnh lên")]),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Kiểm tra ràng buộc BR_deliveryFailed_02
                        if (selectedReason == "Không thể liên lạc được với khách hàng" && !isCallHistoryUploaded) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bạn phải đính kèm ảnh minh chứng cuộc gọi! (MS_ConfirmDelivery_02)"), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        // Dừng gửi vị trí GPS
                        GpsUploadService.stopUploading();

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

                        Navigator.pop(context); // Đóng form

                        try {
                          // Cập nhật trạng thái giao thất bại lên Firebase
                          await OrderRepository().confirmDeliveryFailed(
                            orderId: widget.order.orderId,
                            reason: selectedReason,
                          );

                          messenger.showSnackBar(
                            const SnackBar(content: Text("Đã xác nhận giao hàng thất bại (MS_FailedDelivery_01)"), backgroundColor: Colors.orange),
                          );
                          nav.pop(); // Quay về Home
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text("Lỗi khi báo cáo giao thất bại: $e"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("XÁC NHẬN THẤT BẠI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder để lắng nghe thay đổi trạng thái đơn realtime
    return StreamBuilder<OrderModel?>(
      stream: OrderRepository().watchOrder(widget.order.orderId),
      initialData: widget.order,
      builder: (context, snapshot) {
        final order = snapshot.data ?? widget.order;
        final bool isWaiting = order.status == OrderStatus.waitingForPickup;
        final bool isDelivering = order.status == OrderStatus.delivering;
        final bool isReadOnly = !isWaiting && !isDelivering;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Chi tiết đơn hàng", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade800,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông báo nếu xem ở chế độ lịch sử
                if (isReadOnly) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.grey.shade300,
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Trạng thái hiện tại: ${order.status.displayName.toUpperCase()}\nĐơn hàng đã được hoàn tất hoặc đã hủy. Chỉ hiển thị ở chế độ lịch sử.",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Thông tin chỉ đọc
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, "Người gửi", "${order.customerName} - ${order.customerPhone}"),
                        const Divider(),
                        _buildInfoRow(Icons.location_on, "Điểm lấy", order.pickupAddress),
                        const Divider(),
                        _buildInfoRow(Icons.person_outline, "Người nhận", "${order.receiverName} - ${order.receiverPhone}"),
                        const Divider(),
                        _buildInfoRow(Icons.map, "Điểm giao", order.deliveryAddress),
                        const Divider(),
                        _buildInfoRow(Icons.attach_money, "Tiền COD", "${order.codAmount}đ", color: Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút: Bắt đầu giao
                if (isWaiting)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _startDelivering,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      icon: const Icon(Icons.directions_bike, color: Colors.white),
                      label: const Text("BẮT ĐẦU GIAO HÀNG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Các chức năng khi ĐANG GIAO
                if (isDelivering) ...[
                  // Nút xem bản đồ
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShipperRouteScreen(order: order)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: const Text("XEM TUYẾN ĐƯỜNG BẢN ĐỒ", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // UC07: Khu vực chụp ảnh minh chứng bắt buộc
                  const Text("Minh chứng giao hàng (BẮT BUỘC):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _captureEvidence, // Giả lập bật camera
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isEvidenceCaptured ? Colors.blue.shade50 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isEvidenceCaptured ? Colors.blue : Colors.grey, width: 2, style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: _isEvidenceCaptured
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, color: Colors.blue, size: 40),
                                  Text("Đã đính kèm ảnh (Watermark: Thời gian + Tọa độ)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                                  Text("Nhấn vào đây để mở Camera tích hợp", style: TextStyle(color: Colors.grey))
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hai nút Xác nhận bị vô hiệu hóa nếu chưa chụp ảnh (BR_confirmShipping_01)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEvidenceCaptured ? _showFailedDeliveryDialog : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text("GIAO THẤT BẠI", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEvidenceCaptured ? _completeOrderSuccess : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text("GIAO THÀNH CÔNG", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }
}