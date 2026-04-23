import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

/// Real-time stream of /settings/global from Realtime Database.
/// Falls back to default values (point_value: 35000, allowed_radius: 50)
/// if the node doesn't exist yet.
final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(databaseServiceProvider).streamSettings();
});

class SettingsController extends StateNotifier<AsyncValue<void>> {
  SettingsController(this._db) : super(const AsyncValue.data(null));
  final DatabaseService _db;

  Future<void> updateSettings(AppSettings newSettings) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateSettings(newSettings);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  return SettingsController(ref.watch(databaseServiceProvider));
});

