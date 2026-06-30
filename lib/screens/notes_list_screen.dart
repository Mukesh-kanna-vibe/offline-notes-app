import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notes/notes_bloc.dart';
import '../bloc/notes/notes_event.dart';
import '../bloc/notes/notes_state.dart';
import '../models/note.dart';
import '../models/sync_status.dart';
import '../widgets/note_card.dart';
import 'conflict_resolution_screen.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state.status == NotesStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Offline Notes'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Icon(
                      state.isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 20,
                      color: state.isOnline ? Colors.green : Colors.grey,
                    ),
                    if (state.isSyncing) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sync now',
                      onPressed: state.isOnline
                          ? () => context
                              .read<NotesBloc>()
                              .add(const NotesSyncRequested())
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: _buildBody(context, state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NoteEditorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Note'),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotesState state) {
    if (state.status == NotesStatus.initial ||
        (state.status == NotesStatus.loading && state.notes.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note — works offline too',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notes.length,
      itemBuilder: (context, index) {
        final note = state.notes[index];
        return NoteCard(
          note: note,
          onTap: () => _openNote(context, note),
          onDelete: () => _confirmDelete(context, note),
        );
      },
    );
  }

  void _openNote(BuildContext context, Note note) {
    if (note.syncStatus == SyncStatus.conflict) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConflictResolutionScreen(note: note),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(note: note),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This will delete the note locally and sync when online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotesBloc>().add(NoteDeleteRequested(note));
    }
  }
}
