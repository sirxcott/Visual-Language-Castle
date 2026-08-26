// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visual_language_castle/main.dart';
import 'package:visual_language_castle/screens/practice_room_screen.dart';

void main() {
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
  });
}
