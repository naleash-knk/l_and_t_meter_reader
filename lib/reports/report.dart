import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_vals.dart';
import '../shared/app_drawer.dart';
import '../shared/drawer_swipe_wrapper.dart';
import '../shared/activity_log_service.dart';
import '../shared/responsive.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
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
              'Report',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
                  (constraints.maxHeight * 0.02).clamp(10.0, 16.0);
              return Column(
                children: [
                  DrawerSwipeBlankArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
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
                      children: const [
                        _CompressorReportSlide(),
                        _SolarReportSlide(),
                        _WaterReportSlide(),
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
      onSelectionChanged: (v) {
        if (v.isEmpty) return;
        onSelected(v.first);
      },
    );
  }
}

class _CompressorReportSlide extends StatelessWidget {
  const _CompressorReportSlide();

  @override
  Widget build(BuildContext context) {
    return _ReportSlideScaffold(
      title: 'Compressor Readings',
      exportFileBaseName: 'compressor_readings',
      exportCollection: 'compressor_readings',
      exportColumns: const [
        'Date',
        'Time',
        'User Entry',
        'COMP-1 Running HRS',
        'COMP-1 KWH',
        'COMP-2 Running HRS',
        'COMP-2 KWH',
      ],
      childBuilder: (selectionController) => _ReadingsTable(
        selectionController: selectionController,
        query: FirebaseFirestore.instance
            .collection('compressor_readings')
            .orderBy('Date', descending: true),
        columns: const [
          'Date',
          'Time',
          'User Entry',
          'COMP-1 Running HRS',
          'COMP-1 KWH',
          'COMP-2 Running HRS',
          'COMP-2 KWH',
        ],
      ),
    );
  }
}

class _SolarReportSlide extends StatelessWidget {
  const _SolarReportSlide();

  @override
  Widget build(BuildContext context) {
    return _ReportSlideScaffold(
      title: 'Solar Panel Readings',
      exportFileBaseName: 'solar_panel_readings',
      exportCollection: 'solar_panel_readings',
      exportColumns: const [
        'Date',
        'Time',
        'User Entry',
        'SOLAR-1 KWH',
      ],
      childBuilder: (selectionController) => _ReadingsTable(
        selectionController: selectionController,
        query: FirebaseFirestore.instance
            .collection('solar_panel_readings')
            .orderBy('Date', descending: true),
        columns: const [
          'Date',
          'Time',
          'User Entry',
          'SOLAR-1 KWH',
        ],
      ),
    );
  }
}

class _WaterReportSlide extends StatelessWidget {
  const _WaterReportSlide();

  @override
  Widget build(BuildContext context) {
    return _ReportSlideScaffold(
      title: 'Water Meter Readings',
      exportFileBaseName: 'water_meter_readings',
      exportCollection: 'water_meter_readings',
      exportColumns: const [
        'Date',
        'Time',
        'User Entry',
        'BOREWELL',
        'OUTLET',
        'STPINLET',
        'STPOUTLET',
        'ETPINLET',
        'ETPOUTLET',
      ],
      childBuilder: (selectionController) => _ReadingsTable(
        selectionController: selectionController,
        query: FirebaseFirestore.instance
            .collection('water_meter_readings')
            .orderBy('Date', descending: true),
        columns: const [
          'Date',
          'Time',
          'User Entry',
          'BOREWELL',
          'OUTLET',
          'STPINLET',
          'STPOUTLET',
          'ETPINLET',
          'ETPOUTLET',
        ],
      ),
    );
  }
}

class _ReportSelectionController {
  _ReportSelectionController()
      : selected =
            ValueNotifier<Set<DocumentReference<Map<String, dynamic>>>>({});

  final ValueNotifier<Set<DocumentReference<Map<String, dynamic>>>> selected;

  int get count => selected.value.length;

  void toggle(DocumentReference<Map<String, dynamic>> ref, bool isSelected) {
    final next = Set<DocumentReference<Map<String, dynamic>>>.from(
      selected.value,
    );
    if (isSelected) {
      next.add(ref);
    } else {
      next.remove(ref);
    }
    selected.value = next;
  }

  void replaceSelection(
    Set<DocumentReference<Map<String, dynamic>>> refs,
  ) {
    selected.value = refs;
  }

  void clear() {
    selected.value = {};
  }
}

class _ReportSlideScaffold extends StatefulWidget {
  const _ReportSlideScaffold({
    required this.title,
    required this.exportFileBaseName,
    required this.exportCollection,
    required this.exportColumns,
    required this.childBuilder,
  });

  final String title;
  final String exportFileBaseName;
  final String exportCollection;
  final List<String> exportColumns;
  final Widget Function(_ReportSelectionController controller) childBuilder;

  @override
  State<_ReportSlideScaffold> createState() => _ReportSlideScaffoldState();
}

