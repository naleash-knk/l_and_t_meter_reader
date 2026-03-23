import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../theme_vals.dart';
import '../shared/activity_log_service.dart';
import '../shared/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _emailTouched = false;
  bool _passwordTouched = false;

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customization = context.watch<AppCustomization>();
    final navigator = Navigator.of(context);
    final sizing = ResponsiveSizing.of(context);
    final maxWidth = (sizing.width * 0.92).clamp(320.0, 520.0);

    final isDark =
        customization.themeMode == ThemeMode.dark ||
        (customization.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final toggleIconColor = isDark ? scheme.onSurface : scheme.primary;

    Future<void> onSubmit() async {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
      if (_submitting) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _submitting = true);
      try {
        FocusScope.of(context).unfocus();
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final user = credential.user;
        if (user != null) {
          final userEntryCandidate =
              (user.displayName ?? user.email ?? '').trim();
          final userEntry =
              userEntryCandidate.isEmpty ? 'Unknown' : userEntryCandidate;
          await ActivityLogService().logEvent(
            type: 'login',
            title: 'User login',
            message: '$userEntry logged in.',
            actorUid: user.uid,
            actorName: userEntry,
            actorEmail: user.email ?? '',
          );
        }
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        navigator.pushReplacementNamed('/Dashboard');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface,
                  scheme.surface,
                  scheme.primary.withValues(alpha: isDark ? 0.10 : 0.07),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(sizing.scaled(20)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
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
                                tooltip: isDark ? 'Light mode' : 'Dark mode',
                                onPressed: () {
                                  context.read<AppCustomization>().setThemeMode(
                                    isDark ? ThemeMode.light : ThemeMode.dark,
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
                      SizedBox(height: sizing.scaled(12)),
                      Text(
                        'FORMWORK UNIT-METALSHOP',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: sizing.scaled(6)),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                      SizedBox(height: sizing.scaled(18)),
                      Container(
                        padding: EdgeInsets.all(sizing.scaled(18)),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(sizing.scaled(22)),
                          border: Border.all(
                            color: scheme.onSurface.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.disabled,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                onTap: () {
                                  if (_emailTouched) return;
                                  setState(() => _emailTouched = true);
                                },
                                onChanged: (_) {
                                  if (!_emailTouched) return;
                                  _formKey.currentState?.validate();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) {
                                  if (!_emailTouched) return null;
                                  final v = (value ?? '').trim();
                                  if (v.isEmpty) return 'Enter your email';
                                  final ok = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(v);
                                  if (!ok) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              SizedBox(height: sizing.scaled(14)),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => onSubmit(),
                                onTap: () {
                                  if (_passwordTouched) return;
                                  setState(() => _passwordTouched = true);
                                },
                                onChanged: (_) {
                                  if (!_passwordTouched) return;
                                  _formKey.currentState?.validate();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_passwordTouched) return null;
                                  final v = (value ?? '');
                                  if (v.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  if (v.length < 6) {
                                    return 'Password is too short';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: sizing.scaled(18)),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: sizing.scaled(16),
                                    ),
                                    textStyle: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: _submitting ? null : onSubmit,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _submitting
                                        ? SizedBox(
                                            height: sizing.scaled(22),
                                            width: sizing.scaled(22),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.6,
                                            ),
                                          )
                                        : const Text('Login'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: sizing.scaled(14)),
                      Text(
                        '',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
