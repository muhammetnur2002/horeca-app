import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: isDark
            ? const Color(0xFF1A1C2B).withOpacity(0.8)
            : const Color(0xFF87CEEB).withOpacity(0.8),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Фон (градиент)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0B0E21), const Color(0xFF1B1E3B), const Color(0xFF2D2F54)]
                      : [const Color(0xFF87CEEB), const Color(0xFFB0E0E6), const Color(0xFFF0F8FF)],
                ),
              ),
            ),
          ),

          // Солнце (светлая тема)
          if (!isDark)
            Positioned(
              top: 40,
              right: 40,
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

          // Луна (тёмная тема)
          if (isDark)
            Positioned(
              top: 40,
              right: 40,
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8DC).withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),

          // Звёзды (тёмная тема)
          if (isDark)
            ...List.generate(30, (i) {
              final random = Random(i * 42);
              final x = random.nextDouble() * MediaQuery.of(context).size.width;
              final y = random.nextDouble() * MediaQuery.of(context).size.height * 0.7;
              final size = 2.0 + random.nextDouble() * 4;
              final opacity = 0.4 + random.nextDouble() * 0.6;
              return Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: opacity,
                  child: Icon(Icons.star, size: size, color: Colors.white),
                ),
              );
            }),

          // Пушистые облака (светлая тема)
          if (!isDark) ...[
            _FluffyCloud(left: 0.1, top: 0.12, scale: 1.0),
            _FluffyCloud(left: 0.55, top: 0.22, scale: 1.3),
            _FluffyCloud(left: 0.35, top: 0.38, scale: 0.8),
          ],

          // Кнопки
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BigButton(
                      icon: Icons.assignment,
                      label: l10n.makeRequest,
                      isDark: isDark,
                      onTap: () => context.push('/request'),
                    ),
                    const SizedBox(height: 24),
                    _BigButton(
                      icon: Icons.inventory,
                      label: l10n.inventory,
                      isDark: isDark,
                      onTap: () => context.push('/inventory'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Пушистое облако
class _FluffyCloud extends StatelessWidget {
  final double left;
  final double top;
  final double scale;

  const _FluffyCloud({
    required this.left,
    required this.top,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: screenWidth * left,
      top: screenHeight * top,
      child: Opacity(
        opacity: 0.8,
        child: SizedBox(
          width: 140 * scale,
          height: 70 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 30 * scale,
                top: 15 * scale,
                child: Container(
                  width: 80 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40 * scale),
                  ),
                ),
              ),
              Positioned(
                left: 10 * scale,
                top: 25 * scale,
                child: Container(
                  width: 60 * scale,
                  height: 35 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35 * scale),
                  ),
                ),
              ),
              Positioned(
                left: 70 * scale,
                top: 25 * scale,
                child: Container(
                  width: 60 * scale,
                  height: 35 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35 * scale),
                  ),
                ),
              ),
              Positioned(
                left: 40 * scale,
                top: 0 * scale,
                child: Container(
                  width: 50 * scale,
                  height: 30 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30 * scale),
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

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _BigButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 128,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? Colors.orange.shade700.withOpacity(0.9)
              : const Color(0xFF2E4A3A).withOpacity(0.9),
          foregroundColor: Colors.white,
          textStyle: Theme.of(context).textTheme.headlineLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          shadowColor: isDark ? Colors.orange.withOpacity(0.5) : const Color(0xFF2E4A3A).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42),
            const SizedBox(width: 16),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}