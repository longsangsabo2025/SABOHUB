import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Store Visit Model
class StoreVisit {
  final String id;
  final String companyId;
  final String customerId;
  final String employeeId;
  final String? journeyPlanStopId;
  final DateTime visitDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Map<String, dynamic>? checkInLocation;
  final Map<String, dynamic>? checkOutLocation;
  final String status;
  final String visitType;
  final String? objectives;
  final String? outcomes;
  final String? issuesReported;
  final bool orderPlaced;
  final String? orderId;
  final double? orderAmount;
  final String? visitRating;
  final String? feedback;
  final DateTime createdAt;
  
  // Joined data
  final String? customerName;
  final String? customerAddress;
  final String? employeeName;
  final int? photoCount;
  final int? completedChecklistsCount;

  StoreVisit({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.employeeId,
    this.journeyPlanStopId,
    required this.visitDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.status = 'planned',
    this.visitType = 'regular',
    this.objectives,
    this.outcomes,
    this.issuesReported,
    this.orderPlaced = false,
    this.orderId,
    this.orderAmount,
    this.visitRating,
    this.feedback,
    required this.createdAt,
    this.customerName,
    this.customerAddress,
    this.employeeName,
    this.photoCount,
    this.completedChecklistsCount,
  });

  factory StoreVisit.fromJson(Map<String, dynamic> json) {
    return StoreVisit(
      id: json['id'],
      companyId: json['company_id'],
      customerId: json['customer_id'],
      employeeId: json['employee_id'],
      journeyPlanStopId: json['journey_plan_stop_id'],
      visitDate: DateTime.parse(json['visit_date']),
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time']) 
          : null,
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
      status: json['status'] ?? 'planned',
      visitType: json['visit_type'] ?? 'regular',
      objectives: json['objectives'],
      outcomes: json['outcomes'],
      issuesReported: json['issues_reported'],
      orderPlaced: json['order_placed'] ?? false,
      orderId: json['order_id'],
      orderAmount: json['order_amount']?.toDouble(),
      visitRating: json['visit_rating'],
      feedback: json['feedback'],
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customers']?['name'],
      customerAddress: json['customers']?['address'],
      employeeName: json['employees']?['full_name'],
      photoCount: json['photo_count'],
      completedChecklistsCount: json['completed_checklists_count'],
    );
  }

  int get durationMinutes {
    if (checkInTime == null || checkOutTime == null) return 0;
    return checkOutTime!.difference(checkInTime!).inMinutes;
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCompleted => status == 'completed';
}

/// Visit Photo Model
class VisitPhoto {
  final String id;
  final String visitId;
  final String imageUrl;
  final String photoType;
  final String? caption;
  final Map<String, dynamic>? location;
  final DateTime capturedAt;

  VisitPhoto({
    required this.id,
    required this.visitId,
    required this.imageUrl,
    this.photoType = 'general',
    this.caption,
    this.location,
    required this.capturedAt,
  });

  factory VisitPhoto.fromJson(Map<String, dynamic> json) {
    return VisitPhoto(
      id: json['id'],
      visitId: json['visit_id'],
      imageUrl: json['image_url'],
      photoType: json['photo_type'] ?? 'general',
      caption: json['caption'],
      location: json['location'],
      capturedAt: DateTime.parse(json['captured_at']),
    );
  }
}

/// Competitor Observation Model
class CompetitorObservation {
  final String id;
  final String visitId;
  final String competitorName;
  final String? productCategory;
  final String observationType;
  final String? observationDetails;
  final double? priceObserved;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;

