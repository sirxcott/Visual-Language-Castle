// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visual_language_castle/data/language_tables.dart';
import 'package:visual_language_castle/data/language_taxonomy.dart';
import 'package:visual_language_castle/main.dart';
import 'package:visual_language_castle/models/archived_work.dart';
import 'package:visual_language_castle/models/developer_board.dart';
import 'package:visual_language_castle/models/language_card.dart';
import 'package:visual_language_castle/screens/archive_screen.dart';
import 'package:visual_language_castle/screens/completed_works_screen.dart';
import 'package:visual_language_castle/screens/developer_mode_screen.dart';
import 'package:visual_language_castle/screens/practice_room_screen.dart';
import 'package:visual_language_castle/screens/research_laboratory_screen.dart';
import 'package:visual_language_castle/services/archive_storage.dart';
import 'package:visual_language_castle/services/developer_board_storage.dart';

void main() {
  testWidgets('Developer Mode creates, edits, colors, drags, annotates, and exports custom notes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: DeveloperModeScreen(storage: DeveloperBoardStorage.inMemory())));

    await tester.tap(find.text('New Sticky'));
    await tester.pump();
    final noteField = find.byType(TextField).last;
    await tester.enterText(noteField, 'A deliberately long original structure that keeps growing until the note must use a smaller readable font rather than overflowing its paper surface.');
    await tester.pump();
    final fittedStyle = tester.widget<TextField>(noteField).style!;
    expect(fittedStyle.fontSize, lessThan(17));

    final originalPosition = tester.getTopLeft(find.byType(TextField).last);
    await tester.drag(find.byIcon(Icons.drag_indicator_rounded), const Offset(70, 50));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(TextField).last), isNot(originalPosition));

    await tester.tap(find.byTooltip('Note color'));
    await tester.pumpAndSettle();
    expect(find.text('Linkage'), findsOneWidget);
    await tester.tap(find.text('Linkage'));
    await tester.pump();
    expect(find.text('LINKAGE'), findsOneWidget);
    await tester.tap(find.byTooltip('Notes / Research'));
    await tester.enterText(find.byType(TextField).last, 'Research provenance');
    await tester.tap(find.text('Save notes'));
    await tester.pump();

    await tester.tap(find.text('Export Board'));
    await tester.pump();
    expect(find.textContaining('Research provenance'), findsOneWidget);
    expect(find.textContaining('"color"'), findsOneWidget);
    expect(find.textContaining('"category":"linkage"'), findsOneWidget);
  });

  test('Developer board storage preserves board names, note order, text, notes, colors, and positions', () async {
    final storage = DeveloperBoardStorage.inMemory();
    final board = DeveloperBoard(id: 'board-1', name: 'Original Structures', savedAt: DateTime.utc(2026, 9, 2), notes: [
      DeveloperNote(id: 'note-1', text: 'Mindfulness', researchNotes: 'Research note', colorValue: 0xFFE0651B, position: const Offset(12, 34), category: DeveloperCategory.nominal),
      DeveloperNote(id: 'note-2', text: 'Tranquility', researchNotes: '', colorValue: 0xFF2E9E62, position: const Offset(56, 78), category: DeveloperCategory.linkage),
    ]);
    await storage.saveBoards([board]);
    final restored = await storage.loadBoards();
    expect(restored.single.name, 'Original Structures');
    expect(restored.single.notes.map((note) => note.id), ['note-1', 'note-2']);
    expect(restored.single.notes.first.researchNotes, 'Research note');
    expect(restored.single.notes.last.category, DeveloperCategory.linkage);
    expect(restored.single.notes.last.colorValue, CardCategory.green.color.toARGB32());
    expect(restored.single.notes.last.position, const Offset(56, 78));
    final exported = storage.exportBoard(restored.single);
    expect(exported, contains('Original Structures'));
    expect(exported, contains('Research note'));
    expect(exported, contains('color'));
    expect(exported, contains('"category":"linkage"'));
  });

  test('Developer board storage migrates legacy raw color names and preserves ambiguous colors as unknown', () {
    final storage = DeveloperBoardStorage.inMemory();
    final restored = storage.decodeBoards('[{"id":"legacy","name":"Legacy board","savedAt":"2026-09-02T00:00:00.000Z","notes":[{"id":"orange","text":"","researchNotes":"","category":"orange","color":1,"x":0,"y":0},{"id":"pink","text":"","researchNotes":"","category":"pink","color":2,"x":0,"y":0},{"id":"green","text":"","researchNotes":"","category":"green","color":3,"x":0,"y":0},{"id":"red","text":"","researchNotes":"","category":"red","color":4,"x":0,"y":0},{"id":"notice","text":"","researchNotes":"","category":"notice","color":5,"x":0,"y":0},{"id":"embedded","text":"","researchNotes":"","category":"embedded","color":6,"x":0,"y":0},{"id":"time","text":"","researchNotes":"","category":"darkBlue","color":7,"x":0,"y":0},{"id":"cause","text":"","researchNotes":"","category":"lightBlue","color":8,"x":0,"y":0},{"id":"yellow","text":"","researchNotes":"","category":"yellow","color":9,"x":0,"y":0},{"id":"blue","text":"","researchNotes":"","category":"blue","color":10,"x":0,"y":0},{"id":"color-only","text":"","researchNotes":"","color":4293306701,"x":0,"y":0}]}]');
    final categories = {for (final note in restored.single.notes) note.id: note.category};
    expect(categories['orange'], DeveloperCategory.nominal);
    expect(categories['pink'], DeveloperCategory.verb);
    expect(categories['green'], DeveloperCategory.linkage);
    expect(categories['red'], DeveloperCategory.compliance);
    expect(categories['notice'], DeveloperCategory.notice);
    expect(categories['embedded'], DeveloperCategory.embedded);
    expect(categories['time'], DeveloperCategory.timeBind);
    expect(categories['cause'], DeveloperCategory.causeAndEffect);
    expect(categories['yellow'], DeveloperCategory.unknown);
    expect(categories['blue'], DeveloperCategory.unknown);
    expect(categories['color-only'], DeveloperCategory.unknown);
    final exported = storage.exportBoard(restored.single);
    expect(exported, contains('"category":"nominal"'));
    expect(exported, contains('"category":"timeBind"'));
    expect(exported, contains('"category":"unknown"'));
    expect(exported, isNot(contains('"category":"orange"')));
  });

  testWidgets('visible scrollbars attach to their scroll views without runtime exceptions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completed = List.generate(6, (index) => _testWork(id: 'complete-$index', name: 'Completed $index', isCompleted: true));

    await tester.pumpWidget(MaterialApp(home: CompletedWorksScreen(storage: ArchiveStorage.inMemory(completed))));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Archive loads from injected storage', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'completed', name: 'Finished', isCompleted: true), _testWork(id: 'draft', name: 'Draft')]);
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('Archive opens selected work in Practice Room', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'completed', name: 'Finished', isCompleted: true), _testWork(id: 'draft', name: 'Draft')]);
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Open Finished'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('The Working Wall'), findsOneWidget);
    expect(find.text('the room'), findsNWidgets(2));
    expect(find.byTooltip('Return to Gallery Hall'), findsOneWidget);
  });

  testWidgets('Completed Works displays completed injected records', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'completed', name: 'Finished', isCompleted: true), _testWork(id: 'draft', name: 'Draft')]);
    await tester.pumpWidget(MaterialApp(home: CompletedWorksScreen(storage: storage)));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
  });

  testWidgets('Archive deletion changes only the selected record', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'first', name: 'First'), _testWork(id: 'second', name: 'Second')]);

    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Delete First'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));

    final works = await storage.loadWorks();
    expect(works.map((work) => work.id), ['second']);
  });

  testWidgets('Archive rename is transactional on success and failure', (WidgetTester tester) async {
    final work = _testWork(id: 'rename', name: 'Original');
    final storage = ArchiveStorage.inMemory([work], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rename Original'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Failed Rename');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(find.text('Original'), findsOneWidget);
    storage.clearSaveError();
    await tester.tap(find.byTooltip('Rename Original'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed'), findsOneWidget);
  });

  testWidgets('Archive completion is transactional on success and failure', (WidgetTester tester) async {
    final work = _testWork(id: 'completion', name: 'Completion');
    final storage = ArchiveStorage.inMemory([work], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mark "Completion" complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsNothing);
    expect((await storage.loadWorks()).single.isCompleted, isFalse);
    storage.clearSaveError();
    await tester.tap(find.byTooltip('Mark "Completion" complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('Archive deletion is transactional on success and failure', (WidgetTester tester) async {
    final first = _testWork(id: 'delete-first', name: 'First');
    final second = _testWork(id: 'delete-second', name: 'Second');
    final storage = ArchiveStorage.inMemory([first, second], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete First'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect((await storage.loadWorks()).map((item) => item.id), ['delete-first', 'delete-second']);
    storage.clearSaveError();
    await tester.tap(find.byTooltip('Delete First'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('Practice Room updates an archive in place and Save creates a copy', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory();
    final original = _testWork(id: 'original', name: 'Original', isCompleted: true);
    await storage.saveWorks([original]);

    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: original.cards, initialConnections: original.connections, sourceWork: original, storage: storage)));
    await tester.tap(find.byTooltip('Update Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    var works = await storage.loadWorks();
    expect(works, hasLength(1));
    expect(works.single.id, 'original');
    expect(works.single.isCompleted, isTrue);
    expect(works.single.cards.single.instanceId, original.cards.single.instanceId);
    expect(works.single.cards.single.notes, 'saved note');

    await tester.tap(find.byTooltip('Save to Archive'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Copy');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    works = await storage.loadWorks();
    expect(works, hasLength(2));
    expect(works.map((work) => work.id), contains('original'));
    expect(works.where((work) => work.name == 'Copy'), hasLength(1));
    expect(works.firstWhere((work) => work.name == 'Copy').id, isNot('original'));
  });

  testWidgets('Update Archive preserves the prior record when saving fails', (WidgetTester tester) async {
    final original = _testWork(id: 'update-failure', name: 'Original');
    final storage = ArchiveStorage.inMemory([original], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: original.cards, initialConnections: original.connections, sourceWork: original, storage: storage)));
    await tester.tap(find.byTooltip('Update Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    final restored = (await storage.loadWorks()).single;
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.cards.single.instanceId, original.cards.single.instanceId);
    expect(restored.cards.single.notes, original.cards.single.notes);
  });

  testWidgets('Save to Archive retries without duplicating the copy', (WidgetTester tester) async {
    final card = WorkspaceCard(instanceId: 'save-instance', card: languageTables.first.cards.first, position: const Offset(25, 35), notes: 'wall note');
    final storage = ArchiveStorage.inMemory(const [], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [card], initialConnections: const [], storage: storage)));
    await tester.tap(find.byTooltip('Save to Archive'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Recovered Copy');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    storage.clearSaveError();
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    final works = await storage.loadWorks();
    expect(works, hasLength(1));
    expect(works.single.name, 'Recovered Copy');
    expect(works.single.cards.single.instanceId, 'save-instance');
    expect(works.single.cards.single.notes, 'wall note');
    expect(works.single.cards.single.position, const Offset(25, 35));
  });

  testWidgets('Update Archive retries against authoritative storage without duplication', (WidgetTester tester) async {
    final original = _testWork(id: 'retry-update', name: 'Original', isCompleted: true);
    final storage = ArchiveStorage.inMemory([original], null, StateError('save failed'));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: original.cards, initialConnections: original.connections, sourceWork: original, storage: storage)));
    await tester.tap(find.byTooltip('Update Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    storage.clearSaveError();
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    final works = await storage.loadWorks();
    expect(works, hasLength(1));
    expect(works.single.id, 'retry-update');
    expect(works.single.isCompleted, isTrue);
    expect(works.single.completedAt, original.completedAt);
    expect(works.single.cards.single.instanceId, original.cards.single.instanceId);
  });

  testWidgets('Archive shows feedback when loading fails', (WidgetTester tester) async {
    final storage = ArchiveStorage.forTesting(File('unused-archive.json'), loadError: StateError('test load failure'));

    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Unable to load Archive'), findsOneWidget);
  });

  testWidgets('unchanged archived work leaves without a prompt', (WidgetTester tester) async {
    final work = _testWork(id: 'unchanged', name: 'Unchanged');
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work)));
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('edited archived work can return to editing or discard', (WidgetTester tester) async {
    final work = _testWork(id: 'edited', name: 'Edited');
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work)));
    await tester.drag(find.text('the room').last, const Offset(100, 40));
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Return to Editing'), findsOneWidget);
    await tester.tap(find.text('Return to Editing'));
    await tester.pumpAndSettle();
    expect(find.text('The Working Wall'), findsOneWidget);
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard Changes'));
    await tester.pumpAndSettle();
    expect(find.text('The Working Wall'), findsNothing);
  });

  testWidgets('Update Archive clears the dirty state', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory();
    final work = _testWork(id: 'update-dirty', name: 'Update Dirty');
    await storage.saveWorks([work]);
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work, storage: storage)));
    await tester.drag(find.text('the room').last, const Offset(100, 40));
    await tester.tap(find.byTooltip('Update Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('notes and connections mark archived work dirty', (WidgetTester tester) async {
    final first = _testWork(id: 'mutations', name: 'Mutations');
    final secondCard = WorkspaceCard(instanceId: 'mutations-second', card: languageTables[1].cards.first, position: const Offset(320, 80));
    final work = ArchivedWork(id: first.id, name: first.name, savedAt: first.savedAt, cards: [first.cards.single, secondCard]);
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work)));

    await tester.tap(find.text('the room').last);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('the room').last);
    await tester.pumpAndSettle();
    expect(find.text('YOUR NOTES'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'changed note');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Return to Editing'), findsOneWidget);
    await tester.tap(find.text('Return to Editing'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Connections'));
    await tester.tap(find.text('the room').last);
    await tester.tap(find.text('notice'));
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Discard Changes'), findsOneWidget);
  });

  testWidgets('Archive load retry succeeds with injected storage', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'retry', name: 'Recovered')], StateError('temporary failure'));
    await tester.pumpWidget(MaterialApp(home: ArchiveScreen(storage: storage)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Retry'), findsOneWidget);
    storage.clearLoadError();
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('card addition and removal restore the archived dirty baseline', (WidgetTester tester) async {
    final work = _testWork(id: 'card-change', name: 'Card Change');
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work)));
    await tester.drag(find.text('the room').first, const Offset(420, 120));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Return to Editing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('×').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Return to Gallery Hall'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('Completed Works load retry succeeds with injected storage', (WidgetTester tester) async {
    final storage = ArchiveStorage.inMemory([_testWork(id: 'completed-retry', name: 'Recovered', isCompleted: true)], StateError('temporary failure'));
    await tester.pumpWidget(MaterialApp(home: CompletedWorksScreen(storage: storage)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Retry'), findsOneWidget);
    storage.clearLoadError();
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Recovered'), findsOneWidget);
  });

  test('archive decoder preserves valid records around malformed records', () {
    final contents = jsonEncode([
      _archiveJson(id: 'valid-1', name: 'First'),
      {'id': 'broken', 'name': 'Broken', 'savedAt': 'not-a-date', 'cards': []},
      _archiveJson(id: 'valid-2', name: 'Second'),
    ]);

    final works = ArchiveStorage.instance.decodeWorks(contents);

    expect(works.map((work) => work.id), ['valid-1', 'valid-2']);
  });

  test('archive update replaces one record and preserves its full snapshot', () {
    final firstCard = WorkspaceCard(instanceId: 'copy-a', card: languageTables.first.cards.first, position: const Offset(10, 20), notes: 'first note');
    final secondCard = WorkspaceCard(instanceId: 'copy-b', card: languageTables.first.cards.first, position: const Offset(30, 40), notes: 'second note');
    final original = ArchivedWork(
      id: 'original',
      name: 'Original',
      savedAt: DateTime(2026, 8, 1),
      isCompleted: true,
      completedAt: DateTime(2026, 8, 2),
      cards: [firstCard, secondCard],
      connections: [CardConnection(fromCardId: 'copy-a', toCardId: 'copy-b')],
    );
    final unrelated = ArchivedWork(id: 'unrelated', name: 'Keep me', savedAt: DateTime(2026, 8, 3), cards: const []);
    final updated = ArchivedWork(
      id: original.id,
      name: original.name,
      savedAt: original.savedAt,
      isCompleted: original.isCompleted,
      completedAt: original.completedAt,
      cards: [firstCard, secondCard],
      connections: original.connections,
    );

    final works = ArchiveStorage.instance.replaceWork([original, unrelated], updated);
    final restored = ArchiveStorage.instance.decodeWorks(ArchiveStorage.instance.encodeWorks(works));

    expect(restored.map((work) => work.id), ['original', 'unrelated']);
    expect(restored.first.isCompleted, isTrue);
    expect(restored.first.completedAt, original.completedAt);
    expect(restored.first.cards.map((card) => card.instanceId), ['copy-a', 'copy-b']);
    expect(restored.first.cards.map((card) => card.notes), ['first note', 'second note']);
    expect(restored.first.connections.single.fromCardId, 'copy-a');
    expect(restored.first.connections.single.toCardId, 'copy-b');
    expect(restored[1].name, 'Keep me');
  });

  test('archive copy gets a new ID while preserving duplicate cards and connections', () {
    final source = ArchivedWork(
      id: 'source',
      name: 'Source',
      savedAt: DateTime(2026, 8, 1),
      cards: [
        WorkspaceCard(instanceId: 'copy-a', card: languageTables.first.cards.first, position: Offset.zero, notes: 'note a'),
        WorkspaceCard(instanceId: 'copy-b', card: languageTables.first.cards.first, position: const Offset(20, 20), notes: 'note b'),
      ],
      connections: const [CardConnection(fromCardId: 'copy-a', toCardId: 'copy-b')],
    );

    final copy = ArchiveStorage.instance.createCopy(name: 'Copy', cards: source.cards, connections: source.connections);
    final restored = ArchiveStorage.instance.decodeWorks(ArchiveStorage.instance.encodeWorks([copy])).single;

    expect(copy.id, isNot(source.id));
    expect(copy.name, 'Copy');
    expect(restored.cards.map((card) => card.instanceId), ['copy-a', 'copy-b']);
    expect(restored.cards.map((card) => card.notes), ['note a', 'note b']);
    expect(restored.connections.single.fromCardId, 'copy-a');
    expect(restored.connections.single.toCardId, 'copy-b');
  });

  test('archive decoder safely skips malformed connection entries', () {
    final archive = _archiveJson(id: 'connections', name: 'Connections')..['connections'] = [
      {'from': 'one', 'to': 'two'},
      {'from': 42, 'to': 'two'},
      'not-a-connection',
    ];
    archive['cards'] = [
      _cardJson(sourceId: 'nom-1', instanceId: 'one'),
      _cardJson(sourceId: 'verb-1', instanceId: 'two'),
    ];

    final works = ArchiveStorage.instance.decodeWorks(jsonEncode([archive]));

    expect(works.single.connections, hasLength(1));
    expect(works.single.connections.single.fromCardId, 'one');
  });

  test('archive decoder restores duplicate workspace instances and completion state', () {
    final archive = _archiveJson(id: 'duplicate', name: 'Finished')
      ..['isCompleted'] = true
      ..['completedAt'] = '2026-08-27T12:00:00.000Z'
      ..['cards'] = [
        _cardJson(sourceId: 'nom-1', instanceId: 'copy-a'),
        _cardJson(sourceId: 'nom-1', instanceId: 'copy-b'),
      ]
      ..['connections'] = [
        {'from': 'copy-a', 'to': 'copy-b'},
      ];

    final work = ArchiveStorage.instance.decodeWorks(jsonEncode([archive])).single;

    expect(work.cards.map((card) => card.instanceId), ['copy-a', 'copy-b']);
    expect(work.cards[0].card.id, work.cards[1].card.id);
    expect(work.connections.single.fromCardId, 'copy-a');
    expect(work.connections.single.toCardId, 'copy-b');
    expect(work.isCompleted, isTrue);
    expect(work.completedAt, DateTime.parse('2026-08-27T12:00:00.000Z'));
  });

  test('legacy archives receive stable instances and migrate source connections', () {
    final archive = _archiveJson(id: 'legacy', name: 'Legacy')
      ..['cards'] = [
        _cardJson(sourceId: 'nom-1'),
        _cardJson(sourceId: 'nom-1'),
      ]
      ..['connections'] = [
        {'from': 'nom-1', 'to': 'nom-1'},
      ];

    final work = ArchiveStorage.instance.decodeWorks(jsonEncode([archive])).single;

    expect(work.cards.map((card) => card.instanceId), ['legacy-legacy-0', 'legacy-legacy-1']);
    expect(work.connections.single.fromCardId, 'legacy-legacy-0');
    expect(work.connections.single.toCardId, 'legacy-legacy-0');
    expect(work.isCompleted, isFalse);
    expect(work.completedAt, isNull);
  });

  testWidgets('archived cards restore into the Practice Room', (WidgetTester tester) async {
    final source = languageTables.first.cards.first;
    final restored = WorkspaceCard(instanceId: 'restored-instance', card: source, position: Offset.zero, notes: 'kept');

    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [restored])));

    expect(find.text(source.text), findsNWidgets(2));
    expect(find.byTooltip('Remove from wall'), findsOneWidget);
  });

  testWidgets('Research Laboratory filters by category', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verb').last);
    await tester.pumpAndSettle();

    expect(find.text('notice'), findsOneWidget);
    expect(find.text('the room'), findsNothing);
  });

  testWidgets('Research Laboratory combines search, table, and category filters', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbs').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verb').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'notice');
    await tester.pumpAndSettle();

    expect(find.text('notice'), findsNWidgets(2));
    expect(find.text('allow'), findsNothing);
    expect(find.text('the room'), findsNothing);
  });

  test('expanded Linkages corpus preserves confirmed subtype examples', () {
    final linkages = languageTables.firstWhere((table) => table.name == 'Linkages').cards;
    final basic = linkages.where((card) => linkageSubtypeFor(card) == LinkageSubtype.basic).toList();
    final restatement = linkages.where((card) => linkageSubtypeFor(card) == LinkageSubtype.restatement).toList();
    final momentum = linkages.where((card) => linkageSubtypeFor(card) == LinkageSubtype.momentum).toList();
    final unclassified = linkages.where((card) => linkageSubtypeFor(card) == null).toList();

    expect(linkages, hasLength(66));
    expect(basic, hasLength(7));
    expect(restatement, hasLength(11));
    expect(momentum, hasLength(7));
    expect(unclassified, hasLength(41));
    expect(linkages.map((card) => card.id).toSet(), hasLength(66));
    expect(linkages.map((card) => card.text), containsAll(['And', 'And if that’s the case', 'You may/(VAK)where I’m going with this']));

    // Confirm both "which means" exist in their separate functional tables
    final causeAndEffect = languageTables.firstWhere((table) => table.name == 'Cause and Effect').cards;
    expect(linkages.any((c) => c.id == 'link-5' && c.text == 'which means'), isTrue);
    expect(causeAndEffect.any((c) => c.id == 'cause-5' && c.text == 'which means'), isTrue);

    // Confirm as / while in Linkages vs as you / while you in Time Binds
    final timeBinds = languageTables.firstWhere((table) => table.name == 'Time Binds').cards;
    expect(linkages.map((c) => c.text), containsAll(['as', 'while']));
    expect(timeBinds.map((c) => c.text), containsAll(['as you', 'while you']));
  });

  testWidgets('Research Laboratory filters by Linkage Subtype', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-linkage-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restatement Linkages').last);
    await tester.pumpAndSettle();

    expect(find.text('or should I say'), findsOneWidget);
    expect(find.text('and if that\'s the case'), findsNothing);
    expect(find.text('which means'), findsNothing);
  });

  testWidgets('Linkage Subtype combines with search, table, and category filters', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Linkages').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Linkage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('research-linkage-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Momentum Linkages').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'obvious');
    await tester.pumpAndSettle();

    expect(find.text('obviously'), findsOneWidget);
    expect(find.text('of course'), findsNothing);
    expect(find.text('or rather'), findsNothing);
  });

  testWidgets('Research results show Linkage subtype status and filtered count', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));
    expect(find.text('368 results'), findsOneWidget);
    expect(find.text('Basic Linkages'), findsNWidgets(7));
    expect(find.text('Restatement Linkages'), findsNWidgets(11));
    expect(find.text('Momentum Linkages'), findsNWidgets(7));
    expect(find.text('Unclassified'), findsNWidgets(41));

    await tester.tap(find.byKey(const ValueKey('research-linkage-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basic Linkages').last);
    await tester.pumpAndSettle();
    expect(find.text('7 results'), findsOneWidget);
    expect(find.text('Restatement Linkages'), findsNothing);
  });

  testWidgets('Research hides Linkage Subtype control for unrelated tables', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));
    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbs').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('research-linkage-subtype-filter')), findsNothing);
    expect(find.text('111 results'), findsOneWidget);
  });

  testWidgets('Research Reset Filters restores the full result set', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'obvious');
    await tester.ensureVisible(find.bySemanticsLabel('Reset research filters'));
    await tester.tap(find.bySemanticsLabel('Reset research filters'));
    await tester.pumpAndSettle();

    expect(find.text('368 results'), findsOneWidget);
    expect(find.text('or should I say'), findsOneWidget);
    expect(find.text('Unclassified'), findsNWidgets(41));
    expect(tester.widget<TextField>(find.byKey(const ValueKey('research-search-field'))).controller!.text, isEmpty);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('research-search-field'))).focusNode!.hasFocus, isTrue);
  });

  testWidgets('switching to a non-Linkage table clears hidden subtype state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-linkage-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restatement Linkages').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbs').last);
    await tester.pumpAndSettle();
    expect(find.text('111 results'), findsOneWidget);
    expect(find.byKey(const ValueKey('research-linkage-subtype-filter')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Tables').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('research-linkage-subtype-filter')), findsOneWidget);
    expect(find.text('368 results'), findsOneWidget);
  });

  testWidgets('Research details show the confirmed Linkage subtype', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));
    await tester.ensureVisible(find.text('or should I say'));
    await tester.tap(find.text('or should I say'));
    await tester.pumpAndSettle();

    expect(find.text('LINKAGE STATUS'), findsOneWidget);
    expect(find.text('Restatement Linkages'), findsNWidgets(12));
  });

  test('taxonomy metadata remains excluded from archive serialization', () {
    final card = languageTables.firstWhere((table) => table.name == 'Linkages').cards[5];
    final work = ArchivedWork(id: 'linkage-taxonomy', name: 'Linkage Taxonomy', savedAt: DateTime(2026, 8, 28), cards: [WorkspaceCard(instanceId: 'linkage-instance', card: card, position: Offset.zero)]);
    final encodedCard = ((jsonDecode(ArchiveStorage.instance.encodeWorks([work])) as List<dynamic>).single as Map<String, dynamic>)['cards'] as List<dynamic>;

    expect(encodedCard.single, isNot(contains('subtype')));
    expect(linkageSubtypeFor(card), LinkageSubtype.restatement);
  });

  test('confirmed linkage examples classify correctly', () {
    final restatement = LanguageCard(id: 'test-restatement', text: 'in other words', category: CardCategory.green, tableName: 'Linkages');
    final momentum = LanguageCard(id: 'test-momentum', text: 'obviously', category: CardCategory.green, tableName: 'Linkages');

    expect(linkageSubtypeFor(restatement), LinkageSubtype.restatement);
    expect(linkageSubtypeFor(momentum), LinkageSubtype.momentum);
    expect(languageTables[2].cards.any((card) => linkageSubtypeFor(card) == null), isTrue);
    expect(linkageSubtypeLabel(languageTables[2].cards.first), 'Basic Linkages');
    expect(languageTables.first.name, 'Nominals');
    expect('Nominals are the abbreviated app term for hypnotic nominalizations.', contains('Nominals'));
  });

  test('taxonomy metadata is excluded from archive serialization', () {
    final card = LanguageCard(id: 'test-restatement', text: 'in other words', category: CardCategory.green, tableName: 'Linkages');
    final work = ArchivedWork(id: 'taxonomy', name: 'Taxonomy', savedAt: DateTime(2026, 8, 28), cards: [WorkspaceCard(instanceId: 'taxonomy-card', card: card, position: Offset.zero)]);
    final encoded = ArchiveStorage.instance.encodeWorks([work]);
    final decoded = jsonDecode(encoded) as List<dynamic>;
    final serializedCard = (decoded.single as Map<String, dynamic>)['cards'] as List<dynamic>;

    expect(serializedCard.single, isNot(contains('subtype')));
    expect(linkageSubtypeLabel(card), 'Restatement Linkages');
  });

  test('blue-family roles follow the confirmed practical model', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    final timeBinds = tablesByName['Time Binds']!.cards;
    final causeAndEffect = tablesByName['Cause and Effect']!.cards;
    final lyModifiers = tablesByName['LY Modifiers']!.cards;

    expect(timeBinds.every((card) => card.category == CardCategory.darkBlue), isTrue);
    expect(causeAndEffect.every((card) => card.category == CardCategory.lightBlue), isTrue);
    expect(lyModifiers.every((card) => card.category == CardCategory.lyModifier), isTrue);
    expect(CardCategory.darkBlue.color, const Color(0xFF2F6FD0));
    expect(CardCategory.lightBlue.color, const Color(0xFF1B3E80));
    expect(CardCategory.lyModifier.color, const Color(0xFF6FC0E8));
    expect(tablesByName.keys, isNot(contains('Presuppositions')));
    expect(tablesByName['Linkages'], isNotNull);
    expect(tablesByName['Cause and Effect'], isNotNull);
    expect(tablesByName['Linkages']!.cards, isNotEmpty);
    expect(tablesByName['Cause and Effect']!.cards, isNotEmpty);
  });

  test('blue-family color metadata does not alter archive serialization', () {
    final cards = [
      ...languageTables.firstWhere((table) => table.name == 'Time Binds').cards.take(1),
      ...languageTables.firstWhere((table) => table.name == 'Cause and Effect').cards.take(1),
      ...languageTables.firstWhere((table) => table.name == 'LY Modifiers').cards.take(1),
    ].map((card) => WorkspaceCard(instanceId: 'blue-${card.id}', card: card, position: Offset.zero)).toList();
    final work = ArchivedWork(id: 'blue-family', name: 'Blue Family', savedAt: DateTime(2026, 8, 28), cards: cards);
    final encodedCards = ((jsonDecode(ArchiveStorage.instance.encodeWorks([work])) as List<dynamic>).single as Map<String, dynamic>)['cards'] as List<dynamic>;

    expect(encodedCards.map((card) => (card as Map<String, dynamic>)['category']), ['darkBlue', 'lightBlue', 'lyModifier']);
    expect(encodedCards.every((card) => !(card as Map<String, dynamic>).containsKey('color')), isTrue);
  });

  test('workspace copies have independent instance identities', () {
    final sourceCard = languageTables.first.cards.first;
    final first = WorkspaceCard(card: sourceCard, position: Offset.zero);
    final second = WorkspaceCard(card: sourceCard, position: const Offset(100, 100));

    expect(first.card.id, second.card.id);
    expect(first.instanceId, isNot(second.instanceId));
    final connection = CardConnection(fromCardId: first.instanceId, toCardId: second.instanceId);
    expect(connection.fromCardId, isNot(connection.toCardId));
  });

  testWidgets('working wall remove control follows the live practice room path', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PracticeRoomScreen()));
    await tester.drag(find.text('the room'), const Offset(360, 180));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove from wall'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);
    await tester.tap(find.byTooltip('Connections'));
    await tester.pump();
    expect(find.byTooltip('Remove from wall'), findsNothing);

    await tester.tap(find.byTooltip('Exit Connections'));
    await tester.pump();
    await tester.tap(find.text('×'));
    await tester.pumpAndSettle();
    expect(find.text('Remove card?'), findsOneWidget);
    expect(find.text('Remove "the room" from the Working Wall?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from wall'), findsNothing);
    expect(find.text('the room'), findsOneWidget);
  });

  testWidgets('mobile Table Browser exposes all cards and Add to Wall cascades copies', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: PracticeRoomScreen()));

    expect(find.byTooltip('Add to Wall'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to Wall').first);
    await tester.tap(find.byTooltip('Add to Wall').first);
    await tester.pump();

    final cards = find.text('the room');
    expect(cards, findsNWidgets(3));
    final positions = cards.evaluate().map((element) => tester.getTopLeft(find.byWidget(element.widget))).toList();
    expect(positions[1], isNot(positions[2]));
    await tester.dragFrom(const Offset(180, 270), const Offset(0, -180));
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('mobile touch dragging moves only the selected duplicate workspace card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final source = languageTables.first.cards.first;
    final first = WorkspaceCard(instanceId: 'mobile-first', card: source, position: const Offset(40, 40));
    final second = WorkspaceCard(instanceId: 'mobile-second', card: source, position: const Offset(230, 120));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [first, second])));

    final cards = find.text('the room');
    expect(cards, findsNWidgets(3));
    final firstPosition = tester.getTopLeft(cards.at(1));
    final secondPosition = tester.getTopLeft(cards.at(2));
    await tester.drag(cards.at(1), const Offset(60, 45));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(cards.at(1)), isNot(firstPosition));
    expect(tester.getTopLeft(cards.at(2)), secondPosition);
  });

  testWidgets('mobile Connections controls toggle, connect cards, and restore controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final first = WorkspaceCard(instanceId: 'connection-first', card: languageTables.first.cards.first, position: const Offset(30, 30));
    final second = WorkspaceCard(instanceId: 'connection-second', card: languageTables[1].cards.first, position: const Offset(220, 120));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [first, second])));

    expect(find.byTooltip('Connections'), findsOneWidget);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(find.byTooltip('Connections'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.tap(find.byTooltip('Connections'));
    await tester.pump();
    expect(find.byTooltip('Exit Connections'), findsOneWidget);
    expect(find.byTooltip('Remove from wall'), findsNothing);
    await tester.tap(find.text('the room').last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('notice').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('connections-painter')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.byTooltip('Exit Connections'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Connections'), findsOneWidget);
    expect(find.byTooltip('Remove from wall'), findsNWidgets(2));
  });

  testWidgets('Working Wall reliably selects full cards and connects expanded Nominals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final nominals = languageTables.firstWhere((table) => table.name == 'Nominals').cards;
    final mindfulness = nominals.firstWhere((card) => card.text == 'Mindfulness');
    final tranquility = nominals.firstWhere((card) => card.text == 'Tranquility');
    final calm = nominals.firstWhere((card) => card.text == 'Calm');
    final first = WorkspaceCard(instanceId: 'mindfulness-start', card: mindfulness, position: const Offset(30, 30));
    final second = WorkspaceCard(instanceId: 'tranquility-end', card: tranquility, position: const Offset(330, 30));
    final third = WorkspaceCard(instanceId: 'calm-next', card: calm, position: const Offset(30, 230));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [first, second, third])));

    final firstSurface = find.byKey(const ValueKey('workspace-card-mindfulness-start'));
    await tester.drag(firstSurface, const Offset(40, 25));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Connections'));
    await tester.pump();
    final firstRect = tester.getRect(firstSurface);
    await tester.tapAt(Offset(firstRect.right - 8, firstRect.bottom - 8));
    await tester.pump();

    BoxDecoration decorationFor(Finder finder) => tester.widget<AnimatedContainer>(finder).decoration! as BoxDecoration;
    final selectedBorder = decorationFor(firstSurface).border! as Border;
    expect(selectedBorder.top.color, const Color(0xFFF5D061));
    expect(selectedBorder.top.width, 2.5);

    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('workspace-card-tranquility-end'))));
    await tester.pump();
    expect(find.bySemanticsLabel('Connection from mindfulness-start to tranquility-end'), findsOneWidget);
    expect((decorationFor(firstSurface).border! as Border).top.color, isNot(const Color(0xFFF5D061)));

    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('workspace-card-calm-next'))));
    await tester.pump();
    expect((decorationFor(find.byKey(const ValueKey('workspace-card-calm-next'))).border! as Border).top.color, const Color(0xFFF5D061));
    semantics.dispose();
  });

  testWidgets('mobile tap and sub-threshold movement do not move a workspace card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final card = WorkspaceCard(instanceId: 'threshold-card', card: languageTables.first.cards.first, position: const Offset(40, 40));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [card])));
    final target = find.text('the room').last;
    final original = tester.getTopLeft(target);
    await tester.tap(target);
    await tester.pump();
    expect(tester.getTopLeft(target), original);
    await tester.drag(target, const Offset(3, 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(target), original);
  });

  testWidgets('intentional mobile drag moves the selected instance and remains bounded', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final first = WorkspaceCard(instanceId: 'drag-first', card: languageTables.first.cards.first, position: const Offset(40, 40));
    final second = WorkspaceCard(instanceId: 'drag-second', card: languageTables.first.cards.first, position: const Offset(230, 140));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [first, second])));
    final cards = find.text('the room');
    final secondPosition = tester.getTopLeft(cards.at(2));
    await tester.drag(cards.at(1), const Offset(80, 60));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(cards.at(1)), isNot(const Offset(55, 55)));
    expect(tester.getTopLeft(cards.at(2)), secondPosition);
  });

  testWidgets('mobile orientation changes keep cards inside the visible wall', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final card = WorkspaceCard(instanceId: 'orientation-card', card: languageTables.first.cards.first, position: const Offset(1000, 1000));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [card])));
    await tester.pump();
    final portraitPosition = tester.getTopLeft(find.text('the room').last);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump(const Duration(milliseconds: 100));
    final restoredPosition = tester.getTopLeft(find.text('the room').last);
    expect(portraitPosition.dx, greaterThanOrEqualTo(0));
    expect(portraitPosition.dy, greaterThanOrEqualTo(0));
    expect(restoredPosition.dx, greaterThanOrEqualTo(0));
    expect(restoredPosition.dy, greaterThanOrEqualTo(0));
    expect(restoredPosition.dx, lessThan(390));
    expect(restoredPosition.dy, lessThan(844));
  });

  testWidgets('mobile selection brings instances forward and long press cycles overlap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final source = languageTables.first.cards.first;
    final first = WorkspaceCard(instanceId: 'overlap-first', card: source, position: const Offset(60, 60));
    final second = WorkspaceCard(instanceId: 'overlap-second', card: source, position: const Offset(60, 60));
    await tester.pumpWidget(MaterialApp(home: PracticeRoomScreen(initialCards: [first, second])));

    List<Key?> stackKeys() => tester.widget<Stack>(find.byKey(const ValueKey('working-wall-stack'))).children.map((child) => child.key).toList();
    expect(stackKeys(), containsAllInOrder([const ValueKey('overlap-first'), const ValueKey('overlap-second')]));
    expect(stackKeys().last, const ValueKey('overlap-second'));
    await tester.longPress(find.byKey(const ValueKey('overlap-second')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(stackKeys().last, const ValueKey('overlap-first'));
  });

  test('Notice and Embedded are distinct yellow-family categories with subtype support', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('Notice'));
    expect(tablesByName, contains('Embedded'));

    final noticeTable = tablesByName['Notice']!;
    final embeddedTable = tablesByName['Embedded']!;

    expect(noticeTable.cards, hasLength(12));
    expect(noticeTable.cards.take(4).map((c) => c.id), ['notice-1', 'notice-2', 'notice-3', 'notice-4']);
    expect(noticeTable.cards.every((c) => c.category == CardCategory.notice), isTrue);

    expect(embeddedTable.cards, hasLength(3));
    final intactCards = embeddedTable.cards.where((c) => embeddedSubtypeFor(c) == EmbeddedSubtype.intact).toList();
    final distributedCards = embeddedTable.cards.where((c) => embeddedSubtypeFor(c) == EmbeddedSubtype.distributed).toList();

    expect(intactCards, hasLength(2));
    expect(intactCards.map((c) => c.id), ['embedded-1', 'embedded-2']);
    expect(intactCards.map((c) => c.text), ['find what you\'re looking for', 'change for the better']);

    expect(distributedCards, hasLength(1));
    final distCard = distributedCards.single;
    expect(distCard.id, 'embedded-3');
    expect(distCard.isResearchOnly, isTrue);
    expect(distCard.passage, contains('as you become more and more relaxed'));
    expect(distCard.passage, contains('slip into trance'));
    expect(distCard.fragments, ['close your eyes', 'close them', 'go into trance', 'slip into trance']);

    var lastIdx = 0;
    for (final frag in distCard.fragments) {
      final idx = distCard.passage.indexOf(frag, lastIdx);
      expect(idx, isNot(-1), reason: 'Fragment "$frag" must occur in order in passage');
      lastIdx = idx + frag.length;
    }

    expect(embeddedSubtypeLabel(embeddedTable.cards.first), 'Intact Embedded Commands');
    expect(embeddedSubtypeLabel(distCard), 'Distributed Embedded Commands');

    expect(CardCategory.notice.label, 'Notice');
    expect(CardCategory.embedded.label, 'Embedded');

    expect(CardCategory.notice.color, const Color(0xFFF2C010));
    expect(CardCategory.embedded.color, const Color(0xFF7A6B22));
    expect(CardCategory.notice.color, isNot(equals(CardCategory.embedded.color)));
  });

  testWidgets('Research Laboratory filters distinguish Notice and Embedded subtypes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notice').last);
    await tester.pumpAndSettle();
    expect(find.text('12 results'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Embedded').last);
    await tester.pumpAndSettle();
    expect(find.text('3 results'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-embedded-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intact Embedded Commands').last);
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-embedded-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Distributed Embedded Commands').last);
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
    expect(find.text('Distributed Embedded Commands'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Categories').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'relaxed you may notice');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
  });

  test('Deepeners exists as a distinct Table with 12 confirmed cards', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('Deepeners'));

    final deepenersTable = tablesByName['Deepeners']!;
    expect(deepenersTable.cards, hasLength(12));

    final expectedTexts = [
      'deeply relax',
      'deepen your relaxation',
      'begin to thoroughly immerse yourself in the experience',
      'notice how deeply you\'re sinking into trance',
      'sink all the way down to the next level of trance',
      'sink twice as deep',
      'double your relaxation',
      'twice as relaxed now',
      'every time you ___, you sink twice as deep',
      'as you continue to sink deeper and deeper',
      'sinking further now, doubling your relaxation every time',
      'continue to relax, diving twice as deep now',
    ];

    for (var i = 0; i < 12; i++) {
      expect(deepenersTable.cards[i].id, 'deepener-${i + 1}');
      expect(deepenersTable.cards[i].text, expectedTexts[i]);
      expect(deepenersTable.cards[i].category, CardCategory.deepener);
      expect(deepenersTable.cards[i].tableName, 'Deepeners');
    }

    final allTexts = deepenersTable.cards.map((c) => c.text).toList();
    expect(allTexts, isNot(contains('completely relax')));
    expect(allTexts, isNot(contains('relax completely')));
    expect(allTexts, isNot(contains('That\'s right')));

    expect(CardCategory.deepener.label, 'Deepener');
    expect(CardCategory.deepener.color, const Color(0xFF7A1350));
  });

  testWidgets('Research Laboratory filters and searches Deepeners', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deepeners').last);
    await tester.pumpAndSettle();
    expect(find.text('12 results'), findsOneWidget);
    expect(find.text('deeply relax'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deepener').last);
    await tester.pumpAndSettle();
    expect(find.text('12 results'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'twice as');
    await tester.pumpAndSettle();
    expect(find.text('4 results'), findsOneWidget);
  });

  test('Nominals is formalized and expanded as a unified table', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('Nominals'));
    expect(tablesByName, contains('Time Binds'));

    final nominalsTable = tablesByName['Nominals']!;
    final timeBindsTable = tablesByName['Time Binds']!;

    expect(nominalsTable.cards, hasLength(91));
    final nominalTexts = nominalsTable.cards.map((c) => c.text).toList();
    expect(nominalTexts, isNot(contains('in a moment')));
    expect(nominalTexts, containsAll([
      'the room',
      'a possibility',
      'something useful',
      'your attention',
      'that feeling',
      'a deep sense of peace',
      'your curiosity',
      'a new understanding',
      'an internal awareness',
      'that state of comfort',
      'a quiet realization',
      'your inner wisdom',
    ]));

    expect(nominalsTable.cards.take(5).map((c) => c.id), ['nom-1', 'nom-2', 'nom-3', 'nom-5', 'nom-6']);
    for (var i = 5; i < 12; i++) {
      expect(nominalsTable.cards[i].id, 'nom-${i + 2}');
    }
    expect(nominalTexts, containsAll(['Calm', 'Contentment', 'Approval']));
    expect(nominalsTable.cards.every((c) => c.category == CardCategory.orange), isTrue);
    expect(CardCategory.orange.color, const Color(0xFFE0651B));

    expect(timeBindsTable.cards.map((c) => c.text), contains('in a moment'));
    final timeInAMomentCard = timeBindsTable.cards.firstWhere((c) => c.text == 'in a moment');
    expect(timeInAMomentCard.id, 'time-8');
    expect(timeInAMomentCard.category, CardCategory.darkBlue);
  });

  testWidgets('Research Laboratory filters and searches expanded Nominals', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nominals').last);
    await tester.pumpAndSettle();
    expect(find.text('91 results'), findsOneWidget);
    expect(find.text('your inner wisdom'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'realization');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
    expect(find.text('a quiet realization'), findsOneWidget);
  });

  test('Verbs is formalized and expanded as a unified table', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('Verbs'));

    final verbsTable = tablesByName['Verbs']!;
    expect(verbsTable.cards, hasLength(111));

    final verbTexts = verbsTable.cards.map((c) => c.text).toList();
    expect(verbTexts.take(12), [
      'notice',
      'allow',
      'remember',
      'discover',
      'feel',
      'continue',
      'realize',
      'imagine',
      'experience',
      'absorb',
      'wonder',
      'recognize',
    ]);

    for (var i = 0; i < 12; i++) {
      expect(verbsTable.cards[i].id, 'verb-${i + 1}');
      expect(verbsTable.cards[i].category, CardCategory.pink);
      expect(verbsTable.cards[i].tableName, 'Verbs');
    }
    expect(verbTexts, containsAll(['Notice', 'Adopted', 'Gravitate']));
    expect(CardCategory.pink.color, const Color(0xFFDD3F79));

    // Confirm longer functional phrases remain in specialized tables and not in Verbs
    final noticeTable = tablesByName['Notice']!;
    final complianceTable = tablesByName['Compliance Commands']!;
    final deepenersTable = tablesByName['Deepeners']!;

    expect(noticeTable.cards.map((c) => c.text), contains('notice how'));
    expect(verbsTable.cards.map((c) => c.text), isNot(contains('notice how')));

    expect(complianceTable.cards.map((c) => c.text), contains('Allow your shoulders to relax'));
    expect(verbsTable.cards.map((c) => c.text), isNot(contains('Allow your shoulders to relax')));

    expect(deepenersTable.cards.map((c) => c.text), contains('as you continue to sink deeper and deeper'));
    expect(verbsTable.cards.map((c) => c.text), isNot(contains('as you continue to sink deeper and deeper')));
  });

  testWidgets('Research Laboratory filters and searches expanded Verbs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbs').last);
    await tester.pumpAndSettle();
    expect(find.text('111 results'), findsOneWidget);
    expect(find.text('recognize'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'imagine');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
    expect(find.text('imagine').last, findsOneWidget);
  });

  test('TRANCE WORDPLAY contains exactly 15 unique cards with duplicate trance-8 removed', () {
    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('TRANCE WORDPLAY'));

    final tranceTable = tablesByName['TRANCE WORDPLAY']!;
    expect(tranceTable.cards, hasLength(15));

    final cardIds = tranceTable.cards.map((c) => c.id).toList();
    expect(cardIds, isNot(contains('trance-8')));
    expect(cardIds, containsAll([
      'trance-1', 'trance-2', 'trance-3', 'trance-4', 'trance-5', 'trance-6', 'trance-7',
      'trance-9', 'trance-10', 'trance-11', 'trance-12', 'trance-13', 'trance-14', 'trance-15', 'trance-16'
    ]));

    final cardTexts = tranceTable.cards.map((c) => c.text).toList();
    expect(cardTexts, contains('Trance-formation'));
    expect(cardTexts, contains('Trance-form'));
    expect(cardTexts, contains('form-uh-trance'));
    expect(cardTexts, isNot(contains('trance-formation')));

    expect(tranceTable.cards.every((c) => c.category == CardCategory.tranceWordplay), isTrue);
    expect(CardCategory.tranceWordplay.color, const Color(0xFFA8459A));
    expect(CardCategory.tranceWordplay.label, 'Trance Wordplay');
  });

  testWidgets('Research Laboratory filters and searches TRANCE WORDPLAY', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANCE WORDPLAY').last);
    await tester.pumpAndSettle();
    expect(find.text('15 results'), findsOneWidget);
    expect(find.text('Trance-formation'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'form-uh-trance');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
    expect(find.text('form-uh-trance').last, findsOneWidget);
  });

  test('every production table has defined metadata and resolved category color', () {
    expect(languageTables, hasLength(12));
    for (final table in languageTables) {
      expect(table.name, isNotEmpty);
      expect(table.cards, isNotEmpty);
      for (final card in table.cards) {
        expect(card.text.trim(), isNotEmpty);
        expect(card.category.label, isNotEmpty);
        expect(card.category.color.a, greaterThan(0));
      }
    }
  });

  test('Compliance hierarchy, subtypes, and relocated comp-4 are formalized', () {
    expect(CardCategory.red.label, 'Compliance');
    expect(CardCategory.red.color, const Color(0xFFCE2A24));

    final tablesByName = {for (final table in languageTables) table.name: table};
    expect(tablesByName, contains('Compliance Commands'));
    expect(tablesByName, contains('Compliance Sets'));
    expect(tablesByName, contains('Time Binds'));

    final commandsTable = tablesByName['Compliance Commands']!;
    final setsTable = tablesByName['Compliance Sets']!;
    final timeBindsTable = tablesByName['Time Binds']!;

    expect(commandsTable.cards, hasLength(11));
    expect(setsTable.cards, hasLength(2));
    expect(timeBindsTable.cards, hasLength(9));

    final expectedCommandIds = ['comp-1', 'comp-2', 'comp-3', 'comp-5', 'comp-6', 'comp-7', 'comp-8', 'comp-9', 'comp-10', 'comp-11', 'comp-12'];
    expect(commandsTable.cards.map((c) => c.id), expectedCommandIds);
    expect(commandsTable.cards.every((c) => c.category == CardCategory.red), isTrue);

    // Verify comp-4 relocated to Time Binds as time-9
    final time9 = timeBindsTable.cards.firstWhere((c) => c.text == 'In a moment, I\'m going to ask you to relax');
    expect(time9.id, 'time-9');
    expect(time9.category, CardCategory.darkBlue);
    expect(commandsTable.cards.map((c) => c.text), isNot(contains('In a moment, I\'m going to ask you to relax')));

    // Verify Voluntary & Involuntary classifications
    final primaryVoluntary = commandsTable.cards.where((c) => primaryComplianceSubtypeFor(c) == ComplianceSubtype.voluntary).toList();
    final primaryInvoluntary = commandsTable.cards.where((c) => primaryComplianceSubtypeFor(c) == ComplianceSubtype.involuntary).toList();

    expect(primaryVoluntary, hasLength(7));
    expect(primaryVoluntary.map((c) => c.id), ['comp-1', 'comp-2', 'comp-5', 'comp-6', 'comp-8', 'comp-9', 'comp-10']);

    expect(primaryInvoluntary, hasLength(4));
    expect(primaryInvoluntary.map((c) => c.id), ['comp-3', 'comp-7', 'comp-11', 'comp-12']);

    // Verify secondary classifications
    expect(secondaryComplianceSubtypeFor(commandsTable.cards.firstWhere((c) => c.id == 'comp-1')), ComplianceSubtype.involuntary);
    expect(secondaryComplianceSubtypeFor(commandsTable.cards.firstWhere((c) => c.id == 'comp-8')), ComplianceSubtype.involuntary);
    expect(secondaryComplianceSubtypeFor(commandsTable.cards.firstWhere((c) => c.id == 'comp-3')), ComplianceSubtype.voluntary);
    expect(secondaryComplianceSubtypeFor(commandsTable.cards.firstWhere((c) => c.id == 'comp-12')), ComplianceSubtype.voluntary);

    final set1 = setsTable.cards.firstWhere((c) => c.text == 'Beginning');
    expect(set1.id, 'comp-set-1');
    expect(set1.category, CardCategory.red);
    expect(set1.tableName, 'Compliance Sets');
    expect(set1.isResearchOnly, isTrue);
    expect(set1.fragments, ['come in', 'sit down', 'place feet flat on ground']);
    expect(set1.fragments, hasLength(greaterThanOrEqualTo(3)));

    final set2 = setsTable.cards.firstWhere((c) => c.text == 'Additional things');
    expect(set2.id, 'comp-set-2');
    expect(set2.category, CardCategory.red);
    expect(set2.tableName, 'Compliance Sets');
    expect(set2.isResearchOnly, isTrue);
    expect(set2.fragments, ['put your hands in your lap', 'close your eyes', 'take a deep breath']);
    expect(set2.fragments, hasLength(greaterThanOrEqualTo(3)));
  });

  testWidgets('Research Laboratory filters distinguish Compliance Commands subtypes and Compliance Sets', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compliance').last);
    await tester.pumpAndSettle();
    expect(find.text('13 results'), findsOneWidget);
    expect(find.text('Relax your eyes'), findsOneWidget);
    expect(find.text('Beginning'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Categories').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compliance Commands').last);
    await tester.pumpAndSettle();
    expect(find.text('11 results'), findsOneWidget);

    // Filter by Voluntary compliance subtype (includes primary Voluntary + secondary Voluntary)
    await tester.tap(find.byKey(const ValueKey('research-compliance-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voluntary').last);
    await tester.pumpAndSettle();
    expect(find.text('9 results'), findsOneWidget);
    expect(find.text('Relax your eyes'), findsOneWidget);
    expect(find.text('Let your breathing settle'), findsOneWidget);

    // Filter by Involuntary compliance subtype (includes primary Involuntary + secondary Involuntary)
    await tester.tap(find.byKey(const ValueKey('research-compliance-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Involuntary').last);
    await tester.pumpAndSettle();
    expect(find.text('6 results'), findsOneWidget);
    expect(find.text('Relax your eyes'), findsOneWidget);
    expect(find.text('Let your hands rest comfortably'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('research-compliance-subtype-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Compliance Subtypes').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compliance Sets').last);
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
    expect(find.text('Beginning'), findsOneWidget);
    expect(find.text('Additional things'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('research-search-field')), 'place feet');
    await tester.pumpAndSettle();
    expect(find.text('1 results'), findsOneWidget);
    expect(find.text('Beginning'), findsOneWidget);
  });

  testWidgets('normal browsing excludes research-only tables while Research Laboratory retains their cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final complianceSets = languageTables.firstWhere((table) => table.name == 'Compliance Sets');
    expect(complianceSets.cards, isNotEmpty);
    expect(complianceSets.cards.every((card) => card.isResearchOnly), isTrue);
    expect(normalBrowsingTables.map((table) => table.name), isNot(contains('Compliance Sets')));

    await tester.pumpWidget(const MaterialApp(home: PracticeRoomScreen()));

    for (var index = 0; index < normalBrowsingTables.length; index++) {
      final table = normalBrowsingTables[index];
      expect(find.byTooltip('Add to Wall'), findsWidgets);
      expect(find.text(table.cards.firstWhere((card) => !card.isResearchOnly).text), findsOneWidget);
      expect(find.text('Compliance Sets'), findsNothing);
      await tester.tap(find.byTooltip('Next table (D)'));
      await tester.pump();
    }

    await tester.pumpWidget(const MaterialApp(home: ResearchLaboratoryScreen()));
    await tester.tap(find.byKey(const ValueKey('research-table-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compliance Sets').last);
    await tester.pumpAndSettle();
    expect(find.text('Beginning'), findsOneWidget);
    expect(find.text('Additional things'), findsOneWidget);
  });

  testWidgets('entrance opens into the gallery hall', (WidgetTester tester) async {
    await tester.pumpWidget(const VisualLanguageCastleApp());

    expect(find.text('Visual Language Castle'), findsOneWidget);
    expect(find.text('Enter the architecture of language.'), findsOneWidget);

    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Gallery Hall'), findsOneWidget);
    expect(find.text('Practice Rooms'), findsOneWidget);

    await tester.tap(find.text('Practice Rooms'));
    await tester.pumpAndSettle();

    expect(find.text('The Working Wall'), findsOneWidget);
    expect(find.text('Nominals'), findsOneWidget);
  });

  testWidgets('cards remain on the wall while the table changes', (WidgetTester tester) async {
    await tester.pumpWidget(const VisualLanguageCastleApp());
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Practice Rooms'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('the room'), const Offset(360, 180));
    await tester.pumpAndSettle();
    expect(find.text('the room'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Next table (D)'));
    await tester.pump();
    expect(find.text('Verbs'), findsOneWidget);
    expect(find.text('the room'), findsOneWidget);
  });

  testWidgets('practice room can be opened directly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PracticeRoomScreen()));
    expect(find.text('TABLE BROWSER'), findsOneWidget);
    expect(find.text('Nominals'), findsOneWidget);

    for (var index = 0; index < normalBrowsingTables.length - 1; index++) {
      await tester.tap(find.byTooltip('Next table (D)'));
      await tester.pump();
    }
    expect(find.text('Deepeners'), findsOneWidget);
    expect(find.text('deeply relax'), findsOneWidget);
    expect(normalBrowsingTables.last.cards.map((card) => card.text), contains('sink twice as deep'));
  });

  testWidgets('table guidance explains Nominals and Linkages terminology', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PracticeRoomScreen()));

    await tester.tap(find.byTooltip('Open table guidance'));
    await tester.pumpAndSettle();
    expect(find.text('Nominals are the abbreviated app term for hypnotic nominalizations.'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next table (D)'));
    await tester.tap(find.byTooltip('Next table (D)'));
    await tester.pump();
    await tester.tap(find.byTooltip('Open table guidance'));
    await tester.pumpAndSettle();
    expect(find.text('Linkages are spoken transition structures that maintain and shape hypnotic/conversational momentum.'), findsOneWidget);
    expect(find.text('RESTATEMENT LINKAGES'), findsOneWidget);
    expect(find.text('MOMENTUM LINKAGES'), findsOneWidget);
    await tester.tap(find.text('Close'));
  });

  testWidgets('archive screen renders as a functional destination', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArchiveScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Archive'), findsOneWidget);
  });
}

Map<String, dynamic> _archiveJson({required String id, required String name}) {
  return {
    'id': id,
    'name': name,
    'savedAt': '2026-08-27T12:00:00.000Z',
    'cards': [_cardJson(sourceId: 'nom-1', instanceId: 'one')],
    'connections': <Map<String, String>>[],
  };
}

ArchivedWork _testWork({required String id, required String name, bool isCompleted = false}) {
  final card = WorkspaceCard(
    instanceId: '$id-card',
    card: languageTables.first.cards.first,
    position: const Offset(40, 50),
    notes: 'saved note',
  );
  return ArchivedWork(
    id: id,
    name: name,
    savedAt: DateTime(2026, 8, 1),
    cards: [card],
    connections: const [],
    isCompleted: isCompleted,
    completedAt: isCompleted ? DateTime(2026, 8, 2) : null,
  );
}

Map<String, dynamic> _cardJson({required String sourceId, String? instanceId}) {
  final card = <String, dynamic>{
    'id': sourceId,
    'text': 'the room',
    'category': 'orange',
    'tableName': 'Nominals',
    'referenceNote': '',
    'notes': 'note',
    'x': 12,
    'y': 24,
  };
  if (instanceId != null) card['instanceId'] = instanceId;
  return card;
}
