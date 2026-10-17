import 'package:cloud_firestore/cloud_firestore.dart';

enum GrantStatus { pending, active, revoked, expired }

class TherapistAccessGrant {
  final String id;
  final String clientId;
  final String clientEmail;
  final String therapistId;
  final String therapistEmail;
  final GrantStatus status;
  final List<String> scopes;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;

  const TherapistAccessGrant({
    required this.id,
    required this.clientId,
    required this.clientEmail,
    required this.therapistId,
    required this.therapistEmail,
    required this.status,
    this.scopes = const ['session_reports', 'eeg_telemetry', 'recommendations'],
    required this.grantedAt,
    required this.expiresAt,
    this.revokedAt,
  });

  bool get isActive => status == GrantStatus.active;
  bool get isPending => status == GrantStatus.pending;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'clientId': clientId,
      'clientEmail': clientEmail,
      'therapistId': therapistId,
      'therapistEmail': therapistEmail,
      'status': status.name,
      'scopes': scopes,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
    };
  }

  factory TherapistAccessGrant.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    GrantStatus parseStatus(String? val) {
      switch (val) {
        case 'active':
          return GrantStatus.active;
        case 'revoked':
          return GrantStatus.revoked;
        case 'expired':
          return GrantStatus.expired;
        case 'pending':
        default:
          return GrantStatus.pending;
      }
    }

    return TherapistAccessGrant(
      id: (map['id'] as String?) ?? docId,
      clientId: (map['clientId'] as String?) ?? '',
      clientEmail: (map['clientEmail'] as String?) ?? '',
      therapistId: (map['therapistId'] as String?) ?? '',
      therapistEmail: (map['therapistEmail'] as String?) ?? '',
      status: parseStatus(map['status'] as String?),
      scopes: (map['scopes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['session_reports', 'eeg_telemetry', 'recommendations'],
      grantedAt: parseDate(map['grantedAt']),
      expiresAt: parseDate(map['expiresAt']),
      revokedAt: parseNullableDate(map['revokedAt']),
    );
  }
}
