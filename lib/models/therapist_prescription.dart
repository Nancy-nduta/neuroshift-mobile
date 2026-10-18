import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus { recommended, completed, dismissed }

class TherapistPrescription {
  final String id;
  final String therapistId;
  final String therapistName;
  final String clientId;
  final String clientEmail;
  final String resourceId;
  final String resourceTitle;
  final String resourceCategory;
  final String? instructions;
  final DateTime prescribedAt;
  final PrescriptionStatus status;
  final String? completedSessionId;
  final double? patientCalmScore;
  final int? patientHelpfulnessRating;
  final String? patientFeedback;
  final DateTime? completedAt;

  const TherapistPrescription({
    required this.id,
    required this.therapistId,
    required this.therapistName,
    required this.clientId,
    required this.clientEmail,
    required this.resourceId,
    required this.resourceTitle,
    required this.resourceCategory,
    this.instructions,
    required this.prescribedAt,
    this.status = PrescriptionStatus.recommended,
    this.completedSessionId,
    this.patientCalmScore,
    this.patientHelpfulnessRating,
    this.patientFeedback,
    this.completedAt,
  });

  bool get isCompleted => status == PrescriptionStatus.completed;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'therapistId': therapistId,
      'therapistName': therapistName,
      'clientId': clientId,
      'clientEmail': clientEmail,
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'resourceCategory': resourceCategory,
      'instructions': instructions,
      'prescribedAt': Timestamp.fromDate(prescribedAt),
      'status': status.name,
      'completedSessionId': completedSessionId,
      'patientCalmScore': patientCalmScore,
      'patientHelpfulnessRating': patientHelpfulnessRating,
      'patientFeedback': patientFeedback,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory TherapistPrescription.fromFirestore(Map<String, dynamic> map, String docId) {
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

    PrescriptionStatus parseStatus(String? val) {
      switch (val) {
        case 'completed':
          return PrescriptionStatus.completed;
        case 'dismissed':
          return PrescriptionStatus.dismissed;
        case 'recommended':
        default:
          return PrescriptionStatus.recommended;
      }
    }

    return TherapistPrescription(
      id: (map['id'] as String?) ?? docId,
      therapistId: (map['therapistId'] as String?) ?? '',
      therapistName: (map['therapistName'] as String?) ?? '',
      clientId: (map['clientId'] as String?) ?? '',
      clientEmail: (map['clientEmail'] as String?) ?? '',
      resourceId: (map['resourceId'] as String?) ?? '',
      resourceTitle: (map['resourceTitle'] as String?) ?? '',
      resourceCategory: (map['resourceCategory'] as String?) ?? '',
      instructions: map['instructions'] as String?,
      prescribedAt: parseDate(map['prescribedAt']),
      status: parseStatus(map['status'] as String?),
      completedSessionId: map['completedSessionId'] as String?,
      patientCalmScore: (map['patientCalmScore'] as num?)?.toDouble(),
      patientHelpfulnessRating: (map['patientHelpfulnessRating'] as num?)?.toInt(),
      patientFeedback: map['patientFeedback'] as String?,
      completedAt: parseNullableDate(map['completedAt']),
    );
  }
}
