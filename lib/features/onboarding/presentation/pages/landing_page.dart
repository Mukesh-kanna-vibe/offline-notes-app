import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../theme/onboarding_typography.dart';
import '../widgets/onboarding_feature_chip.dart';
import '../widgets/onboarding_phone_preview.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _pageCount = 3;

  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pageCount - 1;

  void _onContinue() {
    if (_isLastPage) {
      widget.onGetStarted();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _OnboardingSlide(
                    index: 0,
                    currentPage: _currentPage,
                    child: const _WelcomeSlide(),
                  ),
                  _OnboardingSlide(
                    index: 1,
                    currentPage: _currentPage,
                    child: const _PreviewSlide(),
                  ),
                  _OnboardingSlide(
                    index: 2,
                    currentPage: _currentPage,
                    child: const _ReadySlide(),
                  ),
                ],
              ),
            ),
            _buildPageIndicator(),
            const SizedBox(height: 20),
            _buildBottomCta(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Spacer(),
          TextButton(
            onPressed: widget.onGetStarted,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.inkMuted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Skip',
              style: OnboardingTypography.label(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.ink : Colors.transparent,
            border: Border.all(
              color: isActive ? AppTheme.ink : AppTheme.inkSoft,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.fabDark,
            foregroundColor: AppTheme.cardWhite,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _isLastPage ? 'Get Started' : 'Continue',
              key: ValueKey(_isLastPage),
              style: OnboardingTypography.label(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.cardWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.index,
    required this.currentPage,
    required this.child,
  });

  final int index;
  final int currentPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentPage;
    final distance = (index - currentPage).abs().clamp(0, 1).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(end: isActive ? 1 : 1 - distance * 0.35),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide();

  static const _features = [
    'Works Offline',
    'Auto Sync',
    'Conflict Resolution',
    'SQLite Storage',
    'MockAPI Sync',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.onlineBg,
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: AppTheme.onlineGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline first',
                  style: OnboardingTypography.label(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onlineGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Offline First Notes',
            style: OnboardingTypography.heading(fontSize: 38),
          ),
          const SizedBox(height: 20),
          Text(
            'Capture your ideas anywhere.\n'
            'Works completely offline and automatically syncs when you\'re back online.',
            style: OnboardingTypography.body(
              fontSize: 16,
              color: AppTheme.inkMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _features
                .map((feature) => OnboardingFeatureChip(label: feature))
                .toList(),
          ),
          const SizedBox(height: 36),
          _buildIllustration(),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 48,
              color: AppTheme.onlineGreen.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              'Write anywhere',
              style: OnboardingTypography.heading(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No connection required. Your notes stay on device until sync.',
              style: OnboardingTypography.body(
                fontSize: 14,
                color: AppTheme.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSlide extends StatelessWidget {
  const _PreviewSlide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your notes, in sync',
            style: OnboardingTypography.heading(fontSize: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'See sync status at a glance — synced, pending, or in conflict.',
            style: OnboardingTypography.body(
              fontSize: 16,
              color: AppTheme.inkMuted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),
          const OnboardingPhonePreview(),
        ],
      ),
    );
  }
}

class _ReadySlide extends StatelessWidget {
  const _ReadySlide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready when you are',
            style: OnboardingTypography.heading(fontSize: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'SQLite keeps notes safe locally. MockAPI syncs them when you\'re online — '
            'with smart conflict resolution built in.',
            style: OnboardingTypography.body(
              fontSize: 16,
              color: AppTheme.inkMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildSyncIllustration(),
          const SizedBox(height: 28),
          _buildSummaryRow(
            icon: Icons.storage_rounded,
            title: 'SQLite Storage',
            subtitle: 'Fast, reliable local persistence',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.sync_rounded,
            title: 'Auto Sync',
            subtitle: 'Pushes and pulls when connected',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.merge_type_rounded,
            title: 'Conflict Resolution',
            subtitle: 'Merge changes without losing work',
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIllustration() {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.onlineBg,
              AppTheme.cardWhite,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSyncNode(
              icon: Icons.phone_iphone_rounded,
              label: 'Device',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.sync_alt_rounded,
                color: AppTheme.onlineGreen.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
            _buildSyncNode(
              icon: Icons.cloud_outlined,
              label: 'MockAPI',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncNode({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.ink, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: OnboardingTypography.label(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.inkMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 22, color: AppTheme.onlineGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: OnboardingTypography.label(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: OnboardingTypography.body(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
