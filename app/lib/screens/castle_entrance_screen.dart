import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sound_effects.dart';
import '../widgets/castle_door.dart';
import 'gallery_hub_screen.dart';

class CastleEntranceScreen extends StatefulWidget {
  const CastleEntranceScreen({super.key});

  @override
  State<CastleEntranceScreen> createState() => _CastleEntranceScreenState();
}

class _CastleEntranceScreenState extends State<CastleEntranceScreen> with SingleTickerProviderStateMixin {
  static const double _horizontalPadding = 20.0;
  static const double _portalSurround = 24.0;
  static const Duration _openDuration = Duration(milliseconds: 2600);
  static const Duration _revealDelay = Duration(milliseconds: 3000);
  static const CastleDoorCurve _doorCurve = CastleDoorCurve();
  late final AnimationController _doorController;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _doorController = AnimationController(vsync: this, duration: _openDuration);
  }

  @override
  void dispose() {
    _doorController.dispose();
    super.dispose();
  }

  Future<void> _enterCastle() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    _startGateSound();
    _doorController.forward();
    // Cross into the hall once the doors are far enough open to show the
    // chamber, while the swing is still settling behind the fade.
    await Future<void>.delayed(_revealDelay);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => const GalleryHubScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  /// Audio must never gate navigation, so it is fired and forgotten.
  void _startGateSound() {
    SoundEffects.instance.playCastleGate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CastleWallPainter()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 600;
                final availableHeight = constraints.maxHeight;
                final shortViewport = availableHeight < 700;
                final veryShortViewport = availableHeight < 560;
                // Only truly tiny viewports fall back to scrolling; normal
                // laptop/desktop heights must fit everything with zero scroll.
                final emergencyFallback = availableHeight < 420;

                final subtitleFontSize = veryShortViewport ? 9.0 : (shortViewport ? 10.0 : 12.0);
                final titleFontSize = mobile
                    ? (veryShortViewport ? 20.0 : (shortViewport ? 24.0 : 28.0))
                    : (veryShortViewport ? 26.0 : (shortViewport ? 32.0 : 38.0));
                final taglineFontSize = veryShortViewport ? 12.0 : (shortViewport ? 14.0 : 16.0);

                final gapAfterSubtitle = veryShortViewport ? 4.0 : (shortViewport ? 6.0 : 10.0);
                final gapAfterTitle = veryShortViewport ? 4.0 : (shortViewport ? 6.0 : 10.0);
                final gapAfterRule = veryShortViewport ? 6.0 : (shortViewport ? 8.0 : 10.0);
                final gapAfterTagline = veryShortViewport ? 8.0 : (shortViewport ? 14.0 : 24.0);
                final gapAfterStage = veryShortViewport ? 8.0 : (shortViewport ? 14.0 : 24.0);
                final paddingV = veryShortViewport ? 6.0 : (shortViewport ? 12.0 : 20.0);
                final stageWidth = math.min(650.0, constraints.maxWidth - (_horizontalPadding * 2));

                final header = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtitle Header
                    Text(
                      'VISUAL LANGUAGE CASTLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.5,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                    SizedBox(height: gapAfterSubtitle),
                    // Main Title
                    Text(
                      'Visual Language Castle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF5EEDA),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 14, offset: Offset(0, 4)),
                          Shadow(color: Color(0x66D4AF37), blurRadius: 20),
                        ],
                      ),
                    ),
                    SizedBox(height: gapAfterTitle),
                    // Decorative Rule
                    const _DecorativeRule(),
                    SizedBox(height: gapAfterRule),
                    // Tagline
                    Text(
                      'Enter the architecture of language.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFC2B7A0),
                        fontSize: taglineFontSize,
                        fontStyle: FontStyle.italic,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                    ),
                  ],
                );

                final button = _EnterCastleButton(isOpening: _isOpening, onPressed: _enterCastle);

                if (emergencyFallback) {
                  // Emergency-only fallback for extremely small screens: scroll
                  // rather than crush the doors below a usable, undistorted size.
                  final doorHeight = math.max(_minDoorHeight, math.min(220.0, availableHeight * 0.45));
                  final doorWidth = _doorWidthForHeight(doorHeight, mobile, constraints.maxWidth);
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: _horizontalPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        header,
                        SizedBox(height: gapAfterTagline),
                        _buildDoorStage(doorWidth, doorHeight, stageWidth),
                        SizedBox(height: gapAfterStage),
                        button,
                      ],
                    ),
                  );
                }

                // Reserve the header and Enter button heights first (as fixed
                // Column children), then let the doors fill whatever vertical
                // space is left via Expanded -- guaranteeing zero overflow.
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: _horizontalPadding),
                  child: Column(
                    children: [
                      header,
                      SizedBox(height: gapAfterTagline),
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, doorAreaConstraints) {
                              final doorHeight = _doorHeightForBudget(doorAreaConstraints.maxHeight, mobile, constraints.maxWidth);
                              final doorWidth = _doorWidthForHeight(doorHeight, mobile, constraints.maxWidth);
                              return _buildDoorStage(doorWidth, doorHeight, stageWidth);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: gapAfterStage),
                      button,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Doors always keep their original width:height ratio (270:570 desktop,
  // 1:2.1 mobile); only the overall scale changes to fit available space.
  static double _doorAspect(bool mobile) => mobile ? 1 / 2.1 : 270 / 570;

  // Below this, CastleDoor's fixed-size hinge hardware (3 x 36px within the
  // middle 64% of the door) no longer fits and overflows internally.
  static const double _minDoorHeight = 175.0;

  static double _doorWidthForHeight(double height, bool mobile, double screenWidth) {
    final widthBudget = mobile
        ? math.min(170.0, math.max(0.0, (screenWidth - (_horizontalPadding * 2) - _portalSurround) / 2))
        : math.min(270.0, screenWidth * 0.22);
    return math.min(height * _doorAspect(mobile), widthBudget);
  }

  static double _doorHeightForBudget(double heightBudget, bool mobile, double screenWidth) {
    final widthBudget = mobile
        ? math.min(170.0, math.max(0.0, (screenWidth - (_horizontalPadding * 2) - _portalSurround) / 2))
        : math.min(270.0, screenWidth * 0.22);
    final heightLimitFromWidth = widthBudget / _doorAspect(mobile);
    final availableHeight = math.max(_minDoorHeight, heightBudget - _portalSurround);
    return math.min(math.min(570.0, availableHeight), heightLimitFromWidth);
  }

  Widget _buildDoorStage(double doorWidth, double doorHeight, double stageWidth) {
    return SizedBox(
      key: const ValueKey('entrance-door-stage'),
      width: stageWidth,
      height: doorHeight + _portalSurround,
      child: AnimatedBuilder(
        animation: _doorController,
        builder: (context, child) {
          final swing = _doorCurve.transform(_doorController.value);
          return Stack(
            alignment: Alignment.center,
            children: [
            // Stone Surround Portal Frame
            Container(
              key: const ValueKey('entrance-portal-frame'),
              width: doorWidth * 2 + _portalSurround,
              height: doorHeight + _portalSurround,
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 40, spreadRadius: 8),
                  BoxShadow(color: Color(0x33D4AF37), blurRadius: 16, spreadRadius: -2),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChamberBeyondPainter(reveal: swing.clamp(0.0, 1.0)),
                    ),
                  ),
                  // Soft Inner Glow (Chamber Beyond Doors)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFD4A325).withValues(alpha: 0.18 * swing.clamp(0.0, 1.0)),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Castle Doors
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CastleDoor(side: CastleDoorSide.left, progress: swing, width: doorWidth, height: doorHeight),
                CastleDoor(side: CastleDoorSide.right, progress: swing, width: doorWidth, height: doorHeight),
              ],
            ),
          ],
          );
        },
      ),
    );
  }
}

