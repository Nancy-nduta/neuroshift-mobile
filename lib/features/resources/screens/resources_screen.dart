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
    final rankedCatalog = ref.watch(rankedResourcesProvider);
    final rankings = ref.watch(resourceRankingsProvider);

    final filtered = rankedCatalog.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MuseColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MuseSpacing.md),
            child: ActionChip(
              avatar: const Icon(Icons.psychology_alt,
                  size: 16, color: MuseColors.cyanGlow),
              label: const Text(
                'Ask Nova',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: MuseColors.cardSurface,
              side: BorderSide(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiWellnessChatScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
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
                    // Clean Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: MuseColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: MuseColors.cardBorder.withValues(alpha: 0.7)),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(
                            color: MuseColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search meditations, rain, sleep, focus...',
                          hintStyle: const TextStyle(
                              color: MuseColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: MuseColors.textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: MuseColors.textMuted, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                            label: 'All',
                            isSelected: _selectedCategory == null,
                            icon: Icons.apps,
                            color: MuseColors.cyanGlow,
                            onTap: () =>
                                setState(() => _selectedCategory = null),
                          ),
                          ...ResourceCategory.values.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildFilterChip(
                                label: cat.label,
                                isSelected: _selectedCategory == cat,
                                icon: cat.icon,
                                color: cat.color,
                                onTap: () =>
                                    setState(() => _selectedCategory = cat),
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

            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 44, color: MuseColors.textMuted),
                      SizedBox(height: MuseSpacing.sm),
                      Text(
                        'No matching sessions',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try another keyword or category filter.',
                        style: TextStyle(
                            color: MuseColors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MuseSpacing.lg,
                  MuseSpacing.sm,
                  MuseSpacing.lg,
                  MuseSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final eval = rankings[item.id];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : MuseColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : MuseColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: isSelected ? color : MuseColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? MuseColors.textPrimary
                    : MuseColors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    final hasHighRating =
        evaluation != null && evaluation!.performanceScore >= 70.0;

    return MuseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: hasHighRating
          ? MuseColors.mindCyan.withValues(alpha: 0.5)
          : MuseColors.cardBorder,
      child: Row(
        children: [
          // Compact Square Thumbnail with Play Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) {
                      return Container(
                        color: MuseColors.surfaceElevated,
                        child: Icon(
                          item.category.icon,
                          size: 28,
                          color: item.category.color,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Title, Description & Category/Duration Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label,
                        style: TextStyle(
                          color: item.category.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.durationLabel,
                      style: const TextStyle(
                        color: MuseColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (evaluation != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MuseColors.breathMint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${evaluation!.calmPercent.toInt()}% calm',
                          style: const TextStyle(
                            color: MuseColors.breathMint,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
