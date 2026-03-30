import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../routes/app_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _float = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Stack(
        children: [
          // ── Background shapes ────────────────────────────────────────────
          Positioned(
            top: -60,
            right: -40,
            child: _LightBlob(color: const Color(0xFFDDE8FF), size: 280),
          ),
          Positioned(
            top: size.height * 0.28,
            left: -70,
            child: _LightBlob(color: const Color(0xFFE8F0FF), size: 220),
          ),
          Positioned(
            bottom: -30,
            right: size.width * 0.15,
            child: _LightBlob(color: const Color(0xFFDCEAFF), size: 180),
          ),

          // ── Dot grid ─────────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Diagonal accent strip ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.38,
            child: CustomPaint(painter: _DiagonalStripPainter()),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Logo badge ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A6DFF).withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A6DFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FMP Platform',
                            style: TextStyle(
                              color: Color(0xFF1A3A6B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Illustration ──────────────────────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _float,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _float.value),
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) =>
                            Transform.scale(scale: _pulse.value, child: child),
                        child: _TruckIllustration(),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Headline ──────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _slideUp,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 30 * (1 - _slideUp.value)),
                      child: Opacity(opacity: _slideUp.value, child: child),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Move Freight.\n',
                                style: TextStyle(color: Color(0xFF0D1B2E)),
                              ),
                              TextSpan(
                                text: 'Smarter.',
                                style: TextStyle(color: Color(0xFF1A6DFF)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Connect drivers, fleets, and senders\non one intelligent platform.',
                          style: TextStyle(
                            color: const Color(0xFF4A5568).withOpacity(0.85),
                            fontSize: 15,
                            height: 1.65,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ── CTA Button ────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _slideUp,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 40 * (1 - _slideUp.value)),
                      child: Opacity(
                          opacity: _slideUp.value.clamp(0.0, 1.0),
                          child: child),
                    ),
                    child: _PhoneButton(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.phone),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Terms ─────────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Center(
                      child: Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF4A5568).withOpacity(0.45),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone CTA Button ──────────────────────────────────────────────────────────

class _PhoneButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PhoneButton({required this.onTap});

  @override
  State<_PhoneButton> createState() => _PhoneButtonState();
}

class _PhoneButtonState extends State<_PhoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A6DFF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A6DFF).withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container(
              //   padding: const EdgeInsets.all(6),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.18),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: const Icon(Icons.phone_android_rounded,
              //       color: Colors.white, size: 17),
              // ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Phone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Truck Illustration ────────────────────────────────────────────────────────

class _TruckIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 190,
      child: CustomPaint(painter: _TruckPainter()),
    );
  }
}

