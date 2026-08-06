# 📖 Penjelasan Kode — GAPS (Geo Attendance Positioning System)

> Dokumen ini menjelaskan seluruh struktur kode proyek secara rinci, mulai dari arsitektur hingga logika tiap file.

---

## 🗂️ Struktur Folder Proyek

```
lib/
├── core/               ← Aturan global (tema, routing, konstanta)
│   ├── constants.dart
│   ├── router.dart
│   └── theme.dart
├── models/             ← Definisi data / struktur objek
│   ├── app_user.dart
│   ├── attendance.dart
│   ├── app_settings.dart
│   ├── leave.dart
│   └── report.dart
├── providers/          ← Pengelola state (Riverpod)
│   ├── auth_provider.dart
│   ├── attendance_provider.dart
│   ├── settings_provider.dart
│   ├── admin_provider.dart
│   ├── leave_provider.dart
│   └── report_provider.dart
├── services/           ← Logika bisnis murni (tidak ada UI di sini)
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── location_service.dart
│   └── export_service.dart
└── screens/            ← Tampilan UI
    ├── login_screen.dart
    ├── splash_screen.dart
    ├── employee/       ← Halaman khusus karyawan
    └── admin/          ← Halaman khusus admin
```

---

## 🏗️ Arsitektur Keseluruhan

Proyek ini menggunakan pola **Service → Provider → Screen**:

```
Firebase
  │
  ▼
Services         ← Hanya berhubungan langsung dengan Firebase/GPS
  │               (AuthService, DatabaseService, LocationService)
  ▼
Providers        ← Mengelola state & menghubungkan service ke UI
  │               (Riverpod: StreamProvider, StateNotifier, FutureProvider)
  ▼
Screens/Widgets  ← Hanya menampilkan data & menerima input pengguna
```

**Prinsip utama:**
- **Screen tidak boleh langsung panggil Firebase** — harus melalui Provider.
- **Service tidak boleh tahu soal UI** — hanya menerima input & mengembalikan hasil.
- **Provider adalah jembatan** antara Service dan Screen.

---

## 🔑 `core/constants.dart` — Konstanta Global

```dart
class AppConstants {
  static const double kampus1Lat = -4.0167;
  static const double kampus1Lng = 119.6236;
  // ... koordinat kantor lainnya
  
  static const double defaultGeofenceRadius = 50.0; // meter
  static const int defaultPointValue = 35000;        // Rp per poin
  
  static const String emailDomain = '@gaps.com';
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';
}
```

**Fungsi:** Tempat menyimpan semua nilai yang tidak berubah (magic numbers). Dengan cara ini, jika koordinat kantor berubah, cukup edit satu tempat di sini — tidak perlu mencari ke seluruh kode.

> ⚠️ **Catatan:** Kantor 3 dan Kantor 4 saat ini memiliki koordinat yang sama (`-4.0192, 119.6499`). Perlu diperbaiki dengan koordinat yang benar untuk Rumah Mala.

---

