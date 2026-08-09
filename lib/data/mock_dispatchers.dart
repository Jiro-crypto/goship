import '../models/dispatcher_model.dart';

/// Dữ liệu mẫu Điều phối viên (prototype chưa có backend)
class MockDispatchers {
  static List<DispatcherModel> dispatchers = [
    DispatcherModel(
      maDPV: "DPV-01",
      tenDPV: "admin",
      phoneDPV: "0909111222",
      email: "admin@goship.vn",
      isOnline: true,
    ),
  ];

  static DispatcherModel getCurrentDispatcher() => dispatchers.first;
}
