import 'dart:convert';

import '../../domain/entities/note_entities.dart';
import '../../../../core/constants/db_constants.dart';

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
    this.remoteUpdatedAt,
    this.serverId,
    this.conflictLocalTitle,
    this.conflictLocalBody,
    this.conflictLocalUpdatedAt,
    this.conflictRemoteTitle,
    this.conflictRemoteBody,
    this.conflictRemoteUpdatedAt,
    this.syncBaseTitle,
    this.syncBaseBody,
    this.syncBaseIsDeleted,
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
  final String? conflictLocalTitle;
  final String? conflictLocalBody;
  final DateTime? conflictLocalUpdatedAt;
  final String? conflictRemoteTitle;
  final String? conflictRemoteBody;
  final DateTime? conflictRemoteUpdatedAt;
  final String? syncBaseTitle;
  final String? syncBaseBody;
  final bool? syncBaseIsDeleted;

  bool get hasConflictSnapshot =>
      conflictLocalTitle != null &&
      conflictRemoteTitle != null &&
      conflictLocalUpdatedAt != null &&
      conflictRemoteUpdatedAt != null;

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map[DbConstants.colId] as String,
      title: map[DbConstants.colTitle] as String,
      body: map[DbConstants.colBody] as String,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[DbConstants.colUpdatedAt] as String),
      syncStatus: SyncStatus.values.firstWhere(
        (status) => status.name == map[DbConstants.colSyncStatus],
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: (map[DbConstants.colIsDeleted] as int? ?? 0) == 1,
      remoteUpdatedAt: map[DbConstants.colRemoteUpdatedAt] != null
          ? DateTime.parse(map[DbConstants.colRemoteUpdatedAt] as String)
          : null,
      serverId: map[DbConstants.colServerId] as String?,
      conflictLocalTitle: map[DbConstants.colConflictLocalTitle] as String?,
      conflictLocalBody: map[DbConstants.colConflictLocalBody] as String?,
      conflictLocalUpdatedAt: map[DbConstants.colConflictLocalUpdatedAt] != null
          ? DateTime.parse(
              map[DbConstants.colConflictLocalUpdatedAt] as String,
            )
          : null,
      conflictRemoteTitle: map[DbConstants.colConflictRemoteTitle] as String?,
      conflictRemoteBody: map[DbConstants.colConflictRemoteBody] as String?,
      conflictRemoteUpdatedAt:
          map[DbConstants.colConflictRemoteUpdatedAt] != null
              ? DateTime.parse(
                  map[DbConstants.colConflictRemoteUpdatedAt] as String,
                )
              : null,
      syncBaseTitle: map[DbConstants.colSyncBaseTitle] as String?,
      syncBaseBody: map[DbConstants.colSyncBaseBody] as String?,
      syncBaseIsDeleted: map[DbConstants.colSyncBaseIsDeleted] != null
          ? (map[DbConstants.colSyncBaseIsDeleted] as int) == 1
          : null,
    );
  }

  factory NoteModel.fromRemoteJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      syncStatus: SyncStatus.synced,
      isDeleted: json['isDeleted'] == true,
      remoteUpdatedAt: _parseDate(json['updatedAt']),
      serverId: json['id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colTitle: title,
      DbConstants.colBody: body,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
      DbConstants.colSyncStatus: syncStatus.name,
      DbConstants.colIsDeleted: isDeleted ? 1 : 0,
      DbConstants.colRemoteUpdatedAt: remoteUpdatedAt?.toIso8601String(),
      DbConstants.colServerId: serverId,
      DbConstants.colConflictLocalTitle: conflictLocalTitle,
      DbConstants.colConflictLocalBody: conflictLocalBody,
      DbConstants.colConflictLocalUpdatedAt:
          conflictLocalUpdatedAt?.toIso8601String(),
      DbConstants.colConflictRemoteTitle: conflictRemoteTitle,
      DbConstants.colConflictRemoteBody: conflictRemoteBody,
      DbConstants.colConflictRemoteUpdatedAt:
          conflictRemoteUpdatedAt?.toIso8601String(),
      DbConstants.colSyncBaseTitle: syncBaseTitle,
      DbConstants.colSyncBaseBody: syncBaseBody,
      DbConstants.colSyncBaseIsDeleted: (syncBaseIsDeleted ?? false) ? 1 : 0,
    };
  }

  /// MockAPI auto-generates ids — omit [id] on POST; include server id on PUT.
  Map<String, dynamic> toRemoteJson({bool forCreate = false, String? apiId}) {
    final json = <String, dynamic>{
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
    if (!forCreate && apiId != null) {
      json['id'] = apiId;
    }
    return json;
  }

  ConflictData? toConflictData() {
    if (hasConflictSnapshot) {
      return ConflictData(
        localNote: Note(
          id: id,
          title: conflictLocalTitle!,
          body: conflictLocalBody ?? '',
          createdAt: createdAt,
          updatedAt: conflictLocalUpdatedAt!,
          syncStatus: SyncStatus.conflict,
          remoteUpdatedAt: remoteUpdatedAt,
          serverId: serverId,
        ),
        remoteNote: Note(
          id: id,
          title: conflictRemoteTitle!,
          body: conflictRemoteBody ?? '',
          createdAt: createdAt,
          updatedAt: conflictRemoteUpdatedAt!,
          syncStatus: SyncStatus.synced,
          remoteUpdatedAt: conflictRemoteUpdatedAt,
          serverId: serverId,
        ),
      );
    }

    if (syncStatus != SyncStatus.conflict && !hasPartialConflictSnapshot) {
      return null;
    }

    return ConflictData(
      localNote: Note(
        id: id,
        title: conflictLocalTitle ?? title,
        body: conflictLocalBody ?? body,
        createdAt: createdAt,
        updatedAt: conflictLocalUpdatedAt ?? updatedAt,
        syncStatus: SyncStatus.conflict,
        remoteUpdatedAt: remoteUpdatedAt,
        serverId: serverId,
      ),
      remoteNote: Note(
        id: id,
        title: conflictRemoteTitle ?? title,
        body: conflictRemoteBody ?? body,
        createdAt: createdAt,
        updatedAt: conflictRemoteUpdatedAt ?? remoteUpdatedAt ?? updatedAt,
        syncStatus: SyncStatus.synced,
        remoteUpdatedAt: conflictRemoteUpdatedAt ?? remoteUpdatedAt,
        serverId: serverId,
      ),
    );
  }

  bool get hasPartialConflictSnapshot =>
      conflictLocalTitle != null ||
      conflictRemoteTitle != null ||
      conflictLocalUpdatedAt != null ||
      conflictRemoteUpdatedAt != null;

  bool get isInConflictState =>
      syncStatus == SyncStatus.conflict ||
      hasConflictSnapshot ||
      hasPartialConflictSnapshot;

  Note toEntity() {
    final displayStatus = switch (syncStatus) {
      SyncStatus.synced => SyncStatus.synced,
      SyncStatus.conflict => SyncStatus.conflict,
      SyncStatus.pending =>
        isInConflictState ? SyncStatus.conflict : SyncStatus.pending,
    };

    return Note(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: displayStatus,
      isDeleted: isDeleted,
      remoteUpdatedAt: remoteUpdatedAt,
      serverId: serverId,
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? remoteUpdatedAt,
    String? serverId,
    String? conflictLocalTitle,
    String? conflictLocalBody,
    DateTime? conflictLocalUpdatedAt,
    String? conflictRemoteTitle,
    String? conflictRemoteBody,
    DateTime? conflictRemoteUpdatedAt,
    String? syncBaseTitle,
    String? syncBaseBody,
    bool? syncBaseIsDeleted,
    bool clearRemoteUpdatedAt = false,
    bool clearServerId = false,
    bool clearConflictSnapshots = false,
    bool clearSyncBase = false,
  }) {
    return NoteModel(
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
      conflictLocalTitle: clearConflictSnapshots
          ? null
          : (conflictLocalTitle ?? this.conflictLocalTitle),
      conflictLocalBody: clearConflictSnapshots
          ? null
          : (conflictLocalBody ?? this.conflictLocalBody),
      conflictLocalUpdatedAt: clearConflictSnapshots
          ? null
          : (conflictLocalUpdatedAt ?? this.conflictLocalUpdatedAt),
      conflictRemoteTitle: clearConflictSnapshots
          ? null
          : (conflictRemoteTitle ?? this.conflictRemoteTitle),
      conflictRemoteBody: clearConflictSnapshots
          ? null
          : (conflictRemoteBody ?? this.conflictRemoteBody),
      conflictRemoteUpdatedAt: clearConflictSnapshots
          ? null
          : (conflictRemoteUpdatedAt ?? this.conflictRemoteUpdatedAt),
      syncBaseTitle:
          clearSyncBase ? null : (syncBaseTitle ?? this.syncBaseTitle),
      syncBaseBody: clearSyncBase ? null : (syncBaseBody ?? this.syncBaseBody),
      syncBaseIsDeleted: clearSyncBase
          ? null
          : (syncBaseIsDeleted ?? this.syncBaseIsDeleted),
    );
  }

  NoteModel withSyncBaseFrom(NoteModel remote) {
    return copyWith(
      syncBaseTitle: remote.title,
      syncBaseBody: remote.body,
      syncBaseIsDeleted: remote.isDeleted,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }
}

class SyncQueueItemModel {
  const SyncQueueItemModel({
    required this.id,
    required this.noteId,
    required this.operationType,
    required this.payload,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.errorMessage,
  });

  final String id;
  final String noteId;
  final OperationType operationType;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  factory SyncQueueItemModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueItemModel(
      id: map[DbConstants.colId] as String,
      noteId: map[DbConstants.colNoteId] as String,
      operationType: OperationType.fromString(
        map[DbConstants.colOperationType] as String,
      ),
      payload: jsonDecode(map[DbConstants.colPayload] as String)
          as Map<String, dynamic>,
      retryCount: map[DbConstants.colRetryCount] as int? ?? 0,
      createdAt: DateTime.parse(map[DbConstants.colQueueCreatedAt] as String),
      lastAttemptAt: map[DbConstants.colLastAttemptAt] != null
          ? DateTime.parse(map[DbConstants.colLastAttemptAt] as String)
          : null,
      errorMessage: map[DbConstants.colErrorMessage] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colNoteId: noteId,
      DbConstants.colOperationType: operationType.value,
      DbConstants.colPayload: jsonEncode(payload),
      DbConstants.colRetryCount: retryCount,
      DbConstants.colQueueCreatedAt: createdAt.toIso8601String(),
      DbConstants.colLastAttemptAt: lastAttemptAt?.toIso8601String(),
      DbConstants.colErrorMessage: errorMessage,
    };
  }

  SyncQueueItemModel copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncQueueItemModel(
      id: id,
      noteId: noteId,
      operationType: operationType,
      payload: payload,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
