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
  static const double _horizontalPadding = 20.0;
  static const double _portalSurround = 24.0;
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
        builder: (context, child) => Stack(
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
                border: Border.all(color: const Color(0xFF6E5935), width: 3.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 40, spreadRadius: 8),
                  BoxShadow(color: Color(0x33D4AF37), blurRadius: 16, spreadRadius: -2),
                ],
              ),
              child: Stack(
                children: [
                  // Soft Inner Glow (Chamber Beyond Doors)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFD4A325).withValues(alpha: 0.18 * _doorController.value),
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
                CastleDoor(side: CastleDoorSide.left, progress: _doorController.value, width: doorWidth, height: doorHeight),
                CastleDoor(side: CastleDoorSide.right, progress: _doorController.value, width: doorWidth, height: doorHeight),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
