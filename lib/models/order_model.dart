import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_model.dart';

enum OrderStatus {
  waitingForAssignment, // Chờ phân công
  waitingForAcceptance, // Chờ nhận
  waitingForPickup,     // Chờ giao
  delivering,           // Đang giao
  delivered,            // Đã giao
  deliveryFailed,       // Giao thất bại
  cancelled,            // Đã hủy
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.waitingForAssignment:
        return 'Chờ phân công';
      case OrderStatus.waitingForAcceptance:
        return 'Chờ nhận';
      case OrderStatus.waitingForPickup:
        return 'Chờ giao';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.deliveryFailed:
        return 'Giao thất bại';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static OrderStatus fromDisplayName(String name) {
    switch (name) {
      case 'Chờ phân công':
        return OrderStatus.waitingForAssignment;
      case 'Chờ nhận':
        return OrderStatus.waitingForAcceptance;
      case 'Chờ giao':
        return OrderStatus.waitingForPickup;
      case 'Đang giao':
        return OrderStatus.delivering;
      case 'Đã giao':
        return OrderStatus.delivered;
      case 'Giao thất bại':
        return OrderStatus.deliveryFailed;
      case 'Đã hủy':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.waitingForAssignment;
    }
  }
}

class OrderModel {
  final String orderId;
  final String customerId;
  final String customerName;
  final String customerPhone;

  // Denormalized Shipper info
  final String? shipperId;
  final String? shipperName;
  final String? shipperPhone;
  final String? shipperLicensePlate;

  final String? dispatcherId;

  // Receiver info
  final String receiverName;
  final String receiverPhone;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;

  // Goods info
  final double weight;
  final String category;
  final String size;
  final int quantity;
  final double codAmount;
  final double shippingFee;
  final String note;

  // Status & Time
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? cancelReason;
  final String? cancelledBy; // 'Khách hàng' hoặc 'Điều phối viên'

  // Invoice
  final InvoiceModel? invoice;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.shipperId,
    this.shipperName,
    this.shipperPhone,
    this.shipperLicensePlate,
    this.dispatcherId,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.weight,
    required this.category,
    required this.size,
    required this.quantity,
    required this.codAmount,
    required this.shippingFee,
    required this.note,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.cancelReason,
    this.cancelledBy,
    this.invoice,
  });

  // Từ Firestore Document -> Model
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shipperId: data['shipperId'],
      shipperName: data['shipperName'],
      shipperPhone: data['shipperPhone'],
      shipperLicensePlate: data['shipperLicensePlate'],
      dispatcherId: data['dispatcherId'],
      receiverName: data['receiverName'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      pickupLat: data['pickupLat']?.toDouble(),
      pickupLng: data['pickupLng']?.toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryLat: data['deliveryLat']?.toDouble(),
      deliveryLng: data['deliveryLng']?.toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      size: data['size'] ?? '',
      quantity: data['quantity'] ?? 1,
      codAmount: (data['codAmount'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      note: data['note'] ?? '',
      status: OrderStatusExtension.fromDisplayName(data['status'] ?? 'Chờ phân công'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelReason: data['cancelReason'],
      cancelledBy: data['cancelledBy'],
      invoice: InvoiceModel.fromMap(data['invoice']),
    );
  }

  // Model -> Map (để lưu lên Firestore)
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      if (shipperId != null) 'shipperId': shipperId,
      if (shipperName != null) 'shipperName': shipperName,
      if (shipperPhone != null) 'shipperPhone': shipperPhone,
      if (shipperLicensePlate != null) 'shipperLicensePlate': shipperLicensePlate,
      if (dispatcherId != null) 'dispatcherId': dispatcherId,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'pickupAddress': pickupAddress,
      if (pickupLat != null) 'pickupLat': pickupLat,
      if (pickupLng != null) 'pickupLng': pickupLng,
      'deliveryAddress': deliveryAddress,
      if (deliveryLat != null) 'deliveryLat': deliveryLat,
      if (deliveryLng != null) 'deliveryLng': deliveryLng,
      'weight': weight,
      'category': category,
      'size': size,
      'quantity': quantity,
      'codAmount': codAmount,
      'shippingFee': shippingFee,
      'note': note,
      'status': status.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      if (assignedAt != null) 'assignedAt': assignedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (cancelReason != null) 'cancelReason': cancelReason,
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (invoice != null) 'invoice': invoice!.toMap(),
    };
  }

  // CopyWith để tạo bản sao với thay đổi
  OrderModel copyWith({
    String? orderId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? shipperId,
    String? shipperName,
    String? shipperPhone,
    String? shipperLicensePlate,
    String? dispatcherId,
    String? receiverName,
    String? receiverPhone,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    double? weight,
    String? category,
    String? size,
    int? quantity,
    double? codAmount,
    double? shippingFee,
    String? note,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? cancelReason,
    String? cancelledBy,
    InvoiceModel? invoice,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shipperId: shipperId ?? this.shipperId,
      shipperName: shipperName ?? this.shipperName,
      shipperPhone: shipperPhone ?? this.shipperPhone,
      shipperLicensePlate: shipperLicensePlate ?? this.shipperLicensePlate,
      dispatcherId: dispatcherId ?? this.dispatcherId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      codAmount: codAmount ?? this.codAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      invoice: invoice ?? this.invoice,
    );
  }
}