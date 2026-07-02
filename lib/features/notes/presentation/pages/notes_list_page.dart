import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/note_entities.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/connectivity_status_bar.dart';
import '../widgets/note_card.dart';
import '../widgets/note_card_shimmer.dart';
import '../widgets/notes_empty_state.dart';
import '../widgets/premium_search_bar.dart';
import '../widgets/status_chip.dart';
import 'conflict_resolution_page.dart';
import 'note_editor_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  static const _listBottomPadding = 108.0;

  void _dismissSearchFocus() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotesBloc>().add(const NotesStarted());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkInfo = AppScope.of(context).networkInfo;

    return BlocConsumer<NotesBloc, NotesState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.pendingConflictNoteId != current.pendingConflictNoteId ||
          (previous.conflictCount == 0 && current.conflictCount > 0),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    context.read<NotesBloc>().add(const NotesErrorDismissed());
                  },
                ),
              ),
            );
        }

        if (state.conflictCount > 0 && state.pendingConflictNoteId == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${state.conflictCount} note(s) need conflict resolution',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
            );
        }

        final conflictId = state.pendingConflictNoteId;
        if (conflictId != null) {
          context.read<NotesBloc>().add(const ConflictNavigationHandled());
          Navigator.of(context).push(
            PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) =>
                  ConflictResolutionPage(noteId: conflictId),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
            ),
          );
        }
      },
      builder: (context, state) {
        final brightness = Theme.of(context).brightness;

        return Scaffold(
          backgroundColor: AppTheme.pageColor(brightness),
          body: GestureDetector(
            onTap: _dismissSearchFocus,
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${state.notes.length} kept on this device',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        ConnectivityStatusBar(networkInfo: networkInfo),
                        const SizedBox(width: 8),
                        PopupMenuButton<NoteSortOption>(
                          tooltip: 'Sort notes',
                          padding: EdgeInsets.zero,
                          color: AppTheme.cardColor(brightness),
                          surfaceTintColor: Colors.transparent,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          initialValue: state.sortOption,
                          onSelected: (option) {
                            _dismissSearchFocus();
                            context
                                .read<NotesBloc>()
                                .add(NotesSortChanged(option));
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: NoteSortOption.createdAtDesc,
                              child: Text('Recently created'),
                            ),
                            PopupMenuItem(
                              value: NoteSortOption.updatedAtDesc,
                              child: Text('Recently updated'),
                            ),
                            PopupMenuItem(
                              value: NoteSortOption.updatedAtAsc,
                              child: Text('Oldest updated'),
                            ),
                            PopupMenuItem(
                              value: NoteSortOption.titleAsc,
                              child: Text('Title A–Z'),
                            ),
                            PopupMenuItem(
                              value: NoteSortOption.titleDesc,
                              child: Text('Title Z–A'),
                            ),
                          ],
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: AppTheme.squareIconButtonDecoration(
                              brightness,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.conflictCount > 0 || state.pendingCount > 0) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        if (state.conflictCount > 0)
                          StatusChip(
                            icon: Icons.warning_amber_rounded,
                            label: '${state.conflictCount} conflict',
                            background: const Color(0xFFF3E4E4),
                            foreground: AppTheme.conflictRed,
                          ),
                        if (state.conflictCount > 0 && state.pendingCount > 0)
                          const SizedBox(width: 8),
                        if (state.pendingCount > 0)
                          StatusChip(
                            icon: Icons.sync_rounded,
                            label: '${state.pendingCount} pending',
                            background: const Color(0xFFF3EDE0),
                            foreground: AppTheme.pendingAmber,
                          ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: PremiumSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      context.read<NotesBloc>().add(NotesSearchChanged(value));
                      setState(() {});
                    },
                    onClear: () {
                      _searchController.clear();
                      context
                          .read<NotesBloc>()
                          .add(const NotesSearchChanged(''));
                      setState(() {});
                    },
                  ),
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4),
            child: FloatingActionButton.extended(
              onPressed: () {
                _dismissSearchFocus();
                _openEditor(context);
              },
              elevation: 6,
              highlightElevation: 8,
              backgroundColor: AppTheme.fabDark,
              foregroundColor: AppTheme.cardWhite,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('New note'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotesState state) {
    if (state.status == NotesStatus.failure && !state.hasNotes) {
      return NotesErrorState(
        message: state.errorMessage ?? 'Failed to load notes',
        onRetry: () {
          context.read<NotesBloc>().add(const NotesStarted());
        },
      );
    }

    if (state.status == NotesStatus.empty && !state.isSavingNote) {
      return NotesEmptyState(
        isSearching: state.searchQuery.isNotEmpty,
        onCreateNote: () => _openEditor(context),
      );
    }

    if (state.notes.isEmpty && state.isSavingNote) {
      return const NotesShimmerList(itemCount: 1);
    }

    final itemCount = state.notes.length + (state.isSavingNote ? 1 : 0);

    return NotificationListener<ScrollStartNotification>(
      onNotification: (_) {
        _dismissSearchFocus();
        return false;
      },
      child: RefreshIndicator(
      edgeOffset: 8,
      onRefresh: () async {
        final bloc = context.read<NotesBloc>();
        final completed = bloc.stream.firstWhere((state) => !state.isSyncing);
        bloc.add(const NotesRefreshed());
        await completed;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, _listBottomPadding),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (state.isSavingNote && index == 0) {
            return const AnimatedListItem(
              index: 0,
              child: NoteCardShimmer(),
            );
          }

          final noteIndex = state.isSavingNote ? index - 1 : index;
          final note = state.notes[noteIndex];

          return AnimatedListItem(
            index: noteIndex,
            child: NoteCard(
              note: note,
              onTap: () {
                _dismissSearchFocus();
                if (note.syncStatus == SyncStatus.conflict) {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder: (_, __, ___) =>
                          ConflictResolutionPage(noteId: note.id),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                } else {
                  _openEditor(context, note: note);
                }
              },
              onDelete: () => _confirmDelete(context, note.id),
            ),
          );
        },
      ),
    ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Note? note}) async {
    _dismissSearchFocus();
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => NoteEditorPage(note: note),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This note will be removed locally and synced when online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotesBloc>().add(NoteDeleteRequested(id));
    }
  }
}