## 🗺️ `core/router.dart` — Navigasi Antar Halaman

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',   // Mulai dari splash screen
    routes: [ ... ],
    redirect: (context, routerState) {
      // Kalau belum login & bukan di halaman login → paksa ke /login
      if (!isLoggedIn && !isLogin && !isSplash) return AppRoutes.login;
      return null; // null = tidak redirect, lanjutkan ke halaman tujuan
    },
  );
});
```

**Fungsi:** Mengatur alur navigasi seluruh aplikasi menggunakan `go_router`.

**`redirect`** adalah penjaga pintu (auth guard): setiap kali pengguna berpindah halaman, fungsi ini dicek terlebih dahulu. Jika belum login dan mencoba masuk halaman selain login/splash, langsung diarahkan ke `/login`.

**Daftar rute:**

| Path | Halaman |
|------|---------|
| `/` | Splash Screen |
| `/login` | Login |
| `/employee` | Dashboard Karyawan |
| `/employee/history` | Riwayat Absensi |
| `/employee/report` | Lapor Kendala |
| `/employee/leave` | Izin & Cuti |
| `/employee/leaderboard` | Leaderboard Poin |
| `/admin` | Dashboard Admin |
| `/admin/employee/:uid` | Detail Karyawan |
| `/admin/create` | Tambah Karyawan |
| `/profile/edit` | Edit Profil |

---

## 👤 `models/app_user.dart` — Data Pengguna

```dart
class AppUser {
  final String uid;        // ID unik dari Firebase Auth
  final String name;       // Nama lengkap
  final String nik;        // Nomor Induk Karyawan (dipakai untuk login)
  final String email;      // Format: NIK@gaps.com (internal, tidak ditampilkan)
  final String role;       // 'admin' atau 'employee'
  final int totalPoints;   // Total poin yang terkumpul sepanjang waktu
  final String? photoUrl;  // Foto profil (disimpan sebagai Base64 string)
}
```

**`fromMap(uid, map)`** — Mengubah data mentah dari Firebase Database (format `Map`) menjadi objek `AppUser` yang bisa dipakai di kode Dart.

**`toMap()`** — Kebalikannya: mengubah objek `AppUser` menjadi `Map` untuk disimpan ke Firebase.

---

## 📋 `models/attendance.dart` — Data Absensi

```dart
class Attendance {
  final String id;               // Key dari Firebase (push ID otomatis)
  final String userId;           // UID pengguna yang absen
  final DateTime timestamp;      // Waktu absen (check-in)
  final double latitude;
  final double longitude;
  final double distanceFromOffice; // Dalam meter
  final bool isMockLocation;      // true = GPS palsu terdeteksi
  final String? campusId;         // Nama lokasi kantor terdekat
  final bool? isLate;             // true = terlambat (setelah 08:30)
  final bool isCheckout;          // true = sudah check-out
  final DateTime? checkOutTimestamp;
}
```

**Catatan penting:** `isMockLocation = true` tidak langsung menolak absensi — rekaman tetap disimpan di database dengan flag ini. Admin bisa melihat rekaman tersebut di detail karyawan dan memutuskan tindakan.

---

## 📋 `models/app_settings.dart`, `leave.dart`, dan `report.dart`

- **`app_settings.dart`**: Menyimpan data radius toleransi GPS (dalam meter) dan nilai per poin (dalam Rupiah) yang diambil dari `/settings/global` di Firebase.
- **`leave.dart`**: Menyimpan pengajuan cuti, izin, atau sakit karyawan. Memiliki field `status` ('pending', 'approved', 'rejected') yang diubah oleh admin.
- **`report.dart`**: Menyimpan laporan kendala sistem dari karyawan. Juga punya `status` dan `admin_response` untuk balasan admin.

---

## 🔐 `services/auth_service.dart` — Logika Autentikasi Firebase

File ini hanya bertugas **berkomunikasi dengan Firebase Auth**. Tidak ada logika bisnis di sini.

```dart
class AuthService {
  // Daftar akun baru
  Future<UserCredential> createAccount({email, password}) { ... }
  
  // Login
  Future<UserCredential> signIn({email, password}) { ... }
  
  // Logout
  Future<void> signOut() { ... }
  
  // Stream: berubah setiap ada login/logout
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Mengubah kode error Firebase menjadi pesan Indonesia yang ramah
  static String friendlyError(FirebaseAuthException e) { ... }
}
```

**`friendlyError`** — Firebase mengembalikan error dengan kode teknis seperti `wrong-password`. Fungsi ini mengubahnya menjadi pesan yang bisa dibaca manusia, misal "Password salah".

---

## 🗄️ `services/database_service.dart` — Operasi Database

Semua baca/tulis ke **Firebase Realtime Database** ada di sini. Terbagi menjadi 5 kategori:

### Struktur Database di Firebase:
```
/users/{uid}
  name: "Budi Santoso"
  NIK: "EMP001"
  role: "employee"
  total_points: 12

