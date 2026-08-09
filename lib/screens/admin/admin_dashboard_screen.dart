import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_orders.dart';
import '../../data/mock_shippers.dart';
import '../../models/order_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color primaryColor = Colors.orange.shade800;
  final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  int _countByStatus(String status) =>
      MockOrders.orders.where((o) => o.status == status).length;

  double _totalRevenue() {
    return MockOrders.orders
        .where((o) => o.status == "delivered")
        .fold(0.0, (sum, o) => sum + o.phiShip);
  }

  double _totalCOD() {
    return MockOrders.orders
        .where((o) => o.status == "delivered")
        .fold(0.0, (sum, o) => sum + o.tienCOD);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _statusBar(String label, int count, int total, Color color) {
    final percent = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text("$count đơn (${(percent * 100).toStringAsFixed(1)}%)",
                  style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _countByStatus("pending");
    final delivering = _countByStatus("delivering");
    final delivered = _countByStatus("delivered");
    final cancelled = _countByStatus("cancelled");
    final total = MockOrders.orders.length;
    final activeShippers = MockShippers.getActiveShippers().length;
    final totalShippers = MockShippers.shippers.length;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tổng quan hoạt động",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),

            // Grid stat cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _statCard("Tổng đơn", "$total", Icons.receipt_long,
                    Colors.blueGrey),
                _statCard("Đơn chờ phân công", "$pending",
                    Icons.hourglass_top, Colors.orange.shade700),
                _statCard("Đơn đang giao", "$delivering",
                    Icons.local_shipping, Colors.blue.shade700),
                _statCard("Đơn đã giao", "$delivered", Icons.check_circle,
                    Colors.green.shade700),
              ],
            ),

            const SizedBox(height: 16),
            Text("Doanh thu",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                      "Phí ship thu được",
                      currencyFormatter.format(_totalRevenue()),
                      Icons.attach_money,
                      Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                      "Tổng COD",
                      currencyFormatter.format(_totalCOD()),
                      Icons.account_balance_wallet,
                      Colors.purple),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text("Phân bố trạng thái đơn",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _statusBar("Chờ phân công", pending, total,
                        Colors.orange.shade700),
                    _statusBar("Đang giao", delivering, total,
                        Colors.blue.shade700),
                    _statusBar("Đã giao", delivered, total,
                        Colors.green.shade700),
                    _statusBar("Đã hủy", cancelled, total,
                        Colors.red.shade700),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text("Đội ngũ Shipper",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                      "Đang hoạt động",
                      "$activeShippers / $totalShippers",
                      Icons.motorcycle,
                      Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                      "Tỉ lệ hoàn thành",
                      total == 0
                          ? "0%"
                          : "${((delivered / total) * 100).toStringAsFixed(1)}%",
                      Icons.trending_up,
                      Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
