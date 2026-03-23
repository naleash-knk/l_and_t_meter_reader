import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../theme_vals.dart';
import '../shared/app_drawer.dart';
import '../shared/drawer_swipe_wrapper.dart';
import '../shared/activity_log_service.dart';
import '../shared/responsive.dart';

class AccountCreationScreen extends StatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  String? _submitError;

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Account created successfully.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountsDialog() async {
    if (!mounted) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Not signed in'),
            content: const Text(
              'Sign in or create an account to view account details.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(200)
          .get();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          final docs = snapshot.docs;
          return AlertDialog(
            title: const Text('Created accounts'),
            content: SizedBox(
              width: double.maxFinite,
              child: docs.isEmpty
                  ? const Text('No accounts found.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final name = (data['name'] as String?)?.trim();
                        final email = (data['email'] as String?)?.trim();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (name != null && name.isNotEmpty)
                                ? name
                                : '(no name)',
                          ),
                          subtitle: Text(email ?? ''),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unable to load accounts'),
          content: Text(e.message ?? 'Missing or insufficient permissions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customization = context.watch<AppCustomization>();
    final sizing = ResponsiveSizing.of(context);
    final maxWidth = (sizing.width * 0.92).clamp(320.0, 520.0);

    final isDark =
        customization.themeMode == ThemeMode.dark ||
        (customization.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    final toggleIconColor = isDark ? scheme.onSurface : scheme.primary;

    Future<void> onSubmit() async {
      setState(() {
        _nameTouched = true;
        _emailTouched = true;
        _passwordTouched = true;
        _confirmPasswordTouched = true;
      });

      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
      if (_submitting) return;

      setState(() => _submitError = null);

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final creator = FirebaseAuth.instance.currentUser;
      final creatorNameCandidate =
          (creator?.displayName ?? creator?.email ?? '').trim();
      final creatorName =
          creatorNameCandidate.isEmpty ? 'Unknown' : creatorNameCandidate;
      final creatorEmail = (creator?.email ?? '').trim();

      final navigator = Navigator.of(context);
      setState(() => _submitting = true);
      try {
        FocusScope.of(context).unfocus();
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = credential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-null',
            message: 'Account created but user is unavailable.',
          );
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await user.updateDisplayName(name);
        final activityLog = ActivityLogService();
        await activityLog.logEvent(
          type: 'user_created',
          title: 'Account created',
          message: '$creatorName created an account for $name.',
          actorUid: creator?.uid ?? user.uid,
          actorName: creatorName,
          actorEmail: creatorEmail,
          subjectUid: user.uid,
          subjectName: name,
          subjectEmail: email,
          metadata: {
            'createdByUid': creator?.uid ?? user.uid,
          },
        );
        await activityLog.logEvent(
          type: 'user_welcome',
          title: 'Welcome $name',
          message: 'Welcome to FORMWORK UNIT-METALSHOP, $name!',
          actorUid: user.uid,
          actorName: name.isEmpty ? 'New user' : name,
          actorEmail: email,
          subjectUid: user.uid,
          subjectName: name,
          subjectEmail: email,
        );

        if (!mounted) return;
        await _showSuccessDialog();
        if (!mounted) return;
        navigator.pop();
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _submitError = switch (e.code) {
            'email-already-in-use' => 'This email is already in use.',
            'invalid-email' => 'Enter a valid email address.',
            'weak-password' => 'Password is too weak.',
            _ => e.message ?? 'Failed to create account.',
          };
        });
      } on FirebaseException catch (e) {
        if (!mounted) return;
        setState(() => _submitError = e.message ?? 'Failed to save user info.');
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    return Scaffold(
      drawer: AppDrawer(isDark: isDark),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: sizing.scaled(80),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: DrawerSwipeWrapper(
        child: DrawerSwipeBlankArea(
          child: Stack(
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
                                    tooltip: isDark
                                        ? 'Light mode'
                                        : 'Dark mode',
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
                            'Create your account',
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
                                  if (_submitError != null) ...[
                                    Text(
                                      _submitError!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: sizing.scaled(12)),
                                  ],
                                  TextFormField(
                                    controller: _nameController,
                                    keyboardType: TextInputType.name,
                                    autofillHints: const [AutofillHints.name],
                                    textInputAction: TextInputAction.next,
                                    onTap: () {
                                      if (_nameTouched) return;
                                      setState(() => _nameTouched = true);
                                    },
                                    onChanged: (_) {
                                      if (!_nameTouched) return;
                                      _formKey.currentState?.validate();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (!_nameTouched) return null;
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty) return 'Enter your name';
                                      if (v.length < 2)
                                        return 'Name is too short';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: sizing.scaled(14)),
                                  TextFormField(
                                    controller: _emailController,
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
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    textInputAction: TextInputAction.next,
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
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
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
                                      if (v.isEmpty)
                                        return 'Enter your password';
                                      if (v.length < 6) {
                                        return 'Password is too short';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: sizing.scaled(14)),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => onSubmit(),
                                    onTap: () {
                                      if (_confirmPasswordTouched) return;
                                      setState(
                                        () => _confirmPasswordTouched = true,
                                      );
                                    },
                                    onChanged: (_) {
                                      if (!_confirmPasswordTouched) return;
                                      _formKey.currentState?.validate();
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscureConfirmPassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (!_confirmPasswordTouched) return null;
                                      final v = (value ?? '');
                                      if (v.isEmpty) {
                                        return 'Confirm your password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
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
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      onPressed: _submitting ? null : onSubmit,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _submitting
                                            ? SizedBox(
                                                height: sizing.scaled(22),
                                                width: sizing.scaled(22),
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2.6,
                                                    ),
                                              )
                                            : const Text('Create account'),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: sizing.scaled(10)),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? scheme.onSurface
                                            : scheme.primary,
                                      ),
                                      onPressed: _submitting
                                          ? null
                                          : _showAccountsDialog,
                                      child: const Text('List accounts'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: sizing.scaled(14)),
                        ],
                      ),
                    ),
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