/attendance/{pushId}
  user_id: "abc123"
  timestamp: 1722930000000   ← millisecond sejak 1970
  geo_point/latitude: -4.0167
  geo_point/longitude: 119.6236
  distance_from_office: 23.5
  is_mock_location: false
  is_late: false

/settings/global
  point_value: 35000
  allowed_radius: 50.0

/reports/{pushId}
  user_id: "abc123"
  user_name: "Budi Santoso"
  message: "GPS saya error..."
  status: "pending"          ← 'pending' | 'resolved'
  admin_response: null

/leaves/{pushId}
  user_id: "abc123"
  type: "Sakit"              ← 'Sakit' | 'Izin' | 'Cuti'
  reason: "Demam tinggi"
  start_date: 1722930000000
  end_date: 1722930000000
  status: "pending"          ← 'pending' | 'approved' | 'rejected'
```

### Metode Penting:

**`streamUser(uid)`** — Memantau perubahan profil pengguna secara real-time. Jika admin mengubah data karyawan, layar karyawan langsung ter-update otomatis tanpa perlu refresh.

**`streamAllEmployees()`** — Mengambil semua pengguna dengan `role == 'employee'`, diurutkan A-Z berdasarkan nama.

**`getCheckInRecordToday(uid)`** — Memeriksa apakah pengguna sudah absen hari ini. Bekerja dengan cara: ambil semua rekaman milik `uid`, lalu filter yang timestampnya hari ini dan bukan GPS palsu.

**`incrementPoints(uid)`** — Menambah poin menggunakan **transaction** Firebase. Ini penting untuk menghindari race condition (jika dua proses mengupdate poin bersamaan, nilai tidak akan rusak).

**`processCheckout(recordId)`** — Mengupdate rekaman absensi yang sudah ada (bukan membuat rekaman baru) dengan menandai `is_checkout: true` dan menyimpan waktu checkout.

---

## 📍 `services/location_service.dart` — Layanan GPS & Geofencing

Bertanggung jawab atas tiga hal: izin GPS, deteksi GPS palsu, dan validasi geofence.

### Tipe Hasil Validasi (Sealed Class):

```dart
sealed class LocationResult { }

class LocationSuccess   // ✅ Berhasil — posisi valid & dalam radius
class LocationFailure   // ❌ Izin GPS ditolak atau layanan mati
class MockDetected      // ❌ GPS palsu terdeteksi
class OutsideGeofence   // ❌ Posisi di luar radius kantor
```

**Sealed class** artinya semua kemungkinan hasil sudah terdefinisi. Kompiler Dart akan memperingatkan jika ada kasus yang belum ditangani (seperti `switch` yang tidak lengkap).

### Alur `validateCheckIn()`:

```
1. Cek izin GPS
        │
        ▼
2. Ambil posisi GPS saat ini
        │
        ▼
3. Apakah posisi palsu (isMocked)?
   Ya → kembalikan MockDetected
        │
        ▼
4. Hitung jarak ke SEMUA lokasi kantor menggunakan Haversine
        │
        ▼
5. Pilih kantor TERDEKAT
        │
        ▼
6. Apakah jarak ≤ radius yang diizinkan?
   Tidak → kembalikan OutsideGeofence
   Ya    → kembalikan LocationSuccess
