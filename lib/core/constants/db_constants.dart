abstract final class DbConstants {
  static const String databaseName = 'offline_notes.db';
  static const int databaseVersion = 5;

  static const String notesTable = 'notes';
  static const String syncQueueTable = 'sync_queue';

  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colBody = 'body';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncStatus = 'sync_status';
  static const String colIsDeleted = 'is_deleted';
  static const String colRemoteUpdatedAt = 'remote_updated_at';
  static const String colServerId = 'server_id';
  static const String colConflictLocalTitle = 'conflict_local_title';
  static const String colConflictLocalBody = 'conflict_local_body';
  static const String colConflictLocalUpdatedAt = 'conflict_local_updated_at';
  static const String colConflictRemoteTitle = 'conflict_remote_title';
  static const String colConflictRemoteBody = 'conflict_remote_body';
  static const String colConflictRemoteUpdatedAt = 'conflict_remote_updated_at';
  static const String colSyncBaseTitle = 'sync_base_title';
  static const String colSyncBaseBody = 'sync_base_body';
  static const String colSyncBaseIsDeleted = 'sync_base_is_deleted';

  static const String colNoteId = 'note_id';
  static const String colOperationType = 'operation_type';
  static const String colPayload = 'payload';
  static const String colRetryCount = 'retry_count';
  static const String colQueueCreatedAt = 'queue_created_at';
  static const String colLastAttemptAt = 'last_attempt_at';
  static const String colErrorMessage = 'error_message';
}
