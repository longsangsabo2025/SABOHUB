import 'package:flutter/material.dart';

/// Shimmer effect animation for skeleton loading
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Basic skeleton box with customizable dimensions
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color color;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.color = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

/// Skeleton for circular avatars
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListItem extends StatelessWidget {
  final bool hasAvatar;
  final bool hasSubtitle;
  final bool hasTrailing;

  const SkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.hasSubtitle = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (hasAvatar) ...[
              const SkeletonAvatar(),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 150, height: 16),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 8),
                    const SkeletonText(width: 100, height: 12),
                  ],
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              const SkeletonBox(width: 60, height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for cards with KPIs
class SkeletonKPICard extends StatelessWidget {
  const SkeletonKPICard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(8),
                ),
                const Spacer(),
                const SkeletonBox(width: 16, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonText(width: 80, height: 24),
            const SizedBox(height: 4),
            const SkeletonText(width: 60, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for dashboard grid
class SkeletonDashboard extends StatelessWidget {
  final int kpiCount;
  final int listItemCount;

  const SkeletonDashboard({
    super.key,
    this.kpiCount = 4,
    this.listItemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section skeleton
          ShimmerEffect(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 200, height: 24),
                  SizedBox(height: 8),
                  SkeletonText(width: 150, height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // KPI grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: kpiCount,
            itemBuilder: (context, index) => const SkeletonKPICard(),
          ),
          const SizedBox(height: 24),
          // List section skeleton
          ShimmerEffect(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 150, height: 20),
                  const SizedBox(height: 16),
                  ...List.generate(
                    listItemCount,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const SkeletonAvatar(size: 40),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonText(width: 120, height: 14),
                                SizedBox(height: 4),
                                SkeletonText(width: 80, height: 12),
                              ],
                            ),
                          ),
                          const SkeletonBox(width: 50, height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for delivery/order cards
class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonText(width: 100, height: 16),
                  SkeletonBox(
                    width: 80,
                    height: 24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SkeletonText(width: 180, height: 18),
              const SizedBox(height: 8),
              const Row(
                children: [
                  SkeletonBox(width: 16, height: 16),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonText(height: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SkeletonBox(
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(
                      height: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for list of orders/deliveries
class SkeletonOrderList extends StatelessWidget {
  final int itemCount;

  const SkeletonOrderList({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonOrderCard(),
    );
  }
}

/// Skeleton wrapper that shows skeleton while loading
class SkeletonWrapper<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget skeleton;
  final Widget Function(T data) builder;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const SkeletonWrapper({
    super.key,
    required this.asyncValue,
    required this.skeleton,
    required this.builder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: builder,
      loading: () => skeleton,
      error: (error, stack) =>
          errorBuilder?.call(error, stack) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: $error'),
              ],
            ),
          ),
    );
  }
}

/// Helper class for AsyncValue
class AsyncValue<T> {
  final T? data;
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;

  const AsyncValue._({
    this.data,
    this.isLoading = false,
    this.error,
    this.stackTrace,
  });

  factory AsyncValue.data(T data) => AsyncValue._(data: data);
  factory AsyncValue.loading() => const AsyncValue._(isLoading: true);
  factory AsyncValue.error(Object error, [StackTrace? stack]) =>
      AsyncValue._(error: error, stackTrace: stack);

  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stack) error,
  }) {
    if (isLoading) return loading();
    if (this.error != null) return error(this.error!, stackTrace);
    return data(this.data as T);
  }
}
