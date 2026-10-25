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
  // Collapsed by default so the Home screen stays clean and action-focused.
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    if (_isCollapsed) {
      return MuseCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => setState(() => _isCollapsed = false),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: MuseColors.cyanGlow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: MuseColors.cyanGlow,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Start Guide',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'See how headband pairing & guided sessions work',
                    style: TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: MuseColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      );
    }

    return MuseCard(
      borderColor: MuseColors.cyanGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 16, color: MuseColors.cyanGlow),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quick Start Guide',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded,
                    color: MuseColors.textSecondary, size: 20),
                onPressed: () => setState(() => _isCollapsed = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: MuseSpacing.sm),
          const _CompactStepRow(
            number: '1',
            title: 'Wear your headband (optional)',
            subtitle: 'Rest the sensors gently against your forehead and ears.',
            color: MuseColors.cyanGlow,
          ),
          const SizedBox(height: 8),
          const _CompactStepRow(
            number: '2',
            title: 'Listen & unwind',
            subtitle: 'Follow the audio guide while NeuroShift tracks your calm.',
            color: MuseColors.mysticPurple,
          ),
          const SizedBox(height: 8),
          const _CompactStepRow(
            number: '3',
            title: 'Check in afterward',
            subtitle: 'Rate how you feel to personalize future recommendations.',
            color: MuseColors.breathMint,
          ),
          const SizedBox(height: MuseSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bluetooth, size: 15),
                  label: const Text('Pair Headband',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MuseColors.cyanGlow,
                    side: BorderSide(
                        color: MuseColors.cyanGlow.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: widget.onConnectTapped,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _isCollapsed = true),
                child: const Text('Hide',
                    style: TextStyle(
                        color: MuseColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;

  const _CompactStepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
