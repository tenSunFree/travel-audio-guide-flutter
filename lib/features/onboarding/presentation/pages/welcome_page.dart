import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/onboarding_providers.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tile1Fade;
  late final Animation<double> _tile2Fade;
  late final Animation<double> _tile3Fade;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  bool _isLoading = false;
  static const _teal = Color(0xFF007F83);
  static const _background = Color(0xFFF4FBFB);
  static const _textDark = Color(0xFF1F3A3D);
  static const _textSoft = Color(0xFF5F7F82);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
          ),
        );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
          ),
        );
    _tile1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _tile2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _tile3Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _StaticMapBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: const _HeroCard(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Column(
                        children: [
                          Text(
                            '聽見台北的城市故事',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '收藏景點、下載語音導覽，\n把想去的活動變成你的旅程清單。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _textSoft,
                              fontSize: 14,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _tile1Fade,
                    child: const _FeatureTile(
                      icon: Icons.headphones_rounded,
                      title: '語音導覽',
                      description: '邊走邊聽景點故事',
                      badgeText: 'Audio',
                      accentColor: Color(0xFF007F83),
                      accentBg: Color(0xFFEAF7F7),
                    ),
                  ),
                  const SizedBox(height: 9),
                  FadeTransition(
                    opacity: _tile2Fade,
                    child: const _FeatureTile(
                      icon: Icons.download_done_rounded,
                      title: '離線播放',
                      description: '下載後沒有網路也能聽',
                      badgeText: 'Offline',
                      accentColor: Color(0xFF9E6A00),
                      accentBg: Color(0xFFFFF3D6),
                    ),
                  ),
                  const SizedBox(height: 9),
                  FadeTransition(
                    opacity: _tile3Fade,
                    child: const _FeatureTile(
                      icon: Icons.notifications_active_rounded,
                      title: '活動提醒',
                      description: '展覽、活動時間不再錯過',
                      badgeText: 'Reminder',
                      accentColor: Color(0xFFB03A20),
                      accentBg: Color(0xFFFFF0EB),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _onStart,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.explore_outlined),
                          label: Text(
                            _isLoading ? '準備中...' : '開始探索',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  static const _teal = Color(0xFF007F83);
  static const _lightTeal = Color(0xFFBFEDEE);
  static const _lightTealBg = Color(0xFFEAF7F7);
  static const _yellow = Color(0xFFFFD66B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _lightTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.13),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 16,
            top: 14,
            child: Icon(Icons.auto_awesome_rounded, color: _yellow, size: 18),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: _yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 28,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _lightTealBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            child: SizedBox(
              width: 48,
              height: 68,
              child: CustomPaint(painter: _Taipei101Painter()),
            ),
          ),
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'TAIPEI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function cards: icon + title + description + badge
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.accentColor,
    required this.accentBg,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badgeText;
  final Color accentColor;
  final Color accentBg;
  static const _textDark = Color(0xFF1F3A3D);
  static const _textSoft = Color(0xFF5F7F82);
  static const _cardBorder = Color(0xFFD8F0F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: _textSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticMapBackground extends StatelessWidget {
  const _StaticMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StaticMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StaticMapPainter extends CustomPainter {
  final _routePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final _dotPaint = Paint()..style = PaintingStyle.fill;
  final _sparklePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    _routePaint.color = const Color(0xFF007F83).withValues(alpha: 0.07);
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.08,
        size.width * 0.76,
        size.height * 0.26,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.42,
        size.width * 0.64,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.74,
        size.width * 0.16,
        size.height * 0.64,
      );
    canvas.drawPath(path, _routePaint);
    _dotPaint.color = const Color(0xFF007F83).withValues(alpha: 0.11);
    for (final pt in [
      Offset(size.width * 0.10, size.height * 0.20),
      Offset(size.width * 0.44, size.height * 0.10),
      Offset(size.width * 0.76, size.height * 0.26),
      Offset(size.width * 0.64, size.height * 0.56),
      Offset(size.width * 0.18, size.height * 0.64),
    ]) {
      canvas.drawCircle(pt, 5, _dotPaint);
    }
    _sparklePaint.color = const Color(0xFFFFD66B).withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.16),
      5.5,
      _sparklePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.82),
      4.0,
      _sparklePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.68),
      3.5,
      _sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Taipei101Painter extends CustomPainter {
  const _Taipei101Painter();

  static const _teal = Color(0xFF007F83);
  static const _lightTeal = Color(0xFFBFEDEE);

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = _teal
      ..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..color = _lightTeal
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..lineTo(cx - 3.5, 11)
        ..lineTo(cx + 3.5, 11)
        ..close(),
      bodyPaint,
    );
    final floors = [
      _floor(cx, 17, 20, 9),
      _floor(cx, 28, 28, 9),
      _floor(cx, 39, 36, 9),
      _floor(cx, 50, 44, 9),
    ];
    for (final f in floors) {
      canvas.drawRRect(f, bodyPaint);
    }
    canvas.drawRRect(_floor(cx, 62, 26, 7), bodyPaint);
    for (final y in [17.0, 28.0, 39.0, 50.0]) {
      canvas.drawCircle(Offset(cx - 5, y), 1.5, accentPaint);
      canvas.drawCircle(Offset(cx + 5, y), 1.5, accentPaint);
    }
  }

  RRect _floor(double cx, double cy, double w, double h) {
    return RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
