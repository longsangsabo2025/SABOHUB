import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

/// wger.de REST API service with local caching.
///
/// Architecture:
/// - Paginated fetches (20/page) — never loads 896 at once
/// - SharedPreferences cache with TTL (24h for list, 7d for detail)
/// - Muscle/equipment maps cached permanently (15 muscles, ~20 equipment)
class WgerApiService {
  static const _baseUrl = 'https://wger.de/api/v2';
  static const _language = 2; // English
  static const _pageSize = 20;
  static const _listCacheTtl = Duration(hours: 24);
  static const _detailCacheTtl = Duration(days: 7);
  static const _refCacheKey = 'wger_ref_data';

  // In-memory lookup maps (loaded once)
  Map<int, String> _muscles = {};
  Map<int, String> _equipment = {};
  Map<int, String> _categories = {};
  Map<int, _MuscleInfo> _muscleInfo = {};
  bool _refLoaded = false;

  /// Singleton
  static final WgerApiService _instance = WgerApiService._();
  factory WgerApiService() => _instance;
  WgerApiService._();

  // ─── Reference Data (muscles, equipment, categories) ───────────

  /// Load muscle/equipment/category maps. Called once, cached permanently.
  Future<void> ensureRefData() async {
    if (_refLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_refCacheKey);

    if (cached != null) {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      _muscles = (data['muscles'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      _equipment = (data['equipment'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      _categories = (data['categories'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      if (data['muscleInfo'] != null) {
        _muscleInfo = (data['muscleInfo'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            int.parse(k),
            _MuscleInfo.fromJson(v as Map<String, dynamic>),
          ),
        );
      }
      _refLoaded = true;
      return;
    }

    // Fetch from API
    await Future.wait([
      _fetchMuscles(),
      _fetchEquipment(),
      _fetchCategories(),
    ]);
    _refLoaded = true;

    // Persist
    final toCache = jsonEncode({
      'muscles': _muscles.map((k, v) => MapEntry(k.toString(), v)),
      'equipment': _equipment.map((k, v) => MapEntry(k.toString(), v)),
      'categories': _categories.map((k, v) => MapEntry(k.toString(), v)),
      'muscleInfo': _muscleInfo.map(
        (k, v) => MapEntry(k.toString(), v.toJson()),
      ),
    });
    await prefs.setString(_refCacheKey, toCache);
  }

  Future<void> _fetchMuscles() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/muscle/?format=json&limit=50'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      for (final m in data['results'] as List) {
        final id = m['id'] as int;
        final nameEn = (m['name_en'] as String?)?.isNotEmpty == true
            ? m['name_en'] as String
            : m['name'] as String;
        _muscles[id] = nameEn;
        _muscleInfo[id] = _MuscleInfo(
          name: nameEn,
          isFront: m['is_front'] as bool? ?? true,
          imageUrlMain: m['image_url_main'] as String?,
          imageUrlSecondary: m['image_url_secondary'] as String?,
        );
      }
    }
  }

  Future<void> _fetchEquipment() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/equipment/?format=json&limit=50'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      for (final e in data['results'] as List) {
        _equipment[e['id'] as int] = e['name'] as String;
      }
    }
  }

