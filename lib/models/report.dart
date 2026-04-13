// lib/models/report.dart
class Report {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final String status;
  final String? adminResponse;
  final int timestamp;

  const Report({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    this.status = 'pending',
    this.adminResponse,
    required this.timestamp,
  });

  factory Report.fromSnapshot(String key, Map<dynamic, dynamic> map) {
    return Report(
      id: key,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Unknown',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      adminResponse: map['admin_response'] as String?,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'user_name': userName,
      'message': message,
      'status': status,
      'timestamp': timestamp,
    };
    if (adminResponse != null) {
      map['admin_response'] = adminResponse;
    }
    return map;
  }

  Report copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    String? status,
    String? adminResponse,
    int? timestamp,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
