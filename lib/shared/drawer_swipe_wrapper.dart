import 'package:flutter/material.dart';

/// Wrap parts of the UI that should be considered "blank space" for drawer swipe.
/// Any horizontal drag that starts on this widget can open the parent Scaffold's
/// drawer.
class DrawerSwipeBlankArea extends StatelessWidget {
  const DrawerSwipeBlankArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _DrawerSwipeBroker.markAllowed(),
      child: child,
    );
  }
}

/// Internal broker used to communicate "pointer down started on blank area"
/// from a nested widget up to the wrapper without relying on debug APIs.
class _DrawerSwipeBroker {
  static int _token = 0;

  static int consumeToken() {
    final v = _token;
    _token = 0;
    return v;
  }

  static void markAllowed() {
    _token = DateTime.now().microsecondsSinceEpoch;
  }
}

/// Wrap the whole screen body with this. It will open the drawer when a
/// left->right drag starts from a [DrawerSwipeBlankArea].
class DrawerSwipeWrapper extends StatefulWidget {
  const DrawerSwipeWrapper({
    super.key,
    required this.child,
    this.minHorizontalDrag = 32,
    this.maxVerticalSlop = 24,
  });

  final Widget child;
  final double minHorizontalDrag;
  final double maxVerticalSlop;

  @override
  State<DrawerSwipeWrapper> createState() => _DrawerSwipeWrapperState();
}

class _DrawerSwipeWrapperState extends State<DrawerSwipeWrapper> {
  Offset? _start;
  bool _allowed = false;
  bool _triggered = false;

  void _openDrawerIfPossible() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState == null) return;
    if (scaffoldState.isDrawerOpen) return;
    scaffoldState.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _start = event.position;
        _triggered = false;
        // If any DrawerSwipeBlankArea received this pointer down first,
        // it will mark the broker before this listener runs.
        _allowed = _DrawerSwipeBroker.consumeToken() != 0;
      },
      onPointerMove: (event) {
        if (_triggered) return;
        if (!_allowed) return;
        final start = _start;
        if (start == null) return;

        final dx = event.position.dx - start.dx;
        final dy = (event.position.dy - start.dy).abs();
        if (dy > widget.maxVerticalSlop) return;

        if (dx >= widget.minHorizontalDrag) {
          _triggered = true;
          _openDrawerIfPossible();
        }
      },
      onPointerUp: (_) {
        _start = null;
        _allowed = false;
        _triggered = false;
      },
      onPointerCancel: (_) {
        _start = null;
        _allowed = false;
        _triggered = false;
      },
      child: widget.child,
    );
  }
}
