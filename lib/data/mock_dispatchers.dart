import '../models/dispatcher_model.dart';

/// ===============================
/// Dữ liệu mẫu Điều Phối Viên (LAB 3)
/// ===============================
class MockDispatchers {
  static List<DispatcherModel> dispatchers = [
    DispatcherModel(
      maDPV: "DPV-001",
      tenDPV: "admin",                          // ✅ Đổi từ "Trần Lê Minh Toàn"
      email: "admin@goship.vn",
      phone: "0909111222",
      avatar: "https://cdn-icons-png.flaticon.com/512/3075/3075970.png",
      gender: "Nam",
      city: "TP. HCM",
      khuVucQuanLy: "Quận 1, Quận 3, Bình Thạnh",
      caLamViec: "Ca sáng (06:00 - 14:00)",
      soDonDaPhanCongTrongNgay: 7,
      isOnline: true,
    ),
    DispatcherModel(
      maDPV: "DPV-002",
      tenDPV: "Nguyễn Thị Hồng",
      email: "hongnt@goship.vn",
      phone: "0909333444",
      avatar: "https://cdn-icons-png.flaticon.com/512/3075/3075935.png",
      gender: "Nữ",
      city: "TP. HCM",
      khuVucQuanLy: "Quận 7, Nhà Bè, Q.4",
      caLamViec: "Ca chiều (14:00 - 22:00)",
      soDonDaPhanCongTrongNgay: 0,
      isOnline: false,
    ),
  ];

  static DispatcherModel getCurrentDispatcher() =>
      dispatchers.firstWhere((d) => d.isOnline, orElse: () => dispatchers.first);

  static void resetDailyCounters() {
    for (var d in dispatchers) {
      d.soDonDaPhanCongTrongNgay = 0;
    }
  }
}
