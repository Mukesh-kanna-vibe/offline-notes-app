import 'package:equatable/equatable.dart';

enum SyncStatus {
  synced,
  pending,
  conflict;

  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending Sync';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }
}

enum OperationType {
  create,
  update,
  delete;

  String get value => name;

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => OperationType.update,
    );
  }
}

enum NoteSortOption {
  updatedAtDesc,
  updatedAtAsc,
  titleAsc,
  titleDesc,
  createdAtDesc,
}

enum ConflictResolutionChoice {
  keepLocal,
  keepRemote,
  merge,
}

/// Pure domain entity — no JSON or SQLite concerns.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
    this.remoteUpdatedAt,
    this.serverId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final DateTime? remoteUpdatedAt;
  final String? serverId;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? remoteUpdatedAt,
    String? serverId,
    bool clearRemoteUpdatedAt = false,
    bool clearServerId = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      remoteUpdatedAt: clearRemoteUpdatedAt
          ? null
          : (remoteUpdatedAt ?? this.remoteUpdatedAt),
      serverId: clearServerId ? null : (serverId ?? this.serverId),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        createdAt,
        updatedAt,
        syncStatus,
        isDeleted,
        remoteUpdatedAt,
        serverId,
      ];
}

class ConflictData extends Equatable {
  const ConflictData({
    required this.localNote,
    required this.remoteNote,
  });

  final Note localNote;
  final Note remoteNote;

  @override
  List<Object?> get props => [localNote, remoteNote];
}
