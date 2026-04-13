class Leave {
  final String id;
  final String userId;
  final String userName;
  final String type; // 'Sakit' | 'Cuti' | 'Izin'
  final String reason;
  final int startDate; // ms since epoch
  final int endDate; // ms since epoch
  final String status; // 'pending' | 'approved' | 'rejected'
  final int timestamp; // created at

  const Leave({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.status = 'pending',
    required this.timestamp,
  });

  factory Leave.fromSnapshot(String key, Map<dynamic, dynamic> map) {
    return Leave(
      id: key,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Unknown',
      type: map['type'] as String? ?? 'Izin',
      reason: map['reason'] as String? ?? '',
      startDate: map['start_date'] as int? ?? 0,
      endDate: map['end_date'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'reason': reason,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'timestamp': timestamp,
    };
  }

  Leave copyWith({
    String? id,
    String? userId,
    String? userName,
    String? type,
    String? reason,
    int? startDate,
    int? endDate,
    String? status,
    int? timestamp,
  }) {
    return Leave(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
