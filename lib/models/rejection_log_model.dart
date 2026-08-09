import 'package:cloud_firestore/cloud_firestore.dart';

class RejectionLogModel {
  final String id;
  final String orderId;
  final String shipperId;
  final String shipperName;
  final String reason;
  final DateTime rejectedAt;

  RejectionLogModel({
    required this.id,
    required this.orderId,
    required this.shipperId,
    required this.shipperName,
    required this.reason,
    required this.rejectedAt,
  });

  factory RejectionLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RejectionLogModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      shipperId: data['shipperId'] ?? '',
      shipperName: data['shipperName'] ?? '',
      reason: data['reason'] ?? '',
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'shipperId': shipperId,
      'shipperName': shipperName,
      'reason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    };
  }
}