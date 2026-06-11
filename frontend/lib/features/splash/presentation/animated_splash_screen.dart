import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const AnimatedSplashScreen({super.key, required this.nextScreen});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // общая длительность анимации загрузки
    )..repeat(); // повторяем, пока не загрузится

    // Имитация загрузки: через 2.5 секунды переходим к главному экрану
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
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
      builder: (context, child) {
        return CustomPaint(
          painter: _SplashPainter(_controller.value),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Можно добавить логотип или текст заведения по центру
                Icon(Icons.restaurant, size: 80, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Загрузка...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double time;
  _SplashPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = (time % 2) < 1; // первые полсекунды цикла – день, вторые – ночь (упрощённо)
    _drawSky(canvas, size, isDark);
    _drawGround(canvas, size);
    if (isDark) {
      _drawNightElements(canvas, size);
    } else {
      _drawDayElements(canvas, size);
    }
  }

  void _drawSky(Canvas canvas, Size size, bool isDark) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0B0E21), const Color(0xFF1B1E3B), const Color(0xFF2D2F54)]
            : [const Color(0xFF87CEEB), const Color(0xFFB0E0E6), const Color(0xFFF0F8FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = const Color(0xFF4CAF50);
    final groundHeight = size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - groundHeight, size.width, groundHeight),
      groundPaint,
    );
    // Простые домики-рестораны
    _drawBuilding(canvas, size.width * 0.2, size.height - groundHeight, 40, 50);
    _drawBuilding(canvas, size.width * 0.5, size.height - groundHeight, 60, 70);
    _drawBuilding(canvas, size.width * 0.8, size.height - groundHeight, 50, 55);
  }

  void _drawBuilding(Canvas canvas, double left, double bottom, double width, double height) {
    final buildingPaint = Paint()..color = const Color(0xFF795548);
    final roofPaint = Paint()..color = const Color(0xFF5D4037);
    // стены
    canvas.drawRect(Rect.fromLTWH(left, bottom - height, width, height), buildingPaint);
    // крыша
    final path = Path();
    path.moveTo(left - 10, bottom - height);
    path.lineTo(left + width / 2, bottom - height - 20);
    path.lineTo(left + width + 10, bottom - height);
    path.close();
    canvas.drawPath(path, roofPaint);
    // окно
    final windowPaint = Paint()..color = Colors.yellow.withOpacity(0.7);
    canvas.drawRect(
      Rect.fromLTWH(left + width * 0.2, bottom - height + 10, width * 0.3, height * 0.3),
      windowPaint,
    );
    // вывеска
    final signPaint = Paint()..color = Colors.orange;
    canvas.drawRect(
      Rect.fromLTWH(left + 5, bottom - height + 5, width - 10, 8),
      signPaint,
    );
  }

  void _drawDayElements(Canvas canvas, Size size) {
    // Солнце
    final sunPaint = Paint()..color = Colors.yellow.withOpacity(0.8);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      30,
      sunPaint,
    );
    // Облака
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + 0.3 * i) + time * 15 * size.width % (size.width + 200) - 100;
      final y = size.height * 0.15 + 20 * i;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 120, height: 40), cloudPaint);
    }
  }

  void _drawNightElements(Canvas canvas, Size size) {
    final random = Random(42);
    // Луна
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      25,
      Paint()..color = const Color(0xFFFFF8DC).withOpacity(0.8),
    );
    // Звёзды
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;
      final radius = 1.5 + random.nextDouble() * 2;
      final opacity = 0.3 + 0.5 * sin(time * 5 + i);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}