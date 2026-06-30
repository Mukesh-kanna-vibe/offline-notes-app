enum SyncStatus {
  synced,
  pending,
  conflict,
}

extension SyncStatusX on SyncStatus {
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

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
