import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../models/app_user.dart';
import 'auth_provider.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ProfileController(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required AppUser user,
    String? newName,
    File? newImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? base64Image;

      if (newImage != null) {
        // Read file as bytes
        final bytes = await newImage.readAsBytes();
        
        // Decode image
        img.Image? decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          // Resize image to max 256x256
          img.Image resized = img.copyResize(
            decodedImage,
            width: 256,
            height: 256,
            maintainAspect: true,
          );
          
          // Encode to JPG with some compression (80% quality)
          final jpgBytes = img.encodeJpg(resized, quality: 80);
          base64Image = base64Encode(jpgBytes);
        }
      }

      await _ref.read(databaseServiceProvider).updateUserProfile(
            user.uid,
            name: newName,
            photoUrl: base64Image,
          );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error('Gagal memperbarui profil: $e', st);
    }
  }
}
