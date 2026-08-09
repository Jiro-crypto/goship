import 'package:flutter/material.dart';
import '../../data/mock_orders.dart';
import '../../data/mock_shippers.dart';

/// ============================================================================
/// Dashboard thống kê cho Điều Phối Viên
/// ============================================================================
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.orange.shade800;
    final orders = MockOrders.orders;

    final pending = orders.where((o) => o.status == "pending").length;
    final delivering = orders.where((o) => o.status == "delivering").length;
    final delivered = orders.where((o) => o.status == "delivered").length;
    final cancelled = orders.where((o) => o.status == "cancelled").length;

    final activeShippers =
        MockShippers.shippers.where((s) => s.isActive).length;
    final totalShippers = MockShippers.shippers.length;

    final totalRevenue = orders
        .where((o) => o.status == "delivered")
        .fold<double>(0, (sum, o) => sum + o.deliveryFee);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Điều Phối",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tổng quan hôm nay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _statCard("Chờ phân công", "$pending",
                    Icons.pending_actions, Colors.orange),
                _statCard("Đang giao", "$delivering",
                    Icons.local_shipping, Colors.blue),
                _statCard("Đã giao", "$delivered",
                    Icons.check_circle, Colors.green),
                _statCard(
                    "Đã hủy", "$cancelled", Icons.cancel, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Đội ngũ Shipper",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _shipperStat("$activeShippers", "Đang hoạt động",
                        Colors.green),
                    _shipperStat("${totalShippers - activeShippers}", "Offline",
                        Colors.grey),
                    _shipperStat("$totalShippers", "Tổng cộng", primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Doanh thu (phí ship)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tổng doanh thu",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(
                          "${totalRevenue.toStringAsFixed(0)} đ",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Hành động nhanh",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(context, Icons.map, "Giám sát bản đồ", () {
                  // Điều hướng qua admin_map_monitor_screen
                }),
                _actionButton(context, Icons.refresh, "Làm mới", () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _shipperStat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Mở chức năng: $label"),
              duration: const Duration(seconds: 1)),
        );
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade800,
      ),
    );
  }
}