  Future<void> _fetchCategories() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/exercisecategory/?format=json&limit=50'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      for (final c in data['results'] as List) {
        _categories[c['id'] as int] = c['name'] as String;
      }
    }
  }

  // ─── Getters for reference data ────────────────────────────────

  Map<int, String> get categories => _categories;
  Map<int, String> get muscles => _muscles;

  /// Get muscle SVG diagram URLs for anatomy visualization.
  List<String> getMuscleMainSvgs(List<int> muscleIds) {
    return muscleIds
        .where((id) => _muscleInfo[id]?.imageUrlMain != null)
        .map((id) => _muscleInfo[id]!.imageUrlMain!)
        .toList();
  }

  List<String> getMuscleSecondarySvgs(List<int> muscleIds) {
    return muscleIds
        .where((id) => _muscleInfo[id]?.imageUrlSecondary != null)
        .map((id) => _muscleInfo[id]!.imageUrlSecondary!)
        .toList();
  }

  // ─── Exercise List (paginated + cached) ────────────────────────

  /// Fetch exercises page. Returns list + hasMore flag.
  Future<WgerExercisePage> getExercises({
    int page = 1,
    int? categoryId,
    String? searchTerm,
  }) async {
    await ensureRefData();

    final cacheKey = 'wger_ex_p${page}_c${categoryId ?? 'all'}_s${searchTerm ?? ''}';
    final prefs = await SharedPreferences.getInstance();

    // Check cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final ts = DateTime.parse(data['ts'] as String);
      if (DateTime.now().difference(ts) < _listCacheTtl) {
        return WgerExercisePage.fromJson(data);
      }
    }

    // Build URL
    final offset = (page - 1) * _pageSize;
    var url = '$_baseUrl/exercise/?format=json&language=$_language'
        '&limit=$_pageSize&offset=$offset';
    if (categoryId != null) url += '&category=$categoryId';
    if (searchTerm != null && searchTerm.isNotEmpty) {
      url += '&term=$searchTerm';
    }

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('wger API error: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'] as List;
    final hasMore = body['next'] != null;
    final total = body['count'] as int? ?? 0;

    final exercises = results.map((raw) => _mapExercise(raw)).toList();

    final result = WgerExercisePage(
      exercises: exercises,
      hasMore: hasMore,
      total: total,
      page: page,
    );

    // Cache
    await prefs.setString(cacheKey, jsonEncode({
      ...result.toJson(),
      'ts': DateTime.now().toIso8601String(),
    }));

    return result;
  }

  // ─── Exercise Detail (with images) ─────────────────────────────

  /// Fetch full exercise info including images.
  Future<WgerExerciseDetail> getExerciseDetail(int exerciseId) async {
    await ensureRefData();

    final cacheKey = 'wger_detail_$exerciseId';
    final prefs = await SharedPreferences.getInstance();

    // Check cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final ts = DateTime.parse(data['ts'] as String);
      if (DateTime.now().difference(ts) < _detailCacheTtl) {
        return WgerExerciseDetail.fromJson(data);
      }
    }

    final res = await http
        .get(Uri.parse('$_baseUrl/exerciseinfo/$exerciseId/?format=json'));
    if (res.statusCode != 200) {
      throw Exception('wger API error: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final detail = _mapExerciseDetail(body);

    // Cache
    await prefs.setString(cacheKey, jsonEncode({
      ...detail.toJson(),
      'ts': DateTime.now().toIso8601String(),
    }));

    return detail;
  }

  // ─── Mappers ───────────────────────────────────────────────────

  Exercise _mapExercise(Map<String, dynamic> raw) {
    final muscleIds = (raw['muscles'] as List?)?.cast<int>() ?? [];
    final secMuscleIds =
        (raw['muscles_secondary'] as List?)?.cast<int>() ?? [];
    final equipIds = (raw['equipment'] as List?)?.cast<int>() ?? [];
    final catId = raw['category'] as int?;

    return Exercise(
      id: 'wger_${raw['id']}',
      wgerId: raw['id'] as int,
      name: _extractName(raw),
      category: _mapCategory(catId),
      primaryMuscles: muscleIds.map((id) => _muscles[id] ?? 'Unknown').toList(),
      secondaryMuscles:
          secMuscleIds.map((id) => _muscles[id] ?? 'Unknown').toList(),
      equipment: equipIds.map((id) => _equipment[id] ?? 'Unknown').toList(),
      primaryMuscleIds: muscleIds,
      secondaryMuscleIds: secMuscleIds,
    );
  }

  WgerExerciseDetail _mapExerciseDetail(Map<String, dynamic> body) {
    final muscleIds = (body['muscles'] as List?)
            ?.map((m) => (m is Map ? m['id'] as int : m as int))
            .toList() ??
        [];
    final secMuscleIds = (body['muscles_secondary'] as List?)
            ?.map((m) => (m is Map ? m['id'] as int : m as int))
            .toList() ??
        [];
    final equipIds = (body['equipment'] as List?)
            ?.map((e) => (e is Map ? e['id'] as int : e as int))
            .toList() ??
        [];
    final catId =
        body['category'] is Map ? body['category']['id'] as int? : null;

    // Extract images
    final images = <String>[];
    if (body['images'] is List) {
      for (final img in body['images'] as List) {
        if (img is Map && img['image'] != null) {
          images.add(img['image'] as String);
        }
      }
    }

    // Extract description from translations
    String? description;
    if (body['translations'] is List) {
      for (final t in body['translations'] as List) {
        if (t is Map && t['language'] == _language) {
          description = _stripHtml(t['description'] as String? ?? '');
          break;
        }
      }
    }

    // Extract name
    String name = 'Unknown';
    if (body['translations'] is List) {
      for (final t in body['translations'] as List) {
        if (t is Map && t['language'] == _language) {
          name = t['name'] as String? ?? 'Unknown';
          break;
        }
      }
    }

    return WgerExerciseDetail(
      exercise: Exercise(
        id: 'wger_${body['id']}',
        wgerId: body['id'] as int,
        name: name,
        category: _mapCategory(catId),
        primaryMuscles:
            muscleIds.map((id) => _muscles[id] ?? 'Unknown').toList(),
        secondaryMuscles:
            secMuscleIds.map((id) => _muscles[id] ?? 'Unknown').toList(),
        equipment: equipIds.map((id) => _equipment[id] ?? 'Unknown').toList(),
        description: description,
        primaryMuscleIds: muscleIds,
        secondaryMuscleIds: secMuscleIds,
      ),
      imageUrls: images,
      muscleSvgMain: getMuscleMainSvgs(muscleIds),
      muscleSvgSecondary: getMuscleSecondarySvgs(secMuscleIds),
    );
  }

  String _extractName(Map<String, dynamic> raw) {
    // exerciseinfo has translations, exercise list may not
    if (raw['translations'] is List) {
      for (final t in raw['translations'] as List) {
        if (t is Map && t['language'] == _language) {
          return t['name'] as String? ?? 'Unknown';
        }
      }
    }
    return raw['name'] as String? ?? 'Exercise ${raw['id']}';
  }

  String _mapCategory(int? catId) {
    if (catId == null) return 'Other';
    final name = _categories[catId];
    // Map wger categories to Vietnamese
    return _categoryViMap[name] ?? name ?? 'Other';
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }

  static const _categoryViMap = {
    'Abs': 'Bụng',
    'Arms': 'Tay',
    'Back': 'Lưng',
    'Calves': 'Bắp chân',
    'Cardio': 'Cardio',
    'Chest': 'Ngực',
    'Legs': 'Chân',
    'Shoulders': 'Vai',
  };
}

