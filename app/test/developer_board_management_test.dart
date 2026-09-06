import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_language_castle/models/developer_board.dart';
import 'package:visual_language_castle/services/developer_board_storage.dart';

void main() {
  test('developer board archive state round-trips and legacy data stays active', () {
    final storage = DeveloperBoardStorage.inMemory();
    final board = DeveloperBoard(
      id: 'board-1',
      name: 'Eloquence Research',
      savedAt: DateTime.utc(2026, 9, 3),
      archived: true,
      notes: [
        DeveloperNote(
          id: 'note-1',
          text: 'A growing awareness of ___',
          researchNotes: 'Candidate eloquence formula',
          colorValue: DeveloperCategory.linkage.color.toARGB32(),
          category: DeveloperCategory.linkage,
          position: const Offset(42, 84),
        ),
      ],
    );

    final encoded = storage.encodeBoards([board]);
    final decoded = storage.decodeBoards(encoded).single;

    expect(decoded.archived, isTrue);
    expect(decoded.name, 'Eloquence Research');
    expect(decoded.notes.single.text, 'A growing awareness of ___');

    final legacy = storage.decodeBoards(
      '[{"id":"legacy","name":"Legacy board","savedAt":"2026-09-03T00:00:00.000Z","notes":[]}]',
    ).single;

    expect(legacy.archived, isFalse);
  });
}