```

### Rumus Haversine:
Rumus matematika untuk menghitung jarak dua titik di permukaan bumi (dalam meter) berdasarkan koordinat latitude/longitude. Lebih akurat daripada rumus Euclidean karena memperhitungkan kelengkungan bumi.

```dart
static double haversineDistance({lat1, lng1, lat2, lng2}) {
  const R = 6371000.0; // Jari-jari bumi dalam meter
  // ... rumus trigonometri (sin, cos, atan2)
}
```

---

## 📄 `services/export_service.dart` — Layanan Ekspor Data

```dart
class ExportService {
  static Future<void> exportEmployeeRecap(List<AppUser> employees, AppSettings settings) async { ... }
}
```

**Fungsi:** Menggabungkan data karyawan dan pengaturan global, lalu menghasilkan format CSV secara manual (karena format data sederhana). CSV ini kemudian dibagikan via sistem Android/iOS menggunakan package `share_plus`. Ini sangat berguna untuk mentransfer data kehadiran bulan ini ke sistem payroll perusahaan.

---

## ⚡ `providers/auth_provider.dart` — State Autentikasi

### Provider yang tersedia:

**`authStateProvider`** (StreamProvider) — Memantau status login secara real-time. Seluruh aplikasi menggunakan ini untuk tahu apakah pengguna sudah login atau belum.

**`currentUserProfileProvider`** (StreamProvider) — Mengambil profil lengkap pengguna yang sedang login dari database. Otomatis null jika belum login.

**`nikToEmail(nik)`** — Fungsi helper: mengubah NIK menjadi format email internal Firebase.
```
"EMP001" → "EMP001@gaps.com"
```

### `AuthNotifier` — Kelas Pengelola Login:

**`signIn(nik, password)`:**
```
1. Ubah NIK → email (NIK@gaps.com)
2. Login ke Firebase Auth
3. Ambil profil dari database
4. Jika profil tidak ada (admin sudah hapus) → langsung logout
   → cegah karyawan terjebak di loop login-logout tanpa pesan error
5. Jika berhasil → kembalikan AppUser
```

**`createEmployee(name, nik, password)`:**
```
1. Buat Firebase App baru yang TERISOLASI (secondaryApp)
   → Ini kunci solusi bug: tanpa ini, membuat akun baru akan
     langsung sign-out admin dan sign-in sebagai karyawan baru!
2. Buat akun di secondaryApp
3. Tulis profil ke database
4. Hapus secondaryApp (cleanup)
5. Admin tetap login seperti semula
```

---

## ⚡ `providers/attendance_provider.dart` — State Absensi

### State Check-In (Sealed Class):

```dart
sealed class CheckInState { }

class CheckInIdle    // Siap absen
class CheckInLoading // Sedang memproses
class CheckInSuccess // Berhasil absen
class CheckInError   // Gagal, dengan pesan & tipe error
```

### `CheckInNotifier` — Kelas Pengelola Absensi:

**`checkIn()`** — Alur lengkap proses absensi:

```
1. Cek apakah state sudah Loading (cegah double-tap)
2. Ambil data user dari Firebase Auth
3. Ambil radius dari settings/global
4. Cek apakah sudah absen hari ini
   Ya → tampilkan error "Kamu sudah absen hari ini!"
5. Panggil locationService.validateCheckIn()
6. Berdasarkan hasil:
   LocationSuccess → simpan rekaman + tambah poin + refresh provider
   LocationFailure → tampilkan pesan error izin GPS
   MockDetected    → tampilkan error "GPS Palsu terdeteksi!"
   OutsideGeofence → tampilkan jarak & batas radius
