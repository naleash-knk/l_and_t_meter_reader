import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:l_and_t_meter_reader/dashboard/dashboard.dart';
import 'package:l_and_t_meter_reader/home_screen/home_screen.dart';
// import 'package:l_and_t_meter_reader/login_screen/login_screen.dart';
import 'package:provider/provider.dart';

import '../theme_vals.dart';
import '../shared/responsive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bgController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _bgAnimation;
  late Animation<double> _headerOpacityAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _imageOpacityAnimation;
  late Animation<Offset> _imageSlideAnimation;

  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _headerOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _imageOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.9, curve: Curves.easeIn),
    );
    _imageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );

    _bgAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.linear));

    _controller.forward();
    _bgController.repeat();
    _startProgress();
  }

  void _startProgress() {
    final customization = context.read<AppCustomization>();
    final totalMs = customization.splashDuration.inMilliseconds;
    final tickMs = 30;

    Timer.periodic(Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progressValue += tickMs / totalMs;
      });

      if (_progressValue >= 1.0) {
        timer.cancel();

        final isSignedIn = FirebaseAuth.instance.currentUser != null;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isSignedIn ? const DashboardScreen() : const HomeScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final indicatorHeight = context.watch<AppCustomization>().indicatorHeight;
    final sizing = ResponsiveSizing.of(context);
    final logoSize = sizing.scaled(96);
    final headerHeight = sizing.scaled(96);
    final headerAccentWidth = sizing.scaled(140);
    final headerAccentHeight = sizing.scaled(130);
    final topSpacing = sizing.scaled(12);
    final horizontalPadding = sizing.scaled(20);
    final progressPadding = sizing.scaled(24);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgAnimation.value;
              return CustomPaint(
                painter: _SplashBackgroundPainter(
                  t: t,
                  primary: scheme.primary,
                  onSurface: scheme.onSurface,
                  isDark: theme.brightness == Brightness.dark,
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: topSpacing),
                const Spacer(),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(sizing.scaled(20)),
                        child: Image.asset(
                          AppThemeTokens.logoAssetPath,
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _imageOpacityAnimation,
                  child: SlideTransition(
                    position: _imageSlideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Container(
                        padding: EdgeInsets.all(sizing.scaled(12)),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(sizing.scaled(22)),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: sizing.scaled(16),
                              offset: Offset(0, sizing.scaled(8)),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(sizing.scaled(16)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  AppThemeTokens.splashImageAssetPath,
                                  fit: BoxFit.cover,
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Container(
                                    height: sizing.scaled(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          scheme.primary,
                                          scheme.primary.withValues(alpha: 0.2),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _headerOpacityAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Stack(
                        children: [
                          Container(
                            height: headerHeight,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(sizing.scaled(18)),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFBFC4C9),
                                  Color(0xFFE8EAED),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(sizing.scaled(18)),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Transform.rotate(
                                      angle: -0.08,
                                      child: Container(
                                        width: headerAccentWidth,
                                        height: headerAccentHeight,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              scheme.primary.withValues(alpha: 0.55),
                                              scheme.primary.withValues(alpha: 0.15),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: sizing.scaled(10),
                                    left: sizing.scaled(12),
                                    child: const _RivetDot(),
                                  ),
                                  Positioned(
                                    top: sizing.scaled(10),
                                    right: sizing.scaled(12),
                                    child: const _RivetDot(),
                                  ),
                                  Positioned(
                                    bottom: sizing.scaled(10),
                                    left: sizing.scaled(12),
                                    child: const _RivetDot(),
                                  ),
                                  Positioned(
                                    bottom: sizing.scaled(10),
                                    right: sizing.scaled(12),
                                    child: const _RivetDot(),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      sizing.scaled(18),
                                      sizing.scaled(14),
                                      sizing.scaled(18),
                                      sizing.scaled(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'FORMWORK UNIT - METALSHOP',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: const Color(0xFF1B1E22),
                                          ),
                                        ),
                                        SizedBox(height: sizing.scaled(8)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: sizing.scaled(12),
                                            vertical: sizing.scaled(6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1B1E22),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Puducherry',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              letterSpacing: 0.8,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
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
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    progressPadding,
                    0,
                    progressPadding,
                    progressPadding,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: indicatorHeight,
                      child: LinearProgressIndicator(
                        value: _progressValue.clamp(0.0, 1.0),
                        backgroundColor: scheme.primary.withValues(alpha: 0.20),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  _SplashBackgroundPainter({
    required this.t,
    required this.primary,
    required this.onSurface,
    required this.isDark,
  });

  final double t;
  final Color primary;
  final Color onSurface;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: isDark ? 0.28 : 0.16),
          primary.withValues(alpha: isDark ? 0.10 : 0.06),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final dotPaint = Paint()
      ..color = onSurface.withValues(alpha: isDark ? 0.08 : 0.06);
    final accentPaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.14 : 0.10);

    final shortest = size.shortestSide;
    final r1 = shortest * 0.14;
    final r2 = shortest * 0.18;
    final r3 = shortest * 0.12;

    final y1 = size.height * 0.22;
    final y2 = size.height * 0.48;
    final y3 = size.height * 0.76;

    final xTravel = size.width * 1.2;
    final x0 = -size.width * 0.2;

    final x1 = x0 + (t * xTravel);
    final x2 = x0 + (((t + 0.33) % 1.0) * xTravel);
    final x3 = x0 + (((t + 0.66) % 1.0) * xTravel);

    canvas.drawCircle(Offset(x1, y1), r1, accentPaint);
    canvas.drawCircle(Offset(x2, y2), r2, dotPaint);
    canvas.drawCircle(Offset(x3, y3), r3, accentPaint);

    // subtle moving lines
    final linePaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.10 : 0.08)
      ..strokeWidth = (shortest * 0.004).clamp(1.5, 3.0);

    for (var i = 0; i < 5; i++) {
      final yy = size.height * (0.18 + 0.16 * i);
      final offset = ((t + i * 0.12) % 1.0) * size.width;
      canvas.drawLine(
        Offset(-size.width + offset, yy),
        Offset(offset, yy),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primary != primary ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.isDark != isDark;
  }
}

class _RivetDot extends StatelessWidget {
  const _RivetDot();

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing.of(context);
    final dotSize = sizing.scaled(10);
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: const Color(0xFF7B7F85),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: sizing.scaled(1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: sizing.scaled(2),
            offset: Offset(0, sizing.scaled(1)),
          ),
        ],
      ),
    );
  }
}
