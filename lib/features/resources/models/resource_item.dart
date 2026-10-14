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
      title: 'Release Overthinking & Mental Fatigue',
      author: 'The Honest Guys',
      category: ResourceCategory.guidedMeditation,
      durationLabel: '12 min',
      youtubeVideoId: 'syx3a1tmsIA',
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
      title: 'Heavy Rolling Thunderstorm at Night',
      author: 'The Relaxed Guy',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: 'bD6QfU3m69Y',
      description: 'Immersive downpour and thunder designed for sensory deprivation and deep rest.',
    ),
    ResourceItem(
      id: 'rain_04',
      title: 'Cozy Porch Rain & Distant Lightning',
      author: 'Nomad Ambient',
      category: ResourceCategory.rainAndStorm,
      durationLabel: 'Continuous',
      youtubeVideoId: '1fueZCTYkpA',
      description: 'Warm shelter atmosphere watching summer rain wash away environmental tension.',
    ),

    // ==================== 3. WHITE, PINK & BROWN NOISE ====================
    ResourceItem(
      id: 'noise_01',
      title: 'Pure Deep Brown Noise for ADHD & Deep Focus',
      author: 'Crysknife007',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'RqzGargq524',
      description: 'Warm low-frequency rumble that effectively masks background noise and aids focus.',
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
      title: 'Gentle Pink Noise: Balanced Frequency Waves',
      author: 'Brainwave Music',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'wziZaO-yq2I',
      description: 'Naturally balanced acoustic spectrum mirroring the rhythm of brainwaves and waterfalls.',
    ),
    ResourceItem(
      id: 'noise_04',
      title: 'Green Noise: Natural Ambient Woodland Frequency',
      author: 'Sound Oasis',
      category: ResourceCategory.whiteNoise,
      durationLabel: 'Continuous',
      youtubeVideoId: 'K4w4K-n48sU',
      description: 'Mid-range frequency centered on natural organic sounds that promotes calm breathing.',
    ),

    // ==================== 4. PEACEFUL PIANO & AMBIENT MELODIES ====================
    ResourceItem(
      id: 'piano_01',
      title: 'Peaceful Relaxing Piano for Stress Relief',
      author: 'Yellow Brick Cinema',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: 'lCOF9LN_Zxs',
      description: 'Gentle, flowing acoustic piano chords crafted to decelerate autonomic stress.',
    ),
    ResourceItem(
      id: 'piano_02',
      title: 'Soft Piano & Cello: Healing & Quiet Study',
      author: 'Tim Janis',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: '1ZYbU82GVz4',
      description: 'Warm cello harmonies intertwined with delicate solo piano progressions.',
    ),
    ResourceItem(
      id: 'piano_03',
      title: '432Hz Miracle Frequency Healing Meditation',
      author: 'Meditative Mind',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: '7T08D461f88',
      description: 'Harmonically tuned sound meditation activating parasympathetic recovery.',
    ),
    ResourceItem(
      id: 'piano_04',
      title: 'Japanese Garden Piano & Shakuhachi Bamboo Flute',
      author: 'Soothing Relaxation',
      category: ResourceCategory.peacefulPiano,
      durationLabel: 'Continuous',
      youtubeVideoId: '2OEL4P1Rz04',
      description: 'Serene Oriental melody inspired by Zen stone gardens and gentle breeze.',
    ),

    // ==================== 5. NATURE SOUNDSCAPES ====================
    ResourceItem(
      id: 'nature_01',
      title: 'Gentle Ocean Shore Waves & Distant Gulls',
      author: 'Calmsound',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'bn9F19Hi1Lk',
      description: 'Pacing ocean tide rolling onto smooth pebbles for synchronized deep breathing.',
    ),
    ResourceItem(
      id: 'nature_02',
      title: 'Forest Birds Singing by a Gentle Mountain Creek',
      author: 'Nature Soundscapes',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'eKFTSSKCzWA',
      description: 'Pristine mountain stream bubbling over mossy stones with melodious birdsong.',
    ),
    ResourceItem(
      id: 'nature_03',
      title: 'Night Forest Crickets & Crackling Campfire',
      author: 'Virtual Fireplace',
      category: ResourceCategory.natureSoundscapes,
      durationLabel: 'Continuous',
      youtubeVideoId: 'g_tzQ_82g0s',
      description: 'Warm glowing fire ambience with nocturnal wilderness sounds for tranquil calm.',
    ),
  ];
}