```

**`checkOut(recordId)`** — Memanggil `processCheckout()` di database untuk menandai check-out.

---

## ⚡ Provider Lainnya

- **`admin_provider.dart`**: Menyediakan stream untuk menarik daftar semua karyawan, serta riwayat absensi, cuti, dan laporan kendala secara global untuk dasbor admin.
- **`leave_provider.dart` & `report_provider.dart`**: Menangani logika saat karyawan melakukan *submit* form cuti atau lapor kendala. Juga menangani admin saat mereka *resolve/approve* pengajuan.
- **`settings_provider.dart`**: Membaca nilai *radius geofence* dan *nilai poin* terkini secara terus-menerus. Jika admin mengubah pengaturannya, provider ini akan langsung menyesuaikan logika absensi di semua perangkat tanpa perlu direstart.

---

## 🖥️ Layar-Layar Utama

### `login_screen.dart`
- Input NIK dan password
- Tombol "Mulai Setup" untuk seed akun demo pertama kali
- Memanggil `authNotifierProvider.signIn()` 
- Setelah login berhasil, router otomatis redirect ke dashboard yang sesuai berdasarkan `role`

### `employee_dashboard.dart`
- Menampilkan sapaan berdasarkan jam (Pagi/Siang/Sore/Malam)
- Menampilkan total poin karyawan
- Card Check-In dengan status ring (idle/loading/sukses/error)
- Tombol avatar di pojok kanan → membuka `_ProfileSheet` (bottom sheet profil)
- Quick actions: riwayat absensi

### `admin_dashboard.dart`
- Daftar semua karyawan dengan search/filter
- Stats banner: total karyawan & total poin
- Tombol FAB untuk tambah karyawan
- Navigasi via `BottomNavigationBar` ke 5 tab: Karyawan, Laporan, Cuti, Rekap, Pengaturan

### `admin_employee_detail.dart`
- Detail lengkap satu karyawan
- Riwayat absensi karyawan tersebut
- Aksi: Edit Nama, Hapus Rekaman GPS Palsu, Reset Poin, Hapus Karyawan
- Tombol hapus menghapus profil dari database (Firebase Auth akun tetap ada)

### `admin_recap_screen.dart`
- Rekap kehadiran semua karyawan untuk bulan yang dipilih
- Hitung hari kerja (Senin–Jumat) otomatis
- Statistik: Hadir, Terlambat, Absen, persentase kehadiran
- **Estimasi gaji = jumlah hadir bulan ini × nilai per poin**

### `admin_settings_screen.dart`
- Slider radius geofence (10m–200m)
- Input nilai konversi 1 poin (Rp)
- Disimpan ke `/settings/global` di Firebase → langsung berlaku untuk semua karyawan

### `employee_leave_screen.dart`
- List riwayat pengajuan cuti/izin dengan filter bulan
- Tombol FAB → form pengajuan baru (bottom sheet)
- Tipe: Sakit / Izin / Cuti
- Status: pending (menunggu) / approved (disetujui) / rejected (ditolak)

### `employee_report_screen.dart`
- Tab 1: Form laporan kendala (teks bebas)
- Tab 2: Riwayat laporan dengan status & balasan admin
- Setelah submit → otomatis pindah ke Tab 2

---

## 🧮 Logika Rekap Gaji

> Perlu dipahami bahwa **"poin"** di sistem ini adalah satuan kehadiran, bukan poin reward game.

| Istilah | Artinya |
|---------|---------|
| `total_points` | Jumlah hari hadir **sepanjang waktu** (akumulasi) |
| `nilai per poin` | Nilai uang per hari hadir (misal Rp 35.000/hari) |
| **Estimasi Gaji** | Jumlah hadir bulan ini × nilai per poin |

**Contoh:** Budi hadir 20 hari di bulan Agustus, nilai per poin Rp 35.000.  
Estimasi gaji Agustus = 20 × Rp 35.000 = **Rp 700.000**

> ⚠️ Ini adalah *estimasi*, bukan gaji final. Fungsi ekspor CSV (`ExportService`) menggunakan logika yang sama untuk keperluan payroll.

---

## 📦 Dependensi Utama (pubspec.yaml)

| Package | Fungsi |
|---------|--------|
| `firebase_core` | Inisialisasi Firebase |
| `firebase_auth` | Login / Logout |
| `firebase_database` | Realtime Database |
| `flutter_riverpod` | State management |
| `go_router` | Navigasi & routing |
| `geolocator` | Akses GPS & deteksi mock |
| `permission_handler` | Minta izin lokasi |
| `intl` | Format tanggal/waktu dalam Bahasa Indonesia |
| `flutter_animate` | Animasi halus pada widget |
| `image_picker` | Pilih foto profil dari galeri |
