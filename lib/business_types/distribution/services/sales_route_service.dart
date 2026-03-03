import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sales Route Model
class SalesRoute {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final String? description;
  final String? assignedToId;
  final String? territory;
  final String frequency;
  final List<String>? visitDays;
  final int? estimatedDurationMinutes;
  final double? estimatedDistanceKm;
  final String status;
  final DateTime createdAt;
  
  // Joined data
  final String? assignedToName;
  final int? customerCount;

  SalesRoute({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.description,
    this.assignedToId,
    this.territory,
    this.frequency = 'weekly',
    this.visitDays,
    this.estimatedDurationMinutes,
    this.estimatedDistanceKm,
    this.status = 'active',
    required this.createdAt,
    this.assignedToName,
    this.customerCount,
  });

  factory SalesRoute.fromJson(Map<String, dynamic> json) {
    return SalesRoute(
      id: json['id'],
      companyId: json['company_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      assignedToId: json['assigned_to_id'],
      territory: json['territory'],
      frequency: json['frequency'] ?? 'weekly',
      visitDays: json['visit_days'] != null 
          ? List<String>.from(json['visit_days']) 
          : null,
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      estimatedDistanceKm: json['estimated_distance_km']?.toDouble(),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      assignedToName: json['employees']?['full_name'],
      customerCount: json['customer_count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'description': description,
    'assigned_to_id': assignedToId,
    'territory': territory,
    'frequency': frequency,
    'visit_days': visitDays,
    'estimated_duration_minutes': estimatedDurationMinutes,
    'estimated_distance_km': estimatedDistanceKm,
    'status': status,
  };
}

/// Route Customer Model
class RouteCustomer {
  final String id;
  final String routeId;
  final String customerId;
  final int visitOrder;
  final String visitFrequency;
  final String priority;
  final String? specialInstructions;
  
  // Joined customer data
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final String? customerType;

  RouteCustomer({
    required this.id,
    required this.routeId,
    required this.customerId,
    this.visitOrder = 1,
    this.visitFrequency = 'every-visit',
    this.priority = 'normal',
    this.specialInstructions,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.customerType,
  });

  factory RouteCustomer.fromJson(Map<String, dynamic> json) {
    return RouteCustomer(
      id: json['id'],
      routeId: json['route_id'],
      customerId: json['customer_id'],
      visitOrder: json['visit_order'] ?? 1,
      visitFrequency: json['visit_frequency'] ?? 'every-visit',
      priority: json['priority'] ?? 'normal',
      specialInstructions: json['special_instructions'],
      customerName: json['customers']?['name'],
      customerAddress: json['customers']?['address'],
      customerPhone: json['customers']?['phone'],
      customerType: json['customers']?['type'],
    );
  }
}

/// Journey Plan Model
class JourneyPlan {
  final String id;
  final String companyId;
  final String? routeId;
  final String employeeId;
  final DateTime planDate;
  final String status;
  final int totalVisitsPlanned;
  final int visitsCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? startLocation;
  final Map<String, dynamic>? endLocation;
  final double? totalDistanceKm;
  final int? totalDurationMinutes;
  final String? notes;
  
  // Joined data
  final String? routeName;
  final String? employeeName;
  final List<JourneyPlanStop>? stops;

  JourneyPlan({
    required this.id,
    required this.companyId,
    this.routeId,
    required this.employeeId,
    required this.planDate,
    this.status = 'planned',
    this.totalVisitsPlanned = 0,
    this.visitsCompleted = 0,
    this.startedAt,
    this.completedAt,
    this.startLocation,
    this.endLocation,
    this.totalDistanceKm,
    this.totalDurationMinutes,
    this.notes,
    this.routeName,
    this.employeeName,
    this.stops,
  });

  factory JourneyPlan.fromJson(Map<String, dynamic> json) {
    return JourneyPlan(
      id: json['id'],
      companyId: json['company_id'],
      routeId: json['route_id'],
      employeeId: json['employee_id'],
      planDate: DateTime.parse(json['plan_date']),
      status: json['status'] ?? 'planned',
      totalVisitsPlanned: json['total_visits_planned'] ?? 0,
      visitsCompleted: json['visits_completed'] ?? 0,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      totalDistanceKm: json['total_distance_km']?.toDouble(),
      totalDurationMinutes: json['total_duration_minutes'],
      notes: json['notes'],
      routeName: json['sales_routes']?['name'],
      employeeName: json['employees']?['full_name'],
      stops: json['journey_plan_stops'] != null
          ? (json['journey_plan_stops'] as List)
              .map((s) => JourneyPlanStop.fromJson(s))
              .toList()
          : null,
    );
  }

  double get completionRate => 
      totalVisitsPlanned > 0 ? visitsCompleted / totalVisitsPlanned : 0;
}

/// Journey Plan Stop Model
class JourneyPlanStop {
  final String id;
  final String journeyPlanId;
  final String customerId;
  final int stopOrder;
  final String status;
  final String? skipReason;
  final DateTime? actualArrivalTime;
  final DateTime? departureTime;
  final int? durationMinutes;
  final Map<String, dynamic>? checkInLocation;
  final Map<String, dynamic>? checkOutLocation;
  final double? distanceFromPreviousKm;
  final String? storeVisitId;
  final String? notes;
  
  // Joined data
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final double? latitude;
  final double? longitude;

  JourneyPlanStop({
    required this.id,
    required this.journeyPlanId,
    required this.customerId,
    required this.stopOrder,
    this.status = 'pending',
    this.skipReason,
    this.actualArrivalTime,
    this.departureTime,
    this.durationMinutes,
    this.checkInLocation,
    this.checkOutLocation,
    this.distanceFromPreviousKm,
    this.storeVisitId,
    this.notes,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.latitude,
    this.longitude,
  });

  factory JourneyPlanStop.fromJson(Map<String, dynamic> json) {
    return JourneyPlanStop(
      id: json['id'],
      journeyPlanId: json['journey_plan_id'],
      customerId: json['customer_id'],
      stopOrder: json['stop_order'],
      status: json['status'] ?? 'pending',
      skipReason: json['skip_reason'],
      actualArrivalTime: json['actual_arrival_time'] != null 
          ? DateTime.parse(json['actual_arrival_time']) 
          : null,
      departureTime: json['departure_time'] != null 
          ? DateTime.parse(json['departure_time']) 
          : null,
      durationMinutes: json['duration_minutes'],
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
      distanceFromPreviousKm: json['distance_from_previous_km']?.toDouble(),
      storeVisitId: json['store_visit_id'],
      notes: json['notes'],
      customerName: json['customers']?['name'],
      customerAddress: json['customers']?['address'],
      customerPhone: json['customers']?['phone'],
      latitude: json['customers']?['lat']?.toDouble(),  // DB uses 'lat' not 'latitude'
      longitude: json['customers']?['lng']?.toDouble(),  // DB uses 'lng' not 'longitude'
    );
  }
}

/// Sales Route Service
class SalesRouteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== ROUTES ====================

  /// Get all routes for current company
  Future<List<SalesRoute>> getRoutes({String? status}) async {
    final baseQuery = _supabase
        .from('sales_routes')
        .select('''
          *,
          employees!assigned_to_id(full_name)
        ''');
    
    final query = status != null 
        ? baseQuery.eq('status', status)
        : baseQuery;
    
    final response = await query.order('name');
    return (response as List).map((r) => SalesRoute.fromJson(r)).toList();
  }

  /// Get route by ID with customers
  Future<SalesRoute?> getRouteById(String routeId) async {
    final response = await _supabase
        .from('sales_routes')
        .select('''
          *,
          employees!assigned_to_id(full_name),
          route_customers(count)
        ''')
        .eq('id', routeId)
        .maybeSingle();
    
    if (response == null) return null;
    return SalesRoute.fromJson(response);
  }

  /// Create new route
  Future<SalesRoute> createRoute(SalesRoute route) async {
    final response = await _supabase
        .from('sales_routes')
        .insert(route.toJson())
        .select()
        .single();
    
    return SalesRoute.fromJson(response);
  }

  /// Update route
  Future<SalesRoute> updateRoute(String routeId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('sales_routes')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', routeId)
        .select()
        .single();
    
    return SalesRoute.fromJson(response);
  }

  /// Delete route
  Future<void> deleteRoute(String routeId) async {
    await _supabase.from('sales_routes').delete().eq('id', routeId);
  }

  // ==================== ROUTE CUSTOMERS ====================

  /// Get customers in a route
  Future<List<RouteCustomer>> getRouteCustomers(String routeId) async {
    final response = await _supabase
        .from('route_customers')
        .select('''
          *,
          customers(name, address, phone, type)
        ''')
        .eq('route_id', routeId)
        .order('visit_order');
    
    return (response as List).map((r) => RouteCustomer.fromJson(r)).toList();
  }

  /// Add customer to route
  Future<void> addCustomerToRoute({
    required String routeId,
    required String customerId,
    int? visitOrder,
    String? specialInstructions,
  }) async {
    // Get max order if not provided
    if (visitOrder == null) {
      final maxOrder = await _supabase
          .from('route_customers')
          .select('visit_order')
          .eq('route_id', routeId)
          .order('visit_order', ascending: false)
          .limit(1)
          .maybeSingle();
      
      visitOrder = (maxOrder?['visit_order'] ?? 0) + 1;
    }
    
    await _supabase.from('route_customers').insert({
      'route_id': routeId,
      'customer_id': customerId,
      'visit_order': visitOrder,
      'special_instructions': specialInstructions,
    });
  }

  /// Remove customer from route
  Future<void> removeCustomerFromRoute(String routeCustomerId) async {
    await _supabase.from('route_customers').delete().eq('id', routeCustomerId);
  }

  /// Reorder customers in route
  Future<void> reorderRouteCustomers(String routeId, List<String> customerIds) async {
    for (int i = 0; i < customerIds.length; i++) {
      await _supabase
          .from('route_customers')
          .update({'visit_order': i + 1})
          .eq('route_id', routeId)
          .eq('customer_id', customerIds[i]);
    }
  }

  // ==================== JOURNEY PLANS ====================

  /// Get journey plans for date range
  Future<List<JourneyPlan>> getJourneyPlans({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? status,
  }) async {
    var query = _supabase
        .from('journey_plans')
        .select('''
          *,
          sales_routes(name),
          employees(full_name)
        ''');
    
    if (startDate != null) {
      query = query.gte('plan_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('plan_date', endDate.toIso8601String().split('T')[0]);
    }
    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query.order('plan_date', ascending: false);
    return (response as List).map((r) => JourneyPlan.fromJson(r)).toList();
  }

  /// Get today's journey plan for current user
  Future<JourneyPlan?> getTodayJourneyPlan({String? employeeId}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    var query = _supabase
        .from('journey_plans')
        .select('''
          *,
          sales_routes(name),
          employees(full_name),
          journey_plan_stops(
            *,
            customers(name, address, phone, lat, lng)
          )
        ''')
        .eq('plan_date', today);
    
    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }
    
    final response = await query
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) return null;
    return JourneyPlan.fromJson(response);
  }

  /// Get journey plan by ID with stops
  Future<JourneyPlan?> getJourneyPlanById(String planId) async {
    final response = await _supabase
        .from('journey_plans')
        .select('''
          *,
          sales_routes(name),
          employees(full_name),
          journey_plan_stops(
            *,
            customers(name, address, phone, latitude, longitude)
          )
        ''')
        .eq('id', planId)
        .maybeSingle();
    
    if (response == null) return null;
    return JourneyPlan.fromJson(response);
  }

  /// Create journey plan from route
  Future<String> createJourneyPlanFromRoute({
    required String routeId,
    required String employeeId,
    required DateTime planDate,
  }) async {
    final response = await _supabase.rpc('create_journey_plan_from_route', params: {
      'p_route_id': routeId,
      'p_employee_id': employeeId,
      'p_plan_date': planDate.toIso8601String().split('T')[0],
    });
    
    return response as String;
  }

  /// Create quick journey plan from selected customers (no route needed)
  Future<String> createQuickJourneyPlan({
    required String companyId,
    required String employeeId,
    required DateTime planDate,
    required List<String> customerIds,
  }) async {
    // Insert journey_plan
    final planResponse = await _supabase
        .from('journey_plans')
        .insert({
          'company_id': companyId,
          'employee_id': employeeId,
          'plan_date': planDate.toIso8601String().split('T')[0],
          'status': 'planned',
          'total_visits_planned': customerIds.length,
          'visits_completed': 0,
        })
        .select('id')
        .single();
    
    final planId = planResponse['id'] as String;
    
    // Insert stops
    final stops = <Map<String, dynamic>>[];
    for (int i = 0; i < customerIds.length; i++) {
      stops.add({
        'journey_plan_id': planId,
        'customer_id': customerIds[i],
        'stop_order': i + 1,
        'status': 'pending',
      });
    }
    
    await _supabase.from('journey_plan_stops').insert(stops);
    
    return planId;
  }

  /// Get customers for quick journey plan selection
  Future<List<Map<String, dynamic>>> getCustomersForSelection({
    required String companyId,
    String? search,
    String? district,
    String? route,
    int limit = 100,
  }) async {
    var query = _supabase
        .from('customers')
        .select('id, name, address, phone, type, district, route, lat, lng')
        .eq('company_id', companyId)
        .eq('status', 'active');
    
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,phone.ilike.%$search%,address.ilike.%$search%');
    }
    if (district != null && district.isNotEmpty) {
      query = query.eq('district', district);
    }
    if (route != null && route.isNotEmpty) {
      query = query.eq('route', route);
    }
    
    final response = await query
        .order('name')
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get distinct districts and routes for filtering
  Future<Map<String, List<Map<String, dynamic>>>> getDistrictsAndRoutes({
    required String companyId,
  }) async {
    // Get districts with count
    final districtResponse = await _supabase
        .rpc('get_customer_districts', params: {'p_company_id': companyId});
    
    // Get routes with count  
    final routeResponse = await _supabase
        .rpc('get_customer_routes', params: {'p_company_id': companyId});
    
    return {
      'districts': List<Map<String, dynamic>>.from(districtResponse ?? []),
      'routes': List<Map<String, dynamic>>.from(routeResponse ?? []),
    };
  }

  /// Get distinct districts (fallback - direct query)
  Future<List<Map<String, dynamic>>> getDistrictsDirect({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('customers')
        .select('district')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .not('district', 'is', null)
        .not('district', 'eq', '');
    
    // Count manually
    final countMap = <String, int>{};
    for (final row in response) {
      final d = row['district'] as String? ?? '';
      if (d.isNotEmpty) {
        countMap[d] = (countMap[d] ?? 0) + 1;
      }
    }
    
    final result = countMap.entries
        .map((e) => {'district': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return result;
  }

  /// Get distinct routes (fallback - direct query)
  Future<List<Map<String, dynamic>>> getRoutesDirect({
    required String companyId,
  }) async {
    final response = await _supabase
        .from('customers')
        .select('route')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .not('route', 'is', null)
        .not('route', 'eq', '');
    
    final countMap = <String, int>{};
    for (final row in response) {
      final r = row['route'] as String? ?? '';
      if (r.isNotEmpty) {
        countMap[r] = (countMap[r] ?? 0) + 1;
      }
    }
    
    final result = countMap.entries
        .map((e) => {'route': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return result;
  }

  /// Start journey
  Future<bool> startJourney(String planId, {Map<String, dynamic>? location}) async {
    final response = await _supabase.rpc('start_journey', params: {
      'p_plan_id': planId,
      'p_location': location,
    });
    
    return response as bool;
  }

  /// Complete journey
  Future<bool> completeJourney(String planId, {
    Map<String, dynamic>? location,
    String? notes,
  }) async {
    final response = await _supabase.rpc('complete_journey', params: {
      'p_plan_id': planId,
      'p_location': location,
      'p_notes': notes,
    });
    
    return response as bool;
  }

  /// Update journey plan stop status
  Future<void> updateStopStatus({
    required String stopId,
    required String status,
    String? skipReason,
    Map<String, dynamic>? location,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (status == 'arrived') {
      updates['actual_arrival_time'] = DateTime.now().toIso8601String();
      updates['check_in_location'] = location;
    } else if (status == 'completed') {
      updates['departure_time'] = DateTime.now().toIso8601String();
      updates['check_out_location'] = location;
    } else if (status == 'skipped') {
      updates['skip_reason'] = skipReason;
    }
    
    await _supabase
        .from('journey_plan_stops')
        .update(updates)
        .eq('id', stopId);
  }

  /// Reorder journey plan stops (after route optimization)
  Future<void> reorderJourneyStops(List<String> stopIds) async {
    for (int i = 0; i < stopIds.length; i++) {
      await _supabase
          .from('journey_plan_stops')
          .update({'stop_order': i + 1})
          .eq('id', stopIds[i]);
    }
  }
}

// ==================== PROVIDERS ====================

final salesRouteServiceProvider = Provider((ref) => SalesRouteService());

/// Provider for all routes
final salesRoutesProvider = FutureProvider.autoDispose<List<SalesRoute>>((ref) async {
  final service = ref.watch(salesRouteServiceProvider);
  return service.getRoutes(status: 'active');
});

/// Provider for today's journey plan (requires auth to filter by employee)
final todayJourneyPlanProvider = FutureProvider.autoDispose<JourneyPlan?>((ref) async {
  final service = ref.watch(salesRouteServiceProvider);
  // Note: employeeId passed as null - RLS on the table should handle filtering
  // If RLS doesn't filter, we pass employeeId explicitly
  return service.getTodayJourneyPlan();
});

/// Provider for route customers
final routeCustomersProvider = FutureProvider.autoDispose.family<List<RouteCustomer>, String>((ref, routeId) async {
  final service = ref.watch(salesRouteServiceProvider);
  return service.getRouteCustomers(routeId);
});

/// Provider for journey plan details
final journeyPlanDetailProvider = FutureProvider.autoDispose.family<JourneyPlan?, String>((ref, planId) async {
  final service = ref.watch(salesRouteServiceProvider);
  return service.getJourneyPlanById(planId);
});
