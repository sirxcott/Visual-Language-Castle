import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_language_castle/screens/castle_entrance_screen.dart';
import 'package:visual_language_castle/screens/gallery_hub_screen.dart';

void main() {
  final sizes = <Size>[
    const Size(320, 568), // smallest supported phone
    const Size(360, 640), // compact Android phone
    const Size(375, 812), // compact iPhone
    const Size(390, 844), // modern Android/iPhone
    const Size(844, 390), // phone landscape
    const Size(1024, 768), // tablet / compact desktop
    const Size(1280, 600), // short desktop window
    const Size(1280, 720), // Windows/macOS laptop
    const Size(1366, 768), // common Windows laptop
    const Size(1440, 900), // common macOS desktop
    const Size(1920, 1080), // full-HD desktop
    const Size(390, 400), // emergency fallback zone
  ];

  for (final size in sizes) {
    testWidgets('entrance fits completely at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CastleEntranceScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Enter'), findsOneWidget);

      final screenRect = Offset.zero & size;
      final buttonRect = tester.getRect(find.text('Enter'));
      final stageRect = tester.getRect(find.byKey(const ValueKey('entrance-door-stage')));
      final frameRect = tester.getRect(find.byKey(const ValueKey('entrance-portal-frame')));

      expect(screenRect.contains(buttonRect.bottomCenter), isTrue, reason: 'Enter button must remain reachable at $size');
      expect(stageRect.contains(frameRect.topLeft), isTrue, reason: 'Portal top-left must not be clipped at $size');
      expect(stageRect.contains(frameRect.bottomRight), isTrue, reason: 'Portal bottom-right must not be clipped at $size');
      expect(screenRect.contains(frameRect.topLeft), isTrue, reason: 'Portal must stay inside the viewport at $size');
      expect(screenRect.contains(frameRect.bottomRight), isTrue, reason: 'Portal must stay inside the viewport at $size');
    });
  }

  for (final size in sizes) {
    testWidgets('Gallery Hall reaches all destinations by scrolling at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: GalleryHubScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final pageScrollable = find.byType(Scrollable).first;
      for (final title in const ['Practice Rooms', 'Archive', 'Research Laboratory', 'Completed Works']) {
        await tester.scrollUntilVisible(find.text(title), 200, scrollable: pageScrollable);
        expect(find.text(title), findsOneWidget, reason: '$title must be reachable via scrolling for $size');
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('iOS and Android safe areas keep entrance controls visible', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final safePadding in const [
      EdgeInsets.only(top: 47, bottom: 34), // iPhone notch and home indicator
      EdgeInsets.only(top: 24, bottom: 24), // Android status/navigation areas
    ]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: const Size(390, 844), padding: safePadding),
          child: const MaterialApp(home: CastleEntranceScreen()),
        ),
      );
      await tester.pump();

      final buttonRect = tester.getRect(find.text('Enter'));
      final frameRect = tester.getRect(find.byKey(const ValueKey('entrance-portal-frame')));
      expect(frameRect.top, greaterThanOrEqualTo(safePadding.top));
      expect(buttonRect.bottom, lessThanOrEqualTo(844 - safePadding.bottom));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Gallery Hall remains usable with enlarged system text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.5)),
        child: MaterialApp(home: GalleryHubScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final pageScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Completed Works'), 200, scrollable: pageScrollable);
    expect(find.text('Completed Works'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
