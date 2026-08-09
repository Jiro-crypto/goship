/// ===============================
/// Entity: DIEUPHOIVIEN (LAB 3)
/// Bảng DIEUPHOIVIEN: MaDPV, TenDPV, PhoneDPV
/// ===============================
class DispatcherModel {
  final String maDPV;
  final String tenDPV;
  final String phoneDPV;

  final String email;
  bool isOnline;
  int soDonDaPhanCongTrongNgay; // KHÔNG final - tăng mỗi lần phân công

  DispatcherModel({
    required this.maDPV,
    required this.tenDPV,
    required this.phoneDPV,
    this.email = "",
    this.isOnline = true,
    this.soDonDaPhanCongTrongNgay = 0,
  });
}
