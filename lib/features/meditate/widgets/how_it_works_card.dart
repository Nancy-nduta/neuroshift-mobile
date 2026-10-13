import 'package:flutter/material.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_card.dart';

class HowItWorksCard extends StatefulWidget {
  final VoidCallback? onConnectTapped;
  final VoidCallback? onStartTapped;

  const HowItWorksCard({
    super.key,
    this.onConnectTapped,
    this.onStartTapped,
  });

  @override
  State<HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<HowItWorksCard> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    if (_isCollapsed) {
      return MuseCard(
        borderColor: MuseColors.cyanGlow.withValues(alpha: 0.3),
        backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.6),
        child: InkWell(
          onTap: () => setState(() => _isCollapsed = false),
          borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.help_outline, color: MuseColors.cyanGlow, size: 18),
                  ),
                ),
                const SizedBox(width: MuseSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How NeuroShift Works',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Biofeedback + guided meditation learning guide',
                        style: TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isCollapsed = false),
                  child: const Text('View Guide', style: TextStyle(color: MuseColors.cyanGlow, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MuseCard(
      borderColor: MuseColors.cyanGlow.withValues(alpha: 0.4),
      backgroundColor: const Color(0xFF111E2E), // Subtle deep navy
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MuseColors.cyanGlow.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: MuseColors.cyanGlow),
                    SizedBox(width: 4),
                    Text(
                      'HOW NEUROSHIFT WORKS',
                      style: TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: MuseColors.textSecondary, size: 20),
                onPressed: () => setState(() => _isCollapsed = true),
                tooltip: 'Minimize Guide',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: MuseSpacing.sm),

          // Title & Purpose
          const Text(
            'Biofeedback that learns what calms your mind',
            style: TextStyle(
              color: MuseColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: MuseSpacing.xs),
          const Text(
            'NeuroShift monitors your brainwaves, pulse, and stillness in real-time. By combining real sensor data with your personal feedback, it learns the exact exercises that work best for you.',
            style: TextStyle(
              color: MuseColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MuseSpacing.md),

          // 3-Step Visual Cards
          _StepItem(
            stepNumber: '1',
            icon: Icons.headphones_outlined,
            iconColor: MuseColors.cyanGlow,
            title: 'Put on Your Muse 2 Headband',
            description:
                'Ensure the forehead and ear sensors make firm, comfortable contact with your skin.',
          ),
          const SizedBox(height: MuseSpacing.sm),

          _StepItem(
            stepNumber: '2',
            icon: Icons.self_improvement,
            iconColor: MuseColors.mysticPurple,
            title: 'Follow the Guided Meditation',
            description:
                'Put on your headphones and follow the calming audio guide as your headband tracks your brainwaves, heart rate, and relaxation in the background.',
          ),
          const SizedBox(height: MuseSpacing.sm),

          _StepItem(
            stepNumber: '3',
            icon: Icons.star_rate_rounded,
            iconColor: MuseColors.amberGlow,
            title: 'Rate How You Feel & Learn',
            description:
                'Give a quick review after your session. NeuroShift combines your rating with your real sensor data to recommend what actually works best for you.',
          ),
          const SizedBox(height: MuseSpacing.md),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sensors, size: 16),
                  label: const Text('Connect Headband', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MuseColors.cyanGlow,
                    foregroundColor: MuseColors.spaceBackground,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: widget.onConnectTapped,
                ),
              ),
              const SizedBox(width: MuseSpacing.sm),
              TextButton(
                onPressed: () => setState(() => _isCollapsed = true),
                child: const Text('Got it', style: TextStyle(color: MuseColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String stepNumber;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _StepItem({
    required this.stepNumber,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MuseSpacing.sm),
      decoration: BoxDecoration(
        color: MuseColors.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
        border: Border.all(color: MuseColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: MuseSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STEP $stepNumber',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
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
