import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../data/mock_shippers.dart';
import '../../services/preference_service.dart';

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

  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange.shade700;
      case "delivering":
        return Colors.blue.shade700;
      case "delivered":
        return Colors.green.shade700;
      case "cancelled":
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "pending":
        return "Chờ phân công";
      case "delivering":
        return "Đang giao";
      case "delivered":
        return "Đã giao";
      case "cancelled":
        return "Đã hủy";
      default:
        return "Không rõ";
    }
  }

  String _getShipperName(String shipperId) {
    if (shipperId.isEmpty) return "Chưa phân công";
    final shipper = MockShippers.shippers.firstWhere(
      (s) => s.id == shipperId,
      orElse: () => MockShippers.shippers.first,
    );
    return "${shipper.name} (${shipper.id})";
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

  void _reassignShipper() async {
    final activeShippers = MockShippers.getActiveShippers()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (activeShippers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có shipper hoạt động!")),
      );
      return;
    }

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
                  subtitle: Text("${s.phone} • ${s.distance} km"),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        widget.order.maShipper = s.id;
                        widget.order.status = "delivering";
                      });
                      await PreferenceService.saveOrder(widget.order);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Đã chuyển đơn cho ${s.name}"),
                            backgroundColor: Colors.green),
                      );
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
    final order = widget.order;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Chi tiết đơn ${order.orderId}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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
              _infoRow(Icons.person_outline, "Mã KH", order.maKH),
              _infoRow(
                  Icons.access_time,
                  "Ngày tạo",
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(order.thoiGianTao)),
              _infoRow(Icons.category, "Danh mục",
                  order.danhMucHang ?? "Không rõ"),
              _infoRow(Icons.aspect_ratio, "Kích thước",
                  order.kichThuoc ?? "Không rõ"),
              _infoRow(Icons.scale, "Khối lượng",
                  "${order.khoiLuong} kg"),
              _infoRow(Icons.numbers, "Số lượng",
                  "${order.soLuong ?? 1}"),
            ]),

            // Người gửi
            _sectionCard("🏪 Điểm lấy hàng", [
              _infoRow(Icons.store, "Cửa hàng", order.senderName),
              _infoRow(Icons.phone, "SĐT", order.senderPhone),
              _infoRow(Icons.location_on, "Địa chỉ", order.diaChiLay),
            ]),

            // Người nhận
            _sectionCard("🎯 Điểm giao hàng", [
              _infoRow(Icons.person, "Người nhận", order.tenNguoiNhan),
              _infoRow(Icons.phone, "SĐT", order.sdtNguoiNhan),
              _infoRow(Icons.location_on, "Địa chỉ", order.diaChiGiao),
            ]),

            // Thanh toán
            _sectionCard("💰 Thanh toán", [
              _infoRow(Icons.attach_money, "COD",
                  currencyFormatter.format(order.tienCOD),
                  valueColor: Colors.green.shade700),
              _infoRow(Icons.local_shipping, "Phí giao",
                  currencyFormatter.format(order.phiShip)),
              _infoRow(
                Icons.summarize,
                "Tổng thu",
                currencyFormatter.format(order.tienCOD + order.phiShip),
                valueColor: primaryColor,
              ),
            ]),

            // Shipper
            _sectionCard("🏍️ Shipper phụ trách", [
              _infoRow(Icons.badge, "Shipper",
                  _getShipperName(order.maShipper)),
              if (order.maDPV.isNotEmpty)
                _infoRow(Icons.admin_panel_settings, "Điều phối viên",
                    order.maDPV),
            ]),

            // Ghi chú
            if (order.ghiChu.isNotEmpty)
              _sectionCard("📝 Ghi chú", [
                Text(order.ghiChu,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ]),

            // Lý do hủy
            if (order.status == "cancelled" && order.lyDoHuy != null)
              _sectionCard("❌ Thông tin hủy đơn", [
                _infoRow(Icons.person_off, "Người hủy",
                    order.nguoiHuy ?? "Không rõ"),
                _infoRow(
                    Icons.report, "Lý do", order.lyDoHuy ?? "Không có"),
              ]),

            // Nút chuyển shipper
            if (order.status == "delivering") ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _reassignShipper,
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
      ),
    );
  }
}
