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

  // Đọc an toàn một trường String: null / sai kiểu -> chuỗi rỗng.
  // Không gán giá trị mặc định giả (vd: 'Nam', 'TP. Hồ Chí Minh') để UI
  // phân biệt được dữ liệu "chưa cập nhật" với dữ liệu thật.
  static String _str(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String ? value.trim() : '';
  }

  // Từ Firestore Document -> Model
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return CustomerModel.fromMap(data, doc.id);
  }

  // Từ Map -> Model (dùng khi đọc từ query)
  factory CustomerModel.fromMap(Map<String, dynamic> data, String id) {
    return CustomerModel(
      uid: id,
      name: _str(data, 'name'),
      phone: _str(data, 'phone'),
      email: _str(data, 'email'),
      address: _str(data, 'address'),
      avatar: _str(data, 'avatar'),
      gender: _str(data, 'gender'),
      city: _str(data, 'city'),
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
