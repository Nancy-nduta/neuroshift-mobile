import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../theme/muse_spacing.dart';

enum MuseButtonVariant { primary, secondary, outline }

class MuseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final MuseButtonVariant variant;
  final double? width;
  final double height;

  const MuseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = MuseButtonVariant.primary,
    this.width,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case MuseButtonVariant.primary:
        bg = MuseColors.cyanGlow;
        fg = MuseColors.spaceBackground;
        break;
      case MuseButtonVariant.secondary:
        bg = MuseColors.cardBorder;
        fg = MuseColors.textPrimary;
        break;
      case MuseButtonVariant.outline:
        bg = Colors.transparent;
        fg = MuseColors.cyanGlow;
        border = const BorderSide(color: MuseColors.cyanGlow, width: 1.5);
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: variant == MuseButtonVariant.primary ? 4 : 0,
      shadowColor: variant == MuseButtonVariant.primary ? MuseColors.cyanGlow.withValues(alpha: 0.4) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
        side: border ?? BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
    );

    final content = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: MuseSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: fg,
                  ),
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}
