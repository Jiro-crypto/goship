import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/customer_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _customersCollection => _firestore.collection('customers');

  // Lấy thông tin khách hàng theo UID
  Future<CustomerModel?> getCustomerById(String uid) async {
    try {
      DocumentSnapshot doc = await _customersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return CustomerModel.fromFirestore(doc);
    } catch (e) {
      print('Get customer error: $e');
      return null;
    }
  }

  // Cập nhật thông tin khách hàng
  Future<void> updateCustomer(String uid, Map<String, dynamic> data) async {
    await _customersCollection.doc(uid).update(data);
  }

  // Stream lắng nghe thông tin khách hàng
  Stream<CustomerModel?> watchCustomer(String uid) {
    return _customersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CustomerModel.fromFirestore(doc);
    });
  }
  
  // Đảm bảo rằng tài liệu khách hàng tồn tại, nếu không thì tạo mới
  Future<void> ensureCustomerDoc(String uid, {String? email}) async {
  final doc = await _customersCollection.doc(uid).get();
  if (!doc.exists) {
    await _customersCollection.doc(uid).set({
      'uid': uid,
      'name': '',
      'phone': '',
      'email': email ?? '',
      'address': '',
      'avatar': '',
      'gender': '',
      'city': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
}