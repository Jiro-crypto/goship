import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String? invoiceId;
  final String? imageUrl;
  final DateTime? confirmedAt;
  final String paymentStatus; // 'Chưa thanh toán' | 'Đã thanh toán'
  final String? paymentMethod;
  final double? photoLat;
  final double? photoLng;
  final String? shipperNote;
  final double? confirmLat;
  final double? confirmLng;
  final String? transactionId;
  final DateTime? paymentTime;

  InvoiceModel({
    this.invoiceId,
    this.imageUrl,
    this.confirmedAt,
    required this.paymentStatus,
    this.paymentMethod,
    this.photoLat,
    this.photoLng,
    this.shipperNote,
    this.confirmLat,
    this.confirmLng,
    this.transactionId,
    this.paymentTime,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return InvoiceModel(paymentStatus: 'Chưa thanh toán');
    }
    return InvoiceModel(
      invoiceId: data['invoiceId'],
      imageUrl: data['imageUrl'],
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      paymentStatus: data['paymentStatus'] ?? 'Chưa thanh toán',
      paymentMethod: data['paymentMethod'],
      photoLat: data['photoLat']?.toDouble(),
      photoLng: data['photoLng']?.toDouble(),
      shipperNote: data['shipperNote'],
      confirmLat: data['confirmLat']?.toDouble(),
      confirmLng: data['confirmLng']?.toDouble(),
      transactionId: data['transactionId'],
      paymentTime: (data['paymentTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (confirmedAt != null) 'confirmedAt': confirmedAt,
      'paymentStatus': paymentStatus,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (photoLat != null) 'photoLat': photoLat,
      if (photoLng != null) 'photoLng': photoLng,
      if (shipperNote != null) 'shipperNote': shipperNote,
      if (confirmLat != null) 'confirmLat': confirmLat,
      if (confirmLng != null) 'confirmLng': confirmLng,
      if (transactionId != null) 'transactionId': transactionId,
      if (paymentTime != null) 'paymentTime': paymentTime,
    };
  }
}