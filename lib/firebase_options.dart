// ─────────────────────────────────────────────────────────
// PLACEHOLDER — Replace this file by running:
//   flutterfire configure
//
// That command will auto-generate the correct values for
// your Firebase project. You need:
//   - Firebase CLI installed (npm install -g firebase-tools)
//   - FlutterFire CLI (dart pub global activate flutterfire_cli)
//
// Then run inside d:\AbsensiKaryawan:
//   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// ⚠️  REALTIME DATABASE: Make sure to also set the databaseURL field!
//     It looks like: https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com
//
// ─────────────────────────────────────────────────────────

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for ${defaultTargetPlatform.name}. '
          'Run flutterfire configure.',
        );
    }
  }

  // ⚠️  REPLACE these placeholder values with your actual Firebase config!

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzSSUaEDqE-NCaSzqCdsGK3kBsdEVFVoE',
    appId: '1:74123025201:android:f963a8c12ca6f2418dae10',
    messagingSenderId: '74123025201',
    projectId: 'absensikaryawan-3a199',
    storageBucket: 'absensikaryawan-3a199.firebasestorage.app',
    databaseURL: 'https://absensikaryawan-3a199-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNb96_7BG4ft1_AoMGSFnLlHZGJWLDi44',
    appId: '1:74123025201:ios:a993e4d748d44f848dae10',
    messagingSenderId: '74123025201',
    projectId: 'absensikaryawan-3a199',
    storageBucket: 'absensikaryawan-3a199.firebasestorage.app',
    databaseURL: 'https://absensikaryawan-3a199-default-rtdb.asia-southeast1.firebasedatabase.app',
    iosBundleId: 'com.absensi.absensiKaryawan',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAde30Pf98ljMjgbm1uong_YxsCiwrXtqM',
    appId: '1:74123025201:web:2b3d1f38a9b5feb88dae10',
    messagingSenderId: '74123025201',
    projectId: 'absensikaryawan-3a199',
    authDomain: 'absensikaryawan-3a199.firebaseapp.com',
    storageBucket: 'absensikaryawan-3a199.firebasestorage.app',
    measurementId: 'G-HHJS04CCNC',
  );
}
