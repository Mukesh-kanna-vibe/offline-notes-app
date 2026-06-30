import 'sync_status.dart';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.localUpdatedAt,
    this.serverUpdatedAt,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
    this.syncedTitle,
    this.syncedBody,
    this.serverTitle,
    this.serverBody,
    this.serverVersionAtConflict,
  });

  final String id;
  final String title;
  final String body;
  final DateTime localUpdatedAt;
  final DateTime? serverUpdatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final String? syncedTitle;
  final String? syncedBody;
  final String? serverTitle;
  final String? serverBody;
  final DateTime? serverVersionAtConflict;

  Note copyWith({
    String? title,
    String? body,
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    String? syncedTitle,
    String? syncedBody,
    String? serverTitle,
    String? serverBody,
    DateTime? serverVersionAtConflict,
    bool clearServerConflict = false,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedTitle: syncedTitle ?? this.syncedTitle,
      syncedBody: syncedBody ?? this.syncedBody,
      serverTitle: clearServerConflict ? null : (serverTitle ?? this.serverTitle),
      serverBody: clearServerConflict ? null : (serverBody ?? this.serverBody),
      serverVersionAtConflict: clearServerConflict
          ? null
          : (serverVersionAtConflict ?? this.serverVersionAtConflict),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'local_updated_at': localUpdatedAt.toIso8601String(),
      'server_updated_at': serverUpdatedAt?.toIso8601String(),
      'sync_status': syncStatus.name,
      'is_deleted': isDeleted ? 1 : 0,
      'synced_title': syncedTitle,
      'synced_body': syncedBody,
      'server_title': serverTitle,
      'server_body': serverBody,
      'server_version_at_conflict': serverVersionAtConflict?.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      localUpdatedAt: DateTime.parse(map['local_updated_at'] as String),
      serverUpdatedAt: map['server_updated_at'] != null
          ? DateTime.parse(map['server_updated_at'] as String)
          : null,
      syncStatus: SyncStatusX.fromString(map['sync_status'] as String? ?? ''),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      syncedTitle: map['synced_title'] as String?,
      syncedBody: map['synced_body'] as String?,
      serverTitle: map['server_title'] as String?,
      serverBody: map['server_body'] as String?,
      serverVersionAtConflict: map['server_version_at_conflict'] != null
          ? DateTime.parse(map['server_version_at_conflict'] as String)
          : null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'updatedAt': localUpdatedAt.toIso8601String(),
    };
  }

  factory Note.fromApiJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    final updatedAt = updatedAtRaw != null
        ? DateTime.parse(updatedAtRaw.toString())
        : DateTime.now();
    final title = json['title'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    return Note(
      id: json['id'].toString(),
      title: title,
      body: body,
      localUpdatedAt: updatedAt,
      serverUpdatedAt: updatedAt,
      syncedTitle: title,
      syncedBody: body,
      syncStatus: SyncStatus.synced,
    );
  }

  Note asSyncedFromRemote(Note remote) {
    return copyWith(
      title: remote.title,
      body: remote.body,
      serverUpdatedAt: remote.serverUpdatedAt,
      localUpdatedAt: remote.serverUpdatedAt ?? remote.localUpdatedAt,
      syncedTitle: remote.title,
      syncedBody: remote.body,
      syncStatus: SyncStatus.synced,
      clearServerConflict: true,
    );
  }

  Note asSyncedAfterPush(DateTime serverUpdatedAt) {
    return copyWith(
      serverUpdatedAt: serverUpdatedAt,
      syncedTitle: title,
      syncedBody: body,
      syncStatus: SyncStatus.synced,
    );
  }
}
