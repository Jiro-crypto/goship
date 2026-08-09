import 'package:flutter/material.dart';
import '../../data/mock_shippers.dart';
import '../../models/shipper_model.dart';

/// Trang Giám sát vị trí Shipper (BR_shipperTracking)
/// - BR_shipperTracking_01: chỉ Admin / Điều phối viên xem
/// - BR_shipperTracking_02: chỉ theo dõi shipper có trạng thái "Active"
/// - BR_shipperTracking_04: mất mạng -> hiển thị vị trí cuối cùng ghi nhận
///
/// UI đơn giản: bản đồ dạng bảng khung + danh sách shipper Active kèm toạ độ giả lập
/// (dùng lại dữ liệu MockShippers, không phụ thuộc thư viện bản đồ ngoài).
class AdminMapMonitorScreen extends StatefulWidget {
  const AdminMapMonitorScreen({super.key});

  @override
  State<AdminMapMonitorScreen> createState() => _AdminMapMonitorScreenState();
}

class _AdminMapMonitorScreenState extends State<AdminMapMonitorScreen> {
  ShipperModel? _selected;

  @override
  Widget build(BuildContext context) {
    final activeShippers = MockShippers.getActiveShippers();
    final Color primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Giám sát Shipper (Bản đồ)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          // "Bản đồ" giả lập bằng canvas nhẹ (không dùng plugin ngoài để tránh phụ thuộc)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blueGrey.shade50,
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Stack(
                children: [
                  // Lưới nền giả lập bản đồ
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                  // Các chấm vị trí shipper
                  ...activeShippers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final dx = 40.0 + (idx * 70) % 240;
                    final dy = 60.0 + ((idx * 90) % 220);
                    final isSelected = _selected?.id == s.id;
                    return Positioned(
                      left: dx,
                      top: dy,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = s),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.grey.shade300),
                              ),
                              child: Text(
                                s.id,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? primaryColor : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Icon(Icons.motorcycle,
                                color:
                                    isSelected ? primaryColor : Colors.blue.shade700,
                                size: isSelected ? 34 : 28),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Chú thích
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              color: Colors.green.shade600, size: 10),
                          const SizedBox(width: 6),
                          const Text("Shipper Active",
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Danh sách shipper active
          Expanded(
            flex: 2,
            child: activeShippers.isEmpty
                ? const Center(child: Text("Không có shipper Active."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: activeShippers.length,
                    itemBuilder: (context, i) {
                      final s = activeShippers[i];
                      final isSelected = _selected?.id == s.id;
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? primaryColor : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(Icons.motorcycle,
                                color: Colors.green.shade700),
                          ),
                          title: Text(s.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Mã: ${s.id} • SĐT: ${s.phone} • Cách điểm lấy: ${s.distance} km"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Active",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                          onTap: () => setState(() => _selected = s),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.shade100
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
