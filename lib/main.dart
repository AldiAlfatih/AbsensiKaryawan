import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  // On Android, the google-services Gradle plugin may already initialize
  // Firebase natively before Dart runs. We catch the duplicate-app error
  // so the app doesn't crash in that case.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  
  // Enable offline persistence for RTDB (explicit URL to match databaseServiceProvider)
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://absensikaryawan-3a199-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).setPersistenceEnabled(true);

  // Lock to portrait orientation for a focused mobile UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize locale for Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: AbsensiApp(),
    ),
  );
}
