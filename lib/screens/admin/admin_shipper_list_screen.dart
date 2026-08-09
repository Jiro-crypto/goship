import 'package:flutter/material.dart';
import '../../data/mock_shippers.dart';
import '../../data/mock_orders.dart';
import '../../models/shipper_model.dart';

class AdminShipperListScreen extends StatefulWidget {
  const AdminShipperListScreen({super.key});

  @override
  State<AdminShipperListScreen> createState() =>
      _AdminShipperListScreenState();
}

class _AdminShipperListScreenState extends State<AdminShipperListScreen> {
  final Color primaryColor = Colors.orange.shade800;
  String _filter = "all"; // all, active, offline

  int _countOrdersByShipper(String shipperId) {
    return MockOrders.orders
        .where((o) => o.maShipper == shipperId && o.status == "delivering")
        .length;
  }

  int _completedByShipper(String shipperId) {
    return MockOrders.orders
        .where((o) => o.maShipper == shipperId && o.status == "delivered")
        .length;
  }

  void _showShipperDetail(ShipperModel s) {
    final delivering = _countOrdersByShipper(s.id);
    final completed = _completedByShipper(s.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  child: Icon(Icons.motorcycle,
                      color: primaryColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.isActive ? "🟢 Hoạt động" : "⚫ Offline",
                          style: TextStyle(
                              color: s.isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge, color: Colors.blueGrey),
              title: const Text("Mã shipper"),
              trailing: Text(s.id,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("Số điện thoại"),
              trailing: Text(s.phone,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text("Khoảng cách hiện tại"),
              trailing: Text("${s.distance} km",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.local_shipping, color: Colors.blue),
              title: const Text("Đơn đang giao"),
              trailing: Text("$delivering",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Đơn đã hoàn thành"),
              trailing: Text("$completed",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<ShipperModel> _getFilteredShippers() {
    if (_filter == "active") {
      return MockShippers.shippers.where((s) => s.isActive).toList();
    } else if (_filter == "offline") {
      return MockShippers.shippers.where((s) => !s.isActive).toList();
    }
    return MockShippers.shippers;
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: primaryColor,
        labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shippers = _getFilteredShippers();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              _filterChip("Tất cả (${MockShippers.shippers.length})", "all"),
              _filterChip(
                  "Đang hoạt động (${MockShippers.getActiveShippers().length})",
                  "active"),
              _filterChip(
                  "Offline (${MockShippers.shippers.where((s) => !s.isActive).length})",
                  "offline"),
            ],
          ),
        ),
        Expanded(
          child: shippers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("Không có shipper nào",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: shippers.length,
                  itemBuilder: (context, index) {
                    final s = shippers[index];
                    final delivering = _countOrdersByShipper(s.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.15),
                              child: Icon(Icons.motorcycle,
                                  color: primaryColor, size: 26),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: s.isActive
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("📞 ${s.phone}",
                                style: const TextStyle(fontSize: 13)),
                            Text("📍 ${s.distance} km",
                                style: const TextStyle(fontSize: 13)),
                            Text("🚚 Đang giao: $delivering đơn",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: delivering > 0
                                        ? Colors.blue.shade700
                                        : Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showShipperDetail(s),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
