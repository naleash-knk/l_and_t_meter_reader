import 'package:flutter/material.dart';
import 'package:l_and_t_meter_reader/login_screen/login_screen.dart';
import 'package:provider/provider.dart';

import '../theme_vals.dart';
import '../shared/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bgT;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgT = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customization = context.watch<AppCustomization>();
    final sizing = ResponsiveSizing.of(context);

    final isDark =
        customization.themeMode == ThemeMode.dark ||
        (customization.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final toggleIconColor = isDark ? scheme.onSurface : scheme.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgT,
            builder: (context, _) {
              return CustomPaint(
                painter: _HomeBackgroundPainter(
                  t: _bgT.value,
                  primary: scheme.primary,
                  onSurface: scheme.onSurface,
                  isDark: isDark,
                ),
              );
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    (constraints.maxWidth * 0.9).clamp(280.0, 520.0);
                final imageHeight =
                    (constraints.maxHeight * 0.35).clamp(220.0, 320.0);
                final topSpacing =
                    (constraints.maxHeight * 0.04).clamp(12.0, 28.0);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(sizing.scaled(20)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: contentWidth,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: sizing.scaled(56),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      AppThemeTokens.logoAssetPath,
                                      height: sizing.scaled(44),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      tooltip:
                                          isDark ? 'Light mode' : 'Dark mode',
                                      onPressed: () {
                                        context
                                            .read<AppCustomization>()
                                            .setThemeMode(
                                              isDark
                                                  ? ThemeMode.light
                                                  : ThemeMode.dark,
                                            );
                                      },
                                      icon: Icon(
                                        isDark
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                        color: toggleIconColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: topSpacing),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOut,
                              builder: (context, t, child) {
                                return Opacity(
                                  opacity: t,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - t) * 10),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                'FORMWORK UNIT-METALSHOP',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            SizedBox(height: sizing.scaled(16)),
                            SizedBox(
                              height: imageHeight,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.94, end: 1.0),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutBack,
                                builder: (context, t, child) {
                                  return Transform.scale(scale: t, child: child);
                                },
                                child: Center(
                                  child: Image.asset(
                                    'assets/illustrator/illustrator.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: sizing.scaled(12)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  foregroundColor:
                                      isDark ? scheme.onSurface : null,
                                  padding:
                                      EdgeInsets.symmetric(vertical: sizing.scaled(16)),
                                  textStyle:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            ),
                            SizedBox(height: topSpacing),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  _HomeBackgroundPainter({
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
    canvas.drawRect(rect, Paint()..color = Colors.transparent);

    final softPrimary = primary.withValues(alpha: isDark ? 0.28 : 0.10);
    final softSurface = onSurface.withValues(alpha: isDark ? 0.10 : 0.04);

    final c1 = Offset(size.width * (0.20 + 0.06 * t), size.height * 0.22);
    final c2 = Offset(
      size.width * (0.85 - 0.08 * t),
      size.height * (0.30 + 0.05 * t),
    );
    final c3 = Offset(size.width * 0.55, size.height * (0.92 - 0.05 * t));

    final p1 = Paint()..color = softPrimary;
    final p2 = Paint()..color = softSurface;

    canvas.drawCircle(c1, size.shortestSide * 0.42, p1);
    canvas.drawCircle(c2, size.shortestSide * 0.30, p2);
    canvas.drawCircle(c3, size.shortestSide * 0.36, p1);
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primary != primary ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.isDark != isDark;
  }
}
