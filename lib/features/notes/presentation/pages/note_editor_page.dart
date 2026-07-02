import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/note_entities.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    this.note,
    this.mergeConflict,
  });

  final Note? note;
  final ConflictData? mergeConflict;

  bool get isEditing => note != null;
  bool get isMergeMode => mergeConflict != null;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isMergeMode) {
      final conflict = widget.mergeConflict!;
      _titleController = TextEditingController(text: conflict.localNote.title);
      _bodyController = TextEditingController(
        text: _buildMergeBody(conflict),
      );
    } else {
      _titleController = TextEditingController(text: widget.note?.title ?? '');
      _bodyController = TextEditingController(text: widget.note?.body ?? '');
    }
  }

  String _buildMergeBody(ConflictData conflict) {
    return '${conflict.localNote.body}\n\n---\n\n${conflict.remoteNote.body}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<NotesBloc, NotesState>(
      listenWhen: (previous, current) {
        if (!widget.isMergeMode) return false;

        final noteId = widget.mergeConflict!.localNote.id;
        final resolved = previous.lastResolvedConflictNoteId !=
                current.lastResolvedConflictNoteId &&
            current.lastResolvedConflictNoteId == noteId;
        final failed = previous.isResolvingConflict &&
            !current.isResolvingConflict &&
            current.errorMessage != null &&
            current.lastResolvedConflictNoteId != noteId;

        return resolved || failed;
      },
      listener: (context, state) {
        if (state.lastResolvedConflictNoteId ==
            widget.mergeConflict!.localNote.id) {
          Navigator.of(context).pop();
          return;
        }

        if (mounted) {
          setState(() => _isSaving = false);
        }
      },
      child: Container(
        decoration: AppTheme.pageDecoration(Theme.of(context).brightness),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.isMergeMode
                  ? 'Merge Note'
                  : widget.isEditing
                      ? 'Edit Note'
                      : 'New Note',
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveNote,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isMergeMode ? 'Save Merge' : 'Save'),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (widget.isMergeMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(Theme.of(context).brightness),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.border),
                  ),
                    child: Text(
                      'Combine both versions below. Reference cards show the original local and remote copies.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReferenceCard(
                    title: 'Local',
                    noteTitle: widget.mergeConflict!.localNote.title,
                    noteBody: widget.mergeConflict!.localNote.body,
                    updatedAt: dateFormat.format(
                      widget.mergeConflict!.localNote.updatedAt.toLocal(),
                    ),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _ReferenceCard(
                    title: 'Remote',
                    noteTitle: widget.mergeConflict!.remoteNote.title,
                    noteBody: widget.mergeConflict!.remoteNote.body,
                    updatedAt: dateFormat.format(
                      widget.mergeConflict!.remoteNote.updatedAt.toLocal(),
                    ),
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                      ),
                  cursorColor: colorScheme.primary,
                  decoration: _fieldDecoration(context, hint: 'Enter note title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Body',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bodyController,
                  minLines: 10,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  cursorColor: colorScheme.primary,
                  decoration: _fieldDecoration(context, hint: 'Write your note here'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Body is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = AppTheme.cardColor(Theme.of(context).brightness);
    const borderColor = AppTheme.border;

    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: BorderSide(color: colorScheme.onSurface, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final bloc = context.read<NotesBloc>();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (widget.isMergeMode) {
      bloc.add(
        NoteConflictResolutionRequested(
          noteId: widget.mergeConflict!.localNote.id,
          choice: ConflictResolutionChoice.merge,
          mergedTitle: title,
          mergedBody: body,
        ),
      );
      return;
    }

    if (widget.isEditing) {
      bloc.add(
        NoteUpdateRequested(
          id: widget.note!.id,
          title: title,
          body: body,
        ),
      );
    } else {
      bloc.add(NoteCreateRequested(title: title, body: body));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.title,
    required this.noteTitle,
    required this.noteBody,
    required this.updatedAt,
    required this.color,
  });

  final String title;
  final String noteTitle;
  final String noteBody;
  final String updatedAt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title • Updated $updatedAt',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            noteTitle.isEmpty ? 'Untitled' : noteTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            noteBody,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
