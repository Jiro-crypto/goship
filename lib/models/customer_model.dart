import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String avatar;
  final String gender;
  final String city;
  final DateTime createdAt;

  CustomerModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.avatar = '',
    this.gender = '',
    this.city = '',
    required this.createdAt,
  });

  // Từ Firestore Document -> Model
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      avatar: data['avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      gender: data['gender'] ?? 'Nam',
      city: data['city'] ?? 'TP. Hồ Chí Minh',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Từ Map -> Model (dùng khi đọc từ query)
  factory CustomerModel.fromMap(Map<String, dynamic> data, String id) {
    return CustomerModel(
      uid: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      avatar: data['avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      gender: data['gender'] ?? 'Nam',
      city: data['city'] ?? 'TP. Hồ Chí Minh',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Model -> Map (để lưu lên Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'avatar': avatar,
      'gender': gender,
      'city': city,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}