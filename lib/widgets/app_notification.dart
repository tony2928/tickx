import 'dart:async';

import 'package:flutter/material.dart';

enum AppNotificationType { info, success, warning, error }

class AppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismissCurrent();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    final visual = _visualFor(type);

    final entry = OverlayEntry(
      builder: (context) => _DesktopNotificationWidget(
        message: message,
        background: visual.background,
        border: visual.border,
        icon: visual.icon,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, _dismissCurrent);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static _NotificationVisual _visualFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return const _NotificationVisual(
          background: Color(0xFFEAF9EF),
          border: Color(0xFF2E9E5B),
          icon: Icons.check_circle,
        );
      case AppNotificationType.warning:
        return const _NotificationVisual(
          background: Color(0xFFFFF6E8),
          border: Color(0xFFE2A529),
          icon: Icons.warning_amber_rounded,
        );
      case AppNotificationType.error:
        return const _NotificationVisual(
          background: Color(0xFFFFEEF0),
          border: Color(0xFFD6455A),
          icon: Icons.error,
        );
      case AppNotificationType.info:
        return const _NotificationVisual(
          background: Color(0xFFEDF4FF),
          border: Color(0xFF3B82F6),
          icon: Icons.info,
        );
    }
  }
}

class _DesktopNotificationWidget extends StatefulWidget {
  final String message;
  final Color background;
  final Color border;
  final IconData icon;

  const _DesktopNotificationWidget({
    required this.message,
    required this.background,
    required this.border,
    required this.icon,
  });

  @override
  State<_DesktopNotificationWidget> createState() =>
      _DesktopNotificationWidgetState();
}

class _DesktopNotificationWidgetState extends State<_DesktopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 16,
      right: 18,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.border, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.border, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
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
    );
  }
}

class _NotificationVisual {
  final Color background;
  final Color border;
  final IconData icon;

  const _NotificationVisual({
    required this.background,
    required this.border,
    required this.icon,
  });
}
