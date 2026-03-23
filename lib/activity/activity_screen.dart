import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/app_drawer.dart';
import '../shared/drawer_swipe_wrapper.dart';
import '../theme_vals.dart';
import '../shared/responsive.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityFilterKind _selectedFilter = ActivityFilterKind.all;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final day = _twoDigits(dt.day);
    final month = _twoDigits(dt.month);
    final year = dt.year.toString();
    final time =
        '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}';
    return '$day/$month/$year • $time';
  }

  DateTime _resolveTimestamp(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }
    final raw = data['clientCreatedAt']?.toString() ?? '';
    final parsed = DateTime.tryParse(raw);
    return parsed ?? DateTime.now();
  }

  List<_FilterOption> _filterOptions(ColorScheme scheme) {
    return [
      _FilterOption(
        kind: ActivityFilterKind.all,
        label: 'All',
        icon: Icons.grid_view_rounded,
        colors: [scheme.primary, scheme.primaryContainer],
      ),
      _FilterOption(
        kind: ActivityFilterKind.reportEmailed,
        label: 'Report emailed',
        icon: Icons.mark_email_read_rounded,
        colors: [scheme.tertiary, scheme.tertiaryContainer],
      ),
      _FilterOption(
        kind: ActivityFilterKind.reportReset,
        label: 'Report reset',
        icon: Icons.restart_alt_rounded,
        colors: [scheme.errorContainer, scheme.error],
      ),
      _FilterOption(
        kind: ActivityFilterKind.reportSaved,
        label: 'Report saved',
        icon: Icons.save_alt_rounded,
        colors: [scheme.secondary, scheme.secondaryContainer],
      ),
      _FilterOption(
        kind: ActivityFilterKind.reportDeletedOnly,
        label: 'Deleted entries',
        icon: Icons.delete_outline_rounded,
        colors: [scheme.errorContainer, scheme.error],
      ),
      _FilterOption(
        kind: ActivityFilterKind.userEvents,
        label: 'User events',
        icon: Icons.celebration_rounded,
        colors: [scheme.tertiary, scheme.tertiaryContainer],
      ),
      _FilterOption(
        kind: ActivityFilterKind.entries,
        label: 'Entries',
        icon: Icons.playlist_add_check_circle_rounded,
        colors: [scheme.secondary, scheme.secondaryContainer],
      ),
      _FilterOption(
        kind: ActivityFilterKind.loginLogout,
        label: 'Login & logout',
        icon: Icons.login_rounded,
        colors: [scheme.primaryContainer, scheme.primary],
      ),
    ];
  }

  bool _matchesFilter(String type, ActivityFilterKind filter) {
    switch (filter) {
      case ActivityFilterKind.reportEmailed:
        return type == 'report_emailed';
      case ActivityFilterKind.entries:
        return type == 'compressor_entry' ||
            type == 'solar_entry' ||
            type == 'water_entry';
      case ActivityFilterKind.loginLogout:
        return type == 'login' || type == 'logout';
      case ActivityFilterKind.reportDeletedOnly:
        return type == 'report_deleted';
      case ActivityFilterKind.reportReset:
        return type == 'report_reset';
      case ActivityFilterKind.reportSaved:
        return type == 'report_saved';
      case ActivityFilterKind.userEvents:
        return type == 'user_created' || type == 'user_welcome';
      case ActivityFilterKind.all:
        return true;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final filtered = docs
        .where((doc) => _matchesFilter(
              (doc.data()['type'] ?? '').toString().trim(),
              _selectedFilter,
            ))
        .toList();
    return filtered;
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
      drawer: AppDrawer(isDark: isDark),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: sizing.scaled(80),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppThemeTokens.logoAssetPath,
              height: sizing.scaled(30),
              fit: BoxFit.contain,
            ),
            SizedBox(width: sizing.scaled(10)),
            Text(
              'Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: () {
              context.read<AppCustomization>().setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: toggleIconColor,
            ),
          ),
        ],
      ),
      body: DrawerSwipeWrapper(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('activity_logs')
                .orderBy('clientCreatedAt', descending: true)
                .limit(200)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load activity logs.',
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No activity yet.',
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              final filteredDocs = _applyFilter(docs);

              if (filteredDocs.isEmpty) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _FilterStrip(
                        options: _filterOptions(scheme),
                        selected: _selectedFilter,
                        onSelected: (filter) {
                          setState(() => _selectedFilter = filter);
                        },
                        totalCount: docs.length,
                        filteredCount: filteredDocs.length,
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No activity for this filter.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final itemCount = filteredDocs.length * 2 - 1;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _FilterStrip(
                      options: _filterOptions(scheme),
                      selected: _selectedFilter,
                      onSelected: (filter) {
                        setState(() => _selectedFilter = filter);
                      },
                      totalCount: docs.length,
                      filteredCount: filteredDocs.length,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      sizing.scaled(18),
                      sizing.scaled(10),
                      sizing.scaled(18),
                      sizing.scaled(24),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index.isOdd) {
                            return SizedBox(height: sizing.scaled(14));
                          }
                          final itemIndex = index ~/ 2;
                          final data = filteredDocs[itemIndex].data();
                          final createdAt = _resolveTimestamp(data);
                          final title =
                              (data['title'] ?? '').toString().trim();
                          final message =
                              (data['message'] ?? '').toString().trim();
                          final actor =
                              (data['actorName'] ?? '').toString().trim();
                          final type =
                              (data['type'] ?? '').toString().trim();

                          return _ActivityCard(
                            title: title.isEmpty ? 'Activity' : title,
                            message: message,
                            actor: actor.isEmpty ? 'Unknown' : actor,
                            type: type,
                            dateTimeText: _formatDateTime(createdAt),
                            isLast: itemIndex == filteredDocs.length - 1,
                          );
                        },
                        childCount: itemCount,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum ActivityFilterKind {
  all,
  reportEmailed,
  entries,
  loginLogout,
  reportDeletedOnly,
  reportReset,
  reportSaved,
  userEvents,
}

class _FilterOption {
  const _FilterOption({
    required this.kind,
    required this.label,
    required this.icon,
    required this.colors,
  });

  final ActivityFilterKind kind;
  final String label;
  final IconData icon;
  final List<Color> colors;
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.totalCount,
    required this.filteredCount,
  });

  final List<_FilterOption> options;
  final ActivityFilterKind selected;
  final ValueChanged<ActivityFilterKind> onSelected;
  final int totalCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sizing.scaled(18),
        sizing.scaled(16),
        sizing.scaled(18),
        sizing.scaled(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options
                  .map(
                    (option) => Padding(
                      padding: EdgeInsets.only(right: sizing.scaled(10)),
                      child: _FilterTicket(
                        option: option,
                        isSelected: option.kind == selected,
                        onTap: () => onSelected(option.kind),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: sizing.scaled(10)),
          Text(
            'Showing $filteredCount of $totalCount activities',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTicket extends StatelessWidget {
  const _FilterTicket({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _FilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = option.colors;
    final gradient = LinearGradient(
      colors: isSelected
          ? colors
          : [
              colors.first.withValues(alpha: 0.2),
              colors.last.withValues(alpha: 0.3),
            ],
    );
    final selectedTextColor =
        ThemeData.estimateBrightnessForColor(colors.first) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final iconColor =
        isSelected ? selectedTextColor : scheme.onSurfaceVariant;
    final textColor =
        isSelected ? selectedTextColor : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(sizing.scaled(18)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: ClipPath(
          clipper: _TicketClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.35),
                    blurRadius: sizing.scaled(18),
                    offset: Offset(0, sizing.scaled(6)),
                  ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sizing.scaled(16),
                vertical: sizing.scaled(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.icon, size: sizing.scaled(16), color: iconColor),
                  SizedBox(width: sizing.scaled(8)),
                  Text(
                    option.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final radius = size.height * 0.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(size.height * 0.45),
        ),
      );
    path.fillType = PathFillType.evenOdd;
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width - radius * 0.8, size.height / 2),
        radius: radius * 0.35,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.message,
    required this.actor,
    required this.type,
    required this.dateTimeText,
    required this.isLast,
  });

  final String title;
  final String message;
  final String actor;
  final String type;
  final String dateTimeText;
  final bool isLast;

  Color _colorForType(ColorScheme scheme) {
    switch (type) {
      case 'compressor_entry':
        return scheme.primary;
      case 'solar_entry':
        return scheme.tertiary;
      case 'water_entry':
        return scheme.secondary;
      case 'report_emailed':
        return scheme.primaryContainer;
      case 'report_email_failed':
        return scheme.error;
      case 'report_saved':
        return scheme.secondaryContainer;
      case 'report_deleted':
      case 'report_reset':
        return scheme.errorContainer;
      case 'user_created':
      case 'user_welcome':
        return scheme.primaryContainer;
      case 'monthly_reset':
        return scheme.tertiaryContainer;
      default:
        return scheme.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _colorForType(scheme);
    final brightness = ThemeData.estimateBrightnessForColor(accent);
    final accentText =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final sizing = ResponsiveSizing.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: sizing.scaled(26),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: sizing.scaled(12),
                  height: sizing.scaled(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
                SizedBox(height: sizing.scaled(4)),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: sizing.scaled(2),
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: sizing.scaled(10)),
          Expanded(
            child: Container(
            padding: EdgeInsets.all(sizing.scaled(14)),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(sizing.scaled(16)),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: sizing.scaled(16),
                  offset: Offset(0, sizing.scaled(8)),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (type.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizing.scaled(10),
                          vertical: sizing.scaled(4),
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(sizing.scaled(12)),
                        ),
                        child: Text(
                          type.replaceAll('_', ' '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accentText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  SizedBox(height: sizing.scaled(8)),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                SizedBox(height: sizing.scaled(8)),
                Text(
                  '$actor • $dateTimeText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}