// ─── Data Classes ──────────────────────────────────────────────────

class WgerExercisePage {
  final List<Exercise> exercises;
  final bool hasMore;
  final int total;
  final int page;

  const WgerExercisePage({
    required this.exercises,
    required this.hasMore,
    required this.total,
    required this.page,
  });

  factory WgerExercisePage.fromJson(Map<String, dynamic> json) {
    return WgerExercisePage(
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'hasMore': hasMore,
        'total': total,
        'page': page,
      };
}

class WgerExerciseDetail {
  final Exercise exercise;
  final List<String> imageUrls;
  final List<String> muscleSvgMain;
  final List<String> muscleSvgSecondary;

  const WgerExerciseDetail({
    required this.exercise,
    this.imageUrls = const [],
    this.muscleSvgMain = const [],
    this.muscleSvgSecondary = const [],
  });

  factory WgerExerciseDetail.fromJson(Map<String, dynamic> json) {
    return WgerExerciseDetail(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
      muscleSvgMain: (json['muscleSvgMain'] as List?)?.cast<String>() ?? [],
      muscleSvgSecondary:
          (json['muscleSvgSecondary'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise': exercise.toJson(),
        'imageUrls': imageUrls,
        'muscleSvgMain': muscleSvgMain,
        'muscleSvgSecondary': muscleSvgSecondary,
      };
}

class _MuscleInfo {
  final String name;
  final bool isFront;
  final String? imageUrlMain;
  final String? imageUrlSecondary;

  const _MuscleInfo({
    required this.name,
    required this.isFront,
    this.imageUrlMain,
    this.imageUrlSecondary,
  });

  factory _MuscleInfo.fromJson(Map<String, dynamic> json) {
    return _MuscleInfo(
      name: json['name'] as String,
      isFront: json['isFront'] as bool? ?? true,
      imageUrlMain: json['imageUrlMain'] as String?,
      imageUrlSecondary: json['imageUrlSecondary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'isFront': isFront,
        'imageUrlMain': imageUrlMain,
        'imageUrlSecondary': imageUrlSecondary,
      };
}
