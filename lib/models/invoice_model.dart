class InvoiceModel {
  final String maHD;
  final String orderId;
  final String? urlAnhMinhChung;
  final DateTime? thoiGianXacNhan;
  String trangThaiTT; // 'Chưa thanh toán' hoặc 'Đã thanh toán'
  String? phuongThucTT; // 'Tiền mặt', 'MoMo', 'VNPay'
  final double? latChup;
  final double? lngChup;
  final String? ghiChuShipper;
  final double? latXacNhan;
  final double? lngXacNhan;
  String? maGiaoDich;
  DateTime? thoiDiemThanhToan;

  InvoiceModel({
    required this.maHD,
    required this.orderId,
    this.urlAnhMinhChung,
    this.thoiGianXacNhan,
    this.trangThaiTT = 'Chưa thanh toán',
    this.phuongThucTT,
    this.latChup,
    this.lngChup,
    this.ghiChuShipper,
    this.latXacNhan,
    this.lngXacNhan,
    this.maGiaoDich,
    this.thoiDiemThanhToan,
  });

  Map<String, dynamic> toJson() {
    return {
      'maHD': maHD,
      'orderId': orderId,
      'urlAnhMinhChung': urlAnhMinhChung,
      'thoiGianXacNhan': thoiGianXacNhan?.toIso8601String(),
      'trangThaiTT': trangThaiTT,
      'phuongThucTT': phuongThucTT,
      'latChup': latChup,
      'lngChup': lngChup,
      'ghiChuShipper': ghiChuShipper,
      'latXacNhan': latXacNhan,
      'lngXacNhan': lngXacNhan,
      'maGiaoDich': maGiaoDich,
      'thoiDiemThanhToan': thoiDiemThanhToan?.toIso8601String(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      maHD: json['maHD'] ?? '',
      orderId: json['orderId'] ?? '',
      urlAnhMinhChung: json['urlAnhMinhChung'],
      thoiGianXacNhan: json['thoiGianXacNhan'] != null ? DateTime.parse(json['thoiGianXacNhan']) : null,
      trangThaiTT: json['trangThaiTT'] ?? 'Chưa thanh toán',
      phuongThucTT: json['phuongThucTT'],
      latChup: (json['latChup'] as num?)?.toDouble(),
      lngChup: (json['lngChup'] as num?)?.toDouble(),
      ghiChuShipper: json['ghiChuShipper'],
      latXacNhan: (json['latXacNhan'] as num?)?.toDouble(),
      lngXacNhan: (json['lngXacNhan'] as num?)?.toDouble(),
      maGiaoDich: json['maGiaoDich'],
      thoiDiemThanhToan: json['thoiDiemThanhToan'] != null ? DateTime.parse(json['thoiDiemThanhToan']) : null,
    );
  }
}
