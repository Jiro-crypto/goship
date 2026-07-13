import '../models/shipper_model.dart';

class MockShippers {
  static List<ShipperModel> shippers = [
    ShipperModel(id: "SP-001", name: "Nguyễn Trần Gia Bảo", phone: "0901234567", isActive: true, distance: 1.2),
    ShipperModel(id: "SP-002", name: "Phạm Anh Dũng", phone: "0912345678", isActive: true, distance: 2.5),
    ShipperModel(id: "SP-003", name: "Chu Bá Khang", phone: "0923456789", isActive: false, distance: 0.5), // Offline
    ShipperModel(id: "SP-004", name: "Trần Lê Minh Toàn", phone: "0934567890", isActive: true, distance: 3.8),
  ];

  // Hàm hỗ trợ lọc Shipper đang Active (Dành cho chức năng Phân công)
  static List<ShipperModel> getActiveShippers() {
    return shippers.where((shipper) => shipper.isActive).toList();
  }
}