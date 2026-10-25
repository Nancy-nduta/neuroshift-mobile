import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/consent_record.dart';

class OnboardingConsentScreen extends ConsumerStatefulWidget {
  final bool isReviewMode;
  final ConsentRecord? existingRecord;
  final String? overrideUserId;
  final String? overrideUserEmail;

  const OnboardingConsentScreen({
    super.key,
    this.isReviewMode = false,
    this.existingRecord,
    this.overrideUserId,
    this.overrideUserEmail,
  });

  @override
  ConsumerState<OnboardingConsentScreen> createState() =>
      _OnboardingConsentScreenState();
}

class _OnboardingConsentScreenState
    extends ConsumerState<OnboardingConsentScreen> {
  late bool _physiologicalDataConsent;
  late bool _moodTrackingConsent;
  late bool _adaptiveRecommendationsConsent;
  late bool _anonymizedResearchConsent;
  late bool _hasAcknowledgedTerms;

  bool _includeOnboardingCheckin = true;
  int _selectedValence = 3;
  final Set<String> _selectedTags = {'Stress Relief'};
  final TextEditingController _moodNotesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  static const Map<int, String> _valenceLabels = {
    1: 'Low',
    2: 'Stressed',
    3: 'Balanced',
    4: 'Calm',
    5: 'Great',
  };

  static const List<String> _availableTags = [
    'Stress Relief',
    'Focus',
    'Better Sleep',
    'Emotional Balance',
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    if (record != null && record.status != ConsentStatus.withdrawn) {
      _physiologicalDataConsent = record.physiologicalDataConsent;
      _moodTrackingConsent = record.moodTrackingConsent;
      _adaptiveRecommendationsConsent = record.adaptiveRecommendationsConsent;
      _anonymizedResearchConsent = record.anonymizedResearchConsent;
      _hasAcknowledgedTerms = true;
      _includeOnboardingCheckin = false;
    } else {
      _physiologicalDataConsent = true;
      _moodTrackingConsent = true;
      _adaptiveRecommendationsConsent = true;
      _anonymizedResearchConsent = false;
      _hasAcknowledgedTerms = false;
      _includeOnboardingCheckin = !widget.isReviewMode;
    }
  }

  @override
  void dispose() {
    _moodNotesController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _physiologicalDataConsent &&
      _moodTrackingConsent &&
      _hasAcknowledgedTerms &&
      !_isSaving;

  ConsentStatus get _previewStatus => ConsentRecord.computeStatus(
        moodTrackingConsent: _moodTrackingConsent,
        physiologicalDataConsent: _physiologicalDataConsent,
        adaptiveRecommendationsConsent: _adaptiveRecommendationsConsent,
        anonymizedResearchConsent: _anonymizedResearchConsent,
      );

  Future<void> _submitConsent() async {
    if (!_canSubmit) {
      setState(() {
        _errorMessage =
            'Please enable core permissions and check the confirmation box to continue.';
      });
      return;
    }

    final authUser = ref.read(authStateProvider).value;
    final userId = widget.overrideUserId ?? authUser?.uid;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'Please sign in to save your preferences.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final status = _previewStatus;
      final existing = widget.existingRecord;

      final record = ConsentRecord(
        userId: userId,
        policyVersion: ConsentRecord.currentPolicyVersion,
        status: status,
        moodTrackingConsent: _moodTrackingConsent,
        physiologicalDataConsent: _physiologicalDataConsent,
        adaptiveRecommendationsConsent: _adaptiveRecommendationsConsent,
        anonymizedResearchConsent: _anonymizedResearchConsent,
        consentedAt: existing?.consentedAt ?? now,
        rawConsentedAt: existing?.rawConsentedAt ?? now.toIso8601String(),
        lastUpdatedAt: now,
        withdrawnAt: null,
      );

      final repo = ref.read(consentRepositoryProvider);
      await repo.saveConsentRecord(record);

      if (_includeOnboardingCheckin && _moodTrackingConsent) {
        await repo.saveOnboardingMoodCheckin(
          userId: userId,
          valence: _selectedValence,
          moodLabel: _valenceLabels[_selectedValence] ?? 'Balanced',
          notes: _moodNotesController.text,
          tags: _selectedTags.toList(),
        );
      }

      ref.invalidate(currentUserProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MuseColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: MuseColors.breathMint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isReviewMode
                      ? 'Privacy preferences saved.'
                      : 'Welcome to NeuroShift!',
                  style: const TextStyle(color: MuseColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );

      if (widget.isReviewMode && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not save preferences: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _withdrawConsent() async {
    final authUser = ref.read(authStateProvider).value;
    final userId = widget.overrideUserId ?? authUser?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MuseColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Withdraw Consent?',
          style: TextStyle(color: MuseColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          'Pausing consent stops biofeedback and mood tracking until you choose to re-enable them.',
          style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: MuseColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw',
                style: TextStyle(
                    color: MuseColors.roseGlow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(consentRepositoryProvider).withdrawConsent(userId);
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      if (widget.isReviewMode && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not withdraw consent: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final userEmail = widget.overrideUserEmail ?? authUser?.email ?? '';

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isReviewMode ? 'Privacy & Consent' : 'Welcome to NeuroShift',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MuseColors.textPrimary,
          ),
        ),
        actions: [
          if (!widget.isReviewMode)
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => ref.read(authServiceProvider).signOut(),
              child: const Text(
                'Sign Out',
                style:
                    TextStyle(color: MuseColors.textSecondary, fontSize: 12.5),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MuseSpacing.lg,
            vertical: MuseSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Intro Card
              MuseCard(
                borderColor: MuseColors.cyanGlow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: MuseColors.cyanGlow.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: MuseColors.cyanGlow,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NeuroShift Participant Informed Consent',
                            style: TextStyle(
                              color: MuseColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (userEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                color: MuseColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          const Text(
                            'Your privacy comes first. Choose how NeuroShift uses your wellness and headband data below.',
                            style: TextStyle(
                              color: MuseColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.md),

              // Compact Summary Cards
              _buildInfoCard(
                title: 'Purpose & Non-Medical Wellness Disclaimer',
                icon: Icons.favorite_border,
                accentColor: MuseColors.amberGlow,
                summary:
                    'NeuroShift supports relaxation and mindfulness using guided audio and optional headband feedback. It is a wellness tool, not a medical device or crisis service.',
              ),
              const SizedBox(height: MuseSpacing.sm),

              _buildInfoCard(
                title: 'Data Collection, Cloud Firestore Storage & Security',
                icon: Icons.lock_outline,
                accentColor: MuseColors.cyanGlow,
                summary:
                    'Live headband signals are processed on your phone and summarized into private session stats in your account. Nothing is shared with a therapist unless you invite them.',
              ),
              const SizedBox(height: MuseSpacing.lg),

              const Text(
                'Your Permissions',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),

              _buildPermissionToggleCard(
                keyName: 'consent_physiological_switch',
                title: 'Biofeedback & Calm Tracking',
                badgeText: 'Required',
                badgeColor: MuseColors.cyanGlow,
                description:
                    'Reads headband calm and heart-rate signals during sessions.',
                value: _physiologicalDataConsent,
                onChanged: (val) =>
                    setState(() => _physiologicalDataConsent = val),
              ),
              const SizedBox(height: 8),

              _buildPermissionToggleCard(
                keyName: 'consent_mood_switch',
                title: 'Mood Check-Ins',
                badgeText: 'Required',
                badgeColor: MuseColors.cyanGlow,
                description:
                    'Saves your mood reflections so you can see what helps you feel better.',
                value: _moodTrackingConsent,
                onChanged: (val) => setState(() => _moodTrackingConsent = val),
              ),
              const SizedBox(height: 8),

              _buildPermissionToggleCard(
                keyName: 'consent_adaptive_switch',
                title: 'Personalized AI Suggestions',
                badgeText: 'Optional',
                badgeColor: MuseColors.mysticPurple,
                description:
                    'Lets Nova tailor exercises and answers to your recent sessions.',
                value: _adaptiveRecommendationsConsent,
                onChanged: (val) =>
                    setState(() => _adaptiveRecommendationsConsent = val),
              ),
              const SizedBox(height: 8),

              _buildPermissionToggleCard(
                keyName: 'consent_research_switch',
                title: 'Anonymous Wellness Insights',
                badgeText: 'Optional',
                badgeColor: MuseColors.breathMint,
                description:
                    'Shares anonymous, de-identified trends to help improve audio sessions.',
                value: _anonymizedResearchConsent,
                onChanged: (val) =>
                    setState(() => _anonymizedResearchConsent = val),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // Quick Baseline Check-in
              if (!widget.isReviewMode && _moodTrackingConsent) ...[
                MuseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (index) {
                          final valence = index + 1;
                          final isSelected = _selectedValence == valence;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () =>
                                    setState(() => _selectedValence = valence),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? MuseColors.cyanGlow
                                            .withValues(alpha: 0.18)
                                        : MuseColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? MuseColors.cyanGlow
                                          : MuseColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$valence',
                                        style: TextStyle(
                                          color: isSelected
                                              ? MuseColors.cyanGlow
                                              : MuseColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _valenceLabels[valence]!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? MuseColors.textPrimary
                                              : MuseColors.textMuted,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _availableTags.map((tag) {
                          final selected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? MuseColors.spaceBackground
                                    : MuseColors.textSecondary,
                              ),
                            ),
                            selected: selected,
                            selectedColor: MuseColors.cyanGlow,
                            backgroundColor: MuseColors.surfaceElevated,
                            checkmarkColor: MuseColors.spaceBackground,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedTags.add(tag);
                                } else if (_selectedTags.length > 1) {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),
              ],

              // Affirmation Checkbox
              MuseCard(
                borderColor: _hasAcknowledgedTerms
                    ? MuseColors.breathMint
                    : MuseColors.cardBorder,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: CheckboxListTile(
                  key: const Key('consent_acknowledge_checkbox'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: MuseColors.cyanGlow,
                  checkColor: MuseColors.spaceBackground,
                  value: _hasAcknowledgedTerms,
                  onChanged: (val) =>
                      setState(() => _hasAcknowledgedTerms = val ?? false),
                  title: const Text(
                    'I understand that NeuroShift is a wellness app and agree to these privacy preferences.',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: MuseSpacing.sm),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: MuseColors.roseGlow, fontSize: 12),
                ),
              ],

              const SizedBox(height: MuseSpacing.lg),
              MuseButton(
                key: const Key('consent_submit_button'),
                label: _isSaving
                    ? 'Saving...'
                    : (widget.isReviewMode
                        ? 'Save Preferences'
                        : 'Accept & Continue'),
                icon: Icons.check_circle_outline,
                width: double.infinity,
                onPressed: _canSubmit ? _submitConsent : null,
              ),

              if (widget.isReviewMode &&
                  widget.existingRecord != null &&
                  widget.existingRecord!.status != ConsentStatus.withdrawn) ...[
                const SizedBox(height: MuseSpacing.sm),
                Center(
                  child: TextButton.icon(
                    key: const Key('consent_withdraw_button'),
                    onPressed: _isSaving ? null : _withdrawConsent,
                    icon: const Icon(Icons.remove_moderator_outlined,
                        color: MuseColors.roseGlow, size: 16),
                    label: const Text(
                      'Withdraw Consent',
                      style: TextStyle(
                        color: MuseColors.roseGlow,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: MuseSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String summary,
  }) {
    return MuseCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionToggleCard({
    required String keyName,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MuseCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: value ? badgeColor : MuseColors.cardBorder,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
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
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: Key(keyName),
            value: value,
            activeThumbColor: badgeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
