# GAPS (Aplikasi Absensi Karyawan)

GAPS adalah aplikasi absensi modern berbasis seluler (Android & iOS) yang dirancang khusus untuk memonitor kehadiran karyawan secara akurat. Aplikasi ini memanfaatkan teknologi geofencing dan dilengkapi dengan perlindungan anti-spoofing GPS untuk memastikan validitas data kehadiran.

## Fitur Utama
- **Absensi Geofencing**: Karyawan hanya bisa melakukan presensi jika berada di dalam radius lokasi kantor yang sudah ditentukan.
- **Anti-Spoofing GPS**: Mencegah penggunaan aplikasi lokasi palsu (Fake GPS) sehingga data absensi tetap akurat.
- **Multi-Lokasi**: Sistem mendukung banyak titik lokasi absensi (misalnya Kampus 1, Kampus 2, Kantor Cabang, dsb).
- **Manajemen Poin & Gaji**: Merekap kehadiran karyawan otomatis untuk keperluan perhitungan gaji dan poin performa.
- **Ekspor Laporan**: Admin bisa mengekspor data kehadiran dan rekap gaji ke dalam format CSV.
- **Firebase Backend**: Menggunakan Firebase Authentication untuk login aman dan Realtime Database untuk sinkronisasi data yang cepat.

## Prasyarat
Aplikasi ini dibangun menggunakan **Flutter**. Sebelum mulai menjalankan proyek ini di lokal, pastikan Anda sudah memasang:
- Flutter SDK (versi 3.10.x atau lebih baru)
- Dart SDK
- Code Editor (Android Studio atau VS Code)
- Firebase CLI (khusus jika ingin mengubah setelan database/backend)

## Cara Menjalankan Aplikasi
1. Buka folder proyek ini di VS Code atau Android Studio.
2. Buka terminal dan unduh semua library yang dibutuhkan dengan perintah:
   ```bash
   flutter pub get
   ```
3. Sambungkan HP Android/iPhone Anda, atau nyalakan emulator.
4. Jalankan aplikasi dengan:
   ```bash
   flutter run
   ```

## Info Konfigurasi Firebase
Aplikasi ini saat ini terhubung ke Firebase bawaan. Jika Anda ingin menggunakan database Firebase dari akun Anda sendiri, Anda perlu menjalankan ulang konfigurasi Firebase. Buka terminal dan ketik `flutterfire configure`, lalu ikuti langkah-langkahnya untuk memilih project milik Anda sendiri.
