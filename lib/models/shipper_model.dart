/// ===============================
/// Entity: SHIPPER (LAB 3)
/// MaShipper, TenShipper, PhoneShipper, BienSoXe,
/// TrangThaiActive, ViDoHienTai, KinhDoHienTai, CapNhatLanCuoi
/// ===============================
class ShipperModel {
  final String id;         // MaShipper
  final String name;       // TenShipper
  final String phone;      // PhoneShipper
  final String bienSoXe;   // BienSoXe
  bool isActive;           // TrangThaiActive
  final double distance;   // Khoảng cách tới điểm lấy (km) - UC01

  // GPS realtime (BR_collectCoordinates_01 / UC02)
  double viDoHienTai;
  double kinhDoHienTai;
  DateTime capNhatLanCuoi;

  ShipperModel({
    required this.id,
    required this.name,
    required this.phone,
    this.bienSoXe = "",
    required this.isActive,
    required this.distance,
    this.viDoHienTai = 10.7769,
    this.kinhDoHienTai = 106.7009,
    DateTime? capNhatLanCuoi,
  }) : capNhatLanCuoi = capNhatLanCuoi ?? DateTime.now();
}
