import 'package:flutter/material.dart';

/// Serene, meditative color palette inspired directly by the official Muse 2 application.
/// Dominated by deep midnight space, dark slate card layers, soft ethereal cyan for Mind,
/// warm rose for Heart, zen amber for Body, and mint for Breath.
class MuseColors {
  // Deep Backgrounds
  static const Color background = Color(0xFF090D16);
  static const Color spaceBackground = background;
  static const Color surface = Color(0xFF111726);
  static const Color cardSurface = surface;
  static const Color surfaceElevated = Color(0xFF192236);
  static const Color surfaceSubtle = Color(0xFF0E1422);

  // Borders and Dividers
  static const Color border = Color(0xFF222B3D);
  static const Color cardBorder = border;
  static const Color borderLight = Color(0xFF2E3A52);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E9BAE);
  static const Color textTertiary = Color(0xFF5A6678);
  static const Color textMuted = textTertiary;

  // Muse Meditation Experience Accent Colors
  // Mind (EEG Brainwaves / Alpha relaxation)
  static const Color mindCyan = Color(0xFF00E5FF);
  static const Color cyanGlow = mindCyan;
  static const Color mindGlow = Color(0x3300E5FF);

  // Heart (Optical PPG Pulse & HRV)
  static const Color heartRose = Color(0xFFFF2A6D);
  static const Color heartRed = heartRose;
  static const Color roseGlow = heartRose;
  static const Color heartGlow = Color(0x33FF2A6D);

  // Body (Movement & Stillness)
  static const Color bodyAmber = Color(0xFFFFB703);
  static const Color amberGlow = bodyAmber;
  static const Color bodyGlow = Color(0x33FFB703);

  // Breath (Pacing & Parasympathetic activation)
  static const Color breathMint = Color(0xFF06D6A0);
  static const Color breathGlow = Color(0x3306D6A0);

  // Soundscape / Ambient Guided
  static const Color mysticPurple = Color(0xFF9D4EDD);
  static const Color mysticGlow = Color(0x339D4EDD);

  // Status & Horseshoe Fit Indicators
  static const Color fitGood = Color(0xFF00E676); // Vibrant Muse Neon Green
  static const Color calmGlow = fitGood;
  static const Color fitAdjust = Color(0xFFFFB703);
  static const Color neutralGlow = fitAdjust;
  static const Color fitPoor = Color(0xFFEF4444);
  static const Color activeGlow = fitPoor;
  static const Color fitDisconnected = Color(0xFF334155);

  // Gradients
  static const LinearGradient mindGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heartGradient = LinearGradient(
    colors: [Color(0xFFFF2A6D), Color(0xFFD90429)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bodyGradient = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient breathGradient = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF0096C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mysticGradient = LinearGradient(
    colors: [Color(0xFF7209B7), Color(0xFF3F37C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
