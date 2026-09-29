enum InvitationStatus {
  unused,
  used,
  cancelled;

  String get dbValue => switch (this) {
        InvitationStatus.unused => 'unused',
        InvitationStatus.used => 'used',
        InvitationStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        InvitationStatus.unused => 'غير مستخدمة',
        InvitationStatus.used => 'مستخدمة',
        InvitationStatus.cancelled => 'ملغاة',
      };

  static InvitationStatus fromDb(String value) {
    return switch (value) {
      'unused' => InvitationStatus.unused,
      'used' => InvitationStatus.used,
      'cancelled' => InvitationStatus.cancelled,
      _ => InvitationStatus.cancelled,
    };
  }
}

class Invitation {
  const Invitation({
    required this.id,
    required this.guestName,
    required this.allowedCount,
    required this.token,
    required this.status,
    required this.createdAt,
    this.usedAt,
  });

  final String id;
  final String guestName;
  final int allowedCount;
  final String token;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? usedAt;

  bool get isUnused => status == InvitationStatus.unused;
  bool get isUsed => status == InvitationStatus.used;
  bool get isCancelled => status == InvitationStatus.cancelled;

  Invitation copyWith({
    String? id,
    String? guestName,
    int? allowedCount,
    String? token,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? usedAt,
    bool clearUsedAt = false,
  }) {
    return Invitation(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      allowedCount: allowedCount ?? this.allowedCount,
      token: token ?? this.token,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      usedAt: clearUsedAt ? null : usedAt ?? this.usedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'guest_name': guestName,
      'allowed_count': allowedCount,
      'token': token,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
    };
  }

  factory Invitation.fromMap(Map<String, Object?> map) {
    return Invitation(
      id: map['id'] as String,
      guestName: map['guest_name'] as String,
      allowedCount: map['allowed_count'] as int,
      token: map['token'] as String,
      status: InvitationStatus.fromDb(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      usedAt: map['used_at'] == null ? null : DateTime.parse(map['used_at'] as String),
    );
  }
}

class InvitationStats {
  const InvitationStats({
    required this.total,
    required this.unused,
    required this.used,
    required this.cancelled,
  });

  final int total;
  final int unused;
  final int used;
  final int cancelled;
}
