/// Interface for Employee data access
/// Extracted from 46 files directly accessing 'employees' table (101 hits)
abstract class IEmployeeRepository {
  Future<List<Map<String, dynamic>>> getEmployees({
    String? companyId,
    String? role,
    bool? isActive,
    int? limit,
  });
  Future<Map<String, dynamic>?> getEmployeeById(String id);
  Future<Map<String, dynamic>?> getEmployeeByAuthId(String authUserId);
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateEmployee(
      String id, Map<String, dynamic> data);
  Future<void> toggleEmployeeStatus(String id, bool isActive);
  Future<void> deleteEmployee(String id);
  Future<int> getEmployeeCount({String? companyId});
  Stream<List<Map<String, dynamic>>> subscribeToEmployees({String? companyId});
}