class _ReportSlideScaffoldState extends State<_ReportSlideScaffold> {
  final _selectionController = _ReportSelectionController();

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
          padding: EdgeInsets.fromLTRB(
            edgePadding,
            0,
            edgePadding,
            edgePadding,
          ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _ReportExportActions(
                            exportFileBaseName: widget.exportFileBaseName,
                            exportCollection: widget.exportCollection,
                            exportColumns: widget.exportColumns,
                            selectionController: _selectionController,
                          ),
                        ],
                      ),
                      SizedBox(height: headerSpacing),
                      Expanded(
                        child: widget.childBuilder(_selectionController),
                      ),
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

class _ReportExportActions extends StatefulWidget {
  const _ReportExportActions({
    required this.exportFileBaseName,
    required this.exportCollection,
    required this.exportColumns,
    required this.selectionController,
  });

  final String exportFileBaseName;
  final String exportCollection;
  final List<String> exportColumns;
  final _ReportSelectionController selectionController;

  @override
  State<_ReportExportActions> createState() => _ReportExportActionsState();
}

class _ReportExportActionsState extends State<_ReportExportActions> {
  bool _busy = false;
  File? _lastGenerated;

  Future<String> _uploadExcelToStorage(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      throw Exception('Not signed in');
    }

    final filename = file.path.split('/').last;
    final storagePath = 'reports/$uid/$filename';
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(
      file,
      SettableMetadata(
        contentType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    );
    return storagePath;
  }

