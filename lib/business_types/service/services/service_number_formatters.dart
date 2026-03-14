import 'package:intl/intl.dart';

String formatServiceRevenueCompact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

String formatServiceCountCompact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String formatServiceCurrencyCompact(double value) {
  if (value.abs() >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(1)}B';
  }
  if (value.abs() >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(1)}M';
  }
  if (value.abs() >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(1)}K';
  }
  return NumberFormat('#,###').format(value);
}
