import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/notes/notes_bloc.dart';
import '../bloc/notes/notes_event.dart';
import '../bloc/notes/notes_state.dart';
import '../models/note.dart';
import '../models/sync_status.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key, required this.note});

  final Note note;

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  late final TextEditingController _mergeTitleController;
  late final TextEditingController _mergeBodyController;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _mergeTitleController = TextEditingController(text: widget.note.title);
    _mergeBodyController = TextEditingController(text: widget.note.body);
  }

  @override
  void dispose() {
    _mergeTitleController.dispose();
    _mergeBodyController.dispose();
    super.dispose();
  }

  Future<void> _resolve(NotesEvent event) async {
    if (event is ConflictResolveMerge) {
      if (event.title.isEmpty && event.body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a title or body for merged version')),
        );
        return;
      }
    }

    setState(() => _isResolving = true);

    final bloc = context.read<NotesBloc>();
    bloc.add(event);

    try {
      await bloc.stream.firstWhere((state) => _isResolutionComplete(state, event));

      if (!mounted) return;

      final updatedNote = _findNote(bloc.state);
      if (updatedNote?.syncStatus == SyncStatus.synced) {
        Navigator.of(context).pop();
      } else if (!bloc.state.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. Will sync when you are back online.'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bloc.state.errorMessage ?? 'Could not sync. Try again from the list.',
            ),
          ),
        );
        setState(() => _isResolving = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isResolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  bool _isResolutionComplete(NotesState state, NotesEvent event) {
    if (state.isSyncing || state.status == NotesStatus.loading) {
      return false;
    }

    if (state.status == NotesStatus.failure) {
      return true;
    }

    final note = _findNote(state);
    if (note == null) return false;

    if (event is ConflictResolveKeepServer) {
      return note.syncStatus == SyncStatus.synced;
    }

    return note.syncStatus != SyncStatus.conflict;
  }

  Note? _findNote(NotesState state) {
    try {
      return state.notes.firstWhere((note) => note.id == widget.note.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Conflict'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This note was edited on both this device and the server. Choose which version to keep.',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your version (device)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Last edited: ${dateFormat.format(note.localUpdatedAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                _VersionCard(title: note.title, body: note.body),
                const SizedBox(height: 24),
                Text(
                  'Server version',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (note.serverVersionAtConflict != null)
                  Text(
                    'Last edited: ${dateFormat.format(note.serverVersionAtConflict!)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                _VersionCard(
                  title: note.serverTitle ?? '',
                  body: note.serverBody ?? '',
                ),
                const SizedBox(height: 32),
                Text(
                  'Merge manually (optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mergeTitleController,
                  enabled: !_isResolving,
                  decoration: const InputDecoration(
                    labelText: 'Merged title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mergeBodyController,
                  enabled: !_isResolving,
                  decoration: const InputDecoration(
                    labelText: 'Merged body',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isResolving
                      ? null
                      : () => _resolve(ConflictResolveMerge(
                            note: note,
                            title: _mergeTitleController.text.trim(),
                            body: _mergeBodyController.text.trim(),
                          )),
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Save merged version'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isResolving
                      ? null
                      : () => _resolve(ConflictResolveKeepLocal(note)),
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Keep my version'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isResolving
                      ? null
                      : () => _resolve(ConflictResolveKeepServer(note)),
                  icon: const Icon(Icons.cloud),
                  label: const Text('Keep server version'),
                ),
              ],
            ),
          ),
          if (_isResolving)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Syncing...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? 'Untitled' : title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body),
            ],
          ],
        ),
      ),
    );
  }
}
