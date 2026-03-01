import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company.dart';
import '../utils/app_logger.dart';

/// Provider to get all active companies for login dropdown
final allCompaniesProvider = FutureProvider.autoDispose<List<Company>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('companies')
        .select('id, name')
        .order('name', ascending: true);
    
    final List<Company> companies = (response as List)
        .map((json) => Company.fromJson(json as Map<String, dynamic>))
        .toList();
    
    return companies;
  } catch (e) {
    AppLogger.error('Error fetching companies', e);
    return [];
  }
});
