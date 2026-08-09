import '../models/shipper_model.dart';

class MockShippers {
  static List<ShipperModel> shippers = [
    ShipperModel(
      id: "SP-001", name: "Nguyễn Trần Gia Bảo", phone: "0901234567",
      bienSoXe: "59P1-123.45", isActive: true, distance: 1.2,
      viDoHienTai: 10.7725, kinhDoHienTai: 106.6980,
    ),
    ShipperModel(
      id: "SP-002", name: "Phạm Anh Dũng", phone: "0912345678",
      bienSoXe: "59P2-678.90", isActive: true, distance: 2.5,
      viDoHienTai: 10.7800, kinhDoHienTai: 106.7050,
    ),
    ShipperModel(
      id: "SP-003", name: "Chu Bá Khang", phone: "0923456789",
      bienSoXe: "59P3-111.22", isActive: false, distance: 0.5,
      viDoHienTai: 10.7700, kinhDoHienTai: 106.6950,
    ),
    ShipperModel(
      id: "SP-004", name: "Trần Lê Minh Toàn", phone: "0934567890",
      bienSoXe: "59P4-333.44", isActive: true, distance: 3.8,
      viDoHienTai: 10.7850, kinhDoHienTai: 106.6900,
    ),
  ];

  /// BR_assignOrder_02: chỉ phân công shipper Active
  static List<ShipperModel> getActiveShippers() {
    return shippers.where((s) => s.isActive).toList();
  }

  /// LAB 4: sắp xếp theo khoảng cách gần điểm lấy nhất
  static List<ShipperModel> getActiveShippersSortedByDistance() {
    final list = getActiveShippers();
    list.sort((a, b) => a.distance.compareTo(b.distance));
    return list;
  }
}
