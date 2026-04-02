import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../pages/exercise_detail_page.dart';
import '../services/wger_api_service.dart';

/// Exercise Library — Browse 896+ exercises from wger API.
///
/// Architecture:
/// - Paginated (20/page) with infinite scroll
/// - Category filter chips from wger API categories
/// - Search with debounce (500ms)
/// - CachedNetworkImage for thumbnails
/// - Tap → ExerciseDetailPage (full page, not bottom sheet)
class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key});

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  static const _gymColor = Color(0xFF10B981);

  final _wger = WgerApiService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  // State
  List<Exercise> _exercises = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  int _total = 0;

  // Filters
  int? _selectedCategoryId; // null = "Tất cả"
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadExercises();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadExercises() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _wger.ensureRefData();
      final result = await _wger.getExercises(
        page: 1,
        categoryId: _selectedCategoryId,
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
      );
      if (mounted) {
        setState(() {
          _exercises = result.exercises;
          _hasMore = result.hasMore;
          _total = result.total;
          _page = 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _wger.getExercises(
        page: _page + 1,
        categoryId: _selectedCategoryId,
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
      );
      if (mounted) {
        setState(() {
          _exercises.addAll(result.exercises);
          _hasMore = result.hasMore;
          _page = _page + 1;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchTerm != value) {
        _searchTerm = value;
        _loadExercises();
      }
    });
  }

  void _onCategorySelected(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryChips(),
        if (_total > 0 && !_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_total bài tập',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Tìm bài tập (English)...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    // Build chip list: "Tất cả" + wger categories mapped to Vietnamese
    const viNames = {
      'Abs': 'Bụng',
      'Back': 'Lưng',
      'Chest': 'Ngực',
      'Shoulders': 'Vai',
      'Legs': 'Chân',
      'Arms': 'Tay',
      'Calves': 'Bắp chân',
      'Cardio': 'Cardio',
    };

    final cats = _wger.categories.entries.toList();
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: cats.length + 1, // +1 for "Tất cả"
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return FilterChip(
              label: const Text('Tất cả', style: TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => _onCategorySelected(null),
              selectedColor: _gymColor.withValues(alpha: 0.15),
              checkmarkColor: _gymColor,
            );
          }
          final entry = cats[index - 1];
          final viName = viNames[entry.value] ?? entry.value;
          final isSelected = _selectedCategoryId == entry.key;
          return FilterChip(
            label: Text(viName, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => _onCategorySelected(entry.key),
            selectedColor: _gymColor.withValues(alpha: 0.15),
            checkmarkColor: _gymColor,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _gymColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Lỗi kết nối wger', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadExercises,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Không tìm thấy bài tập',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _gymColor,
      onRefresh: _loadExercises,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == _exercises.length) {
            // Loading more indicator
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _gymColor,
                  ),
                ),
              ),
            );
          }
          return _ExerciseTile(
            exercise: _exercises[index],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseDetailPage(
                  exercise: _exercises[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  static const _gymColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildLeading(),
        title: Text(
          exercise.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              exercise.category,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (exercise.primaryMuscles.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Text('·', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  exercise.primaryMuscles.take(2).join(', '),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading() {
    // If exercise has an imageUrl, show thumbnail
    if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: exercise.imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _buildEmojiLeading(),
        ),
      );
    }
    return _buildEmojiLeading();
  }

  Widget _buildEmojiLeading() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _gymColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _categoryEmoji(exercise.category),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Ngực': return '🫁';
      case 'Lưng': return '🔙';
      case 'Vai': return '🤷';
      case 'Tay': case 'Tay trước': return '💪';
      case 'Tay sau': return '🦾';
      case 'Chân': return '🦵';
      case 'Bụng': return '🎯';
      case 'Cardio': return '❤️';
      case 'Bắp chân': return '🦶';
      default: return '🏋️';
    }
  }
}
