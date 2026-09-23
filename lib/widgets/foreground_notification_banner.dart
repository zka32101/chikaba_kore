import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/app_notification.dart';

/// フォアグラウンド受信時のアプリ内通知バナー。
///
/// `ScaffoldMessenger.showSnackBar`ではなく`Overlay`に直接`OverlayEntry`を挿入する
/// 専用実装とし、画面最上部（SafeArea考慮）にスライドイン＋自動消滅するバナーとして表示する。
/// これによりSnackBarの制約（画面下部固定でナビゲーション等と競合、アイコン非対応、
/// 他のSnackBarと表示キューを共有してしまう）を避ける。
///
/// 複数の通知がほぼ同時に届いた場合、[ForegroundBannerQueue]は常に1件だけを表示し、
/// 表示中の1件が消えた（自動タイムアウト／タップ／✕）タイミングでキューの次の1件を
/// 表示する直列キューとして動作する。
class ForegroundBannerQueue {
  final Queue<_QueuedNotification> _pending = Queue();
  bool _isShowing = false;

  /// 通知をキューへ追加する。何も表示中でなければ即座に表示を開始し、
  /// 表示中であれば現在のバナーが消えるまで待ってから表示する。
  void enqueue(
    OverlayState overlay,
    AppNotification notification, {
    VoidCallback? onTap,
    Duration displayDuration = const Duration(seconds: 5),
  }) {
    _pending.add(_QueuedNotification(notification: notification, onTap: onTap, displayDuration: displayDuration));
    _showNextIfIdle(overlay);
  }

  void _showNextIfIdle(OverlayState overlay) {
    if (_isShowing || _pending.isEmpty) return;
    _isShowing = true;
    final item = _pending.removeFirst();

    late OverlayEntry entry;
    final dismiss = _DismissHandle();

    entry = OverlayEntry(
      builder: (context) => _ForegroundBanner(
        notification: item.notification,
        displayDuration: item.displayDuration,
        dismissHandle: dismiss,
        onTap: () {
          dismiss.dismiss();
          item.onTap?.call();
        },
        onDismissed: () {
          if (entry.mounted) entry.remove();
          _isShowing = false;
          _showNextIfIdle(overlay); // キューに次があれば続けて表示する
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _QueuedNotification {
  const _QueuedNotification({required this.notification, required this.onTap, required this.displayDuration});
  final AppNotification notification;
  final VoidCallback? onTap;
  final Duration displayDuration;
}

/// アニメーション側から「外部（タップ等）から即座に消す」トリガーを受け取るための小さな仲介役。
class _DismissHandle {
  VoidCallback? _onDismissRequested;
  void dismiss() => _onDismissRequested?.call();
}

class _ForegroundBanner extends StatefulWidget {
  const _ForegroundBanner({
    required this.notification,
    required this.displayDuration,
    required this.dismissHandle,
    required this.onTap,
    required this.onDismissed,
  });

  final AppNotification notification;
  final Duration displayDuration;
  final _DismissHandle dismissHandle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  State<_ForegroundBanner> createState() => _ForegroundBannerState();
}

class _ForegroundBannerState extends State<_ForegroundBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    widget.dismissHandle._onDismissRequested = _dismiss;
    _controller.forward();
    _autoDismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              color: theme.colorScheme.primaryContainer,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _dismiss();
                  widget.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.campaign_outlined, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.notification.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.notification.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkResponse(
                        onTap: _dismiss,
                        radius: 20,
                        child: Icon(Icons.close, size: 20, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
