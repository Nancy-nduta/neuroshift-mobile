import 'package:flutter/material.dart';
import '../../../../core/theme/muse_colors.dart';

enum ResourceCategory {
  guidedMeditation('Guided Meditation', Icons.self_improvement, MuseColors.cyanGlow),
  rainAndStorm('Rain & Storm', Icons.thunderstorm_outlined, Color(0xFF4FC3F7)),
  whiteNoise('White & Brown Noise', Icons.graphic_eq, Color(0xFFB0BEC5)),
  peacefulPiano('Peaceful Piano', Icons.piano, MuseColors.bodyAmber),
  natureSoundscapes('Nature Soundscapes', Icons.forest_outlined, MuseColors.breathMint);

  final String label;
  final IconData icon;
  final Color color;

  const ResourceCategory(this.label, this.icon, this.color);
}

class ResourceItem {
  final String id;
  final String title;
  final String author;
  final ResourceCategory category;
  final String durationLabel;
  final String youtubeVideoId;
  final String description;

  const ResourceItem({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.durationLabel,
    required this.youtubeVideoId,
    required this.description,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';

  /// Curated collection of 20 high-quality, diverse in-app audio & meditation resources.
  static const List<ResourceItem> catalog = [
    // ==================== 1. GUIDED MEDITATIONS ====================
    ResourceItem(
      id: 'med_01',
      title: '5-Minute Morning Meditation to Clear Your Mind',
      author: 'Goodful',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '5 min',
      youtubeVideoId: 'inpok4MKVLM',
      description: 'Quick morning mindfulness session to release mental clutter and center focus.',
    ),
    ResourceItem(
      id: 'med_02',
      title: '10-Minute Daily Mindfulness Meditation',
      author: 'Great Meditation',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '10 min',
      youtubeVideoId: 'ZToicYcHIOU',
      description: 'Simple guided breath awareness to reset stress and build calm alpha brainwaves.',
    ),
    ResourceItem(
      id: 'med_03',
      title: '10-Minute Meditation for Anxiety & Stress Relief',
      author: 'Boho Beautiful Yoga',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '10 min',
      youtubeVideoId: 'O-6f5wQXSu8',
      description: 'Gentle somatic guidance to soothe the nervous system and slow racing thoughts.',
    ),
    ResourceItem(
      id: 'med_04',
      title: 'Body Scan Meditation for Deep Physical Relaxation',
      author: 'The Mindful Movement',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '15 min',
      youtubeVideoId: 'u4gZgnCy5ew',
      description: 'Gradual top-to-toe awareness practice to dissolve bodily tension and calm heart rate.',
    ),
    ResourceItem(
      id: 'med_05',
      title: 'Release Overthinking & 5-Minute Mindfulness Reset',
      author: 'Mindful Breathing',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '5 min',
      youtubeVideoId: 'ssss7V1_eyA',
      description: 'Grounding visualization to stop thought loops and invite deep emotional stillness.',
    ),

    // ==================== 2. RAIN & STORM SOUNDS ====================
    ResourceItem(
      id: 'rain_01',
      title: 'Gentle Rain on a Window with Distant Soft Thunder',
      author: 'Relaxing White Noise',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: 'mPZkdNFkNps',
      description: 'Hypnotic steady rainfall against glass, paired with soothing low-frequency rumbles.',
    ),
    ResourceItem(
      id: 'rain_02',
      title: 'Forest Rain on Lush Canopy Leaves',
      author: 'Calmsound',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: 'q76bMs-NwRk',
      description: 'Natural mountain rain showers pattering on dense woodland foliage.',
    ),
    ResourceItem(
      id: 'rain_03',
      title: 'Heavy Rolling Rain & Deep Night Downpour',
      author: 'The Relaxed Guy',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: 'jX6kn9_U8qk',
      description: 'Immersive downpour and gentle drops designed for sensory deprivation and deep rest.',
    ),
    ResourceItem(
      id: 'rain_04',
      title: 'Cozy Rain & Soft Ambient Harmony',
      author: 'Nomad Ambient',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: '1fueZCTYkpA',
      description: 'Warm shelter atmosphere watching summer rain wash away environmental tension.',
    ),

    // ==================== 3. WHITE, PINK & BROWN NOISE ====================
    ResourceItem(
      id: 'noise_01',
      title: 'Alpha Wave Harmonic Resonance (10 Hz Focus)',
      author: 'Brainwave Flow',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'WPni755-Krg',
      description: 'Acoustic frequency tuned to 10 Hz alpha brainwaves to stabilize focus and clear clutter.',
    ),
    ResourceItem(
      id: 'noise_02',
      title: 'Classic Pure White Noise Sound Machine',
      author: 'Relaxing White Noise',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'nMfPqeZjc2c',
      description: 'Uniform spectral frequency masking all ambient distractions for meditation.',
    ),
    ResourceItem(
      id: 'noise_03',
      title: 'Gentle Lofi Acoustic Beats: Relax & Study',
      author: 'Lofi Records',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: '5qap5aO4i9A',
      description: 'Naturally balanced acoustic spectrum mirroring the rhythm of deep focus states.',
    ),
    ResourceItem(
      id: 'noise_04',
      title: 'Smooth Chill Lo-Fi Drift for Ambient Grounding',
      author: 'Chilled Cow',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'DWcJFNfaw9c',
      description: 'Warm mid-range frequencies and steady rhythmic textures that calm racing thoughts.',
    ),

    // ==================== 4. PEACEFUL PIANO & AMBIENT MELODIES ====================
    ResourceItem(
      id: 'piano_01',
      title: 'Peaceful Relaxing Piano for Stress Relief',
      author: 'Peder B. Helland',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: 'lCOF9LN_Zxs',
      description: 'Gentle, flowing acoustic piano chords crafted to decelerate autonomic stress.',
    ),
    ResourceItem(
      id: 'piano_02',
      title: 'Soft Piano & Nature Symphony: Stress Release',
      author: 'Peder B. Helland',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: '1ZYbU82GVz4',
      description: 'Warm harmonies intertwined with delicate solo piano progressions and flying strings.',
    ),
    ResourceItem(
      id: 'piano_03',
      title: 'Waterfall & Forest Solitude Ambient Serenade',
      author: 'Nature Melodies',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: 'lE6RYpe9IT0',
      description: 'Harmonically tuned sound meditation activating parasympathetic recovery.',
    ),
    ResourceItem(
      id: 'piano_04',
      title: 'The Hidden Valley: Ambient Piano Meditation',
      author: 'Soothing Relaxation',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: '2OEL4P1Rz04',
      description: 'Serene ambient melody inspired by hidden valleys, stone gardens, and gentle breeze.',
    ),

    // ==================== 5. NATURE SOUNDSCAPES ====================
    ResourceItem(
      id: 'nature_01',
      title: 'Gentle Ocean Shore Waves & Rolling Tide',
      author: 'Calmsound',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'bn9F19Hi1Lk',
      description: 'Pacing ocean tide rolling onto smooth pebbles for synchronized deep breathing.',
    ),
    ResourceItem(
      id: 'nature_02',
      title: 'Forest Stream & Mountain Breeze Harmony',
      author: 'Nature Soundscapes',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'eKFTSSKCzWA',
      description: 'Pristine mountain stream bubbling over mossy stones with melodious birdsong.',
    ),
    ResourceItem(
      id: 'nature_03',
      title: 'Warm Hearth Fireplace Resonance & Cozy Crackle',
      author: 'Cozy Fireplace',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'L_LUpnjgPso',
      description: 'Warm glowing fire ambience with gentle crackling timber for tranquil nervous system reset.',
    ),
  ];
}
