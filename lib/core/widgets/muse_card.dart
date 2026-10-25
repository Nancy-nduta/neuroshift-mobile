import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../theme/muse_spacing.dart';

class MuseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;

  const MuseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MuseSpacing.md),
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor != null
        ? borderColor!.withValues(alpha: 0.45)
        : MuseColors.cardBorder.withValues(alpha: 0.65);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF121826),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
