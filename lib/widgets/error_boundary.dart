import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_errors.dart';
import '../core/errors/error_handler.dart';
import 'sabo_refresh_button.dart';

/// Global error boundary widget that catches and handles errors
class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget Function(AppError error)? errorBuilder;
  final void Function(AppError error)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  AppError? _error;
  late final ErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();

    // Cache error handler to avoid using ref in dispose
    _errorHandler = ref.read(errorHandlerProvider);
    _errorHandler.addListener(_handleError);
  }

  @override
  void dispose() {
    // Use cached handler instead of ref
    _errorHandler.removeListener(_handleError);
    super.dispose();
  }

  void _handleError(AppError error) {
    if (mounted) {
      setState(() {
        _error = error;
      });

      // Call custom error handler if provided
      widget.onError?.call(error);

      // Show error snackbar for medium/high severity errors
      if (error.severity == ErrorSeverity.medium ||
          error.severity == ErrorSeverity.high) {
        _showErrorSnackbar(error);
      }
    }
  }

  void _showErrorSnackbar(AppError error) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.severity),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        duration: Duration(
          seconds: error.severity == ErrorSeverity.high ? 5 : 3,
        ),
        action: error.severity == ErrorSeverity.high
            ? SnackBarAction(
                label: 'Chi tiết',
                textColor: Colors.white,
                onPressed: () => _showErrorDialog(error),
              )
            : null,
      ),
    );
  }

  void _showErrorDialog(AppError error) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(error: error),
    );
  }

  IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info;
      case ErrorSeverity.medium:
        return Icons.warning;
      case ErrorSeverity.high:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If there's a critical error, show error widget
    if (_error?.severity == ErrorSeverity.critical) {
      return widget.errorBuilder?.call(_error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _clearError,
          );
    }

    return widget.child;
  }
}

/// Default error widget for critical errors
class _DefaultErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Đã xảy ra lỗi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error.userMessage,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SaboRefreshButton.refreshColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error dialog for detailed error information
class ErrorDialog extends StatelessWidget {
  final AppError error;

  const ErrorDialog({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          const Text('Chi tiết lỗi'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thông báo:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(error.userMessage),
            const SizedBox(height: 16),
            if (error.code != null) ...[
              Text(
                'Mã lỗi:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(error.code!),
              const SizedBox(height: 16),
            ],
            Text(
              'Thời gian:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(error.timestamp.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
