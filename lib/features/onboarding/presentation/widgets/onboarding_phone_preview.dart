import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../notes/domain/entities/note_entities.dart';
import '../theme/onboarding_typography.dart';
import 'onboarding_preview_note_card.dart';

class OnboardingPhonePreview extends StatelessWidget {
  const OnboardingPhonePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'onboarding-phone-preview',
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ColoredBox(
                color: AppTheme.pageBackground,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '12:46',
                            style: OnboardingTypography.label(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '5G',
                                style: OnboardingTypography.label(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.inkMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.battery_full_rounded,
                                size: 14,
                                color: AppTheme.onlineGreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Notes',
                        style: OnboardingTypography.heading(
                          fontSize: 24,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '3 kept on this device',
                        style: OnboardingTypography.body(
                          fontSize: 12,
                          color: AppTheme.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: AppTheme.inkSoft,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Search notes',
                              style: OnboardingTypography.body(
                                fontSize: 12,
                                color: AppTheme.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const OnboardingPreviewNoteCard(
                        title: 'Grocery list',
                        time: '12:46',
                        body: 'Oat milk, eggs, sourdough',
                        status: SyncStatus.synced,
                      ),
                      const SizedBox(height: 10),
                      const OnboardingPreviewNoteCard(
                        title: 'Meeting notes',
                        time: 'Jul 2',
                        body: 'Offline edits waiting to sync',
                        status: SyncStatus.pending,
                      ),
                      const SizedBox(height: 10),
                      const OnboardingPreviewNoteCard(
                        title: 'Project plan',
                        time: 'Jul 1',
                        body: 'Resolve version conflict',
                        status: SyncStatus.conflict,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
