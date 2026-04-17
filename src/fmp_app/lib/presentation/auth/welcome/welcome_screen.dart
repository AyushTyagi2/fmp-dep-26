import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_router.dart';
import '../auth_controller.dart';

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
    final auth = context.read<AuthController>();

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

                  const SizedBox(height: 36),

                  // ── Email OTP button ──────────────────────────────────────
                  AnimatedBuilder(
                    animation: _slideUp,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 40 * (1 - _slideUp.value)),
                      child: Opacity(
                          opacity: _slideUp.value.clamp(0.0, 1.0),
                          child: child),
                    ),
                    child: _EmailButton(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.email),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Divider ───────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF4A5568).withOpacity(0.18),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: const Color(0xFF4A5568).withOpacity(0.45),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF4A5568).withOpacity(0.18),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Google Sign-In button ─────────────────────────────────
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _GoogleButton(
                      onTap: () async {
                        await auth.signInWithGoogle(context);
                      },
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

// ── Email OTP Button ──────────────────────────────────────────────────────────

class _EmailButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EmailButton({required this.onTap});

  @override
  State<_EmailButton> createState() => _EmailButtonState();
}

class _EmailButtonState extends State<_EmailButton>
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Email',
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

// ── Google Sign-In Button ─────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
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
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" logo drawn with coloured text
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const _GoogleLogo(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFF1A202C),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    // Simple multicolour "G" using a CustomPainter
    return CustomPaint(painter: _GoogleGPainter(), size: const Size(28, 28));
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    final colors = [
      const Color(0xFF4285F4), // blue
      const Color(0xFF34A853), // green
      const Color(0xFFFBBC05), // yellow
      const Color(0xFFEA4335), // red
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    // Draw 4 arcs (blue top-right, green bottom-right, yellow bottom-left, red top-left)
    final sweeps = [
      [0.0, 90.0],
      [90.0, 90.0],
      [180.0, 90.0],
      [270.0, 90.0],
    ];

    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        sweeps[i][0] * 3.14159 / 180,
        sweeps[i][1] * 3.14159 / 180,
        false,
        paint,
      );
    }

    // Horizontal bar for the "G" cutout
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    final roadPaint = Paint()
      ..color = const Color(0xFFD1DCF0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.80), Offset(w, h * 0.80), roadPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFFB8C9E8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < w; x += 20) {
      canvas.drawLine(
          Offset(x, h * 0.80), Offset(x + 10, h * 0.80), dashPaint);
    }

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.62, h * 0.055),
          const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFF1A6DFF)
        ..style = PaintingStyle.fill,
    );

    final doorPaint = Paint()
      ..color = const Color(0xFFB0C4E8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.35, h * 0.36), Offset(w * 0.35, h * 0.76),
        doorPaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.53), Offset(w * 0.66, h * 0.53),
        doorPaint);

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

    _drawWheel(canvas, Offset(w * 0.20, h * 0.785), 14);
    _drawWheel(canvas, Offset(w * 0.52, h * 0.785), 14);
    _drawWheel(canvas, Offset(w * 0.845, h * 0.785), 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.945, h * 0.56, w * 0.035, h * 0.07),
          const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFFFB800)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius,
        Paint()
          ..color = const Color(0xFF3D4F6B)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius,
        Paint()
          ..color = const Color(0xFF8DA8CC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.drawCircle(center, radius * 0.44,
        Paint()
          ..color = const Color(0xFFD8E6FF)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius * 0.12,
        Paint()
          ..color = const Color(0xFF1A6DFF)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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