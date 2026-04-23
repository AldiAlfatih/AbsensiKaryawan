import 'package:firebase_database/firebase_database.dart';

/// Represents an employee or admin user stored at /users/{uid}.
class AppUser {
  final String uid;
  final String name;
  final String nik;           // NIK (Nomor Induk Karyawan)
  final String email;
  final String role;          // 'admin' | 'employee'
  final int totalPoints;      // total_points in DB
  final String? photoUrl;     // Base64 encoded image string or URL

  const AppUser({
    required this.uid,
    required this.name,
    required this.nik,
    required this.email,
    required this.role,
    this.totalPoints = 0,
    this.photoUrl,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);
    return AppUser(
      uid: snap.key ?? '',
      name: data['name'] as String? ?? '',
      nik: data['NIK'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      photoUrl: data['photo_url'] as String?,
    );
  }

  factory AppUser.fromMap(String uid, Map<Object?, Object?> data) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      nik: data['NIK'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      photoUrl: data['photo_url'] as String?,
    );
  }

  /// Serialized to match the DB schema: users/$uid
  Map<String, dynamic> toMap() => {
        'name': name,
        'NIK': nik,
        'email': email,
        'role': role,
        'total_points': totalPoints,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

  AppUser copyWith({
    String? uid,
    String? name,
    String? nik,
    String? email,
    String? role,
    int? totalPoints,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      email: email ?? this.email,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
