import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../notes/domain/entities/note_entities.dart';
import '../../../notes/presentation/widgets/paper_fold_corner.dart';
import '../../../notes/presentation/widgets/sync_status_badge.dart';
import '../theme/onboarding_typography.dart';

class OnboardingPreviewNoteCard extends StatelessWidget {
  const OnboardingPreviewNoteCard({
    super.key,
    required this.title,
    required this.time,
    required this.body,
    required this.status,
  });

  final String title;
  final String time;
  final String body;
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final isConflict = status == SyncStatus.conflict;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isConflict
                  ? AppTheme.conflictRed.withValues(alpha: 0.45)
                  : AppTheme.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OnboardingTypography.label(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: OnboardingTypography.body(
                      fontSize: 11,
                      color: AppTheme.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnboardingTypography.body(
                  fontSize: 12,
                  color: AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 8),
              SyncStatusBadge(status: status),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: PaperFoldCorner(),
        ),
      ],
    );
  }
}
