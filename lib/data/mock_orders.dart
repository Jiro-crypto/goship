import '../models/order_model.dart';

class MockOrders {
  static List<OrderModel> orders = [
    OrderModel(
      id: "GS-7721",
      senderName: "Gong Cha Hồ Tùng Mậu",
      senderPhone: "0283912345",
      receiverName: "Anh Tuấn (Khách hàng)",
      receiverPhone: "0901234567",
      pickupAddress: "86 Hồ Tùng Mậu, Bến Nghé, Quận 1, TP. HCM",
      deliveryAddress: "252 Lê Văn Sỹ, Phường 1, Quận 3, TP. HCM",
      price: 120000,
      deliveryFee: 25000,
      status: "pending",
      pickupLatitude: 10.7719,
      pickupLongitude: 106.7038,
      deliveryLatitude: 10.7905,
      deliveryLongitude: 106.6775,
    ),
    OrderModel(
      id: "GS-3304",
      senderName: "Pizza Hut Cao Thắng",
      senderPhone: "19001822",
      receiverName: "Chị Lan",
      receiverPhone: "0934567890",
      pickupAddress: "38 Cao Thắng, Phường 5, Quận 3, TP. HCM",
      deliveryAddress: "152 Điện Biên Phủ, Phường 25, Bình Thạnh, TP. HCM",
      price: 320000,
      deliveryFee: 38000,
      status: "pending",
      pickupLatitude: 10.7770,
      pickupLongitude: 106.6800,
      deliveryLatitude: 10.8035,
      deliveryLongitude: 106.6980,
    ),
  ];
}
