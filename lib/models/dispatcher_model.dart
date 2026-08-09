/// ===============================
/// UC: ĐIỀU PHỐI VIÊN (ADMIN)
/// Tài liệu: LAB 3 - Thiết kế dữ liệu
/// Entity: DIEUPHOIVIEN (MaDPV)
/// ===============================
class DispatcherModel {
  // Khóa chính
  final String maDPV;                  // Mã điều phối viên
  final String tenDPV;                 // Tên điều phối viên

  // Thông tin cá nhân
  final String email;
  final String phone;
  final String avatar;
  final String gender;
  final String city;

  // Thông tin nghiệp vụ
  final String khuVucQuanLy;          // "Quận 1, Quận 3, Bình Thạnh"
  final String caLamViec;             // "Sáng 06:00-14:00"
  
  // ⚠️ KHÔNG được để final — cần tăng giá trị mỗi lần phân công (BR_assignOrder_06)
  int soDonDaPhanCongTrongNgay;

  // Trạng thái phiên làm việc
  bool isOnline;                      // Đang trong ca hay đã đăng xuất

  DispatcherModel({
    required this.maDPV,
    required this.tenDPV,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.gender,
    required this.city,
    required this.khuVucQuanLy,
    required this.caLamViec,
    this.soDonDaPhanCongTrongNgay = 0,
    this.isOnline = false,
  });

  /// Object → Map (phục vụ SharedPreferences / lưu session)
  Map<String, dynamic> toJson() => {
        "maDPV": maDPV,
        "tenDPV": tenDPV,
        "email": email,
        "phone": phone,
        "avatar": avatar,
        "gender": gender,
        "city": city,
        "khuVucQuanLy": khuVucQuanLy,
        "caLamViec": caLamViec,
        "soDonDaPhanCongTrongNgay": soDonDaPhanCongTrongNgay,
        "isOnline": isOnline,
      };

  /// Map → Object
  factory DispatcherModel.fromJson(Map<String, dynamic> json) => DispatcherModel(
        maDPV: json["maDPV"] ?? "",
        tenDPV: json["tenDPV"] ?? "",
        email: json["email"] ?? "",
        phone: json["phone"] ?? "",
        avatar: json["avatar"] ?? "",
        gender: json["gender"] ?? "",
        city: json["city"] ?? "",
        khuVucQuanLy: json["khuVucQuanLy"] ?? "",
        caLamViec: json["caLamViec"] ?? "",
        soDonDaPhanCongTrongNgay: json["soDonDaPhanCongTrongNgay"] ?? 0,
        isOnline: json["isOnline"] ?? false,
      );

  @override
  String toString() =>
      "Dispatcher[$maDPV] $tenDPV <$email> | Khu vực: $khuVucQuanLy | Ca: $caLamViec | Online: $isOnline";
}
