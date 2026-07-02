import 'package:flutter/material.dart';

import '../../domain/entities/note_entities.dart';
import '../../../../app/theme/app_theme.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      SyncStatus.synced => (AppTheme.inkMuted, Icons.check_rounded),
      SyncStatus.pending => (AppTheme.pendingAmber, Icons.sync_rounded),
      SyncStatus.conflict => (AppTheme.conflictRed, Icons.warning_amber_rounded),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
