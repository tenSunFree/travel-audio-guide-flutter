import 'dart:math' as math;
import 'package:flutter/material.dart';

class CityParticlesBackground extends StatefulWidget {
  const CityParticlesBackground({super.key});

  @override
  State<CityParticlesBackground> createState() =>
      _CityParticlesBackgroundState();
}

class _CityParticlesBackgroundState extends State<CityParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static final _dots = _generateDots();

  static List<_MapDot> _generateDots() {
    final rng = math.Random(10);
    return List.generate(18, (_) {
      return _MapDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 3.0 + rng.nextDouble() * 4.0,
        phase: rng.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _MapBackgroundPainter(
          dots: _dots,
          progress: _controller.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  _MapBackgroundPainter({required this.dots, required this.progress});

  final List<_MapDot> dots;
  final double progress;
  final _routePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  final _dotPaint = Paint()..style = PaintingStyle.fill;
  final _starPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    _routePaint.color = const Color(0xFF007F83).withOpacity(0.10);
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.12,
        size.width * 0.68,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.44,
        size.width * 0.62,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.78,
        size.width * 0.18,
        size.height * 0.66,
      );
    canvas.drawPath(path, _routePaint);
    _dotPaint.color = const Color(0xFF007F83).withOpacity(0.18);
    for (final offset in [0.0, 0.3, 0.6, 1.0]) {
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length * offset);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3, _dotPaint);
      }
    }
    for (final dot in dots) {
      final opacity =
          0.12 +
          0.22 * ((math.sin(progress * math.pi * 2 + dot.phase) + 1) / 2);
      _dotPaint.color = const Color(0xFF007F83).withOpacity(opacity);
      canvas.drawCircle(
        Offset(dot.x * size.width, dot.y * size.height),
        dot.size,
        _dotPaint,
      );
    }
    _starPaint.color = const Color(0xFFFFD66B).withOpacity(0.30);
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.18),
      5.5,
      _starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.80),
      4.0,
      _starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.62),
      3.5,
      _starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.38),
      3.0,
      _starPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapBackgroundPainter old) =>
      old.progress != progress;
}

class _MapDot {
  const _MapDot({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double phase;
}
