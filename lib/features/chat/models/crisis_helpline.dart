/// Represents a verified crisis helpline / emergency response service
/// used in NeuroShift's One-Tap Cascading Crisis SOS system.
class CrisisHelpline {
  final String id;
  final String name;
  final String phoneNumber;
  final String formattedDisplayNumber;
  final String description;
  final bool isTollFree;
  final String hours;
  final String priorityBadge;

  const CrisisHelpline({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.formattedDisplayNumber,
    required this.description,
    this.isTollFree = true,
    this.hours = '24/7',
    required this.priorityBadge,
  });

  /// Standard tel: URI for one-tap system dialing
  Uri get telUri => Uri.parse('tel:$phoneNumber');
}
