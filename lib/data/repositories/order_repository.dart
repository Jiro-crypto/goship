import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../models/invoice_model.dart';
import '../../models/rejection_log_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Helper để lấy collection reference ---
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // --- Tạo OrderId tự động ---
  Future<String> _generateOrderId() async {
    DocumentReference counterRef = _firestore.collection('metadata').doc('counters');

    int newCount = await _firestore.runTransaction<int>((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);
      int currentCount = (snapshot.data() as Map?)?['orderCounter'] ?? 0;
      int nextCount = currentCount + 1;
      transaction.set(counterRef, {'orderCounter': nextCount});
      return nextCount;
    });

    String date = DateTime.now().toString().substring(2, 10).replaceAll('-', '');
    String paddedCount = newCount.toString().padLeft(4, '0');
    return 'ORD-$date-$paddedCount';
  }

  // --- Tạo đơn hàng mới ---
  Future<OrderModel> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String pickupAddress,
    required String deliveryAddress,
    required double codAmount,
    required double shippingFee,
    double weight = 0,
    String category = '',
    String size = '',
    int quantity = 1,
    String note = '',
    double? pickupLat,
    double? pickupLng,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      String newOrderId = await _generateOrderId();

      // Lấy thông tin customer từ collection
      DocumentSnapshot customerDoc = await _firestore.collection('customers').doc(userId).get();
      Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;

      OrderModel order = OrderModel(
        orderId: newOrderId,
        customerId: userId,
        customerName: customerData['name'] ?? '',
        customerPhone: customerData['phone'] ?? '',
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        deliveryAddress: deliveryAddress,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        weight: weight,
        category: category,
        size: size,
        quantity: quantity,
        codAmount: codAmount,
        shippingFee: shippingFee,
        note: note,
        status: OrderStatus.waitingForAssignment,
        createdAt: DateTime.now(),
        shipperId: null,
        shipperName: null,
        shipperPhone: null,
        shipperLicensePlate: null,
        dispatcherId: null,
        assignedAt: null,
        completedAt: null,
        cancelReason: null,
        cancelledBy: null,
        invoice: null,
      );

      await _ordersCollection.doc(newOrderId).set(order.toMap());
      return order;
    } catch (e) {
      print('Create order error: $e');
      rethrow;
    }
  }

  // --- Lấy đơn hàng theo ID ---
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      print('Get order error: $e');
      return null;
    }
  }

  // --- Lấy danh sách đơn của khách hàng (Stream real-time) ---
  Stream<List<OrderModel>> getOrdersByCustomer(String customerId) {
    return _ordersCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
        });
  }

  // --- Lấy danh sách đơn của Shipper theo trạng thái ---
  Stream<List<OrderModel>> getOrdersByShipper(
    String shipperId, {
    OrderStatus? status,
  }) {
    Query query = _ordersCollection.where('shipperId', isEqualTo: shipperId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.displayName);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  // --- Lấy danh sách đơn theo trạng thái (cho Admin) ---
  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _ordersCollection
        .where('status', isEqualTo: status.displayName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
        });
  }

  // --- Lấy danh sách đơn Chờ phân công (cho Admin) ---
  Stream<List<OrderModel>> getPendingOrders() {
    return _ordersCollection
        .where('status', isEqualTo: OrderStatus.waitingForAssignment.displayName)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
        });
  }

  // --- Phân công đơn cho Shipper ---
  Future<void> assignOrderToShipper({
    required String orderId,
    required String shipperId,
    required String dispatcherId,
  }) async {
    try {
      // Lấy thông tin shipper
      DocumentSnapshot shipperDoc = await _firestore.collection('shippers').doc(shipperId).get();
      Map<String, dynamic> shipperData = shipperDoc.data() as Map<String, dynamic>;

      await _ordersCollection.doc(orderId).update({
        'shipperId': shipperId,
        'shipperName': shipperData['name'] ?? '',
        'shipperPhone': shipperData['phone'] ?? '',
        'shipperLicensePlate': shipperData['licensePlate'] ?? '',
        'dispatcherId': dispatcherId,
        'status': OrderStatus.waitingForAcceptance.displayName,
        'assignedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Assign order error: $e');
      rethrow;
    }
  }

  // --- Shipper nhận đơn ---
  Future<void> acceptOrder(String orderId) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.waitingForPickup.displayName,
    });
  }

  // --- Shipper bắt đầu giao (chuyển sang Đang giao) ---
  Future<void> startDelivery(String orderId) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.delivering.displayName,
    });
  }

  // --- Xác nhận giao hàng thành công ---
  Future<void> confirmDeliverySuccess({
    required String orderId,
    required double confirmLat,
    required double confirmLng,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.delivered.displayName,
      'completedAt': FieldValue.serverTimestamp(),
      'invoice.confirmLat': confirmLat,
      'invoice.confirmLng': confirmLng,
    });
  }

  // --- Xác nhận giao hàng thất bại ---
  Future<void> confirmDeliveryFailed({
    required String orderId,
    required String reason,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.deliveryFailed.displayName,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Hủy đơn từ Khách hàng ---
  Future<void> cancelOrderByCustomer({
    required String orderId,
    required String reason,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.cancelled.displayName,
      'cancelReason': reason,
      'cancelledBy': 'Khách hàng',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Hủy đơn từ Điều phối viên ---
  Future<void> cancelOrderByDispatcher({
    required String orderId,
    required String reason,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.cancelled.displayName,
      'cancelReason': reason,
      'cancelledBy': 'Điều phối viên',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Cập nhật Invoice (sau khi upload ảnh) ---
  Future<void> updateInvoice(String orderId, InvoiceModel invoice) async {
    await _ordersCollection.doc(orderId).update({
      'invoice': invoice.toMap(),
    });
  }

  // --- Cập nhật vị trí Shipper (từ GPS) ---
  Future<void> updateShipperLocation({
    required String shipperId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('shippers').doc(shipperId).update({
      'currentLat': lat,
      'currentLng': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // --- UC17: Shipper từ chối đơn ---
  // Thực hiện 3 bước trong 1 Firestore transaction:
  // (1) Ghi rejection_log để lưu lịch sử từ chối
  // (2) Reset thông tin Shipper trên đơn về null
  // (3) Trả trạng thái đơn về 'Chờ phân công' để Admin xử lý lại
  Future<RejectionLogModel> rejectOrder({
    required String orderId,
    required String shipperId,
    required String shipperName,
    required String reason,
  }) async {
    // Chuẩn bị document mới cho rejection_log trước khi vào transaction
    final DocumentReference logRef =
        _firestore.collection('rejection_logs').doc();

    final RejectionLogModel rejectionLog = RejectionLogModel(
      id: logRef.id,
      orderId: orderId,
      shipperId: shipperId,
      shipperName: shipperName,
      reason: reason,
      rejectedAt: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // Kiểm tra đơn hàng còn tồn tại và đang ở trạng thái hợp lệ
        final DocumentSnapshot orderSnapshot =
            await transaction.get(_ordersCollection.doc(orderId));

        if (!orderSnapshot.exists) {
          throw Exception('Đơn hàng $orderId không tồn tại.');
        }

        final Map<String, dynamic> orderData =
            orderSnapshot.data() as Map<String, dynamic>;
        final String currentStatus = orderData['status'] ?? '';

        // Chỉ cho phép từ chối khi đơn đang ở trạng thái 'Chờ nhận'
        if (currentStatus != OrderStatus.waitingForAcceptance.displayName) {
          throw Exception(
            'Không thể từ chối đơn ở trạng thái "$currentStatus". '
            'Chỉ có thể từ chối khi đơn ở trạng thái "Chờ nhận".',
          );
        }

        // Bước 1: Ghi rejection_log
        transaction.set(logRef, {
          ...rejectionLog.toMap(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        // Bước 2 & 3: Reset Shipper và trả đơn về 'Chờ phân công'
        transaction.update(_ordersCollection.doc(orderId), {
          'status': OrderStatus.waitingForAssignment.displayName,
          'shipperId': null,
          'shipperName': null,
          'shipperPhone': null,
          'shipperLicensePlate': null,
          'dispatcherId': null,
          'assignedAt': null,
        });
      });

      return rejectionLog;
    } catch (e) {
      print('Reject order error: $e');
      rethrow;
    }
  }

  // --- UC03: Xử lý timeout 60 giây khi Shipper không phản hồi ---
  //
  // Luồng hoạt động:
  //   - Nếu dailyRejectionCount < 3: tự động TỪ CHỐI (ghi log + reset đơn + tăng biến đếm)
  //   - Nếu dailyRejectionCount >= 3: tự động NHẬN ĐƠN (chuyển sang 'Chờ giao')
  //
  // Lưu ý: dailyRejectionCount được reset về 0 vào đầu ngày mới bằng cách
  // so sánh [rejectionCountDate] với ngày hiện tại trong transaction.
  //
  // Hàm trả về [true] nếu đơn được TỰ ĐỘNG NHẬN, [false] nếu TỰ ĐỘNG TỪ CHỐI.
  Future<bool> handleOrderTimeout({
    required String orderId,
    required String shipperId,
    required String shipperName,
  }) async {
    const int maxDailyRejections = 3;

    // Chuẩn bị document rejection_log mới trước transaction
    final DocumentReference logRef =
        _firestore.collection('rejection_logs').doc();
    final DocumentReference shipperRef =
        _firestore.collection('shippers').doc(shipperId);

    // Xác định chuỗi ngày hôm nay, dùng UTC để đồng nhất với server
    final String todayStr =
        DateTime.now().toUtc().toString().substring(0, 10); // 'yyyy-MM-dd'

    bool wasAutoAccepted = false;

    try {
      await _firestore.runTransaction((transaction) async {
        // --- Đọc dữ liệu cần thiết ---
        final DocumentSnapshot orderSnapshot =
            await transaction.get(_ordersCollection.doc(orderId));
        final DocumentSnapshot shipperSnapshot =
            await transaction.get(shipperRef);

        if (!orderSnapshot.exists) {
          throw Exception('Đơn hàng $orderId không tồn tại.');
        }

        final Map<String, dynamic> orderData =
            orderSnapshot.data() as Map<String, dynamic>;
        final String currentStatus = orderData['status'] ?? '';

        // Guard: chỉ xử lý nếu đơn vẫn đang chờ nhận (tránh xử lý 2 lần)
        if (currentStatus != OrderStatus.waitingForAcceptance.displayName) {
          return;
        }

        // --- Đọc và cập nhật dailyRejectionCount ---
        final Map<String, dynamic> shipperData =
            shipperSnapshot.data() as Map<String, dynamic>? ?? {};

        final String? lastDate = shipperData['rejectionCountDate'];
        final int currentCount = shipperData['dailyRejectionCount'] ?? 0;

        // Reset về 0 nếu đã sang ngày mới
        final int todayCount = (lastDate == todayStr) ? currentCount : 0;

        if (todayCount < maxDailyRejections) {
          // ---- NHÁNH TỰ ĐỘNG TỪ CHỐI ----
          wasAutoAccepted = false;

          // Bước 1: Ghi rejection_log với lý do hệ thống
          transaction.set(logRef, {
            'orderId': orderId,
            'shipperId': shipperId,
            'shipperName': shipperName,
            'reason': 'Hệ thống tự động từ chối (không phản hồi sau 60 giây)',
            'rejectedAt': FieldValue.serverTimestamp(),
          });

          // Bước 2: Reset đơn hàng về 'Chờ phân công'
          transaction.update(_ordersCollection.doc(orderId), {
            'status': OrderStatus.waitingForAssignment.displayName,
            'shipperId': null,
            'shipperName': null,
            'shipperPhone': null,
            'shipperLicensePlate': null,
            'dispatcherId': null,
            'assignedAt': null,
          });

          // Bước 3: Tăng dailyRejectionCount + ghi nhận ngày hôm nay
          transaction.update(shipperRef, {
            'dailyRejectionCount': todayCount + 1,
            'rejectionCountDate': todayStr,
          });
        } else {
          // ---- NHÁNH TỰ ĐỘNG NHẬN ĐƠN ----
          wasAutoAccepted = true;

          // Chuyển trạng thái sang 'Chờ giao' (Shipper đã "nhận")
          transaction.update(_ordersCollection.doc(orderId), {
            'status': OrderStatus.waitingForPickup.displayName,
          });
        }
      });

      return wasAutoAccepted;
    } catch (e) {
      print('Handle order timeout error: $e');
      rethrow;
    }
  }
}