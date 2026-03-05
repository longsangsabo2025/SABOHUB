import '../../models/company.dart';

/// Abstract interface cho CompanyService.
///
/// Cho phép:
/// - Mock trong unit tests
/// - Swap implementation (e.g. offline-first) mà không sửa code dùng
/// - Enforce contract rõ ràng
///
/// Tất cả code mới nên depend on [ICompanyService] thay vì [CompanyService].
abstract class ICompanyService {
  /// Get all companies (admin/platform only, excludes soft-deleted).
  Future<List<Company>> getAllCompanies();

  /// Get companies owned by a user (CEO dashboard).
  Future<List<Company>> getMyCompanies({String? userId});

  /// Get company by ID.
  Future<Company?> getCompanyById(String id);

  /// Create a new company.
  Future<Company> createCompany({
    required String name,
    required String userId,
    String? address,
    String? phone,
    String? email,
    String? businessType,
  });

  /// Update company fields.
  Future<Company> updateCompany(String id, Map<String, dynamic> updates);

  /// Soft delete a company.
  Future<void> deleteCompany(String id);

  /// Restore a soft-deleted company.
  Future<void> restoreCompany(String id);

  /// Get company statistics.
  Future<Map<String, dynamic>> getCompanyStats(String companyId);

  /// Real-time stream of companies.
  Stream<List<Company>> subscribeToCompanies();
}
