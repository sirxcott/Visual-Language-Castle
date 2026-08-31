import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_language_castle/screens/castle_entrance_screen.dart';
import 'package:visual_language_castle/screens/gallery_hub_screen.dart';

void main() {
  final sizes = <Size>[
    const Size(1366, 768),
    const Size(1280, 720),
    const Size(1440, 900),
    const Size(1280, 600),
    const Size(1024, 640),
    const Size(1920, 1080),
    const Size(375, 812), // mobile
    const Size(390, 400), // emergency fallback zone
  ];

  for (final size in sizes) {
    testWidgets('no overflow at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterError.onError = (details) {
        throw details.exception;
      };

      await tester.pumpWidget(const MaterialApp(home: CastleEntranceScreen()));
      await tester.pump();

      expect(find.text('Enter'), findsOneWidget);
      final buttonRect = tester.getRect(find.text('Enter'));
      expect(buttonRect.bottom, lessThanOrEqualTo(size.height), reason: 'Enter button must be within viewport for $size');
    });
  }

  for (final size in sizes) {
    testWidgets('Gallery Hall reaches all destinations by scrolling at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterError.onError = (details) {
        throw details.exception;
      };

      await tester.pumpWidget(const MaterialApp(home: GalleryHubScreen()));
      await tester.pump();

      // The Gallery Hall has exactly one interactive Scrollable (the page's
      // SingleChildScrollView); the grid's own Scrollable never scrolls.
      final pageScrollable = find.byType(Scrollable).first;
      for (final title in const ['Practice Rooms', 'Archive', 'Research Laboratory', 'Completed Works']) {
        await tester.scrollUntilVisible(find.text(title), 200, scrollable: pageScrollable);
        expect(find.text(title), findsOneWidget, reason: '$title must be reachable via scrolling for $size');
      }
    });
  }
}
