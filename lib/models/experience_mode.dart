import 'package:flutter/material.dart';
import '../core/theme/muse_colors.dart';

enum ExperienceType { mind, heart, body, breath, soundscape }

class ExperienceMode {
  final ExperienceType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final LinearGradient gradient;
  final List<int> availableDurationsMinutes;

  const ExperienceMode({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    this.availableDurationsMinutes = const [3, 5, 10, 15, 20],
  });

  String get name => type.name;
  String get displayName => title;

  static const ExperienceMode mind = ExperienceMode(
    type: ExperienceType.mind,
    title: 'Mind Meditation',
    subtitle: 'Real-time brainwave feedback',
    description:
        'Translates your EEG brainwave signals into gentle weather sounds. '
        'When your mind is active, the weather becomes stormy; as your mind calms, the weather quiets and birds chirp.',
    icon: Icons.psychology_outlined,
    accentColor: MuseColors.mindCyan,
    gradient: MuseColors.mindGradient,
  );

  static const ExperienceMode heart = ExperienceMode(
    type: ExperienceType.heart,
    title: 'Heart Meditation',
    subtitle: 'Optical PPG pulse & rhythm',
    description:
        'Tunes into your pulse and heart rate variability (HRV). '
        'Hear your heartbeat represented as a rhythmic drumbeat, guiding you into a slower, more synchronized tempo.',
    icon: Icons.favorite_border_rounded,
    accentColor: MuseColors.heartRose,
    gradient: MuseColors.heartGradient,
  );

  static const ExperienceMode body = ExperienceMode(
    type: ExperienceType.body,
    title: 'Body Meditation',
    subtitle: 'Physical posture & stillness',
    description:
        'Monitors subtle physical micro-movements and posture adjustments using the 3-axis accelerometer. '
        'Wind chimes gently alert you when tension or fidgeting arises.',
    icon: Icons.accessibility_new_rounded,
    accentColor: MuseColors.bodyAmber,
    gradient: MuseColors.bodyGradient,
  );

  static const ExperienceMode breath = ExperienceMode(
    type: ExperienceType.breath,
    title: 'Breath Meditation',
    subtitle: 'Rhythmic pacing & calm',
    description:
        'Guides your respiratory cycles to activate your parasympathetic relaxation response. '
        'Synchronizes your inhalation and exhalation rhythm with ambient musical waves.',
    icon: Icons.air_rounded,
    accentColor: MuseColors.breathMint,
    gradient: MuseColors.breathGradient,
  );

  static const ExperienceMode soundscape = ExperienceMode(
    type: ExperienceType.soundscape,
    title: 'Ambient Soundscape',
    subtitle: 'Serene nature & open timer',
    description:
        'Immerse in rain, ocean waves, forest ambience, or a tranquil bell timer while your Muse 2 headband passively tracks your biometric calmness.',
    icon: Icons.nature_people_outlined,
    accentColor: MuseColors.mysticPurple,
    gradient: MuseColors.mysticGradient,
  );

  static const List<ExperienceMode> values = [
    mind,
    heart,
    body,
    breath,
    soundscape,
  ];

  static const List<ExperienceMode> allModes = values;
}