  CompetitorObservation({
    required this.id,
    required this.visitId,
    required this.competitorName,
    this.productCategory,
    this.observationType = 'general',
    this.observationDetails,
    this.priceObserved,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  factory CompetitorObservation.fromJson(Map<String, dynamic> json) {
    return CompetitorObservation(
      id: json['id'],
      visitId: json['visit_id'],
      competitorName: json['competitor_name'],
      productCategory: json['product_category'],
      observationType: json['observation_type'] ?? 'general',
      observationDetails: json['observation_details'],
      priceObserved: json['price_observed']?.toDouble(),
      imageUrl: json['image_url'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Visit Checklist Model
class VisitChecklist {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? applicableFor;
  final bool isRequired;
  final bool isActive;
  final List<ChecklistItem>? items;

  VisitChecklist({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.applicableFor,
    this.isRequired = false,
    this.isActive = true,
    this.items,
  });

  factory VisitChecklist.fromJson(Map<String, dynamic> json) {
    return VisitChecklist(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      description: json['description'],
      applicableFor: json['applicable_for'],
      isRequired: json['is_required'] ?? false,
      isActive: json['is_active'] ?? true,
      items: json['checklist_items'] != null
          ? (json['checklist_items'] as List)
              .map((i) => ChecklistItem.fromJson(i))
              .toList()
          : null,
    );
  }
}

/// Checklist Item Model
class ChecklistItem {
  final String id;
  final String checklistId;
  final String itemText;
  final String itemType;
  final List<String>? options;
  final bool isRequired;
  final int displayOrder;

  ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.itemText,
    this.itemType = 'checkbox',
    this.options,
    this.isRequired = false,
    this.displayOrder = 0,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      checklistId: json['checklist_id'],
      itemText: json['item_text'],
      itemType: json['item_type'] ?? 'checkbox',
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : null,
      isRequired: json['is_required'] ?? false,
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

/// Today's Visit Stats
class TodayVisitStats {
  final int totalVisits;
  final int completedVisits;
  final int avgDurationMinutes;
  final double totalOrderAmount;

  TodayVisitStats({
    required this.totalVisits,
    required this.completedVisits,
    required this.avgDurationMinutes,
    required this.totalOrderAmount,
  });

  factory TodayVisitStats.fromJson(Map<String, dynamic> json) {
    return TodayVisitStats(
      totalVisits: json['total_visits'] ?? 0,
      completedVisits: json['completed_visits'] ?? 0,
      avgDurationMinutes: json['avg_duration_minutes'] ?? 0,
      totalOrderAmount: (json['total_order_amount'] ?? 0).toDouble(),
    );
  }
}

/// Store Visit Service
class StoreVisitService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== STORE VISITS ====================

  /// Get visits for date range
  Future<List<StoreVisit>> getVisits({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? customerId,
    String? status,
  }) async {
    var query = _supabase
        .from('store_visits')
        .select('''
          *,
          customers(name, address),
          employees(full_name)
        ''');
    
    if (startDate != null) {
      query = query.gte('visit_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('visit_date', endDate.toIso8601String().split('T')[0]);
    }
    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query.order('visit_date', ascending: false);
    return (response as List).map((v) => StoreVisit.fromJson(v)).toList();
  }

  /// Get today's visits for current user
  Future<List<StoreVisit>> getTodayVisits() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _supabase
        .from('store_visits')
        .select('''
          *,
          customers(name, address),
          employees(full_name)
        ''')
        .eq('visit_date', today)
        .order('check_in_time');
    
    return (response as List).map((v) => StoreVisit.fromJson(v)).toList();
  }

  /// Get visit by ID with details
  Future<StoreVisit?> getVisitById(String visitId) async {
    final response = await _supabase
        .from('store_visits')
        .select('''
          *,
          customers(name, address, phone),
          employees(full_name)
        ''')
        .eq('id', visitId)
        .maybeSingle();
    
    if (response == null) return null;
    return StoreVisit.fromJson(response);
  }

  /// Check in to store using database function
  Future<String?> checkIn({
    required String customerId,
    required Map<String, dynamic> location,
    String? journeyPlanStopId,
    String? objectives,
  }) async {
    final response = await _supabase.rpc('check_in_store', params: {
      'p_customer_id': customerId,
      'p_location': location,
      'p_journey_stop_id': journeyPlanStopId,
      'p_objectives': objectives,
    });
    
    return response?['visit_id'] as String?;
  }

  /// Check out from store using database function
  Future<bool> checkOut({
    required String visitId,
    required Map<String, dynamic> location,
    String? outcomes,
    String? issuesReported,
  }) async {
    final response = await _supabase.rpc('check_out_store', params: {
      'p_visit_id': visitId,
      'p_location': location,
      'p_outcomes': outcomes,
      'p_issues': issuesReported,
    });
    
    return response as bool;
  }

  /// Get today's visit stats for current user
  Future<TodayVisitStats> getTodayStats() async {
    final response = await _supabase.rpc('get_today_visit_stats');
    return TodayVisitStats.fromJson(response ?? {});
  }

  /// Update visit details
  Future<void> updateVisit(String visitId, Map<String, dynamic> updates) async {
    await _supabase
        .from('store_visits')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', visitId);
  }

  // ==================== VISIT PHOTOS ====================

  /// Get photos for a visit
  Future<List<VisitPhoto>> getVisitPhotos(String visitId) async {
    final response = await _supabase
        .from('visit_photos')
        .select()
        .eq('visit_id', visitId)
        .order('captured_at');
    
    return (response as List).map((p) => VisitPhoto.fromJson(p)).toList();
  }

  /// Upload and add photo to visit
  Future<VisitPhoto?> addPhoto({
    required String visitId,
    required File imageFile,
    required String photoType,
    String? caption,
    Map<String, dynamic>? location,
  }) async {
    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = imageFile.path.split('.').last;
    final filename = 'visit_photos/$visitId/$timestamp.$ext';
    
    // Upload to storage
    await _supabase.storage.from('visit-assets').upload(
      filename,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    
    // Get public URL
    final imageUrl = _supabase.storage.from('visit-assets').getPublicUrl(filename);
    
    // Insert record
    final response = await _supabase
        .from('visit_photos')
        .insert({
          'visit_id': visitId,
          'image_url': imageUrl,
          'photo_type': photoType,
          'caption': caption,
          'location': location,
          'captured_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    return VisitPhoto.fromJson(response);
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId) async {
    // Get photo URL first
    final photo = await _supabase
        .from('visit_photos')
        .select('image_url')
        .eq('id', photoId)
        .single();
    
    // Delete from storage
    final url = photo['image_url'] as String;
    final path = url.split('/visit-assets/').last;
    await _supabase.storage.from('visit-assets').remove([path]);
    
    // Delete record
    await _supabase.from('visit_photos').delete().eq('id', photoId);
  }

  // ==================== COMPETITOR OBSERVATIONS ====================

  /// Get competitor observations for a visit
  Future<List<CompetitorObservation>> getCompetitorObservations(String visitId) async {
    final response = await _supabase
        .from('competitor_observations')
        .select()
        .eq('visit_id', visitId)
        .order('created_at');
    
    return (response as List).map((c) => CompetitorObservation.fromJson(c)).toList();
  }

  /// Add competitor observation
  Future<CompetitorObservation> addCompetitorObservation({
    required String visitId,
    required String competitorName,
    String? productCategory,
    required String observationType,
    String? observationDetails,
    double? priceObserved,
    String? notes,
    File? imageFile,
  }) async {
    String? imageUrl;
    
    // Upload image if provided
    if (imageFile != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = imageFile.path.split('.').last;
      final filename = 'competitor_photos/$visitId/$timestamp.$ext';
      
      await _supabase.storage.from('visit-assets').upload(
        filename,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      imageUrl = _supabase.storage.from('visit-assets').getPublicUrl(filename);
    }
    
    final response = await _supabase
        .from('competitor_observations')
        .insert({
          'visit_id': visitId,
          'competitor_name': competitorName,
          'product_category': productCategory,
          'observation_type': observationType,
          'observation_details': observationDetails,
          'price_observed': priceObserved,
          'image_url': imageUrl,
          'notes': notes,
        })
        .select()
        .single();
    
    return CompetitorObservation.fromJson(response);
  }

  // ==================== CHECKLISTS ====================

  /// Get available checklists
  Future<List<VisitChecklist>> getChecklists({String? applicableFor}) async {
    final baseQuery = _supabase
        .from('visit_checklists')
        .select('''
          *,
          checklist_items(*)
        ''')
        .eq('is_active', true);
    
    final query = applicableFor != null 
        ? baseQuery.or('applicable_for.is.null,applicable_for.eq.$applicableFor')
        : baseQuery;
    
    final response = await query.order('name');
    return (response as List).map((c) => VisitChecklist.fromJson(c)).toList();
  }

  /// Submit checklist response for a visit
  Future<void> submitChecklistResponse({
    required String visitId,
    required String checklistId,
    required Map<String, dynamic> responses,
    String? notes,
  }) async {
    // Create checklist response
    final checklistResponse = await _supabase
        .from('visit_checklist_responses')
        .insert({
          'visit_id': visitId,
          'checklist_id': checklistId,
          'completed_at': DateTime.now().toIso8601String(),
          'notes': notes,
        })
        .select()
        .single();
    
    final responseId = checklistResponse['id'] as String;
    
    // Insert item responses
    final itemResponses = responses.entries.map((entry) => {
      'checklist_response_id': responseId,
      'checklist_item_id': entry.key,
      'response_value': entry.value,
    }).toList();
    
    await _supabase.from('checklist_item_responses').insert(itemResponses);
  }

  /// Get checklist responses for a visit
  Future<List<Map<String, dynamic>>> getVisitChecklistResponses(String visitId) async {
    final response = await _supabase
        .from('visit_checklist_responses')
        .select('''
          *,
          visit_checklists(name),
          checklist_item_responses(
            *,
            checklist_items(item_text)
          )
        ''')
        .eq('visit_id', visitId);
    
    return List<Map<String, dynamic>>.from(response);
  }
}

// ==================== PROVIDERS ====================

final storeVisitServiceProvider = Provider((ref) => StoreVisitService());

/// Provider for today's visits
final todayVisitsProvider = FutureProvider.autoDispose<List<StoreVisit>>((ref) async {
  final service = ref.watch(storeVisitServiceProvider);
  return service.getTodayVisits();
});

/// Provider for today's stats
final todayVisitStatsProvider = FutureProvider.autoDispose<TodayVisitStats>((ref) async {
  final service = ref.watch(storeVisitServiceProvider);
  return service.getTodayStats();
});

/// Provider for visit details
final visitDetailProvider = FutureProvider.autoDispose.family<StoreVisit?, String>((ref, visitId) async {
  final service = ref.watch(storeVisitServiceProvider);
  return service.getVisitById(visitId);
});

/// Provider for visit photos
final visitPhotosProvider = FutureProvider.autoDispose.family<List<VisitPhoto>, String>((ref, visitId) async {
  final service = ref.watch(storeVisitServiceProvider);
  return service.getVisitPhotos(visitId);
});

/// Provider for available checklists
final visitChecklistsProvider = FutureProvider.autoDispose<List<VisitChecklist>>((ref) async {
  final service = ref.watch(storeVisitServiceProvider);
  return service.getChecklists();
});

/// Active visit notifier using Notifier
class ActiveVisitNotifier extends Notifier<StoreVisit?> {
  @override
  StoreVisit? build() => null;
  
  Future<void> checkIn({
    required String customerId,
    required Map<String, dynamic> location,
    String? journeyPlanStopId,
    String? objectives,
  }) async {
    final service = ref.read(storeVisitServiceProvider);
    final visitId = await service.checkIn(
      customerId: customerId,
      location: location,
      journeyPlanStopId: journeyPlanStopId,
      objectives: objectives,
    );
    
    if (visitId != null) {
      state = await service.getVisitById(visitId);
    }
  }
  
  Future<void> checkOut({
    required Map<String, dynamic> location,
    String? outcomes,
    String? issuesReported,
  }) async {
    if (state == null) return;
    
    final service = ref.read(storeVisitServiceProvider);
    await service.checkOut(
      visitId: state!.id,
      location: location,
      outcomes: outcomes,
      issuesReported: issuesReported,
    );
    
    state = null;
  }
  
  void clearActiveVisit() {
    state = null;
  }
}

final activeVisitProvider = NotifierProvider<ActiveVisitNotifier, StoreVisit?>(() {
  return ActiveVisitNotifier();
});