class _TruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow under truck
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A6DFF).withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.83), width: w * 0.88, height: 55));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.83), width: w * 0.82, height: 24),
      shadowPaint,
    );

    // Road
    final roadPaint = Paint()
      ..color = const Color(0xFFD1DCF0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.80), Offset(w, h * 0.80), roadPaint);

    // Dashed line
    final dashPaint = Paint()
      ..color = const Color(0xFFB8C9E8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < w; x += 20) {
      canvas.drawLine(
          Offset(x, h * 0.80), Offset(x + 10, h * 0.80), dashPaint);
    }

    // Cargo box
    final cargoFill = Paint()
      ..color = const Color(0xFFE8EFFF)
      ..style = PaintingStyle.fill;
    final cargoBorder = Paint()
      ..color = const Color(0xFFB0C4E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cargoRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.62, h * 0.46),
        const Radius.circular(7));
    canvas.drawRRect(cargoRect, cargoFill);
    canvas.drawRRect(cargoRect, cargoBorder);

    // Cargo roof accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.62, h * 0.055),
          const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFF1A6DFF)
        ..style = PaintingStyle.fill,
    );

    // Door lines
    final doorPaint = Paint()
      ..color = const Color(0xFFB0C4E8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.35, h * 0.36), Offset(w * 0.35, h * 0.76),
        doorPaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.53), Offset(w * 0.66, h * 0.53),
        doorPaint);

    // FMP logo on cargo
    final logoPaint = Paint()
      ..color = const Color(0xFF1A6DFF).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.10, h * 0.56, w * 0.18, h * 0.12),
          const Radius.circular(4)),
      logoPaint,
    );

    // Cab
    final cabFill = Paint()
      ..color = const Color(0xFFD8E6FF)
      ..style = PaintingStyle.fill;
    final cabPath = Path()
      ..moveTo(w * 0.66, h * 0.76)
      ..lineTo(w * 0.66, h * 0.42)
      ..quadraticBezierTo(w * 0.66, h * 0.35, w * 0.73, h * 0.34)
      ..lineTo(w * 0.84, h * 0.34)
      ..quadraticBezierTo(w * 0.96, h * 0.36, w * 0.97, h * 0.46)
      ..lineTo(w * 0.97, h * 0.76)
      ..close();

    canvas.drawPath(cabPath, cabFill);
    canvas.drawPath(
        cabPath,
        Paint()
          ..color = const Color(0xFFB0C4E8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Cab window
    final windowPath = Path()
      ..moveTo(w * 0.70, h * 0.44)
      ..lineTo(w * 0.70, h * 0.37)
      ..quadraticBezierTo(w * 0.71, h * 0.36, w * 0.73, h * 0.36)
      ..lineTo(w * 0.83, h * 0.36)
      ..quadraticBezierTo(w * 0.92, h * 0.38, w * 0.93, h * 0.44)
      ..close();

    canvas.drawPath(
        windowPath,
        Paint()
          ..color = const Color(0xFF1A6DFF).withOpacity(0.20)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        windowPath,
        Paint()
          ..color = const Color(0xFF1A6DFF).withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Wheels
    _drawWheel(canvas, Offset(w * 0.20, h * 0.785), 14);
    _drawWheel(canvas, Offset(w * 0.52, h * 0.785), 14);
    _drawWheel(canvas, Offset(w * 0.845, h * 0.785), 12);

    // Headlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.945, h * 0.56, w * 0.035, h * 0.07),
          const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFFFB800)
        ..style = PaintingStyle.fill,
    );

    // Headlight beam
    final beamPath = Path()
      ..moveTo(w * 0.97, h * 0.56)
      ..lineTo(w * 1.07, h * 0.51)
      ..lineTo(w * 1.07, h * 0.67)
      ..lineTo(w * 0.97, h * 0.63)
      ..close();
    canvas.drawPath(
        beamPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFB800).withOpacity(0.20),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(
              Rect.fromLTWH(w * 0.97, h * 0.51, w * 0.10, h * 0.16)));

    // Speed lines
    final speeds = [
      [0.0, h * 0.54, w * 0.025, h * 0.54, 0.35],
      [0.0, h * 0.61, w * 0.05, h * 0.61, 0.20],
      [0.0, h * 0.47, w * 0.035, h * 0.47, 0.28],
    ];
    final speedPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final l in speeds) {
      speedPaint.color =
          const Color(0xFF1A6DFF).withOpacity(l[4] as double);
      canvas.drawLine(Offset(l[0] as double, l[1] as double),
          Offset(l[2] as double, l[3] as double), speedPaint);
    }
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    // Tire
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF3D4F6B)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF8DA8CC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Hub
    canvas.drawCircle(
        center,
        radius * 0.44,
        Paint()
          ..color = const Color(0xFFD8E6FF)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        radius * 0.44,
        Paint()
          ..color = const Color(0xFF1A6DFF).withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    // Center
    canvas.drawCircle(
        center,
        radius * 0.12,
        Paint()
          ..color = const Color(0xFF1A6DFF)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Light Blob ────────────────────────────────────────────────────────────────

class _LightBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _LightBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, const Color(0xFFF5F7FF).withOpacity(0)],
        ),
      ),
    );
  }
}

// ── Diagonal Strip Painter ────────────────────────────────────────────────────

class _DiagonalStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAF0FF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.22)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Dot Grid Painter ──────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A6DFF).withOpacity(0.055)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}