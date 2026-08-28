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
import 'package:visual_language_castle/main.dart';
import 'package:visual_language_castle/models/archived_work.dart';
import 'package:visual_language_castle/models/language_card.dart';
import 'package:visual_language_castle/screens/archive_screen.dart';
import 'package:visual_language_castle/screens/completed_works_screen.dart';
import 'package:visual_language_castle/screens/practice_room_screen.dart';
import 'package:visual_language_castle/screens/research_laboratory_screen.dart';
import 'package:visual_language_castle/services/archive_storage.dart';

void main() {
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
    await tester.tap(find.byTooltip('Remove from wall').last);
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

    for (var index = 0; index < 8; index++) {
      await tester.tap(find.byTooltip('Next table (D)'));
      await tester.pump();
    }
    expect(find.text('TRANCE WORDPLAY'), findsOneWidget);
    expect(find.text('Trance-position'), findsOneWidget);
    expect(languageTables.last.cards.map((card) => card.text), contains('trance-formation'));
    expect(languageTables.last.cards.map((card) => card.text), contains('form-uh-trance'));
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
