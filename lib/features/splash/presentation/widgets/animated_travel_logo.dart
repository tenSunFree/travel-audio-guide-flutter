import 'package:flutter/material.dart';

class AnimatedTravelLogo extends StatefulWidget {
  const AnimatedTravelLogo({super.key});

  @override
  State<AnimatedTravelLogo> createState() => _AnimatedTravelLogoState();
}

class _AnimatedTravelLogoState extends State<AnimatedTravelLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  static const _teal = Color(0xFF007F83);
  static const _lightTeal = Color(0xFFBFEDEE);
  static const _yellow = Color(0xFFFFD66B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.18, end: 0.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      child: _buildCard(),
      builder: (_, staticChild) {
        return SizedBox(
          width: 170,
          height: 158,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withValues(alpha: _pulseOpacity.value),
                  ),
                ),
              ),
              staticChild!,
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withValues(alpha: 0.25),
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      width: 118,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _lightTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            top: 16,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            right: 12,
            top: 12,
            child: Icon(Icons.auto_awesome_rounded, color: _yellow, size: 16),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _lightTeal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            top: 16,
            bottom: 16,
            child: Icon(Icons.location_on_rounded, color: _teal, size: 44),
          ),
        ],
      ),
    );
  }
}
