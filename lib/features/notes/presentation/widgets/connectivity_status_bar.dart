import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/network_info.dart';

class ConnectivityStatusBar extends StatefulWidget {
  const ConnectivityStatusBar({super.key, required this.networkInfo});

  final NetworkInfo networkInfo;

  @override
  State<ConnectivityStatusBar> createState() => _ConnectivityStatusBarState();
}

class _ConnectivityStatusBarState extends State<ConnectivityStatusBar> {
  late bool _isOnline;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _isOnline = true;
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connected = await widget.networkInfo.isConnected;
    if (mounted) {
      setState(() => _isOnline = connected);
    }

    _subscription = widget.networkInfo.onConnectivityChanged.listen(
      (isConnected) {
        if (mounted) {
          setState(() => _isOnline = isConnected);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (Color dot, Color bg, Color fg, String label) = _isOnline
        ? (
            AppTheme.onlineGreen,
            AppTheme.onlineBg,
            AppTheme.onlineGreen,
            'Online',
          )
        : (
            AppTheme.inkSoft,
            AppTheme.offlineBg,
            AppTheme.inkMuted,
            'Offline',
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}
