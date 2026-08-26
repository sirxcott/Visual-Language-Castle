import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/castle_door.dart';
import 'gallery_hub_screen.dart';

class CastleEntranceScreen extends StatefulWidget {
  const CastleEntranceScreen({super.key});

  @override
  State<CastleEntranceScreen> createState() => _CastleEntranceScreenState();
}

class _CastleEntranceScreenState extends State<CastleEntranceScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _doorController;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _doorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250));
  }

  @override
  void dispose() {
    _doorController.dispose();
    super.dispose();
  }

  Future<void> _enterCastle() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    await _doorController.forward();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => const GalleryHubScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final doorHeight = math.min(570.0, constraints.maxHeight * 0.57);
          final doorWidth = math.min(270.0, constraints.maxWidth * 0.22);
          final stageWidth = math.min(650.0, constraints.maxWidth * 0.9);
          return Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _CastleWallPainter()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('VISUAL LANGUAGE CASTLE', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD0B477), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 4)),
                        const SizedBox(height: 12),
                        const Text('Visual Language Castle', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF1E7D0), fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        const Text('Enter the architecture of language.', style: TextStyle(color: Color(0xFFB8AE9B), fontSize: 16, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: stageWidth,
                          height: doorHeight,
                          child: AnimatedBuilder(
                            animation: _doorController,
                            builder: (context, child) => Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: doorWidth * 2 + 10,
                                  height: doorHeight + 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF070707),
                                    border: Border.all(color: const Color(0xFF6E5935), width: 3),
                                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 35, spreadRadius: 7)],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CastleDoor(side: CastleDoorSide.left, progress: _doorController.value, width: doorWidth, height: doorHeight),
                                    CastleDoor(side: CastleDoorSide.right, progress: _doorController.value, width: doorWidth, height: doorHeight),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _isOpening ? null : _enterCastle,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Enter'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB69558),
                            foregroundColor: const Color(0xFF17120C),
                            disabledBackgroundColor: const Color(0xFF665538),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CastleWallPainter extends CustomPainter {
  const _CastleWallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const RadialGradient(center: Alignment(0, 0.1), radius: 1.0, colors: [Color(0xFF323333), Color(0xFF17191A), Color(0xFF080909)]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final stone = Paint()..color = const Color(0x221F2020)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var row = 0; row < size.height / 58; row++) {
      final y = row * 58.0;
      final offset = row.isEven ? 0.0 : 44.0;
      for (var column = -1; column < size.width / 88; column++) {
        final x = column * 88.0 + offset;
        canvas.drawRect(Rect.fromLTWH(x, y, 86, 56), stone);
      }
    }

    final vignette = Paint()..shader = RadialGradient(colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)], stops: const [0.48, 1.0]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
