import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/features/notes/domain/entities/note_entities.dart';

void main() {
  test('OperationType parses from string', () {
    expect(OperationType.fromString('create'), OperationType.create);
    expect(OperationType.fromString('update'), OperationType.update);
    expect(OperationType.fromString('delete'), OperationType.delete);
  });
}
