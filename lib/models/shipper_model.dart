import 'package:cloud_firestore/cloud_firestore.dart';

class ShipperModel {
  final String uid;
  final String shipperId;
  final String name;
  final String phone;
  final String licensePlate;
  final bool isActive;
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastUpdated;

  // Dùng cho UC03: theo dõi số lần tự động từ chối trong ngày
  final int dailyRejectionCount;   // Số lần đã từ chối hôm nay (tự động hoặc thủ công)
  final String? rejectionCountDate; // Ngày ghi nhận, format 'yyyy-MM-dd' (vd: '2026-08-09')

  ShipperModel({
    required this.uid,
    required this.shipperId,
    required this.name,
    required this.phone,
    required this.licensePlate,
    required this.isActive,
    this.currentLat,
    this.currentLng,
    this.lastUpdated,
    this.dailyRejectionCount = 0,
    this.rejectionCountDate,
  });

  factory ShipperModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShipperModel(
      uid: doc.id,
      shipperId: data['shipperId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      isActive: data['isActive'] ?? true,
      currentLat: data['currentLat']?.toDouble(),
      currentLng: data['currentLng']?.toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      dailyRejectionCount: data['dailyRejectionCount'] ?? 0,
      rejectionCountDate: data['rejectionCountDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shipperId': shipperId,
      'name': name,
      'phone': phone,
      'licensePlate': licensePlate,
      'isActive': isActive,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'lastUpdated': FieldValue.serverTimestamp(),
      'dailyRejectionCount': dailyRejectionCount,
      if (rejectionCountDate != null) 'rejectionCountDate': rejectionCountDate,
    };
  }
}
