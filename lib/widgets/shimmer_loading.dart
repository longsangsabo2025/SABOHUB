import 'package:flutter/material.dart';

/// Shimmer loading placeholder widgets for skeleton screens
/// Provides loading placeholders that animate while data loads

/// Base shimmer container with animation
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder for company header section
class ShimmerCompanyHeader extends StatelessWidget {
  const ShimmerCompanyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBox(width: 60, height: 60, borderRadius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 180, height: 20),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 120, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ShimmerBox(height: 48),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for summary cards
class ShimmerSummaryCards extends StatelessWidget {
  final int itemCount;

  const ShimmerSummaryCards({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        itemCount,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == itemCount - 1 ? 0 : 6,
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBox(width: 80, height: 14),
                  SizedBox(height: 12),
                  _ShimmerBox(width: 60, height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for chart sections
class ShimmerChart extends StatelessWidget {
  final double height;

  const ShimmerChart({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(width: 140, height: 18),
          const SizedBox(height: 16),
          _ShimmerBox(height: height - 50),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for transaction rows
class ShimmerTransactionRow extends StatelessWidget {
  final int itemCount;

  const ShimmerTransactionRow({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 12 : 0),
            child: Row(
              children: const [
                _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(height: 14),
                      SizedBox(height: 6),
                      _ShimmerBox(width: 80, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                _ShimmerBox(width: 60, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
