import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

/// A deterministic, unique avatar for each customer based on their name/code.
/// Uses Multiavatar to generate 12 billion+ unique SVG avatars.
class CustomerAvatar extends StatelessWidget {
  /// The string used to generate the avatar (typically customer name or code).
  final String seed;

  /// Radius of the circular avatar.
  final double radius;

  /// Optional background color. If null, uses transparent.
  final Color? backgroundColor;

  /// Optional border — e.g. for credit limit highlight.
  final Border? border;

  const CustomerAvatar({
    super.key,
    required this.seed,
    this.radius = 20,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final svgCode = multiavatar(seed.isNotEmpty ? seed : '?');
    final size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(radius * 0.1),
        child: SvgPicture.string(
          svgCode,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
