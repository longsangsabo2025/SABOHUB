import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/app_logger.dart';

final supabase = Supabase.instance.client;

// ============================================================================
// SALES TARGETS SERVICE
// ============================================================================

class SalesTarget {
  final String id;
  final String companyId;
  final String? employeeId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double targetRevenue;
  final int targetOrders;
  final int targetVisits;
  final int targetNewCustomers;
  final double targetCollections;
  final double actualRevenue;
  final int actualOrders;
  final int actualVisits;
  final int actualNewCustomers;
  final double actualCollections;
  final String status;

  SalesTarget({
    required this.id,
    required this.companyId,
    this.employeeId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.targetRevenue,
    required this.targetOrders,
    required this.targetVisits,
    required this.targetNewCustomers,
    required this.targetCollections,
    required this.actualRevenue,
    required this.actualOrders,
    required this.actualVisits,
    required this.actualNewCustomers,
    required this.actualCollections,
    required this.status,
  });

  factory SalesTarget.fromJson(Map<String, dynamic> json) {
    return SalesTarget(
      id: json['id'],
      companyId: json['company_id'],
      employeeId: json['employee_id'],
      periodType: json['period_type'] ?? 'monthly',
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      targetRevenue: (json['target_revenue'] ?? 0).toDouble(),
      targetOrders: json['target_orders'] ?? 0,
      targetVisits: json['target_visits'] ?? 0,
      targetNewCustomers: json['target_new_customers'] ?? 0,
      targetCollections: (json['target_collections'] ?? 0).toDouble(),
      actualRevenue: (json['actual_revenue'] ?? 0).toDouble(),
      actualOrders: json['actual_orders'] ?? 0,
      actualVisits: json['actual_visits'] ?? 0,
      actualNewCustomers: json['actual_new_customers'] ?? 0,
      actualCollections: (json['actual_collections'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }

  double get revenueProgress => targetRevenue > 0 ? actualRevenue / targetRevenue : 0;
  double get ordersProgress => targetOrders > 0 ? actualOrders / targetOrders : 0;
  double get visitsProgress => targetVisits > 0 ? actualVisits / targetVisits : 0;
  double get newCustomersProgress => targetNewCustomers > 0 ? actualNewCustomers / targetNewCustomers : 0;
  double get collectionsProgress => targetCollections > 0 ? actualCollections / targetCollections : 0;
}

class SalesTargetService {
  Future<SalesTarget?> getCurrentTarget(String companyId, String employeeId) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('sales_targets')
          .select()
          .eq('company_id', companyId)
          .eq('employee_id', employeeId)
          .eq('status', 'active')
          .lte('period_start', now.toIso8601String())
          .gte('period_end', now.toIso8601String())
          .order('period_start', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return SalesTarget.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to load sales target', e);
      return null;
    }
  }

  Future<List<SalesTarget>> getTargetHistory(String companyId, String employeeId, {int limit = 12}) async {
    try {
      final response = await supabase
          .from('sales_targets')
          .select()
          .eq('company_id', companyId)
          .eq('employee_id', employeeId)
          .order('period_start', ascending: false)
          .limit(limit);

      return (response as List).map((e) => SalesTarget.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load target history', e);
      return [];
    }
  }

  Future<void> updateActuals(String targetId, {
    double? revenue,
    int? orders,
    int? visits,
    int? newCustomers,
    double? collections,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (revenue != null) updates['actual_revenue'] = revenue;
      if (orders != null) updates['actual_orders'] = orders;
      if (visits != null) updates['actual_visits'] = visits;
      if (newCustomers != null) updates['actual_new_customers'] = newCustomers;
      if (collections != null) updates['actual_collections'] = collections;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('sales_targets').update(updates).eq('id', targetId);
    } catch (e) {
      AppLogger.error('Failed to update target actuals', e);
      rethrow;
    }
  }
}

final salesTargetServiceProvider = Provider((ref) => SalesTargetService());

// ============================================================================
// COMPETITOR REPORTS SERVICE
// ============================================================================

class CompetitorReport {
  final String id;
  final String companyId;
  final String? customerId;
  final String? visitId;
  final String? reportedBy;
  final String competitorName;
  final String? competitorBrand;
  final String activityType;
  final String? description;
  final double? observedPrice;
  final String? promotionDetails;
  final String? estimatedImpact;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime observedAt;
  final DateTime createdAt;

  CompetitorReport({
    required this.id,
    required this.companyId,
    this.customerId,
    this.visitId,
    this.reportedBy,
    required this.competitorName,
    this.competitorBrand,
    required this.activityType,
    this.description,
    this.observedPrice,
    this.promotionDetails,
    this.estimatedImpact,
    required this.photos,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.observedAt,
    required this.createdAt,
  });

  factory CompetitorReport.fromJson(Map<String, dynamic> json) {
    return CompetitorReport(
      id: json['id'],
      companyId: json['company_id'],
      customerId: json['customer_id'],
      visitId: json['visit_id'],
      reportedBy: json['reported_by'],
      competitorName: json['competitor_name'] ?? '',
      competitorBrand: json['competitor_brand'],
      activityType: json['activity_type'] ?? 'other',
      description: json['description'],
      observedPrice: json['observed_price']?.toDouble(),
      promotionDetails: json['promotion_details'],
      estimatedImpact: json['estimated_impact'],
      photos: List<String>.from(json['photos'] ?? []),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      observedAt: DateTime.parse(json['observed_at'] ?? json['created_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CompetitorReportService {
  Future<List<CompetitorReport>> getReports(String companyId, {
    String? customerId,
    int limit = 50,
  }) async {
    try {
      var query = supabase
          .from('competitor_reports')
          .select()
          .eq('company_id', companyId);

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query.order('observed_at', ascending: false).limit(limit);
      return (response as List).map((e) => CompetitorReport.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load competitor reports', e);
      return [];
    }
  }

  Future<String> createReport({
    required String companyId,
    String? customerId,
    String? visitId,
    required String reportedBy,
    required String competitorName,
    String? competitorBrand,
    required String activityType,
    String? description,
    double? observedPrice,
    String? promotionDetails,
    String? estimatedImpact,
    List<String>? photos,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final response = await supabase.from('competitor_reports').insert({
        'company_id': companyId,
        'customer_id': customerId,
        'visit_id': visitId,
        'reported_by': reportedBy,
        'competitor_name': competitorName,
        'competitor_brand': competitorBrand,
        'activity_type': activityType,
        'description': description,
        'observed_price': observedPrice,
        'promotion_details': promotionDetails,
        'estimated_impact': estimatedImpact,
        'photos': photos ?? [],
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'observed_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return response['id'];
    } catch (e) {
      AppLogger.error('Failed to create competitor report', e);
      rethrow;
    }
  }
}

final competitorReportServiceProvider = Provider((ref) => CompetitorReportService());

// ============================================================================
// SURVEY SERVICE
// ============================================================================

class Survey {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final String surveyType;
  final List<Map<String, dynamic>> questions;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int targetResponses;
  final int currentResponses;

  Survey({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    required this.surveyType,
    required this.questions,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.targetResponses,
    required this.currentResponses,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'],
      companyId: json['company_id'],
      title: json['title'] ?? '',
      description: json['description'],
      surveyType: json['survey_type'] ?? 'customer',
      questions: List<Map<String, dynamic>>.from(json['questions'] ?? []),
      isActive: json['is_active'] ?? false,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      targetResponses: json['target_responses'] ?? 0,
      currentResponses: json['current_responses'] ?? 0,
    );
  }
}

class SurveyService {
  Future<List<Survey>> getActiveSurveys(String companyId) async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('surveys')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Survey.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load surveys', e);
      return [];
    }
  }

  Future<void> submitResponse({
    required String surveyId,
    required String companyId,
    String? customerId,
    String? visitId,
    required String respondentId,
    required Map<String, dynamic> answers,
    double? totalScore,
    double? latitude,
    double? longitude,
    int? durationSeconds,
  }) async {
    try {
      await supabase.from('survey_responses').insert({
        'survey_id': surveyId,
        'company_id': companyId,
        'customer_id': customerId,
        'visit_id': visitId,
        'respondent_id': respondentId,
        'answers': answers,
        'total_score': totalScore,
        'latitude': latitude,
        'longitude': longitude,
        'duration_seconds': durationSeconds,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Update survey response count
      await supabase.rpc('increment_survey_responses', params: {'survey_id': surveyId});
    } catch (e) {
      AppLogger.error('Failed to submit survey response', e);
      rethrow;
    }
  }

  Future<bool> hasRespondedToday(String surveyId, String customerId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('survey_responses')
          .select('id')
          .eq('survey_id', surveyId)
          .eq('customer_id', customerId)
          .gte('completed_at', today)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}

final surveyServiceProvider = Provider((ref) => SurveyService());

// ============================================================================
// VISIT PHOTO SERVICE
// ============================================================================

class VisitPhotoService {
  Future<List<Map<String, dynamic>>> getVisitPhotos(String visitId) async {
    try {
      final response = await supabase
          .from('store_visit_photos')
          .select()
          .eq('visit_id', visitId)
          .order('taken_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Failed to load visit photos', e);
      return [];
    }
  }

  Future<String> uploadPhoto({
    required String visitId,
    required String companyId,
    required String category, // shelf, posm, competitor, product, other
    required String photoUrl,
    String? thumbnailUrl,
    String? caption,
    double? latitude,
    double? longitude,
    required String uploadedBy,
  }) async {
    try {
      final response = await supabase.from('store_visit_photos').insert({
        'visit_id': visitId,
        'company_id': companyId,
        'category': category,
        'photo_url': photoUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
        'latitude': latitude,
        'longitude': longitude,
        'taken_at': DateTime.now().toIso8601String(),
        'uploaded_by': uploadedBy,
      }).select('id').single();

      return response['id'];
    } catch (e) {
      AppLogger.error('Failed to upload visit photo', e);
      rethrow;
    }
  }
}

final visitPhotoServiceProvider = Provider((ref) => VisitPhotoService());

// ============================================================================
// STORE INVENTORY CHECK SERVICE
// ============================================================================

class StoreInventoryCheck {
  final String id;
  final String storeVisitId;
  final String productId;
  final int shelfStock;
  final int backStock;
  final int totalStock;
  final bool isOutOfStock;
  final bool isLowStock;
  final bool isExpired;
  final DateTime? expiryDate;
  final bool hasShelfSpace;
  final String? shelfPosition;
  final double? shelfShare;
  final double? currentPrice;
  final double? competitorPrice;
  final double? priceDifference;
  final bool onPromotion;
  final String? promotionDetails;
  final String? photoUrl;
  final String? notes;

  StoreInventoryCheck({
    required this.id,
    required this.storeVisitId,
    required this.productId,
    required this.shelfStock,
    required this.backStock,
    required this.totalStock,
    required this.isOutOfStock,
    required this.isLowStock,
    required this.isExpired,
    this.expiryDate,
    required this.hasShelfSpace,
    this.shelfPosition,
    this.shelfShare,
    this.currentPrice,
    this.competitorPrice,
    this.priceDifference,
    required this.onPromotion,
    this.promotionDetails,
    this.photoUrl,
    this.notes,
  });

  factory StoreInventoryCheck.fromJson(Map<String, dynamic> json) {
    return StoreInventoryCheck(
      id: json['id'],
      storeVisitId: json['store_visit_id'],
      productId: json['product_id'],
      shelfStock: json['shelf_stock'] ?? 0,
      backStock: json['back_stock'] ?? 0,
      totalStock: json['total_stock'] ?? 0,
      isOutOfStock: json['is_out_of_stock'] ?? false,
      isLowStock: json['is_low_stock'] ?? false,
      isExpired: json['is_expired'] ?? false,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      hasShelfSpace: json['has_shelf_space'] ?? true,
      shelfPosition: json['shelf_position'],
      shelfShare: json['shelf_share']?.toDouble(),
      currentPrice: json['current_price']?.toDouble(),
      competitorPrice: json['competitor_price']?.toDouble(),
      priceDifference: json['price_difference']?.toDouble(),
      onPromotion: json['on_promotion'] ?? false,
      promotionDetails: json['promotion_details'],
      photoUrl: json['photo_url'],
      notes: json['notes'],
    );
  }
}

class StoreInventoryCheckService {
  Future<List<StoreInventoryCheck>> getChecks(String visitId) async {
    try {
      final response = await supabase
          .from('store_inventory_checks')
          .select('*, products:product_id(name, sku)')
          .eq('store_visit_id', visitId);

      return (response as List).map((e) => StoreInventoryCheck.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load inventory checks', e);
      return [];
    }
  }

  Future<void> saveCheck({
    required String visitId,
    required String productId,
    required int shelfStock,
    int backStock = 0,
    bool isOutOfStock = false,
    bool isLowStock = false,
    bool isExpired = false,
    DateTime? expiryDate,
    bool hasShelfSpace = true,
    String? shelfPosition,
    double? shelfShare,
    double? currentPrice,
    double? competitorPrice,
    bool onPromotion = false,
    String? promotionDetails,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      final totalStock = shelfStock + backStock;
      final priceDiff = (currentPrice != null && competitorPrice != null)
          ? currentPrice - competitorPrice
          : null;

      await supabase.from('store_inventory_checks').upsert({
        'store_visit_id': visitId,
        'product_id': productId,
        'shelf_stock': shelfStock,
        'back_stock': backStock,
        'total_stock': totalStock,
        'is_out_of_stock': isOutOfStock || totalStock == 0,
        'is_low_stock': isLowStock,
        'is_expired': isExpired,
        'expiry_date': expiryDate?.toIso8601String(),
        'has_shelf_space': hasShelfSpace,
        'shelf_position': shelfPosition,
        'shelf_share': shelfShare,
        'current_price': currentPrice,
        'competitor_price': competitorPrice,
        'price_difference': priceDiff,
        'on_promotion': onPromotion,
        'promotion_details': promotionDetails,
        'photo_url': photoUrl,
        'notes': notes,
      }, onConflict: 'store_visit_id,product_id');
    } catch (e) {
      AppLogger.error('Failed to save inventory check', e);
      rethrow;
    }
  }
}

final storeInventoryCheckServiceProvider = Provider((ref) => StoreInventoryCheckService());

// ============================================================================
// PROMOTION SERVICE
// ============================================================================

class Promotion {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final String? description;
  final String promotionType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> benefits;
  final int? maxUses;
  final int? maxUsesPerCustomer;
  final int currentUses;

  Promotion({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.description,
    required this.promotionType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.conditions,
    required this.benefits,
    this.maxUses,
    this.maxUsesPerCustomer,
    required this.currentUses,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      companyId: json['company_id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      promotionType: json['promotion_type'] ?? 'discount',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? false,
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
      benefits: Map<String, dynamic>.from(json['benefits'] ?? {}),
      maxUses: json['max_uses'],
      maxUsesPerCustomer: json['max_uses_per_customer'],
      currentUses: json['current_uses'] ?? 0,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class PromotionService {
  Future<List<Promotion>> getActivePromotions(String companyId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await supabase
          .from('distributor_promotions')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('end_date', ascending: true);

      return (response as List).map((e) => Promotion.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load promotions', e);
      return [];
    }
  }

  Future<List<Promotion>> getPromotionsForProduct(String productId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await supabase
          .from('distributor_promotions')
          .select()
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .contains('conditions', {'product_ids': [productId]});

      return (response as List).map((e) => Promotion.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to load product promotions', e);
      return [];
    }
  }
}

final promotionServiceProvider = Provider((ref) => PromotionService());

// ============================================================================
// CUSTOMER HISTORY SERVICE
// ============================================================================

class CustomerHistoryService {
  Future<List<Map<String, dynamic>>> getOrderHistory(String customerId, {int limit = 20}) async {
    try {
      final response = await supabase
          .from('sales_orders')
          .select('id, order_number, order_date, total, status, payment_status')
          .eq('customer_id', customerId)
          .order('order_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Failed to load order history', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFrequentProducts(String customerId, {int limit = 10}) async {
    try {
      final response = await supabase.rpc('get_customer_frequent_products', params: {
        'p_customer_id': customerId,
        'p_limit': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Failed to load frequent products', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final response = await supabase
          .from('customers')
          .select('total_debt, credit_limit, total_orders, total_revenue, last_order_date, last_visit_date')
          .eq('id', customerId)
          .single();

      return response;
    } catch (e) {
      AppLogger.error('Failed to load customer stats', e);
      return {};
    }
  }
}

final customerHistoryServiceProvider = Provider((ref) => CustomerHistoryService());
