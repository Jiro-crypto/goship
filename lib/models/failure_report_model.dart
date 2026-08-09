import 'package:cloud_firestore/cloud_firestore.dart';

class FailureReportModel {
  final String id;
  final String orderId;
  final String shipperId;
  final String shipperName;
  final String reason; // 'Khách từ chối nhận' hoặc 'Không liên lạc được'
  final String? callScreenshotUrl;
  final DateTime reportedAt;

  FailureReportModel({
    required this.id,
    required this.orderId,
    required this.shipperId,
    required this.shipperName,
    required this.reason,
    this.callScreenshotUrl,
    required this.reportedAt,
  });

  factory FailureReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FailureReportModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      shipperId: data['shipperId'] ?? '',
      shipperName: data['shipperName'] ?? '',
      reason: data['reason'] ?? '',
      callScreenshotUrl: data['callScreenshotUrl'],
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'shipperId': shipperId,
      'shipperName': shipperName,
      'reason': reason,
      if (callScreenshotUrl != null) 'callScreenshotUrl': callScreenshotUrl,
      'reportedAt': FieldValue.serverTimestamp(),
    };
  }
}