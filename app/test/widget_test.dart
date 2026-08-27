// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visual_language_castle/data/language_tables.dart';
import 'package:visual_language_castle/main.dart';
import 'package:visual_language_castle/models/archived_work.dart';
import 'package:visual_language_castle/models/language_card.dart';
import 'package:visual_language_castle/screens/archive_screen.dart';
import 'package:visual_language_castle/screens/practice_room_screen.dart';

void main() {
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
