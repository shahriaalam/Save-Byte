import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a scrollable screen to prevent rubber-band overscroll at the top
/// (eliminating blank white gaps) and reloads the page when the user
/// pulls down at the top boundary twice within a 2-second window.
class DoublePullReload extends StatefulWidget {
  const DoublePullReload({
    required this.child,
    required this.onReload,
    this.hintMessage = 'Pull down once more to reload',
    this.reloadingMessage = 'Reloading...',
    super.key,
  });

  final Widget child;
  final Future<void> Function() onReload;
  final String hintMessage;
  final String reloadingMessage;

  @override
  State<DoublePullReload> createState() => _DoublePullReloadState();
}

class _DoublePullReloadState extends State<DoublePullReload> {
  DateTime? _lastPullTime;
  int _pullCount = 0;
  double _accumulatedDownDrag = 0.0;
  bool _isReloading = false;
  bool _isAtTop = true;
  bool _dragStartedAtTop = false;
  Timer? _resetTimer;

  void _onPullDetected() {
    final now = DateTime.now();
    if (_pullCount == 1 &&
        _lastPullTime != null &&
        now.difference(_lastPullTime!) <= const Duration(seconds: 2)) {
      // Second pull within 2 seconds: Trigger reload!
      _pullCount = 0;
      _lastPullTime = null;
      _resetTimer?.cancel();
      _triggerReload();
    } else {
      // First pull: Record and notify user
      _pullCount = 1;
      _lastPullTime = now;
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _pullCount = 0;
            _lastPullTime = null;
          });
        }
      });
      HapticFeedback.lightImpact();
      if (mounted && widget.hintMessage.isNotEmpty) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.removeCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.hintMessage,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 84, left: 24, right: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _triggerReload() async {
    if (_isReloading) return;
    setState(() => _isReloading = true);
    HapticFeedback.mediumImpact();

    if (mounted && widget.reloadingMessage.isNotEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.reloadingMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 84, left: 24, right: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    try {
      await widget.onReload();
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _accumulatedDownDrag = 0.0;
        _dragStartedAtTop = _isAtTop;
      },
      onPointerMove: (event) {
        if (_dragStartedAtTop) {
          if (event.delta.dy > 0) {
            _accumulatedDownDrag += event.delta.dy;
          } else if (event.delta.dy < -2) {
            _accumulatedDownDrag = 0.0;
          }
        }
      },
      onPointerUp: (_) {
        if (_dragStartedAtTop && _accumulatedDownDrag >= 20.0 && !_isReloading) {
          _onPullDetected();
        }
        _accumulatedDownDrag = 0.0;
        _dragStartedAtTop = false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels <= 1.0) {
            _isAtTop = true;
          } else {
            _isAtTop = false;
          }
          if (_dragStartedAtTop &&
              notification is OverscrollNotification &&
              notification.overscroll < 0) {
            _accumulatedDownDrag += notification.overscroll.abs();
          }
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
