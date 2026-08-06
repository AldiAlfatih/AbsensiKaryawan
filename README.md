# GAPS - Geo Attendance Positioning System

Aplikasi absensi karyawan berbasis Android & iOS yang dikembangkan menggunakan framework **Flutter** dan **Firebase**. Aplikasi ini dilengkapi dengan verifikasi lokasi presisi tinggi berbasis **Geofencing** serta fitur penanganan lokasi palsu (**Anti-GPS Spoofing**).

---

## 1. Peran Pengguna (Roles)

Sistem ini memiliki dua peran utama dengan hak akses yang berbeda:

### A. Admin (`role: admin`)
* **Daftar & Detail Karyawan**: Melihat daftar seluruh karyawan, detail poin, serta riwayat presensi tiap individu.
* **Manajemen Karyawan**: Menambahkan akun karyawan baru (sistem registrasi terpusat oleh Admin).
* **Persetujuan Cuti & Izin**: Meninjau dan memproses (setujui/tolak) pengajuan cuti dari karyawan.
* **Pusat Laporan Kendala**: Membaca dan membalas laporan kendala teknis yang dikirim karyawan.
* **Pengaturan Sistem**: Mengatur radius geofence (jarak maksimum yang diizinkan untuk absen dalam meter) dan nilai konversi 1 poin ke Rupiah secara *real-time*.
* **Ekspor Data Payroll**: Mengunduh rekapitulasi poin dan estimasi gaji karyawan dalam bentuk file CSV.

### B. Karyawan (`role: employee`)
* **Presensi Masuk & Keluar**: Melakukan *Check-In* dan *Check-Out* harian saat berada di dalam radius kantor yang ditentukan.
* **Validasi Otomatis**: Sistem otomatis mengecek apakah GPS aktif, berada di dalam radius kantor, dan tidak menggunakan aplikasi Fake GPS.
* **Pengajuan Cuti / Izin / Sakit**: Mengirim permohonan izin beserta tanggal dan alasannya.
* **Laporan Kendala**: Mengirim pesan bantuan ke Admin jika mengalami masalah teknis.
* **Riwayat & Papan Peringkat**: Melihat riwayat kehadiran pribadi serta papan peringkat (*leaderboard*) poin karyawan.

---

## 2. Akun Pengujian (Testing Accounts)

Gunakan akun berikut untuk mencoba aplikasi setelah database diinisialisasi:

| Peran | NIK (Username) | Password | Catatan |
| :--- | :--- | :--- | :--- |
| **Admin** | `ADM001` | `password123` (atau `12345678`) | Akses penuh ke Dashboard Admin |
| **Karyawan** | `EMP001` | `password123` (atau `12345678`) | Akun karyawan sampel (Budi Santoso) |

> **Catatan Teknikal Login:**
> Pengguna melakukan login menggunakan **NIK**. Di belakang layar, aplikasi mengonversi NIK tersebut menjadi format email internal `NIK@gaps.com` untuk kebutuhan autentikasi Firebase.

---

## 3. Prasyarat Sistem (Prerequisites)

Sebelum menjalankan atau mengembangkan proyek ini, pastikan komputer Anda telah terpasang:

1. **Flutter SDK** versi `3.10.4` atau yang lebih baru.
2. **Dart SDK** (terikut saat instalasi Flutter).
3. **Android Studio** / **VS Code** (dengan ekstensi Flutter & Dart).
4. **Firebase CLI** & **FlutterFire CLI** (apabila ingin mengubah atau menautkan ke project Firebase baru).
5. **Perangkat HP Android** (dengan Mode Developer & USB Debugging aktif) atau **Emulator Android** dengan layanan lokasi (GPS) aktif.

---

## 4. Langkah Setup & Instalasi Proyek

### Langkah 1: Clone Repository & Download Dependensi
Buka terminal dan jalankan perintah berikut:

```bash
# 1. Clone repository ini
git clone <URL_REPOSITORY_ANDA>

# 2. Masuk ke folder proyek
cd AbsensiKaryawan

# 3. Unduh semua paket/library Flutter
flutter pub get
```

