import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_vals.dart';
import '../shared/app_drawer.dart';
import '../shared/drawer_swipe_wrapper.dart';
import '../shared/activity_log_service.dart';
import '../shared/responsive.dart';

String _twoDigits(int v) => v.toString().padLeft(2, '0');

String _formatRailwayTime(DateTime dt) {
  return '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  final _compressorFormKey = GlobalKey<FormState>();
  final _waterFormKey = GlobalKey<FormState>();
  final _solarFormKey = GlobalKey<FormState>();

  final _c1RunningController = TextEditingController();
  final _c1KwhController = TextEditingController();
  final _c2RunningController = TextEditingController();
  final _c2KwhController = TextEditingController();
  final _solarKwhController = TextEditingController();

  final _borewellController = TextEditingController();
  final _outletController = TextEditingController();
  final _stpInletController = TextEditingController();
  final _stpOutletController = TextEditingController();
  final _etpInletController = TextEditingController();
  final _etpOutletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pageController.dispose();
    _c1RunningController.dispose();
    _c1KwhController.dispose();
    _c2RunningController.dispose();
    _c2KwhController.dispose();
    _solarKwhController.dispose();
    _borewellController.dispose();
    _outletController.dispose();
    _stpInletController.dispose();
    _stpOutletController.dispose();
    _etpInletController.dispose();
    _etpOutletController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return _formatRailwayTime(dt);
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  String _formatDateLine(DateTime dt) {
    return '${_weekdayName(dt.weekday)}, ${_twoDigits(dt.day)} ${_monthName(dt.month)} ${dt.year}';
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
        title: Image.asset(
          AppThemeTokens.logoAssetPath,
          height: sizing.scaled(34),
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'Activity',
            onPressed: () {
              Navigator.pushNamed(context, '/Activity');
            },
            icon: Icon(
              Icons.notifications_none_outlined,
              color: toggleIconColor,
            ),
          ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final edgePadding =
                  (constraints.maxWidth * 0.05).clamp(12.0, 24.0);
              final headerSpacing =
                  (constraints.maxHeight * 0.02).clamp(10.0, 18.0);
              return Column(
                children: [
                  Flexible(
                    flex: 0,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: headerSpacing),
                          Text(
                            'FORMWORK UNIT-METALSHOP',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: headerSpacing * 0.6),
                          SizedBox(height: headerSpacing + 2),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: edgePadding,
                            ),
                            child: _ClockCard(
                              timeText: _formatTime(_now),
                              dateText: _formatDateLine(_now),
                              pulseOn: _now.second.isEven,
                            ),
                          ),
                          SizedBox(height: headerSpacing),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: edgePadding,
                            ),
                            child: _SegmentTabs(
                              selectedIndex: _pageIndex,
                              onSelected: (index) {
                                setState(() => _pageIndex = index);
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: headerSpacing * 0.8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _pageIndex = index);
                      },
                      children: [
                        _CompressorSlide(
                          formKey: _compressorFormKey,
                          c1RunningController: _c1RunningController,
                          c1KwhController: _c1KwhController,
                          c2RunningController: _c2RunningController,
                          c2KwhController: _c2KwhController,
                        ),
                        _SolarPanelSlide(
                          formKey: _solarFormKey,
                          kwhController: _solarKwhController,
                        ),
                        _WaterMeterSlide(
                          formKey: _waterFormKey,
                          borewellController: _borewellController,
                          outletController: _outletController,
                          stpInletController: _stpInletController,
                          stpOutletController: _stpOutletController,
                          etpInletController: _etpInletController,
                          etpOutletController: _etpOutletController,
                        ),
                      ],
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

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.timeText,
    required this.dateText,
    required this.pulseOn,
  });

  final String timeText;
  final String dateText;
  final bool pulseOn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const clockBackground = AppThemeTokens.darkBlue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = (width * 0.045).clamp(12.0, 18.0);
        final badgeSize = (width * 0.12).clamp(36.0, 52.0);
        final timeSize = (width * 0.085).clamp(22.0, 32.0);
        final dateSize = (width * 0.042).clamp(12.0, 16.0);
        const radius = 20.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.8,
              ),
              decoration: BoxDecoration(
                color: clockBackground,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  _ClockBadge(
                    foreground: Colors.white,
                    accent: Colors.black,
                    pulseOn: pulseOn,
                    size: badgeSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: timeSize,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: dateSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _ClockBadge extends StatelessWidget {
  const _ClockBadge({
    required this.foreground,
    required this.accent,
    required this.pulseOn,
    required this.size,
  });

  final Color foreground;
  final Color accent;
  final bool pulseOn;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ledOn = accent.withValues(alpha: 0.90);
    final ledOff = foreground.withValues(alpha: 0.16);
    final fill = pulseOn ? ledOn : ledOff;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: ledOn.withValues(alpha: pulseOn ? 0.35 : 0.08),
            blurRadius: pulseOn ? 16 : 6,
            spreadRadius: pulseOn ? 2 : 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.35,
          height: size * 0.35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: foreground.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Compressor')),
        ButtonSegment(value: 1, label: Text('Solar Panel')),
        ButtonSegment(value: 2, label: Text('Water Meter')),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (set) {
        if (set.isEmpty) return;
        onSelected(set.first);
      },
    );
  }
}

