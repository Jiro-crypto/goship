import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shipper_model.dart';

class ShipperRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _shippersCollection => _firestore.collection('shippers');

  // Lấy danh sách Shipper đang hoạt động
  Future<List<ShipperModel>> getActiveShippers() async {
    try {
      QuerySnapshot snapshot = await _shippersCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => ShipperModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Get active shippers error: $e');
      return [];
    }
  }

  // Stream danh sách Shipper đang hoạt động (real-time)
  Stream<List<ShipperModel>> watchActiveShippers() {
    return _shippersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ShipperModel.fromFirestore(doc)).toList();
        });
  }

  // Stream toàn bộ danh sách Shipper (cho Dashboard)
  Stream<List<ShipperModel>> watchAllShippers() {
    return _shippersCollection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ShipperModel.fromFirestore(doc)).toList();
        });
  }

  // Lấy thông tin Shipper theo ID
  Future<ShipperModel?> getShipperById(String shipperId) async {
    try {
      DocumentSnapshot doc = await _shippersCollection.doc(shipperId).get();
      if (!doc.exists) return null;
      return ShipperModel.fromFirestore(doc);
    } catch (e) {
      print('Get shipper error: $e');
      return null;
    }
  }

  // Cập nhật vị trí Shipper (dùng trong UC07)
  Future<void> updateLocation({
    required String shipperId,
    required double lat, // Latitude (vĩ độ)
    required double lng, // Longitude (kinh độ)
  }) async {
    await _shippersCollection.doc(shipperId).update({
      'currentLat': lat,
      'currentLng': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Hàm theo dõi vị trí của Shipper theo shipperId 
  Stream<ShipperModel?> watchShipperLocation(String shipperId) {
    return _shippersCollection.doc(shipperId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ShipperModel.fromFirestore(doc);
    });
  }

  // UC17/UC03: Tăng biến đếm số lần từ chối trong ngày
  Future<void> updateShipperRejectionCount(String shipperId) async {
    final String todayStr = DateTime.now().toUtc().toString().substring(0, 10);
    final doc = await _shippersCollection.doc(shipperId).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String? lastDate = data['rejectionCountDate'];
    final int currentCount = data['dailyRejectionCount'] ?? 0;
    final int todayCount = (lastDate == todayStr) ? currentCount : 0;

    await _shippersCollection.doc(shipperId).update({
      'dailyRejectionCount': todayCount + 1,
      'rejectionCountDate': todayStr,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}