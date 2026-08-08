class OrderModel {
  final String orderId;
  final String maKH;
  String maShipper;
  final String maDPV;
  final String tenNguoiNhan;
  final String sdtNguoiNhan;
  final String diaChiLay;
  final double latLay;
  final double lngLay;
  final String diaChiGiao;
  final double latGiao;
  final double lngGiao;
  final double khoiLuong;
  final String ghiChu;
  final double tienCOD;
  final double phiShip;
  String trangThaiDon; // Chờ phân công, Chờ giao, Đang giao, Đã giao, Đã hủy, Giao thất bại
  final DateTime thoiGianTao;
  final DateTime? thoiGianPhanCong;
  final DateTime? thoiGianHoanThanh;
  String? lyDoHuy;
  String? nguoiHuy; // 'KhachHang' hoặc 'DieuPhoiVien'
  final String? danhMucHang;
  final String? kichThuoc;
  final int? soLuong;
  final String? urlAnhMinhChung;
  final String senderName;
  final String senderPhone;

  OrderModel({
    String? orderId,
    String? id,
    this.maKH = 'KH-001',
    this.maShipper = '',
    this.maDPV = '',
    String? tenNguoiNhan,
    String? receiverName,
    String? sdtNguoiNhan,
    String? receiverPhone,
    String? diaChiLay,
    String? pickupAddress,
    double? latLay,
    double? pickupLatitude,
    double? lngLay,
    double? pickupLongitude,
    String? diaChiGiao,
    String? deliveryAddress,
    double? latGiao,
    double? deliveryLatitude,
    double? lngGiao,
    double? deliveryLongitude,
    this.khoiLuong = 0.0,
    this.ghiChu = '',
    double? tienCOD,
    double? price,
    double? phiShip,
    double? deliveryFee,
    String? trangThaiDon,
    String? status,
    DateTime? thoiGianTao,
    this.thoiGianPhanCong,
    this.thoiGianHoanThanh,
    this.lyDoHuy,
    this.nguoiHuy,
    this.danhMucHang,
    this.kichThuoc,
    this.soLuong = 1,
    this.urlAnhMinhChung,
    this.senderName = 'GoShip Store',
    this.senderPhone = '19001000',
  })  : orderId = orderId ?? id ?? '',
        tenNguoiNhan = tenNguoiNhan ?? receiverName ?? '',
        sdtNguoiNhan = sdtNguoiNhan ?? receiverPhone ?? '',
        diaChiLay = diaChiLay ?? pickupAddress ?? '',
        latLay = latLay ?? pickupLatitude ?? 0.0,
        lngLay = lngLay ?? pickupLongitude ?? 0.0,
        diaChiGiao = diaChiGiao ?? deliveryAddress ?? '',
        latGiao = latGiao ?? deliveryLatitude ?? 0.0,
        lngGiao = lngGiao ?? deliveryLongitude ?? 0.0,
        tienCOD = tienCOD ?? price ?? 0.0,
        phiShip = phiShip ?? deliveryFee ?? 0.0,
        trangThaiDon = trangThaiDon ?? (status == 'delivering' ? 'Đang giao' : status == 'delivered' ? 'Đã giao' : status == 'cancelled' ? 'Đã hủy' : status ?? 'Chờ phân công'),
        thoiGianTao = thoiGianTao ?? DateTime.now();

  // Backward compatibility getters & setters
  String get id => orderId;
  String get receiverName => tenNguoiNhan;
  String get receiverPhone => sdtNguoiNhan;
  String get pickupAddress => diaChiLay;
  String get deliveryAddress => diaChiGiao;
  double get price => tienCOD;
  double get deliveryFee => phiShip;
  double get pickupLatitude => latLay;
  double get pickupLongitude => lngLay;
  double get deliveryLatitude => latGiao;
  double get deliveryLongitude => lngGiao;

  String get status {
    switch (trangThaiDon) {
      case 'Chờ phân công':
      case 'Chờ giao':
        return 'pending';
      case 'Đang giao':
        return 'delivering';
      case 'Đã giao':
        return 'delivered';
      case 'Đã hủy':
        return 'cancelled';
      default:
        return trangThaiDon;
    }
  }

  set status(String val) {
    switch (val) {
      case 'pending':
        trangThaiDon = 'Chờ phân công';
        break;
      case 'delivering':
        trangThaiDon = 'Đang giao';
        break;
      case 'delivered':
        trangThaiDon = 'Đã giao';
        break;
      case 'cancelled':
        trangThaiDon = 'Đã hủy';
        break;
      default:
        trangThaiDon = val;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "orderId": orderId,
      "maKH": maKH,
      "maShipper": maShipper,
      "maDPV": maDPV,
      "tenNguoiNhan": tenNguoiNhan,
      "sdtNguoiNhan": sdtNguoiNhan,
      "diaChiLay": diaChiLay,
      "latLay": latLay,
      "lngLay": lngLay,
      "diaChiGiao": diaChiGiao,
      "latGiao": latGiao,
      "lngGiao": lngGiao,
      "khoiLuong": khoiLuong,
      "ghiChu": ghiChu,
      "tienCOD": tienCOD,
      "phiShip": phiShip,
      "trangThaiDon": trangThaiDon,
      "thoiGianTao": thoiGianTao.toIso8601String(),
      "thoiGianPhanCong": thoiGianPhanCong?.toIso8601String(),
      "thoiGianHoanThanh": thoiGianHoanThanh?.toIso8601String(),
      "lyDoHuy": lyDoHuy,
      "nguoiHuy": nguoiHuy,
      "danhMucHang": danhMucHang,
      "kichThuoc": kichThuoc,
      "soLuong": soLuong,
      "urlAnhMinhChung": urlAnhMinhChung,
      "senderName": senderName,
      "senderPhone": senderPhone,
    };
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 1;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 1;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json["orderId"]?.toString() ?? json["id"]?.toString() ?? "",
      maKH: json["maKH"]?.toString() ?? "KH-001",
      maShipper: json["maShipper"]?.toString() ?? "",
      maDPV: json["maDPV"]?.toString() ?? "",
      tenNguoiNhan: json["tenNguoiNhan"]?.toString() ?? json["receiverName"]?.toString() ?? "",
      sdtNguoiNhan: json["sdtNguoiNhan"]?.toString() ?? json["receiverPhone"]?.toString() ?? "",
      diaChiLay: json["diaChiLay"]?.toString() ?? json["pickupAddress"]?.toString() ?? "",
      latLay: _parseDouble(json["latLay"] ?? json["pickupLatitude"]),
      lngLay: _parseDouble(json["lngLay"] ?? json["pickupLongitude"]),
      diaChiGiao: json["diaChiGiao"]?.toString() ?? json["deliveryAddress"]?.toString() ?? "",
      latGiao: _parseDouble(json["latGiao"] ?? json["deliveryLatitude"]),
      lngGiao: _parseDouble(json["lngGiao"] ?? json["deliveryLongitude"]),
      khoiLuong: _parseDouble(json["khoiLuong"]),
      ghiChu: json["ghiChu"]?.toString() ?? "",
      tienCOD: _parseDouble(json["tienCOD"] ?? json["price"]),
      phiShip: _parseDouble(json["phiShip"] ?? json["deliveryFee"]),
      trangThaiDon: json["trangThaiDon"]?.toString() ?? (json["status"] == "delivering" ? "Đang giao" : json["status"] == "delivered" ? "Đã giao" : "Chờ phân công"),
      thoiGianTao: json["thoiGianTao"] != null ? (DateTime.tryParse(json["thoiGianTao"].toString()) ?? DateTime.now()) : DateTime.now(),
      thoiGianPhanCong: json["thoiGianPhanCong"] != null ? DateTime.tryParse(json["thoiGianPhanCong"].toString()) : null,
      thoiGianHoanThanh: json["thoiGianHoanThanh"] != null ? DateTime.tryParse(json["thoiGianHoanThanh"].toString()) : null,
      lyDoHuy: json["lyDoHuy"]?.toString(),
      nguoiHuy: json["nguoiHuy"]?.toString(),
      danhMucHang: json["danhMucHang"]?.toString(),
      kichThuoc: json["kichThuoc"]?.toString(),
      soLuong: _parseInt(json["soLuong"]),
      urlAnhMinhChung: json["urlAnhMinhChung"]?.toString(),
      senderName: json["senderName"]?.toString() ?? "GoShip Store",
      senderPhone: json["senderPhone"]?.toString() ?? "19001000",
    );
  }
}