  Future<File> _generateExcel() async {
    final bytes = await _generateExcelBytes();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${widget.exportFileBaseName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> _generateExcelBytes() async {
    final snap = await FirebaseFirestore.instance
        .collection(widget.exportCollection)
        .orderBy('Date', descending: true)
        .get();

    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sheet1'];

    sheet.appendRow(
      widget.exportColumns.map((e) => excel.TextCellValue(e)).toList(),
    );

    for (final doc in snap.docs) {
      final data = doc.data();
      sheet.appendRow(
        widget.exportColumns
            .map((k) => excel.TextCellValue((data[k] ?? '').toString()))
            .toList(),
      );
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel bytes');
    }
    return Uint8List.fromList(bytes);
  }


  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Yes',
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black,
              ),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _handleGenerate(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final ok = await _confirmAction(
        context,
        title: 'Save in device?',
        message: 'Generate and save this report on the device?',
      );
      if (!ok) return;

      final bytes = await _generateExcelBytes();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select save location',
        fileName:
            '${widget.exportFileBaseName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        allowedExtensions: const ['xlsx'],
        type: FileType.custom,
      );
      if (savePath == null || savePath.trim().isEmpty) return;
      final file = File(savePath);
      _lastGenerated = file;
      if (!context.mounted) return;
      await ActivityLogService().logEvent(
        type: 'report_saved',
        title: 'Report saved on device',
        message:
            'Saved ${widget.exportFileBaseName} report to device.',
        metadata: {
          'report': widget.exportCollection,
          'fileName': file.path.split('/').last,
        },
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Excel saved'),
            content: SelectableText(file.path),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate Excel: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _handleEmail(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final ok = await _confirmAction(
        context,
        title: 'Send as email?',
        message: 'Generate and send this report to your email?',
      );
      if (!ok) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in');
      }
      final userEmail = user.email;
      if (userEmail == null || userEmail.trim().isEmpty) {
        throw Exception('No logged-in email found');
      }

      final file = _lastGenerated ?? await _generateExcel();
      _lastGenerated = file;

      final storagePath = await _uploadExcelToStorage(file);
      final mailRef = await FirebaseFirestore.instance
          .collection('mail_requests')
          .add({
            'to': userEmail.trim(),
            'subject': 'FORMWORK UNIT-METALSHOP Report',
            'body': 'Please find the attached report.',
            'storagePath': storagePath,
            'filename': file.path.split('/').last,
            'status': 'queued',
            'createdAt': FieldValue.serverTimestamp(),
            'uid': user.uid,
          });

      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Sending report'),
            content: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Preparing and sending your report. Please wait…',
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      );

      String status = 'error';
      String? err;
      try {
        final snap = await mailRef
            .snapshots()
            .firstWhere((s) {
              final sStatus = s.data()?['status']?.toString();
              return sStatus == 'sent' || sStatus == 'error';
            })
            .timeout(const Duration(seconds: 60));
        status = snap.data()?['status']?.toString() ?? 'error';
        err = snap.data()?['error']?.toString();
      } catch (_) {
        status = 'error';
        err = 'Timed out waiting for email confirmation.';
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (status == 'sent') {
        await ActivityLogService().logEvent(
          type: 'report_emailed',
          title: 'Report emailed',
          message:
              'Sent ${widget.exportFileBaseName} report to $userEmail.',
          metadata: {
            'report': widget.exportCollection,
            'to': userEmail,
            'mailRequestId': mailRef.id,
          },
        );
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Email sent successfully'),
              content: const Text(
                'The report has been sent to your email.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseStorage.instance.ref(storagePath).delete();
                    } catch (_) {
                      // If cleanup fails, we silently ignore to avoid blocking UX.
                    }
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        await ActivityLogService().logEvent(
          type: 'report_email_failed',
          title: 'Report email failed',
          message: err ?? 'Unknown error',
          metadata: {
            'report': widget.exportCollection,
            'to': userEmail,
            'mailRequestId': mailRef.id,
          },
        );
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final isDark =
                Theme.of(dialogContext).brightness == Brightness.dark;
            return AlertDialog(
              title: const Text('Email failed'),
              content: Text(err ?? 'Unknown error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child:  Text('Close',style: TextStyle(
                    color:isDark? Colors.red:null
                  ),),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send report: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _handleReset(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final shouldReset = await _confirmAction(
        context,
        title: 'Reset report data?',
        message: 'This will permanently delete all entries in this report.',
        confirmText: 'Delete',
      );

      if (shouldReset != true) return;

      final collection =
          FirebaseFirestore.instance.collection(widget.exportCollection);
      final snap = await collection.get();
      final docs = snap.docs;

      if (docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No entries to delete.')));
        return;
      }

      for (var i = 0; i < docs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = docs.sublist(
          i,
          (i + 500).clamp(0, docs.length),
        );
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await ActivityLogService().logEvent(
        type: 'report_reset',
        title: 'Report data cleared',
        message:
            'Cleared ${docs.length} entries from ${widget.exportCollection}.',
        metadata: {
          'report': widget.exportCollection,
          'count': docs.length,
        },
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report cleared.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _handleDeleteSelected(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final selected = widget.selectionController.selected.value;
      if (selected.isEmpty) return;

      final ok = await _confirmAction(
        context,
        title: 'Delete selected entries?',
        message: 'Delete ${selected.length} selected entries?',
        confirmText: 'Delete',
      );
      if (!ok) return;

      final refs = selected.toList();
      for (var i = 0; i < refs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = refs.sublist(i, (i + 500).clamp(0, refs.length));
        for (final ref in chunk) {
          batch.delete(ref);
        }
        await batch.commit();
      }

      widget.selectionController.clear();
      await ActivityLogService().logEvent(
        type: 'report_deleted',
        title: 'Report entries deleted',
        message:
            'Deleted ${selected.length} entries from ${widget.exportCollection}.',
        metadata: {
          'report': widget.exportCollection,
          'count': selected.length,
        },
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} entries deleted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<
      Set<DocumentReference<Map<String, dynamic>>>
    >(
      valueListenable: widget.selectionController.selected,
      builder: (context, selected, _) {
        final hasSelection = selected.isNotEmpty;
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            if (hasSelection)
              IconButton(
                tooltip: 'Delete selected',
                onPressed: _busy ? null : () => _handleDeleteSelected(context),
                color: Colors.red,
                icon: const Icon(Icons.delete_outline),
              )
            else ...[
              IconButton(
                tooltip: 'Save in Device',
                onPressed: _busy ? null : () => _handleGenerate(context),
                icon: const Icon(Icons.save_outlined),
              ),
              IconButton(
                tooltip: 'Sent as Email',
                onPressed: _busy ? null : () => _handleEmail(context),
                icon: const Icon(Icons.email_outlined),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: _busy ? null : () => _handleReset(context),
                color: Colors.red,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReadingsTable extends StatefulWidget {
  const _ReadingsTable({
    required this.selectionController,
    required this.query,
    required this.columns,
  });

  final _ReportSelectionController selectionController;
  final Query<Map<String, dynamic>> query;
  final List<String> columns;

  @override
  State<_ReadingsTable> createState() => _ReadingsTableState();
}

class _ReadingsTableState extends State<_ReadingsTable> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load entries: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No entries found'));
        }

        final validRefs = docs.map((d) => d.reference).toSet();
        final current = widget.selectionController.selected.value;
        if (!validRefs.containsAll(current) ||
            current.length !=
                current.where((ref) => validRefs.contains(ref)).length) {
          widget.selectionController.replaceSelection(
            current.intersection(validRefs),
          );
        }

        return ValueListenableBuilder<
          Set<DocumentReference<Map<String, dynamic>>>
        >(
          valueListenable: widget.selectionController.selected,
          builder: (context, selected, _) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final scheme = theme.colorScheme;
                    final isDark = theme.brightness == Brightness.dark;
                    final checkboxTheme = isDark
                        ? theme.checkboxTheme.copyWith(
                          fillColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.red;
                            }
                            return null;
                          }),
                          checkColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return null;
                          }),
                        )
                        : theme.checkboxTheme;
                    return Theme(
                      data: theme.copyWith(checkboxTheme: checkboxTheme),
                      child: DataTable(
                        showCheckboxColumn: true,
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return scheme.secondaryContainer.withValues(
                                alpha: 0.35,
                              );
                            }
                            return null;
                          },
                        ),
                        columns: [
                          for (final col in widget.columns)
                            DataColumn(label: Text(col)),
                        ],
                        rows: docs.map((d) {
                          final data = d.data();
                          final isSelected = selected.contains(d.reference);
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (next) {
                              if (next == null) return;
                              widget.selectionController.toggle(
                                d.reference,
                                next,
                              );
                            },
                            cells: [
                              for (final col in widget.columns)
                                DataCell(Text(data[col]?.toString() ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
