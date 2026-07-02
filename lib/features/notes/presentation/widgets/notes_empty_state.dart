import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({
    super.key,
    required this.onCreateNote,
    this.isSearching = false,
  });

  final VoidCallback onCreateNote;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_rounded
                    : Icons.edit_note_rounded,
                size: 40,
                color: AppTheme.inkMuted,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isSearching ? 'No matching notes' : 'Your notes live here',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearching
                  ? 'Try another keyword or clear the search.'
                  : 'Write offline anytime. Notes sync automatically when you\'re back online.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onCreateNote,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create your first note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotesErrorState extends StatelessWidget {
  const NotesErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: AppTheme.conflictRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
