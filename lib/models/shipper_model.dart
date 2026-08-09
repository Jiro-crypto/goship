/// ===============================
/// Entity: SHIPPER (MaShipper)
/// Bổ sung: toạ độ realtime & biển số xe theo LAB 3
/// ===============================
class ShipperModel {
  // Khóa chính & thông tin nhận dạng
  final String id;
  final String name;
  final String phone;

  // Trạng thái nghiệp vụ
  bool isActive;                      // BR_onlineShipper_01
  final double distance;               // Khoảng cách tới điểm lấy (km)

  // GPS realtime (đồng bộ với BR_collectCoordinates_01)
  double currentLatitude;
  double currentLongitude;
  DateTime lastUpdate;

  // Phương tiện
  final String bienSoXe;
  final String loaiPhuongTien;        // Xe máy / Ô tô / Xe đạp

  ShipperModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.isActive,
    required this.distance,
    this.currentLatitude = 10.7769,
    this.currentLongitude = 106.7009,
    DateTime? lastUpdate,
    this.bienSoXe = "",
    this.loaiPhuongTien = "Xe máy",
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone": phone,
        "isActive": isActive,
        "distance": distance,
        "currentLatitude": currentLatitude,
        "currentLongitude": currentLongitude,
        "lastUpdate": lastUpdate.toIso8601String(),
        "bienSoXe": bienSoXe,
        "loaiPhuongTien": loaiPhuongTien,
      };

  factory ShipperModel.fromJson(Map<String, dynamic> json) => ShipperModel(
        id: json["id"] ?? "",
        name: json["name"] ?? "",
        phone: json["phone"] ?? "",
        isActive: json["isActive"] ?? false,
        distance: (json["distance"] as num?)?.toDouble() ?? 0.0,
        currentLatitude: (json["currentLatitude"] as num?)?.toDouble() ?? 10.7769,
        currentLongitude: (json["currentLongitude"] as num?)?.toDouble() ?? 106.7009,
        lastUpdate: json["lastUpdate"] != null
            ? DateTime.parse(json["lastUpdate"])
            : DateTime.now(),
        bienSoXe: json["bienSoXe"] ?? "",
        loaiPhuongTien: json["loaiPhuongTien"] ?? "Xe máy",
      );
}