### Langkah 2: Konfigurasi Firebase Backend

Aplikasi ini menggunakan **Firebase Authentication** dan **Firebase Realtime Database**.

1. Pastikan file konfigurasi berikut sudah berada di tempatnya:
   - `android/app/google-services.json`
   - `lib/firebase_options.dart`

2. Pastikan bidang `databaseURL` di file `lib/firebase_options.dart` mengarah ke URL Realtime Database Anda, contoh:
   ```dart
   databaseURL: 'https://<PROJECT-ID>-default-rtdb.asia-southeast1.firebasedatabase.app'
   ```

### Langkah 3: Pengaturan Firebase Console (Web)

Buka [Firebase Console](https://console.firebase.google.com/) pada project Anda:

1. **Authentication**: 
   - Masuk ke menu **Authentication** -> **Sign-in method**.
   - Aktifkan provider **Email/Password**.

2. **Realtime Database**:
   - Masuk ke menu **Realtime Database** -> tab **Rules**.
   - Masukkan aturan (*security rules*) berikut lalu klik **Publish**:

   ```json
   {
     "rules": {
       ".read": "auth != null",
       ".write": "auth != null",
       "attendance": {
         ".indexOn": ["user_id", "timestamp"]
       },
       "leaves": {
         ".indexOn": ["user_id", "status"]
       },
       "reports": {
         ".indexOn": ["user_id", "status"]
       }
     }
   }
   ```

---

## 5. Cara Menjalankan Aplikasi (Testing)

### Menjalankan di Mode Debug
Sambungkan HP Android atau nyalakan emulator, lalu jalankan:

```bash
flutter run
```

### Menjalankan di Mode Release (Performa Asli)
```bash
flutter run --release
```

---

## 6. Cara Build File APK (Android)

Untuk membuat file instalasi APK yang bisa dikirim dan diinstal langsung di HP Android:

```bash
# 1. Bersihkan sisa-sisa build lama
flutter clean

# 2. Ambil kembali paket dependensi
flutter pub get

# 3. Build APK rilis
flutter build apk
```

File APK yang berhasil di-build dapat ditemukan pada jalur direktori:
```
D:\AbsensiKaryawan\build\app\outputs\flutter-apk\app-release.apk
```

---

## 7. Alur Kerja Presensi (Workflow)

```
[Karyawan Tekan "Check In"] 
           │
           ▼
[Pemeriksaan Izin GPS & Lokasi Aktif?] ──(Tidak)──► [Minta Izin / Nyalakan GPS]
           │ (Ya)
           ▼
[Pemeriksaan Fake GPS / Mock Location?] ──(Ya)────► [Tolak Absen & Tampilkan Peringatan]
           │ (Tidak)
           ▼
[Pemeriksaan Jarak ke Koordinat Kantor] ──(> Radius)► [Tolak Absen: Di Luar Radius]
           │ (<= Radius)
           ▼
[Simpan Data Kehadiran & Tambah Poin]
           │
           ▼
[Tampilkan Status Berhasil + Opsi Check-Out]
```

---

## 8. Catatan & Solusi Masalah Umum (Troubleshooting)

* **Error `permission denied` di Realtime Database**:
  Terjadi jika aturan di tab *Rules* Firebase Console belum di-publish atau formatnya salah. Pastikan `.read` dan `.write` sudah diizinkan untuk `auth != null`, lalu restart aplikasi (`flutter run` ulang).
* **Konflik Build Gradle / Kotlin di Windows (Drive C vs Drive D)**:
  Jika kompilasi Gradle terhenti akibat masalah cache lintas drive, pastikan file `android/gradle.properties` sudah memiliki konfigurasi:
  ```properties
  kotlin.incremental=false
  ```
* **Aplikasi Mengalami Crash / Layar Hitam saat Buka**:
  Pastikan `databaseURL` pada `lib/firebase_options.dart` serta `lib/main.dart` sudah menunjuk ke URL Realtime Database yang tepat.
