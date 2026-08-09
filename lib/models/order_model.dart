/// ===============================
/// Entity: DONHANG (OrderID)
/// Bổ sung các trường nghiệp vụ theo LAB 3
/// ===============================
class OrderModel {
  // ====== Khoá chính & cơ bản ======
  final String id;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final double price;
  final double deliveryFee;

  // ====== Trạng thái có thể thay đổi ======
  String status; // 'pending' | 'pending_acceptance' | 'waiting_delivery'
                // | 'delivering' | 'delivered' | 'failed' | 'cancelled'

  // ====== Toạ độ GPS ======
  final double pickupLatitude;
  final double pickupLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;

  // ====== Nghiệp vụ phân công (UC01) ======
  String? maShipperAssigned;
  String? maDPVAssigned;
  DateTime? thoiGianPhanCong;
  DateTime? thoiGianTao;

  // ====== Nghiệp vụ huỷ đơn ======
  String? lyDoHuy;
  String? nguoiHuy;                    // CUSTOMER | SHIPPER | ADMIN

  // ====== Thông tin hàng hoá (UC10) ======
  String danhMucHang;                 // Đồ ăn / Điện tử / Tài liệu
  String kichThuoc;                   // S / M / L
  double khoiLuong;                   // kg
  String phuongThucThanhToan;         // COD / MOMO / ZALOPAY / VISA / PAYPAL

  // ====== Minh chứng giao hàng (UC07, UC09) ======
  String? hinhAnhMinhChung;
  DateTime? thoiGianChupAnh;
  String? anhLichSuCuocGoi;

  OrderModel({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.price,
    required this.deliveryFee,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.maShipperAssigned,
    this.maDPVAssigned,
    this.thoiGianPhanCong,
    this.thoiGianTao,
    this.lyDoHuy,
    this.nguoiHuy,
    this.danhMucHang = "Đồ ăn",
    this.kichThuoc = "M",
    this.khoiLuong = 1.0,
    this.phuongThucThanhToan = "COD",
    this.hinhAnhMinhChung,
    this.thoiGianChupAnh,
    this.anhLichSuCuocGoi,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "senderName": senderName,
        "senderPhone": senderPhone,
        "receiverName": receiverName,
        "receiverPhone": receiverPhone,
        "pickupAddress": pickupAddress,
        "deliveryAddress": deliveryAddress,
        "price": price,
        "deliveryFee": deliveryFee,
        "status": status,
        "pickupLatitude": pickupLatitude,
        "pickupLongitude": pickupLongitude,
        "deliveryLatitude": deliveryLatitude,
        "deliveryLongitude": deliveryLongitude,
        "maShipperAssigned": maShipperAssigned,
        "maDPVAssigned": maDPVAssigned,
        "thoiGianPhanCong": thoiGianPhanCong?.toIso8601String(),
        "thoiGianTao": thoiGianTao?.toIso8601String(),
        "lyDoHuy": lyDoHuy,
        "nguoiHuy": nguoiHuy,
        "danhMucHang": danhMucHang,
        "kichThuoc": kichThuoc,
        "khoiLuong": khoiLuong,
        "phuongThucThanhToan": phuongThucThanhToan,
        "hinhAnhMinhChung": hinhAnhMinhChung,
        "thoiGianChupAnh": thoiGianChupAnh?.toIso8601String(),
        "anhLichSuCuocGoi": anhLichSuCuocGoi,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json["id"] ?? "",
        senderName: json["senderName"] ?? "",
        senderPhone: json["senderPhone"] ?? "",
        receiverName: json["receiverName"] ?? "",
        receiverPhone: json["receiverPhone"] ?? "",
        pickupAddress: json["pickupAddress"] ?? "",
        deliveryAddress: json["deliveryAddress"] ?? "",
        price: (json["price"] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json["deliveryFee"] as num?)?.toDouble() ?? 0.0,
        status: json["status"] ?? "pending",
        pickupLatitude: (json["pickupLatitude"] as num?)?.toDouble() ?? 0.0,
        pickupLongitude: (json["pickupLongitude"] as num?)?.toDouble() ?? 0.0,
        deliveryLatitude: (json["deliveryLatitude"] as num?)?.toDouble() ?? 0.0,
        deliveryLongitude: (json["deliveryLongitude"] as num?)?.toDouble() ?? 0.0,
        maShipperAssigned: json["maShipperAssigned"],
        maDPVAssigned: json["maDPVAssigned"],
        thoiGianPhanCong: json["thoiGianPhanCong"] != null
            ? DateTime.parse(json["thoiGianPhanCong"])
            : null,
        thoiGianTao: json["thoiGianTao"] != null
            ? DateTime.parse(json["thoiGianTao"])
            : null,
        lyDoHuy: json["lyDoHuy"],
        nguoiHuy: json["nguoiHuy"],
        danhMucHang: json["danhMucHang"] ?? "Đồ ăn",
        kichThuoc: json["kichThuoc"] ?? "M",
        khoiLuong: (json["khoiLuong"] as num?)?.toDouble() ?? 1.0,
        phuongThucThanhToan: json["phuongThucThanhToan"] ?? "COD",
        hinhAnhMinhChung: json["hinhAnhMinhChung"],
        thoiGianChupAnh: json["thoiGianChupAnh"] != null
            ? DateTime.parse(json["thoiGianChupAnh"])
            : null,
        anhLichSuCuocGoi: json["anhLichSuCuocGoi"],
      );
}
