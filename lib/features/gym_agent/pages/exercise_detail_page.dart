import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/exercise.dart';
import '../services/wger_api_service.dart';
import '../widgets/youtube_exercise_widget.dart';

/// Exercise Detail Page — full info with images, muscle SVG, YouTube video.
///
/// Data loading strategy:
/// - exerciseinfo API call only when user opens this page (on-demand)
/// - Images: CachedNetworkImage with placeholder/shimmer
/// - Muscle SVG: ~5KB each, loaded inline
/// - Video: YouTube link-out (zero bandwidth)
class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  static const _gymColor = Color(0xFF10B981);

  WgerExerciseDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (widget.exercise.wgerId == null) {
      // Built-in exercise — no API call needed
      setState(() => _loading = false);
      return;
    }
    try {
      final detail =
          await WgerApiService().getExerciseDetail(widget.exercise.wgerId!);
      if (mounted) setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = _detail?.exercise ?? widget.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(ex.displayName),
        backgroundColor: _gymColor,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Lỗi tải chi tiết', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () { setState(() { _error = null; _loading = true; }); _loadDetail(); },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image Gallery ─────────────────────────
            if (_loading)
              _buildImagePlaceholder()
            else if (_detail != null && _detail!.imageUrls.isNotEmpty)
              _buildImageGallery(_detail!.imageUrls)
            else
              _buildNoImageBanner(),

            const SizedBox(height: 16),

            // ─── Category + Equipment chips ────────────
            _buildChipRow(ex),

            const SizedBox(height: 16),

            // ─── Muscle Groups ─────────────────────────
            if (ex.primaryMuscles.isNotEmpty) ...[
              _buildSectionTitle('💪 Cơ chính'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ex.primaryMuscles
                    .map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 13)),
                          backgroundColor: _gymColor.withValues(alpha: 0.1),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            if (ex.secondaryMuscles.isNotEmpty) ...[
              _buildSectionTitle('🔗 Cơ phụ'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ex.secondaryMuscles
                    .map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 13)),
                          backgroundColor: Colors.grey[100],
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            // ─── Muscle Anatomy SVG ────────────────────
            if (!_loading && _detail != null) ...[
              if (_detail!.muscleSvgMain.isNotEmpty ||
                  _detail!.muscleSvgSecondary.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('🧬 Bản đồ cơ bắp'),
                const SizedBox(height: 8),
                _buildMuscleSvgRow(),
              ],
            ],

            const SizedBox(height: 16),

            // ─── Description ───────────────────────────
            if (ex.description != null && ex.description!.isNotEmpty) ...[
              _buildSectionTitle('📝 Hướng dẫn'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ex.description!,
                  style: const TextStyle(height: 1.6, fontSize: 14),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ─── YouTube Video ─────────────────────────
            YouTubeExerciseCard(exerciseName: ex.name),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _gymColor),
      ),
    );
  }

  Widget _buildImageGallery(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: urls.first,
          height: 220,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholder: (_, __) => _buildImagePlaceholder(),
          errorWidget: (_, __, ___) => _buildNoImageBanner(),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: urls[index],
            height: 220,
            width: 280,
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(
              width: 280,
              color: Colors.grey[100],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 280,
              color: Colors.grey[100],
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoImageBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _gymColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _categoryEmoji(widget.exercise.category),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exercise.category,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipRow(Exercise ex) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Chip(
          avatar: Text(ex.difficulty.emoji),
          label: Text(ex.difficulty.label),
        ),
        Chip(label: Text(ex.category)),
        if (ex.equipment.isNotEmpty)
          ...ex.equipment.map((e) => Chip(
                avatar: const Icon(Icons.fitness_center, size: 16),
                label: Text(e, style: const TextStyle(fontSize: 12)),
              )),
      ],
    );
  }

  Widget _buildMuscleSvgRow() {
    final mainSvgs = _detail!.muscleSvgMain;
    final secSvgs = _detail!.muscleSvgSecondary;
    final allSvgs = [...mainSvgs, ...secSvgs];

    if (allSvgs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allSvgs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isMain = index < mainSvgs.length;
          return Container(
            width: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMain
                  ? _gymColor.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMain
                    ? _gymColor.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SvgPicture.network(
                    allSvgs[index],
                    placeholderBuilder: (_) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMain ? 'Cơ chính' : 'Cơ phụ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isMain ? _gymColor : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Ngực': return '🫁';
      case 'Lưng': return '🔙';
      case 'Vai': return '🤷';
      case 'Tay trước': case 'Tay': return '💪';
      case 'Tay sau': return '🦾';
      case 'Chân': return '🦵';
      case 'Bụng': return '🎯';
      case 'Cardio': return '❤️';
      case 'Bắp chân': return '🦶';
      default: return '🏋️';
    }
  }
}
