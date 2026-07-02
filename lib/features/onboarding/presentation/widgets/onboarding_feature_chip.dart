import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../theme/onboarding_typography.dart';

class OnboardingFeatureChip extends StatelessWidget {
  const OnboardingFeatureChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 16,
            color: AppTheme.onlineGreen,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: OnboardingTypography.label(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