class _SlideScaffold extends StatelessWidget {
  const _SlideScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final edgePadding =
            (constraints.maxWidth * 0.05).clamp(12.0, 20.0);
        final innerPadding =
            (constraints.maxWidth * 0.04).clamp(12.0, 18.0);
        final headerSpacing =
            (constraints.maxHeight * 0.02).clamp(10.0, 16.0);
        const radius = 22.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(edgePadding, 0, edgePadding, edgePadding),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.10),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(innerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: headerSpacing),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompressorSlide extends StatelessWidget {
  const _CompressorSlide({
    required this.formKey,
    required this.c1RunningController,
    required this.c1KwhController,
    required this.c2RunningController,
    required this.c2KwhController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController c1RunningController;
  final TextEditingController c1KwhController;
  final TextEditingController c2RunningController;
  final TextEditingController c2KwhController;

  String? _validateNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(v);
    if (!ok) return 'Numbers only';
    final digitsOnly = v.replaceAll('.', '');
    if (digitsOnly.length > 8) return 'Max 8 digits';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SlideScaffold(
      title: 'Compressor',
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(1.0),
                        2: FlexColumnWidth(1.0),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            _PillHeaderCell(text: 'Unit'),
                            _PillHeaderCell(text: 'Running Hrs'),
                            _PillHeaderCell(text: 'KWH'),
                          ],
                        ),
                        TableRow(
                          children: [
                            const _RowLabelCell(text: 'Compressor 1'),
                            _PaddedField(
                              controller: c1RunningController,
                              hintText: '0.0',
                              validator: _validateNumber,
                            ),
                            _PaddedField(
                              controller: c1KwhController,
                              hintText: '0.0',
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const _RowLabelCell(text: 'Compressor 2'),
                            _PaddedField(
                              controller: c2RunningController,
                              hintText: '0.0',
                              validator: _validateNumber,
                            ),
                            _PaddedField(
                              controller: c2KwhController,
                              hintText: '0.0',
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final ok = formKey.currentState?.validate() ?? false;
                  if (!ok) return;
                  FocusScope.of(context).unfocus();

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception('Not signed in');
                    }

                    final userEntryCandidate =
                        (user.displayName ?? user.email ?? '').trim();
                    final userEntry =
                        userEntryCandidate.isEmpty ? 'Unknown' : userEntryCandidate;
                    final now = DateTime.now();
                    final date =
                        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                    final time = _formatRailwayTime(now);

                    final c1RunningText = c1RunningController.text.trim();
                    final c1KwhText = c1KwhController.text.trim();
                    final c2RunningText = c2RunningController.text.trim();
                    final c2KwhText = c2KwhController.text.trim();

                    final c1Running = c1RunningText.isEmpty
                        ? null
                        : double.parse(c1RunningText);
                    final c1Kwh =
                        c1KwhText.isEmpty ? null : double.parse(c1KwhText);
                    final c2Running = c2RunningText.isEmpty
                        ? null
                        : double.parse(c2RunningText);
                    final c2Kwh =
                        c2KwhText.isEmpty ? null : double.parse(c2KwhText);

                    await FirebaseFirestore.instance
                        .collection('compressor_readings')
                        .add({
                          'uid': user.uid,
                          'User Entry': userEntry,
                          'Date': date,
                          'Time': time,
                          'COMP-1 Running HRS': c1Running,
                          'COMP-1 KWH': c1Kwh,
                          'COMP-2 Running HRS': c2Running,
                          'COMP-2 KWH': c2Kwh,
                        });
                    await ActivityLogService().logEvent(
                      type: 'compressor_entry',
                      title: 'Compressor readings saved',
                      message:
                          '$userEntry saved compressor readings at $time.',
                      metadata: {
                        'c1Running': c1Running,
                        'c1Kwh': c1Kwh,
                        'c2Running': c2Running,
                        'c2Kwh': c2Kwh,
                      },
                    );

                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Saved'),
                        content: const Text(
                          'Compressor readings saved successfully.',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    c1RunningController.clear();
                    c1KwhController.clear();
                    c2RunningController.clear();
                    c2KwhController.clear();
                  } catch (e) {
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(
                          'Failed to save compressor readings.\n\n$e',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolarPanelSlide extends StatelessWidget {
  const _SolarPanelSlide({
    required this.formKey,
    required this.kwhController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController kwhController;

  String? _validateNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(v);
    if (!ok) return 'Numbers only';
    final digitsOnly = v.replaceAll('.', '');
    if (digitsOnly.length > 8) return 'Max 8 digits';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SlideScaffold(
      title: 'Solar Panel',
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(1.0),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            _PillHeaderCell(text: 'Unit'),
                            _PillHeaderCell(text: 'KWH'),
                          ],
                        ),
                        TableRow(
                          children: [
                            const _RowLabelCell(text: 'Solar Panel 1'),
                            _PaddedField(
                              controller: kwhController,
                              hintText: '0.0',
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final ok = formKey.currentState?.validate() ?? false;
                  if (!ok) return;
                  FocusScope.of(context).unfocus();

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception('Not signed in');
                    }

                    final userEntryCandidate =
                        (user.displayName ?? user.email ?? '').trim();
                    final userEntry =
                        userEntryCandidate.isEmpty ? 'Unknown' : userEntryCandidate;
                    final now = DateTime.now();
                    final date =
                        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                    final time = _formatRailwayTime(now);

                    final kwhText = kwhController.text.trim();

                    final kwh = kwhText.isEmpty ? null : double.parse(kwhText);

                    await FirebaseFirestore.instance
                        .collection('solar_panel_readings')
                        .add({
                          'uid': user.uid,
                          'User Entry': userEntry,
                          'Date': date,
                          'Time': time,
                          'SOLAR-1 KWH': kwh,
                        });
                    await ActivityLogService().logEvent(
                      type: 'solar_entry',
                      title: 'Solar panel readings saved',
                      message:
                          '$userEntry saved solar panel readings at $time.',
                      metadata: {
                        'kwh': kwh,
                      },
                    );

                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Saved'),
                        content: const Text(
                          'Solar panel readings saved successfully.',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    kwhController.clear();
                  } catch (e) {
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(
                          'Failed to save solar panel readings.\n\n$e',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterMeterSlide extends StatelessWidget {
  const _WaterMeterSlide({
    required this.formKey,
    required this.borewellController,
    required this.outletController,
    required this.stpInletController,
    required this.stpOutletController,
    required this.etpInletController,
    required this.etpOutletController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController borewellController;
  final TextEditingController outletController;
  final TextEditingController stpInletController;
  final TextEditingController stpOutletController;
  final TextEditingController etpInletController;
  final TextEditingController etpOutletController;

  String? _validateNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(v);
    if (!ok) return 'Numbers only';
    final digitsOnly = v.replaceAll('.', '');
    if (digitsOnly.length > 8) return 'Max 8 digits';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SlideScaffold(
      title: 'Water Meter',
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.3),
                        1: FlexColumnWidth(1.1),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            _PillHeaderCell(text: 'Point'),
                            _PillHeaderCell(text: 'Reading'),
                          ],
                        ),
                        _WaterRow(
                          label: 'BOREWELL',
                          controller: borewellController,
                          validator: _validateNumber,
                        ),
                        _WaterRow(
                          label: 'OUTLET',
                          controller: outletController,
                          validator: _validateNumber,
                        ),
                        _WaterRow(
                          label: 'STP INLET',
                          controller: stpInletController,
                          validator: _validateNumber,
                        ),
                        _WaterRow(
                          label: 'STP OUTLET',
                          controller: stpOutletController,
                          validator: _validateNumber,
                        ),
                        _WaterRow(
                          label: 'ETP INLET',
                          controller: etpInletController,
                          validator: _validateNumber,
                        ),
                        _WaterRow(
                          label: 'ETP OUTLET',
                          controller: etpOutletController,
                          validator: _validateNumber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final ok = formKey.currentState?.validate() ?? false;
                  if (!ok) return;
                  FocusScope.of(context).unfocus();

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception('Not signed in');
                    }

                    final borewellText = borewellController.text.trim();
                    final outletText = outletController.text.trim();
                    final stpInletText = stpInletController.text.trim();
                    final stpOutletText = stpOutletController.text.trim();
                    final etpInletText = etpInletController.text.trim();
                    final etpOutletText = etpOutletController.text.trim();

                    final borewell = borewellText.isEmpty
                        ? null
                        : double.parse(borewellText);
                    final outlet =
                        outletText.isEmpty ? null : double.parse(outletText);
                    final stpInlet = stpInletText.isEmpty
                        ? null
                        : double.parse(stpInletText);
                    final stpOutlet = stpOutletText.isEmpty
                        ? null
                        : double.parse(stpOutletText);
                    final etpInlet = etpInletText.isEmpty
                        ? null
                        : double.parse(etpInletText);
                    final etpOutlet = etpOutletText.isEmpty
                        ? null
                        : double.parse(etpOutletText);

                    final now = DateTime.now();
                    final date =
                        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                    final time = _formatRailwayTime(now);
                    final userEntryCandidate =
                        (user.displayName ?? user.email ?? '').trim();
                    final userEntry =
                        userEntryCandidate.isEmpty ? 'Unknown' : userEntryCandidate;
                    await FirebaseFirestore.instance
                        .collection('water_meter_readings')
                        .add({
                          'uid': user.uid,
                          'User Entry': userEntry,
                          'Date': date,
                          'Time': time,
                          'BOREWELL': borewell,
                          'OUTLET': outlet,
                          'STPINLET': stpInlet,
                          'STPOUTLET': stpOutlet,
                          'ETPINLET': etpInlet,
                          'ETPOUTLET': etpOutlet,
                        });
                    await ActivityLogService().logEvent(
                      type: 'water_entry',
                      title: 'Water meter readings saved',
                      message:
                          '$userEntry saved water meter readings at $time.',
                      metadata: {
                        'borewell': borewell,
                        'outlet': outlet,
                        'stpInlet': stpInlet,
                        'stpOutlet': stpOutlet,
                        'etpInlet': etpInlet,
                        'etpOutlet': etpOutlet,
                      },
                    );

                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Saved'),
                        content: const Text(
                          'Water meter readings saved successfully.',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    borewellController.clear();
                    outletController.clear();
                    stpInletController.clear();
                    stpOutletController.clear();
                    etpInletController.clear();
                    etpOutletController.clear();
                  } catch (e) {
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(
                          'Failed to save water meter readings.\n\n$e',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillHeaderCell extends StatelessWidget {
  const _PillHeaderCell({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? scheme.secondaryContainer : scheme.primary.withValues(alpha: 0.16);
    final foreground = isDark ? scheme.onSecondaryContainer : scheme.onSurface;
    final borderColor = isDark
        ? scheme.onSecondaryContainer.withValues(alpha: 0.35)
        : scheme.onSurface.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: background,
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _RowLabelCell extends StatelessWidget {
  const _RowLabelCell({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PaddedField extends StatelessWidget {
  const _PaddedField({
    required this.controller,
    required this.hintText,
    required this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: validator,
      ),
    );
  }
}

class _WaterRow extends TableRow {
  _WaterRow({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) : super(
         children: [
           _RowLabelCell(text: label),
           _PaddedField(
             controller: controller,
             hintText: '0.0',
             validator: validator,
           ),
         ],
       );
}