class _ChamberBeyondPainter extends CustomPainter {
  const _ChamberBeyondPainter({required this.reveal});

  /// 0 = doors shut, 1 = doors fully open.
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal <= 0.001) return;

    final w = size.width;
    final h = size.height;

    // Centered distant vanishing point and tight back corridor arch (~30-50 ft depth)
    final backLeft = w * 0.42;
    final backRight = w * 0.58;
    final backTop = h * 0.43;
    final backBottom = h * 0.59;
    final backArchHeight = h * 0.03;

    // 1. Far Back Wall (End of Long Corridor)
    final backWallPath = Path()
      ..moveTo(backLeft, backBottom)
      ..lineTo(backLeft, backTop + backArchHeight)
      ..quadraticBezierTo(w * 0.5, backTop - backArchHeight * 0.5, backRight, backTop + backArchHeight)
      ..lineTo(backRight, backBottom)
      ..close();

    final backWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF070605).withValues(alpha: reveal),
          const Color(0xFF0F0D0B).withValues(alpha: reveal),
        ],
      ).createShader(Rect.fromLTRB(backLeft, backTop, backRight, backBottom));
    canvas.drawPath(backWallPath, backWallPaint);

    final backArchStroke = Paint()
      ..color = const Color(0xFF050404).withValues(alpha: 0.8 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(backWallPath, backArchStroke);

    // 2. Ceiling Converging into Distance
    final ceilingPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(backRight, backTop + backArchHeight)
      ..quadraticBezierTo(w * 0.5, backTop - backArchHeight * 0.5, backLeft, backTop + backArchHeight)
      ..close();

    final ceilingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0C0B0A).withValues(alpha: 0.95 * reveal),
          const Color(0xFF161412).withValues(alpha: 0.85 * reveal),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, backTop));
    canvas.drawPath(ceilingPath, ceilingPaint);

    // 3. Side Walls Converging Toward Distant Center
    // Left Wall
    final leftWallPath = Path()
      ..moveTo(0, 0)
      ..lineTo(backLeft, backTop + backArchHeight)
      ..lineTo(backLeft, backBottom)
      ..lineTo(0, h)
      ..close();

    final leftWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF1A1714).withValues(alpha: 0.95 * reveal),
          const Color(0xFF100E0C).withValues(alpha: 0.95 * reveal),
        ],
      ).createShader(Rect.fromLTWH(0, 0, backLeft, h));
    canvas.drawPath(leftWallPath, leftWallPaint);

    // Right Wall
    final rightWallPath = Path()
      ..moveTo(w, 0)
      ..lineTo(backRight, backTop + backArchHeight)
      ..lineTo(backRight, backBottom)
      ..lineTo(w, h)
      ..close();

    final rightWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          const Color(0xFF1A1714).withValues(alpha: 0.95 * reveal),
          const Color(0xFF100E0C).withValues(alpha: 0.95 * reveal),
        ],
      ).createShader(Rect.fromLTWH(backRight, 0, w - backRight, h));
    canvas.drawPath(rightWallPath, rightWallPaint);

    // Stone joints / course lines on side walls for perspective depth
    final wallLinePaint = Paint()
      ..color = const Color(0xFF0A0908).withValues(alpha: 0.6 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      final t = i / 5.0;
      final yFront = h * t;
      final yBack = backTop + (backBottom - backTop) * t;
      canvas.drawLine(Offset(0, yFront), Offset(backLeft, yBack), wallLinePaint);
      canvas.drawLine(Offset(w, yFront), Offset(backRight, yBack), wallLinePaint);
    }

    // 4. Floor with Steep Converging Perspective Lines & Flagstones
    final floorPath = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(backRight, backBottom)
      ..lineTo(backLeft, backBottom)
      ..close();

    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF221E19).withValues(alpha: 0.98 * reveal),
          const Color(0xFF12100D).withValues(alpha: 0.95 * reveal),
        ],
      ).createShader(Rect.fromLTWH(0, backBottom, w, h - backBottom));
    canvas.drawPath(floorPath, floorPaint);

    // Converging floor guide lines leading steeply toward distant center
    final floorLinePaint = Paint()
      ..color = const Color(0xFF0D0B0A).withValues(alpha: 0.7 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const numFloorLines = 8;
    for (var i = 1; i < numFloorLines; i++) {
      final fraction = i / numFloorLines;
      final xFront = w * fraction;
      final xBack = backLeft + (backRight - backLeft) * fraction;
      canvas.drawLine(Offset(xFront, h), Offset(xBack, backBottom), floorLinePaint);
    }

    // Horizontal flagstone course lines stepping into distance
    for (var step = 1; step <= 7; step++) {
      final depth = math.pow(step / 8, 2.0).toDouble();
      final y = h - (h - backBottom) * (1 - depth);
      final insetLeft = backLeft * (1 - depth);
      final insetRight = w - (w - backRight) * (1 - depth);
      canvas.drawLine(Offset(insetLeft, y), Offset(insetRight, y), floorLinePaint);
    }

    // 5. Two Wall Torches / Sconces (Left and Right)
    final leftWallX = w * 0.18;
    final leftWallY = h * 0.48;
    _drawTorch(canvas, size, Offset(leftWallX, leftWallY), isLeft: true);

    final rightWallX = w * 0.82;
    final rightWallY = h * 0.48;
    _drawTorch(canvas, size, Offset(rightWallX, rightWallY), isLeft: false);
  }

  void _drawTorch(Canvas canvas, Size size, Offset position, {required bool isLeft}) {
    final x = position.dx;
    final y = position.dy;

    // Localized warm light glow around torch flame
    final glowRadius = math.min(size.width, size.height) * 0.18;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0.35 * reveal),
          const Color(0xFFFF5722).withValues(alpha: 0.12 * reveal),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: glowRadius));
    canvas.drawCircle(position, glowRadius, glowPaint);

    // Torch wall bracket / stem (short dark brown stem)
    final bracketPaint = Paint()
      ..color = const Color(0xFF2A1B0E).withValues(alpha: 0.95 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final wallAttachX = isLeft ? x - 12.0 : x + 12.0;
    final bracketPath = Path()
      ..moveTo(wallAttachX, y + 10.0)
      ..lineTo(x, y + 6.0)
      ..lineTo(x, y - 2.0);
    canvas.drawPath(bracketPath, bracketPaint);

    // Torch handle / cup
    final cupPaint = Paint()
      ..color = const Color(0xFF1C120A).withValues(alpha: 0.95 * reveal)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 2.0), width: 5.0, height: 7.0), cupPaint);

    // Warm glowing light / flame at end of torch stem
    final flameOuterPaint = Paint()
      ..color = const Color(0xFFFF8F00).withValues(alpha: 0.9 * reveal)
      ..style = PaintingStyle.fill;
    final flameInnerPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.95 * reveal)
      ..style = PaintingStyle.fill;

    // Small flame teardrop shape
    final flamePath = Path()
      ..moveTo(x - 3.0, y - 3.0)
      ..quadraticBezierTo(x - 4.0, y - 10.0, x, y - 15.0)
      ..quadraticBezierTo(x + 4.0, y - 10.0, x + 3.0, y - 3.0)
      ..close();
    canvas.drawPath(flamePath, flameOuterPaint);

    final innerFlamePath = Path()
      ..moveTo(x - 1.5, y - 4.0)
      ..quadraticBezierTo(x - 2.0, y - 8.0, x, y - 11.0)
      ..quadraticBezierTo(x + 2.0, y - 8.0, x + 1.5, y - 4.0)
      ..close();
    canvas.drawPath(innerFlamePath, flameInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _ChamberBeyondPainter oldDelegate) => oldDelegate.reveal != reveal;
}

