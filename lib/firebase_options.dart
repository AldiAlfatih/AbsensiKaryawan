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
    apiKey: 'AIzaSyBxR8MSlnxD1wtMxm4kZSL6Zvrct7YVfUg',
    appId: '1:1095551068022:android:97b14998139d0326f4fc57',
    messagingSenderId: '1095551068022',
    projectId: 'absensikaryawan-d5b76',
    databaseURL: 'https://absensikaryawan-d5b76-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'absensikaryawan-d5b76.firebasestorage.app',
  );

  // databaseURL is REQUIRED for Realtime Database to work.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.absensi.absensiKaryawan',
    databaseURL: 'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCfWpztsuJdn-jz-1aTdBelXNBqahUUsac',
    appId: '1:1095551068022:web:cd02f22f9ce19471f4fc57',
    messagingSenderId: '1095551068022',
    projectId: 'absensikaryawan-d5b76',
    authDomain: 'absensikaryawan-d5b76.firebaseapp.com',
    databaseURL: 'https://absensikaryawan-d5b76-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'absensikaryawan-d5b76.firebasestorage.app',
    measurementId: 'G-6903NFQ7Y6',
  );

}