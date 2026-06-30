enum OperationType {
  create,
  update,
  delete,
}

extension OperationTypeX on OperationType {
  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => OperationType.update,
    );
  }
}

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.noteId,
    required this.type,
    required this.createdAt,
    this.forcePush = false,
  });

  final int id;
  final String noteId;
  final OperationType type;
  final DateTime createdAt;
  final bool forcePush;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'force_push': forcePush ? 1 : 0,
    };
  }

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'] as int,
      noteId: map['note_id'] as String,
      type: OperationTypeX.fromString(map['type'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      forcePush: (map['force_push'] as int? ?? 0) == 1,
    );
  }
}