class _DecorativeRule extends StatelessWidget {
  const _DecorativeRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 12,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFC09A52)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x99D4AF37), blurRadius: 4)],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC09A52), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterCastleButton extends StatefulWidget {
  const _EnterCastleButton({required this.isOpening, required this.onPressed});

  final bool isOpening;
  final VoidCallback onPressed;

  @override
  State<_EnterCastleButton> createState() => _EnterCastleButtonState();
}

class _EnterCastleButtonState extends State<_EnterCastleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFC09A52);
    const gold = Color(0xFFD4AF37);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: _hovered ? gold.withValues(alpha: 0.45) : Colors.black87,
              blurRadius: _hovered ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: widget.isOpening ? null : widget.onPressed,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Enter'),
          style: FilledButton.styleFrom(
            backgroundColor: _hovered ? const Color(0xFF2C2419) : const Color(0xFF1E1B15),
            foregroundColor: gold,
            disabledBackgroundColor: const Color(0xFF14120E),
            disabledForegroundColor: const Color(0xFF665538),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            side: BorderSide(color: _hovered ? gold : brass, width: 1.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}

class _CastleWallPainter extends CustomPainter {
  const _CastleWallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Atmospheric radial gradient background
    final background = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.1,
        colors: const [
          Color(0xFF232527),
          Color(0xFF141617),
          Color(0xFF090A0B),
          Color(0xFF040405),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    // Warm ambient torch-glow from upper center
    final torchGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 0.7,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, torchGlow);

    // Ashlar stone masonry block coursing
    final stoneStroke = Paint()
      ..color = const Color(0x1F2A2722)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final stoneHighlight = Paint()
      ..color = const Color(0x12F5EEDA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const blockHeight = 62.0;
    const blockWidth = 96.0;

    for (var row = 0; row < size.height / blockHeight + 1; row++) {
      final y = row * blockHeight;
      final offset = row.isEven ? 0.0 : blockWidth / 2;
      for (var col = -1; col < size.width / blockWidth + 1; col++) {
        final x = col * blockWidth + offset;
        final rect = Rect.fromLTWH(x, y, blockWidth - 2, blockHeight - 2);

        // Draw stone outline
        canvas.drawRect(rect, stoneStroke);

        // Top-left subtle stone edge highlight
        canvas.drawLine(rect.topLeft, rect.topRight, stoneHighlight);
        canvas.drawLine(rect.topLeft, rect.bottomLeft, stoneHighlight);
      }
    }

    // Outer vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
        stops: const [0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
