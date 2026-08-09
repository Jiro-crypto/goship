import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// DevSeedScreen — Chỉ dùng cho Demo / Dev
/// Nhấn nút để tạo:
/// - 1 tài khoản Firebase Auth cho Shipper (shipper@goship.vn / password123)
/// - 4 documents trong collection 'shippers' (1 active + 3 dummy)
/// ============================================================
class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});

  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _log = '';
  bool _isRunning = false;

  void _addLog(String msg) {
    setState(() => _log += '\n$msg');
  }

  Future<void> _seedAll() async {
    setState(() {
      _isRunning = true;
      _log = '⏳ Bắt đầu tạo dữ liệu...';
    });

    // ─── 1. Tạo tài khoản Firebase Auth cho Shipper demo ───────
    const String shipperEmail = 'shipper1@goship.vn';
    const String shipperPassword = 'password123';
    String shipperUid = '';

    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: shipperEmail,
        password: shipperPassword,
      );
      shipperUid = cred.user!.uid;
      _addLog('✅ Tạo tài khoản Auth: $shipperEmail (UID: $shipperUid)');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Đăng nhập để lấy UID
        try {
          UserCredential cred = await _auth.signInWithEmailAndPassword(
            email: shipperEmail,
            password: shipperPassword,
          );
          shipperUid = cred.user?.uid ?? '';
        } catch (_) {
          // Nếu Pigeon bug, vẫn lấy từ currentUser
          shipperUid = _auth.currentUser?.uid ?? '';
        }
        _addLog('ℹ️ Email đã tồn tại, lấy UID: $shipperUid');
      } else {
        _addLog('❌ Lỗi tạo Auth: ${e.code} - ${e.message}');
      }
    } catch (e) {
      // Workaround Pigeon bug
      shipperUid = _auth.currentUser?.uid ?? '';
      if (shipperUid.isNotEmpty) {
        _addLog('⚠️ Pigeon bug nhưng Auth OK. UID: $shipperUid');
      } else {
        _addLog('❌ Lỗi không xác định: $e');
      }
    }

    // ─── 2. Tạo 4 documents trong collection 'shippers' ────────
    final List<Map<String, dynamic>> shippers = [
      {
        'uid': shipperUid,
        'shipperId': 'SP-001',
        'name': 'Trần Minh Quân',
        'email': shipperEmail,
        'phone': '0912345678',
        'licensePlate': '51G-12345',
        'isActive': true,
        'currentLat': 10.7769,
        'currentLng': 106.7009,
        'dailyRejectionCount': 0,
        'rejectionCountDate': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'DEMO-SP-002',
        'shipperId': 'SP-002',
        'name': 'Lê Văn Bình',
        'email': 'shipper2@goship.vn',
        'phone': '0923456789',
        'licensePlate': '51F-67890',
        'isActive': false,
        'currentLat': 10.7800,
        'currentLng': 106.6950,
        'dailyRejectionCount': 0,
        'rejectionCountDate': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'DEMO-SP-003',
        'shipperId': 'SP-003',
        'name': 'Nguyễn Thị Hoa',
        'email': 'shipper3@goship.vn',
        'phone': '0934567890',
        'licensePlate': '51H-11223',
        'isActive': false,
        'currentLat': 10.7300,
        'currentLng': 106.7200,
        'dailyRejectionCount': 1,
        'rejectionCountDate': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'DEMO-SP-004',
        'shipperId': 'SP-004',
        'name': 'Phạm Công Đức',
        'email': 'shipper4@goship.vn',
        'phone': '0945678901',
        'licensePlate': '51K-33445',
        'isActive': false,
        'currentLat': 10.8000,
        'currentLng': 106.7100,
        'dailyRejectionCount': 0,
        'rejectionCountDate': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    ];

    // Dùng UID thực cho shipper đầu tiên nếu có
    if (shipperUid.isNotEmpty) {
      shippers[0]['uid'] = shipperUid;
    }

    for (final shipperData in shippers) {
      try {
        final String docId = shipperData['uid'] as String;
        await _firestore.collection('shippers').doc(docId).set(shipperData, SetOptions(merge: true));
        _addLog('✅ Shipper: ${shipperData['name']} (${shipperData['shipperId']})');
      } catch (e) {
        _addLog('❌ Lỗi tạo shipper ${shipperData['name']}: $e');
      }
    }

    // ─── 3. Gán shipper_id vào login_screen demo account ───────
    // Cập nhật demo login screen để shipper@goship.vn → điều hướng đến ShipperHomeScreen
    _addLog('\n────────────────────────────────────');
    _addLog('🎉 Hoàn tất!');
    _addLog('📱 Đăng nhập Shipper Demo:');
    _addLog('   Email: $shipperEmail');
    _addLog('   Password: $shipperPassword');
    _addLog('   → Vào màn hình ShipperHomeScreen');
    _addLog('────────────────────────────────────');

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev: Seed Dữ liệu Demo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Chỉ dùng cho Demo / Dev', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  SizedBox(height: 6),
                  Text('Nhấn nút bên dưới sẽ tạo:\n'
                    '• 1 tài khoản Firebase Auth: shipper1@goship.vn / password123\n'
                    '• 4 documents trong Firestore collection "shippers"\n'
                    '• Shipper SP-001 (Trần Minh Quân) là tài khoản ACTIVE để demo',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _seedAll,
                icon: _isRunning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(_isRunning ? 'Đang tạo dữ liệu...' : 'TẠO DỮ LIỆU DEMO',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _log.isEmpty ? '(Nhật ký sẽ hiển thị ở đây...)' : _log,
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
