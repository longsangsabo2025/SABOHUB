import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity state
enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}

/// Provider for network connectivity status
final networkStatusProvider = NotifierProvider<NetworkStatusNotifier, NetworkStatus>(() {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  StreamSubscription? _subscription;

  @override
  NetworkStatus build() {
    // Initialize listener
    _initializeListener();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _subscription?.cancel();
    });
    
    return NetworkStatus.unknown;
  }

  Future<void> _initializeListener() async {
    // Check initial status
    final result = await Connectivity().checkConnectivity();
    state = _getStatusFromResults(result);

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      state = _getStatusFromResults(results);
    });
  }

  NetworkStatus _getStatusFromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return NetworkStatus.disconnected;
    }
    return NetworkStatus.connected;
  }
}

/// Widget that shows network status banner when offline
class NetworkStatusBanner extends ConsumerWidget {
  final Widget child;
  final bool showWhenOnline;

  const NetworkStatusBanner({
    super.key,
    required this.child,
    this.showWhenOnline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: status == NetworkStatus.disconnected ? 32 : 0,
          child: status == NetworkStatus.disconnected
              ? Container(
                  color: Colors.red.shade600,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Không có kết nối mạng',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Main content
        Expanded(child: child),
      ],
    );
  }
}

/// Hook/Extension to easily check network status
extension NetworkStatusExtension on WidgetRef {
  bool get isOnline => watch(networkStatusProvider) == NetworkStatus.connected;
  bool get isOffline => watch(networkStatusProvider) == NetworkStatus.disconnected;
}

/// Widget that wraps content and shows offline message when no network
class OfflineAwareWidget extends ConsumerWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool allowOffline;

  const OfflineAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.allowOffline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    if (status == NetworkStatus.disconnected && !allowOffline) {
      return offlineWidget ?? _buildDefaultOfflineWidget(context);
    }

    return child;
  }

  Widget _buildDefaultOfflineWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có kết nối mạng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra kết nối và thử lại',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                // Just check - the provider listener will update UI
                await Connectivity().checkConnectivity();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a snackbar when network status changes
class NetworkStatusListener extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkStatusListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends ConsumerState<NetworkStatusListener> {
  NetworkStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    ref.listen(networkStatusProvider, (previous, next) {
      if (_previousStatus != null && previous != next) {
        if (next == NetworkStatus.disconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Mất kết nối mạng'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (next == NetworkStatus.connected && _previousStatus == NetworkStatus.disconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã kết nối lại'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      _previousStatus = next;
    });

    return widget.child;
  }
}
