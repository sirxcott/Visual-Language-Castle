import 'package:flutter/material.dart';

import 'screens/castle_entrance_screen.dart';

void main() {
  runApp(const VisualLanguageCastleApp());
}

class VisualLanguageCastleApp extends StatelessWidget {
  const VisualLanguageCastleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visual Language Castle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0C0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB69558),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Georgia',
        useMaterial3: true,
      ),
      home: const CastleEntranceScreen(),
    );
  }
}
