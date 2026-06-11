import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dayOpacity;
  late final Animation<double> _nightOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _dayOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _nightOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dayOpacity = _dayOpacity.value;
        final nightOpacity = _nightOpacity.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Дневной фон
            Opacity(
              opacity: dayOpacity,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6), Color(0xFFF0F8FF)],
                  ),
                ),
              ),
            ),
            // Ночной фон
            Opacity(
              opacity: nightOpacity,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B0E21), Color(0xFF1B1E3B), Color(0xFF2D2F54)],
                  ),
                ),
              ),
            ),
            // Солнце (днём)
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.1,
              child: Opacity(
                opacity: dayOpacity,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.yellow, blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                ),
              ),
            ),
            // Луна (ночью)
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.1,
              child: Opacity(
                opacity: nightOpacity,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8DC),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 15, spreadRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
            // Звёзды (ночью)
            if (nightOpacity > 0)
              ...List.generate(30, (i) {
                final random = Random(i * 42);
                final x = random.nextDouble() * size.width;
                final y = random.nextDouble() * size.height * 0.7;
                final r = 2.0 + random.nextDouble() * 3;
                final opacity = 0.4 + random.nextDouble() * 0.6;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: nightOpacity * opacity,
                    child: Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            // Облака (днём)
            if (dayOpacity > 0)
              ..._buildClouds(size, dayOpacity),
            // Надпись "Загрузка..." по центру
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dayOpacity > 0.5 ? Icons.wb_sunny : Icons.nightlight_round,
                    size: 64,
                    color: (dayOpacity > 0.5) ? Colors.orange : Colors.white70,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Загрузка...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: (dayOpacity > 0.5) ? Colors.black87 : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildClouds(Size size, double opacity) {
    return [
      Positioned(
        left: size.width * 0.2,
        top: size.height * 0.2,
        child: Opacity(
          opacity: opacity * 0.7,
          child: Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      Positioned(
        left: size.width * 0.55,
        top: size.height * 0.35,
        child: Opacity(
          opacity: opacity * 0.6,
          child: Container(
            width: 130,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
      Positioned(
        left: size.width * 0.4,
        top: size.height * 0.5,
        child: Opacity(
          opacity: opacity * 0.5,
          child: Container(
            width: 90,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      ),
    ];
  }
}