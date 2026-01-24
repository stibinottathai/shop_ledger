import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slow spin
    )..repeat();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Artificial delay to show splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (mounted) {
        if (seenOnboarding) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    }
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgLight = Colors.white; // background-light
    final bgDark = const Color(0xFF0F172A); // background-dark
    final textMain = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Stack(
        children: [
          // Background Gradient Blur (Top Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withOpacity(0.05), // Green-50ish
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar (Time & Status Icons mockup)
                    // In a real app we typically don't draw the status bar content manually
                    // unless it's a fullscreen game or specialized UI.
                    // The design requested shows it, but usually we let the OS handle it.
                    // I'll skip drawing fake status bar icons to avoid overlap with real OS status bar.
                    const SizedBox(height: 1), // Spacer
                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with Glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 256,
                              height: 256,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF22C55E).withOpacity(0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7],
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B).withOpacity(0.5)
                                    : const Color(0xFFF0FDF4), // Green-50
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFDCFCE7), // Green-100
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded, // Ledger icon style
                                size: 48,
                                color: Color(0xFF22C55E), // Primary Green
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Shop Ledger',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Content
                    Column(
                      children: [
                        // Gradient Spinner
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: AnimatedBuilder(
                            animation: _spinnerController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _spinnerController.value * 2 * math.pi,
                                child: CustomPaint(
                                  painter: _GradientSpinnerPainter(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Efficient. Simple. Professional.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'VERSION 2.4.0 • ENTERPRISE EDITION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textMuted.withOpacity(0.6),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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

class _GradientSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 3.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepGradient = const SweepGradient(
      colors: [
        Color(0xFF22C55E), // Green
        Color(0xFFF59E0B), // Amber
        Color(0xFF22C55E), // Green
      ],
      stops: [0.0, 0.5, 1.0],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    paint.shader = sweepGradient;

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
