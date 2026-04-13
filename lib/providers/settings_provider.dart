import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'auth_provider.dart';

/// Real-time stream of /settings/global from Realtime Database.
/// Falls back to default values (point_value: 35000, allowed_radius: 50)
/// if the node doesn't exist yet.
final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(databaseServiceProvider).streamSettings();
});
