import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/note_entities.dart';
import 'paper_fold_corner.dart';
import 'sync_status_badge.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(local.year, local.month, local.day);

    if (noteDay == today) {
      return DateFormat('HH:mm').format(local);
    }

    if (local.year == now.year) {
      return DateFormat('MMM d').format(local);
    }

    return DateFormat('MMM d, yyyy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isConflict = note.syncStatus == SyncStatus.conflict;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Ink(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(brightness),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(
                  color: isConflict
                      ? AppTheme.conflictRed.withValues(alpha: 0.45)
                      : AppTheme.border,
                ),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatTimestamp(note.updatedAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.inkSoft,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.inkMuted,
                          ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SyncStatusBadge(status: note.syncStatus),
                        const Spacer(),
                        IconButton(
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppTheme.inkSoft,
                          ),
                          tooltip: 'Delete note',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: PaperFoldCorner(),
            ),
          ],
        ),
      ),
    );
  }
}
