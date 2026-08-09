import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_id_generator.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo đơn hàng mới
  static Future<String> createOrder({
    required String customerName,
    required String customerPhone,
    required String receiverName,
    required String receiverPhone,
    required String pickupAddress,
    required String deliveryAddress,
    required double codAmount,
    required double shippingFee,
  }) async {
    try {
      String newOrderId = await OrderIdGenerator.generateOrderId();
      User? user = FirebaseAuth.instance.currentUser;
      String customerId = user?.uid ?? '';

      Map<String, dynamic> orderData = {
        'orderId': newOrderId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'shipperId': null,
        'shipperName': null,
        'shipperPhone': null,
        'shipperLicensePlate': null,
        'dispatcherId': null,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'pickupAddress': pickupAddress,
        'pickupLat': null,
        'pickupLng': null,
        'deliveryAddress': deliveryAddress,
        'deliveryLat': null,
        'deliveryLng': null,
        'weight': 0,
        'category': '',
        'size': '',
        'quantity': 1,
        'codAmount': codAmount,
        'shippingFee': shippingFee,
        'note': '',
        'status': 'Chờ phân công',
        'createdAt': FieldValue.serverTimestamp(),
        'assignedAt': null,
        'completedAt': null,
        'cancelReason': null,
        'cancelledBy': null,
        'invoice': null,
      };

      await _firestore.collection('orders').doc(newOrderId).set(orderData);
      return newOrderId;
    } catch (e) {
      print("Lỗi tạo đơn: $e");
      rethrow;
    }
  }

  // Lấy danh sách đơn hàng theo khách hàng
  static Stream<QuerySnapshot> getOrdersByCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Lấy chi tiết một đơn
  static Future<DocumentSnapshot> getOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).get();
  }

  // Cập nhật trạng thái đơn hàng
  static Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore.collection('orders').doc(orderId).update({
      'status': status,
      if (status == 'Đã giao' || status == 'Giao thất bại')
        'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật invoice (thêm ảnh)
  static Future<void> updateInvoice(String orderId, Map<String, dynamic> invoiceData) {
    return _firestore.collection('orders').doc(orderId).update({
      'invoice': invoiceData,
    });
  }

  // ... các hàm khác (phân công, shipper nhận, v.v.)
}