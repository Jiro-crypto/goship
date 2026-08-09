// File: lib/firebase_options.dart
//
// ⚠️  PLACEHOLDER — File này cần được thay thế bằng file thật!
//
// Chạy lệnh sau để tạo file firebase_options.dart chính xác cho project của bạn:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Sau đó xóa file placeholder này và dùng file được tạo tự động.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️  THAY THẾ toàn bộ các giá trị bên dưới bằng config thật từ Firebase Console!

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAt-pBPbeRTgAbZO1tn646pwvcZ8IAFL8E',
    appId: '1:916905766262:android:6f0f81610766b69e729e57',
    messagingSenderId: '916905766262',
    projectId: 'logiroute-2a957',
    storageBucket: 'logiroute-2a957.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBq85ZixzSxdaqcIBbZ4jaXVbmiQEjGAg',
    appId: '1:916905766262:ios:942f741f74b1b3f1729e57',
    messagingSenderId: '916905766262',
    projectId: 'logiroute-2a957',
    storageBucket: 'logiroute-2a957.firebasestorage.app',
    iosBundleId: 'none',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR-MACOS-API-KEY',
    appId: 'YOUR-MACOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-PROJECT-ID.appspot.com',
    iosBundleId: 'com.example.goship',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-WEB-API-KEY',
    appId: 'YOUR-WEB-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-PROJECT-ID.appspot.com',
    authDomain: 'YOUR-PROJECT-ID.firebaseapp.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB_A9SJUIFSJoCuxFr8XXmz8F7od1-Jec0',
    appId: '1:916905766262:web:535da73f1aa7c349729e57',
    messagingSenderId: '916905766262',
    projectId: 'logiroute-2a957',
    authDomain: 'logiroute-2a957.firebaseapp.com',
    storageBucket: 'logiroute-2a957.firebasestorage.app',
  );
}
