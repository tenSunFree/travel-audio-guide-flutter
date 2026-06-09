import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../onboarding/di/onboarding_providers.dart';
import '../widgets/animated_travel_logo.dart';
import '../widgets/city_particles_background.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _backgroundFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _backgroundFade = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
        );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _titleFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          ),
        );
    _subtitleFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
    );
  }

  Future<void> _runSequence() async {
    try {
      _backgroundController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _logoController.forward().orCancel;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _textController.forward().orCancel;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      final hasSeenWelcome = ref.read(onboardingProvider);
      context.go(hasSeenWelcome ? AppRoutes.home : AppRoutes.welcome);
    } on TickerCanceled {
      // Widget is disposed of early (unit test or fast return), normally ignored.
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: FadeTransition(
        opacity: _backgroundFade,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4FBFB), Color(0xFFEAF7F7), Color(0xFFF8FFFE)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const RepaintBoundary(child: CityParticlesBackground()),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SlideTransition(
                        position: _logoSlide,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const AnimatedTravelLogo(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: const Text(
                            '台北旅遊導覽',
                            style: TextStyle(
                              color: Color(0xFF1F3A3D),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: const Text(
                          '聽見城市的故事',
                          style: TextStyle(
                            color: Color(0xFF5F8A8D),
                            fontSize: 15,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
