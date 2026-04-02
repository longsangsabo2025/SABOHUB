import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/gym_stats_viewmodel.dart';

/// Gym Progress Charts — Visualize workout volume, strength, and body metrics.
class GymProgressPage extends ConsumerWidget {
  const GymProgressPage({super.key});

  static const _gymColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gymStatsProvider).asData?.value ?? GymStats.empty();

    return RefreshIndicator(
      onRefresh: () => ref.read(gymStatsProvider.notifier).refresh(),
      color: _gymColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVolumeChart(context, stats.weeklyVolumeByDay),
            const SizedBox(height: 20),
            _buildStrengthChart(context),
            const SizedBox(height: 20),
            _buildBodyWeightChart(context),
            const SizedBox(height: 20),
            _buildMuscleGroupDistribution(context),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // WEEKLY VOLUME CHART (BarChart)
  // ==============================================
  Widget _buildVolumeChart(BuildContext context, List<double> weeklyVolume) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxRaw = weeklyVolume.reduce((a, b) => a > b ? a : b);
    final maxY = (maxRaw > 0 ? maxRaw : 1000.0) * 1.3;

    return _ChartCard(
      title: 'Volume tuan nay (kg)',
      subtitle: 'Tong: ${weeklyVolume.reduce((a, b) => a + b).toStringAsFixed(0)} kg',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toStringAsFixed(0)} kg',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[index],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    final label = value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}K'
                        : value.toStringAsFixed(0);
                    return Text(label, style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: weeklyVolume.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: entry.value > 0 ? _gymColor : Colors.grey.shade200,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // STRENGTH PROGRESS (LineChart)
  // ==============================================
  Widget _buildStrengthChart(BuildContext context) {
    // Placeholder — future: track max weights per exercise
    final benchData = [60.0, 62.5, 65.0, 65.0, 67.5, 70.0, 72.5, 75.0];
    final squatData = [80.0, 82.5, 85.0, 87.5, 90.0, 90.0, 92.5, 95.0];
    final deadliftData = [100.0, 105.0, 107.5, 110.0, 112.5, 115.0, 117.5, 120.0];
    final weeks = List.generate(8, (i) => 'W${i + 1}');

    final maxY =
        [...benchData, ...squatData, ...deadliftData].reduce((a, b) => a > b ? a : b) * 1.15;

    return _ChartCard(
      title: 'Tien bo suc manh (kg)',
      subtitle: '8 tuan gan nhat',
      legend: const [
        _LegendItem('Bench Press', Colors.blue),
        _LegendItem('Squat', _gymColor),
        _LegendItem('Deadlift', Colors.orange),
      ],
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= weeks.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(weeks[index],
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) =>
                        Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 50,
              maxY: maxY,
              lineBarsData: [
                _lineBarData(benchData, Colors.blue),
                _lineBarData(squatData, _gymColor),
                _lineBarData(deadliftData, Colors.orange),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    final labels = ['Bench', 'Squat', 'Deadlift'];
                    return spots.asMap().entries.map((entry) {
                      return LineTooltipItem(
                        '${labels[entry.key]}: ${entry.value.y.toStringAsFixed(1)}kg',
                        TextStyle(
                          color: entry.value.bar.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
    );
  }

  LineChartBarData _lineBarData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.05),
      ),
    );
  }

  // ==============================================
  // BODY WEIGHT TREND (LineChart)
  // ==============================================
  Widget _buildBodyWeightChart(BuildContext context) {
    // Placeholder — future: from GymSession bodyWeight tracking
    final weights = [75.0, 74.8, 74.5, 74.2, 74.0, 73.8, 73.5, 73.2];

    return _ChartCard(
      title: 'Can nang (kg)',
      subtitle: '${weights.last}kg - giam ${(weights.first - weights.last).toStringAsFixed(1)}kg',
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minY: weights.reduce((a, b) => a < b ? a : b) - 1,
            maxY: weights.reduce((a, b) => a > b ? a : b) + 1,
            lineBarsData: [
              LineChartBarData(
                spots: weights
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MUSCLE GROUP DISTRIBUTION (PieChart)
  // ==============================================
  Widget _buildMuscleGroupDistribution(BuildContext context) {
    // Placeholder — future: aggregate from GymSession exercise categories
    final groups = [
      _MuscleGroup('Nguc', 22, Colors.red),
      _MuscleGroup('Lung', 20, Colors.blue),
      _MuscleGroup('Chan', 25, _gymColor),
      _MuscleGroup('Vai', 12, Colors.orange),
      _MuscleGroup('Tay', 10, Colors.purple),
      _MuscleGroup('Bung', 6, Colors.teal),
      _MuscleGroup('Cardio', 5, Colors.pink),
    ];

    return _ChartCard(
      title: 'Phan bo nhom co',
      subtitle: 'Ti le % volume theo nhom co',
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: groups.map((g) {
                    return PieChartSectionData(
                      value: g.percent,
                      color: g.color,
                      radius: 50,
                      title: '${g.percent.toInt()}%',
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groups.map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: g.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${g.name} ${g.percent.toInt()}%',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// SHARED WIDGETS
// ==============================================

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<_LegendItem>? legend;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (legend != null) ...[
              const SizedBox(height: 8),
              Row(
                children: legend!
                    .map((l) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: l.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(l.label,
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}

class _MuscleGroup {
  final String name;
  final double percent;
  final Color color;
  _MuscleGroup(this.name, this.percent, this.color);
}
