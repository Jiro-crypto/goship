import 'package:cloud_firestore/cloud_firestore.dart';

class OrderIdGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> generateOrderId() async {
    DocumentReference counterRef = _firestore.collection('metadata').doc('counters');
    
    int newCount = await _firestore.runTransaction<int>((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);
      int currentCount = (snapshot.data() as Map?)?['orderCounter'] ?? 0;
      int nextCount = currentCount + 1;
      
      transaction.set(counterRef, {'orderCounter': nextCount});
      return nextCount;
    });

    // Format: ORD-YYMMDD-XXXX
    String date = DateTime.now().toString().substring(2, 10).replaceAll('-', '');
    String paddedCount = newCount.toString().padLeft(4, '0');
    return 'ORD-$date-$paddedCount';
  }
}