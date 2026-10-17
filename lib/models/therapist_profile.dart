class TherapistProfile {
  final String id;
  final String displayName;
  final String email;
  final String organization;
  final String licenseNumber;
  final bool isVerified;
  final DateTime createdAt;
  final String? rawCreatedAt;

  const TherapistProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.organization,
    required this.licenseNumber,
    this.isVerified = false,
    required this.createdAt,
    this.rawCreatedAt,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'organization': organization,
      'licenseNumber': licenseNumber,
      'isVerified': isVerified,
      'createdAt': rawCreatedAt ?? createdAt.toIso8601String(),
    };
  }

  factory TherapistProfile.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawDate = map['createdAt'] is String ? map['createdAt'] as String : null;

    return TherapistProfile(
      id: (map['id'] as String?) ?? docId,
      displayName: (map['displayName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      organization: (map['organization'] as String?) ?? '',
      licenseNumber: (map['licenseNumber'] as String?) ?? '',
      isVerified: (map['isVerified'] as bool?) ?? false,
      createdAt: parseDate(map['createdAt']),
      rawCreatedAt: rawDate,
    );
  }
}
