import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_card.dart';
import '../../chat/screens/ai_wellness_chat_screen.dart';
import '../models/resource_evaluation.dart';
import '../models/resource_item.dart';
import '../providers/resource_ranking_provider.dart';
import 'resource_practice_screen.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  ResourceCategory? _selectedCategory;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openResource(ResourceItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResourcePracticeScreen(resource: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically ranked list of resources based on recorded EEG calm & ratings
    final rankedCatalog = ref.watch(rankedResourcesProvider);
    final rankings = ref.watch(resourceRankingsProvider);

    final filtered = rankedCatalog.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('RESOURCES'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Intuitive Subtitle & Instructions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MuseSpacing.lg,
                  MuseSpacing.xs,
                  MuseSpacing.lg,
                  MuseSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore guided meditations, rain sounds, white noise, and acoustic piano. Tap any session to start listening, connect your Muse 2 headband to observe your brainwaves in real time, and complete the practice to train your personal recommendation engine.',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Nova AI Mental Health Guide Banner
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiWellnessChatScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              const Color(0xFF9D4EDD).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                          border: Border.all(color: const Color(0x4D00E5FF), width: 1.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology_alt, color: MuseColors.cyanGlow, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Nova AI Mental Health Guide',
                                    style: TextStyle(
                                      color: MuseColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Need help? Ask questions about anxiety, sleep, brainwaves & get guidance',
                                    style: TextStyle(color: MuseColors.textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: MuseColors.cyanGlow, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: MuseColors.cardSurface,
                        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                        border: Border.all(color: MuseColors.cardBorder),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: MuseColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search 20 resources (e.g. rain, piano, focus)...',
                          hintStyle: const TextStyle(color: MuseColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: MuseColors.textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: MuseColors.textMuted, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All (${rankedCatalog.length})',
                            isSelected: _selectedCategory == null,
                            icon: Icons.apps,
                            color: MuseColors.cyanGlow,
                            onTap: () => setState(() => _selectedCategory = null),
                          ),
                          ...ResourceCategory.values.map((cat) {
                            final count = rankedCatalog.where((item) => item.category == cat).length;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildFilterChip(
                                label: '${cat.label} ($count)',
                                isSelected: _selectedCategory == cat,
                                icon: cat.icon,
                                color: cat.color,
                                onTap: () => setState(() => _selectedCategory = cat),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Resources List
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: MuseColors.textMuted),
                      SizedBox(height: MuseSpacing.md),
                      Text(
                        'No matching resources found',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try searching for "meditation", "rain", "piano", or clear your filter.',
                        style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(MuseSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final eval = rankings[item.id];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: MuseSpacing.md),
                        child: _ResourceCard(
                          item: item,
                          evaluation: eval,
                          onTap: () => _openResource(item),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.20) : MuseColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : MuseColors.cardBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : MuseColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MuseColors.textPrimary : MuseColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ResourceItem item;
  final ResourceEvaluation? evaluation;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.item,
    this.evaluation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHighRating = evaluation != null && evaluation!.performanceScore >= 70.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MuseCard(
        borderColor: hasHighRating
            ? MuseColors.mindCyan.withValues(alpha: 0.6)
            : MuseColors.cardBorder,
        backgroundColor: hasHighRating
            ? MuseColors.mindCyan.withValues(alpha: 0.05)
            : MuseColors.cardSurface,
        onTap: onTap,
        padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with duration tag & play overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(MuseSpacing.radiusMd)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) {
                      return Container(
                        color: MuseColors.surfaceElevated,
                        child: Center(
                          child: Icon(item.category.icon, size: 48, color: item.category.color),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Center Play Icon Button
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              // Duration Badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 10, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        item.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.category.color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.category.icon, size: 11, color: MuseColors.spaceBackground),
                      const SizedBox(width: 4),
                      Text(
                        item.category.label,
                        style: const TextStyle(
                          color: MuseColors.spaceBackground,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Rated / Performance Badge if evaluated
              if (evaluation != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasHighRating
                          ? MuseColors.mindCyan
                          : MuseColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (hasHighRating)
                          BoxShadow(
                            color: MuseColors.mindCyan.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasHighRating ? Icons.star : Icons.history,
                          size: 11,
                          color: hasHighRating ? MuseColors.spaceBackground : MuseColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasHighRating
                              ? 'TOP RATED • ${evaluation!.performanceScore.toInt()}%'
                              : 'SCORE: ${evaluation!.performanceScore.toInt()}%',
                          style: TextStyle(
                            color: hasHighRating ? MuseColors.spaceBackground : MuseColors.textPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Metadata Info
          Padding(
            padding: const EdgeInsets.all(MuseSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: MuseSpacing.sm),

                // If evaluated, show mood detection report snippet
                if (evaluation != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: MuseSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MuseColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MuseColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, size: 12, color: MuseColors.mindCyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Mood Detected: ${evaluation!.inferredMood} • ${evaluation!.calmPercent.toInt()}% Calm',
                            style: const TextStyle(
                              color: MuseColors.mindCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '★' * evaluation!.starRating,
                          style: const TextStyle(
                            color: MuseColors.bodyAmber,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: MuseColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.author,
                      style: const TextStyle(
                        color: MuseColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'START SESSION',
                      style: TextStyle(
                        color: MuseColors.mindCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 14, color: MuseColors.mindCyan),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
