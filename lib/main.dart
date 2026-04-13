import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_database/firebase_database.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (single call)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence for RTDB
  FirebaseDatabase.instance.setPersistenceEnabled(true);

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
