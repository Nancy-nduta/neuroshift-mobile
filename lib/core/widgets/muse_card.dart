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
    this.borderRadius = MuseSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? MuseColors.cardBorder,
      width: 1.0,
    );

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? MuseColors.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
