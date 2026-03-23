import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:l_and_t_meter_reader/shared/activity_log_service.dart';
import 'responsive.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizing = ResponsiveSizing.of(context);

    return Drawer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                (constraints.maxWidth * 0.07).clamp(16.0, 24.0);
            final sectionSpacing = sizing.scaled(12);

            return Column(
              children: [
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnapshot) {
                    final user = authSnapshot.data;
                    if (user == null) {
                      return _DrawerHeader(
                        isDark: isDark,
                        theme: theme,
                        scheme: scheme,
                        displayName: 'Not signed in',
                        email: '',
                      );
                    }

                    return StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, userDocSnapshot) {
                        final data = userDocSnapshot.data?.data();
                        final displayName =
                            ((data?['name'] as String?)?.trim().isNotEmpty ??
                                false)
                            ? (data?['name'] as String).trim()
                            : (user.displayName?.trim().isNotEmpty ?? false)
                            ? user.displayName!.trim()
                            : 'Account';
                        final email =
                            ((data?['email'] as String?)?.trim().isNotEmpty ??
                                false)
                            ? (data?['email'] as String).trim()
                            : (user.email ?? '');

                        return _DrawerHeader(
                          isDark: isDark,
                          theme: theme,
                          scheme: scheme,
                          displayName: displayName,
                          email: email,
                        );
                      },
                    );
                  },
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            sizing.scaled(16),
                            horizontalPadding,
                            sizing.scaled(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: sizing.scaled(18),
                                color: scheme.primary,
                              ),
                              SizedBox(width: sizing.scaled(8)),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          12,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              _DrawerTile(
                                title: 'Dashboard',
                                subtitle: 'Overview',
                                icon: Icons.dashboard_outlined,
                                accent: scheme.primary,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/Dashboard',
                                    (route) => false,
                                  );
                                },
                              ),
                              SizedBox(height: sectionSpacing),
                              _DrawerTile(
                                title: 'Activity',
                                subtitle: 'Timeline',
                                icon: Icons.notifications_none_outlined,
                                accent: scheme.primaryContainer,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/Activity');
                                },
                              ),
                              SizedBox(height: sectionSpacing),
                              _DrawerTile(
                                title: 'Reports',
                                subtitle: 'Entry Records',
                                icon: Icons.assessment_outlined,
                                accent: scheme.tertiary,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/Report');
                                },
                              ),
                              SizedBox(height: sectionSpacing),
                              _DrawerTile(
                                title: 'Accounts',
                                subtitle: 'User records',
                                icon: Icons.manage_accounts_outlined,
                                accent: scheme.secondary,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/AccountCreation',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sizing.scaled(16),
                    sizing.scaled(6),
                    sizing.scaled(16),
                    sizing.scaled(10),
                  ),
                  child: ListTile(
                    tileColor: scheme.error,
                    iconColor: scheme.onError,
                    textColor: scheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sizing.scaled(8)),
                    ),
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('Logout'),
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Confirm logout'),
                          content: const Text('Do you want to logout?'),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  dialogContext,
                                ).colorScheme.error,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout != true) return;
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final userEntryCandidate =
                            (user.displayName ?? user.email ?? '').trim();
                        final userEntry =
                            userEntryCandidate.isEmpty ? 'Unknown' : userEntryCandidate;
                        await ActivityLogService().logEvent(
                          type: 'logout',
                          title: 'User logout',
                          message: '$userEntry logged out.',
                          actorUid: user.uid,
                          actorName: userEntry,
                          actorEmail: user.email ?? '',
                        );
                      }
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(
                        '/LoginScreen',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isDark,
    required this.theme,
    required this.scheme,
    required this.displayName,
    required this.email,
  });

  final bool isDark;
  final ThemeData theme;
  final ColorScheme scheme;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing.of(context);
    final initials = _initialsFrom(displayName);
    final headerBackground = scheme.primaryContainer;
    final headerForeground = scheme.onPrimaryContainer;
    return Container(
      padding: EdgeInsets.fromLTRB(
        sizing.scaled(16),
        sizing.scaled(16),
        sizing.scaled(16),
        sizing.scaled(14),
      ),
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.primary.withValues(alpha: isDark ? 0.32 : 0.20),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: sizing.scaled(80),
              height: sizing.scaled(80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: sizing.scaled(70),
              height: sizing.scaled(70),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: sizing.scaled(22),
                backgroundColor: headerForeground.withValues(alpha: 0.2),
                foregroundColor: headerForeground,
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: headerForeground,
                  ),
                ),
              ),
              SizedBox(width: sizing.scaled(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: headerForeground,
                      ),
                    ),
                    SizedBox(height: sizing.scaled(2)),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: headerForeground.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = ThemeData.estimateBrightnessForColor(accent);
    final foreground =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final sizing = ResponsiveSizing.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sizing.scaled(8)),
          child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sizing.scaled(8)),
            color: accent,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.2),
                blurRadius: sizing.scaled(12),
                offset: Offset(0, sizing.scaled(6)),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: sizing.scaled(6),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: -16,
                child: Container(
                  width: sizing.scaled(60),
                  height: sizing.scaled(60),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: foreground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(sizing.scaled(10)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sizing.scaled(14),
                  sizing.scaled(14),
                  sizing.scaled(14),
                  sizing.scaled(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(sizing.scaled(10)),
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(sizing.scaled(8)),
                      ),
                      child: Icon(icon, size: sizing.scaled(20), color: foreground),
                    ),
                    SizedBox(height: sizing.scaled(10)),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                    SizedBox(height: sizing.scaled(4)),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                    ),
                    SizedBox(height: sizing.scaled(8)),
                    Row(
                      children: [
                        Container(
                          width: sizing.scaled(8),
                          height: sizing.scaled(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: foreground.withValues(alpha: 0.85),
                          ),
                        ),
                        SizedBox(width: sizing.scaled(6)),
                        Text(
                          'Open',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: sizing.scaled(16),
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initialsFrom(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'A';
  final first = parts.first;
  final second = parts.length > 1 ? parts[1] : '';
  final a = first.isNotEmpty ? first[0] : 'A';
  final b = second.isNotEmpty ? second[0] : '';
  return (a + b).toUpperCase();
}
