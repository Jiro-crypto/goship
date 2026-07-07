class OrderModel {
  final String id;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final double price;
  final double deliveryFee;
  String status; // 'pending', 'delivering', 'delivered'
  final double pickupLatitude;
  final double pickupLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;

  OrderModel({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.price,
    required this.deliveryFee,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "senderName": senderName,
      "senderPhone": senderPhone,
      "receiverName": receiverName,
      "receiverPhone": receiverPhone,
      "pickupAddress": pickupAddress,
      "deliveryAddress": deliveryAddress,
      "price": price,
      "deliveryFee": deliveryFee,
      "status": status,
      "pickupLatitude": pickupLatitude,
      "pickupLongitude": pickupLongitude,
      "deliveryLatitude": deliveryLatitude,
      "deliveryLongitude": deliveryLongitude,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json["id"] ?? "",
      senderName: json["senderName"] ?? "",
      senderPhone: json["senderPhone"] ?? "",
      receiverName: json["receiverName"] ?? "",
      receiverPhone: json["receiverPhone"] ?? "",
      pickupAddress: json["pickupAddress"] ?? "",
      deliveryAddress: json["deliveryAddress"] ?? "",
      price: (json["price"] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json["deliveryFee"] as num?)?.toDouble() ?? 0.0,
      status: json["status"] ?? "pending",
      pickupLatitude: (json["pickupLatitude"] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json["pickupLongitude"] as num?)?.toDouble() ?? 0.0,
      deliveryLatitude: (json["deliveryLatitude"] as num?)?.toDouble() ?? 0.0,
      deliveryLongitude: (json["deliveryLongitude"] as num?)?.toDouble() ?? 0.0,
    );
  }
}
