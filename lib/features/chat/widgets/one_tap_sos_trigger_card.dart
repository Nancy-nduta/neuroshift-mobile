import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/muse_colors.dart';
import '../models/crisis_helpline.dart';
import '../services/crisis_detector.dart';

/// Interactive, life-critical One-Tap Cascading Crisis SOS Card.
///
/// Designed for users experiencing acute distress or suicidal thoughts.
/// Implements a one-tap phone dialer trigger across verified toll-free helplines.
/// If a line is busy or does not answer, the user can immediately cascade
/// to dial the next toll-free number with a single tap until someone answers.
class OneTapSosTriggerCard extends StatefulWidget {
  final List<CrisisHelpline>? helplines;
  final String? countryCode;
  final VoidCallback? onDismiss;
  final bool isModal;

  const OneTapSosTriggerCard({
    super.key,
    this.helplines,
    this.countryCode,
    this.onDismiss,
    this.isModal = false,
  });

  @override
  State<OneTapSosTriggerCard> createState() => _OneTapSosTriggerCardState();
}

class _OneTapSosTriggerCardState extends State<OneTapSosTriggerCard> {
  late final List<CrisisHelpline> _helplines;
  int _currentIndex = 0;
  bool _hasAttemptedCall = false;
  bool _showAllNumbers = false;
  bool _isConnectedWithSomeone = false;
  final Set<String> _attemptedNumbers = {};

  @override
  void initState() {
    super.initState();
    final effectiveCountry = widget.countryCode ?? 'KE';
    _helplines = widget.helplines ??
        CrisisResources(effectiveCountry).helplines;
  }

  CrisisHelpline get _currentHelpline =>
      _helplines.isNotEmpty ? _helplines[_currentIndex] : _fallbackHelpline;

  CrisisHelpline get _nextHelpline {
    if (_helplines.isEmpty) return _fallbackHelpline;
    final nextIdx = (_currentIndex + 1) % _helplines.length;
    return _helplines[nextIdx];
  }

  static const _fallbackHelpline = CrisisHelpline(
    id: 'ke_redcross',
    name: 'Kenya Red Cross Crisis Helpline',
    phoneNumber: '1199',
    formattedDisplayNumber: '1199',
    description: '24/7 National Psychological First Aid & Crisis Support (Toll-Free).',
    priorityBadge: 'Priority 1 (Free)',
  );

  Future<void> _dialHelpline(CrisisHelpline helpline) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _hasAttemptedCall = true;
      _attemptedNumbers.add(helpline.phoneNumber);
    });

    try {
      final uri = helpline.telUri;
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showCopyFallbackDialog(helpline);
      }
    } catch (_) {
      if (mounted) {
        _showCopyFallbackDialog(helpline);
      }
    }
  }

  void _cascadeToNext() {
    if (_helplines.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _helplines.length;
    });
    // Immediately trigger dial for the next helpline in the cascade
    _dialHelpline(_helplines[_currentIndex]);
  }

  void _showCopyFallbackDialog(CrisisHelpline helpline) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33EF4444)),
        ),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                helpline.name,
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your device could not open the phone dialer automatically. Please dial or copy this toll-free number:',
              style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33EF4444)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    helpline.formattedDisplayNumber,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: MuseColors.mindCyan, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: helpline.phoneNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${helpline.formattedDisplayNumber} to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: MuseColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnectedWithSomeone) {
      return _buildConnectedCard();
    }

    final current = _currentHelpline;
    final next = _nextHelpline;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF130D1A), // Deep emergency dark plum/slate
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x88EF4444),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22EF4444),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SOS Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0x33EF4444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.crisis_alert_rounded,
                  color: Color(0xFFFF4D4D),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ONE-TAP CRISIS SOS HELPLINE',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x4400E5FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x5500E5FF), width: 0.8),
                  ),
                  child: Text(
                    'LINE ${_currentIndex + 1} OF ${_helplines.length}',
                    style: const TextStyle(
                      color: MuseColors.mindCyan,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Active Helpline Card Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1424),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x33EF4444)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x33EF4444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              current.priorityBadge.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF8080),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.access_time_filled,
                            color: MuseColors.textSecondary,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            current.hours,
                            style: const TextStyle(
                              color: MuseColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current.name,
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current.description,
                        style: const TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Primary Big Dial Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626), // Vivid Red
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor: const Color(0x66DC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _dialHelpline(current),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_in_talk, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'ONE-TAP CALL: ${current.formattedDisplayNumber} (FREE)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Cascading Option (When user placed call or needs alternative)
                if (_hasAttemptedCall) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23161A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66F59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_missed_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Line busy or did not pick up?',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap below to immediately cascade to the next available emergency helpline:',
                          style: TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Cascade to Next Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0x33F59E0B),
                            foregroundColor: const Color(0xFFFCD34D),
                            side: const BorderSide(
                              color: Color(0xFFF59E0B),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.forward_to_inbox, size: 16),
                          label: Text(
                            'REDIAL NEXT: ${next.name} (${next.formattedDisplayNumber})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: _cascadeToNext,
                        ),

                        const SizedBox(height: 8),

                        // Connected confirmation button
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 15),
                          label: const Text(
                            'Someone answered / Connected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConnectedWithSomeone = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // 5. Expandable Full List of Toll-Free Numbers
                InkWell(
                  onTap: () {
                    setState(() {
                      _showAllNumbers = !_showAllNumbers;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAllNumbers
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: MuseColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showAllNumbers
                              ? 'Hide helpline directory'
                              : 'View all ${_helplines.length} verified emergency lines',
                          style: const TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAllNumbers) ...[
                  const SizedBox(height: 8),
                  ..._helplines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final h = entry.value;
                    final isCurrent = idx == _currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0x33DC2626)
                            : const Color(0xFF0F1523),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0x88DC2626)
                              : const Color(0x22FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      h.formattedDisplayNumber,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? const Color(0xFFFF6B6B)
                                            : MuseColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (h.isTollFree)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x3310B981),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text(
                                          'FREE',
                                          style: TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  h.name,
                                  style: const TextStyle(
                                    color: MuseColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0x22DC2626),
                              foregroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentIndex = idx;
                              });
                              _dialHelpline(h);
                            },
                            child: const Text(
                              'Dial',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E19),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x8810B981), width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 30),
          const SizedBox(height: 8),
          const Text(
            'We are glad you are speaking with someone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MuseColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Take all the time you need. Nova and NeuroShift are here whenever you return.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MuseColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _isConnectedWithSomeone = false;
              });
            },
            child: const Text(
              'Show helpline options again',
              style: TextStyle(
                color: MuseColors.mindCyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
