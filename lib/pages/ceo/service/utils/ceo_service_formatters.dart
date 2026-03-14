String formatCeoMoneyMetric(double value) {
  if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}ty';
  if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}tr';
  if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(0)}k';
  return '${value.toInt()}d';
}

String formatCeoMoneyShort(double value) {
  if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}tr';
  if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(0)}k';
  return '${value.toInt()}d';
}

String formatCeoCountCompact(int value) {
  if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
  if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
  return '$value';
}
