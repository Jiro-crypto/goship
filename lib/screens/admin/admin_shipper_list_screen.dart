import 'package:flutter/material.dart';
import '../../data/mock_shippers.dart';
import '../../models/shipper_model.dart';

/// ============================================================================
/// UC – Quản lý Đội ngũ Shipper (Admin)
/// Cho phép lọc theo trạng thái và bật/tắt shipper
/// ============================================================================
class AdminShipperListScreen extends StatefulWidget {
  const AdminShipperListScreen({super.key});

  @override
  State<AdminShipperListScreen> createState() => _AdminShipperListScreenState();
}

class _AdminShipperListScreenState extends State<AdminShipperListScreen> {
  final Color primaryColor = Colors.orange.shade800;
  String _filter = "all"; // all / active / offline

  List<ShipperModel> get _filtered {
    if (_filter == "active") {
      return MockShippers.shippers.where((s) => s.isActive).toList();
    } else if (_filter == "offline") {
      return MockShippers.shippers.where((s) => !s.isActive).toList();
    }
    return MockShippers.shippers;
  }

  void _toggleShipperStatus(ShipperModel s) {
    setState(() => s.isActive = !s.isActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Đã ${s.isActive ? 'kích hoạt' : 'vô hiệu hoá'} shipper ${s.name}"),
        backgroundColor: s.isActive ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = MockShippers.shippers.length;
    final active = MockShippers.shippers.where((s) => s.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Shipper",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Thống kê nhanh
          Container(
            padding: const EdgeInsets.all(12),
            color: primaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryChip("Tổng", "$total", Colors.blue),
                _summaryChip("Đang hoạt động", "$active", Colors.green),
                _summaryChip("Offline", "${total - active}", Colors.grey),
              ],
            ),
          ),
          // Bộ lọc
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip("Tất cả", "all"),
                const SizedBox(width: 8),
                _filterChip("Đang hoạt động", "active"),
                const SizedBox(width: 8),
                _filterChip("Offline", "offline"),
              ],
            ),
          ),
          // Danh sách
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text("Không có shipper nào.",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final s = _filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.2),
                                child: Icon(Icons.person, color: primaryColor),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: s.isActive ? Colors.green : Colors.grey,
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
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ID: ${s.id} • ${s.phone}"),
                              Text("Cách trung tâm: ${s.distance} km"),
                            ],
                          ),
                          trailing: Switch(
                            value: s.isActive,
                            activeColor: primaryColor,
                            onChanged: (_) => _toggleShipperStatus(s),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primaryColor,
      labelStyle:
          TextStyle(color: selected ? Colors.white : Colors.black),
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
