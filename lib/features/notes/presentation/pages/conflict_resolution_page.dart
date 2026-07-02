import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/note_entities.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import 'note_editor_page.dart';

class ConflictResolutionPage extends StatefulWidget {
  const ConflictResolutionPage({super.key, required this.noteId});

  final String noteId;

  @override
  State<ConflictResolutionPage> createState() =>
      _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(LoadConflict(widget.noteId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotesBloc, NotesState>(
      listenWhen: (previous, current) =>
          previous.lastResolvedConflictNoteId !=
          current.lastResolvedConflictNoteId,
      listener: (context, state) {
        if (state.lastResolvedConflictNoteId == widget.noteId) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              context.read<NotesBloc>().add(ConflictPageClosed(widget.noteId));
            }
          },
          child: Container(
            decoration: AppTheme.pageDecoration(Theme.of(context).brightness),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Resolve Conflict'),
              ),
              body: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotesState state) {
    if (state.isResolvingConflict && state.conflictData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final conflict = state.conflictData;
    if (conflict == null || conflict.localNote.id != widget.noteId) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ??
                    'Unable to load conflict details for this note.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: state.isResolvingConflict
                    ? null
                    : () {
                        context
                            .read<NotesBloc>()
                            .add(LoadConflict(widget.noteId));
                      },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 48),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync conflict detected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your device and the server both changed this note. '
                      'Nothing will be overwritten until you choose.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _VersionCard(
          title: 'Local Version',
          subtitle: 'On this device',
          icon: Icons.phone_android_rounded,
          note: conflict.localNote,
          updatedLabel:
              dateFormat.format(conflict.localNote.updatedAt.toLocal()),
          accentColor: colorScheme.primary,
        ),
        const SizedBox(height: 14),
        _VersionCard(
          title: 'Remote Version',
          subtitle: 'On MockAPI server',
          icon: Icons.cloud_outlined,
          note: conflict.remoteNote,
          updatedLabel:
              dateFormat.format(conflict.remoteNote.updatedAt.toLocal()),
          accentColor: colorScheme.tertiary,
        ),
        const SizedBox(height: 28),
        Text(
          'Choose how to resolve',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: state.isResolvingConflict
              ? null
              : () => _resolve(context, ConflictResolutionChoice.keepLocal),
          icon: const Icon(Icons.phone_android_rounded),
          label: const Text('Keep Local'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: state.isResolvingConflict
              ? null
              : () => _resolve(context, ConflictResolutionChoice.keepRemote),
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Keep Remote'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: state.isResolvingConflict
              ? null
              : () => _openMergeEditor(context, conflict),
          icon: const Icon(Icons.merge_type_rounded),
          label: const Text('Merge'),
        ),
        if (state.isResolvingConflict) ...[
          const SizedBox(height: 28),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  void _resolve(BuildContext context, ConflictResolutionChoice choice) {
    context.read<NotesBloc>().add(
          NoteConflictResolutionRequested(
            noteId: widget.noteId,
            choice: choice,
          ),
        );
  }

  Future<void> _openMergeEditor(
    BuildContext context,
    ConflictData conflict,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          note: conflict.localNote,
          mergeConflict: conflict,
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.note,
    required this.updatedLabel,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Note note;
  final String updatedLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow(context),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accentColor,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Updated $updatedLabel',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Divider(height: 24),
          Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            note.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
