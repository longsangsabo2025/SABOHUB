/// Interface for Customer data access
/// Extracted from 33 files directly accessing 'customers' table (81 hits)
/// NOTE: No CustomerService exists yet - this will be the first proper abstraction
abstract class ICustomerRepository {
  Future<List<Map<String, dynamic>>> getCustomers({
    String? companyId,
    String? tier,
    String? assignedTo,
    String? searchQuery,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>?> getCustomerById(String id);
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateCustomer(
      String id, Map<String, dynamic> data);
  Future<void> deleteCustomer(String id);
  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId);
  Future<Map<String, dynamic>> getCustomerStats({String? companyId});
  Future<int> getCustomerCount({String? companyId});
  Stream<List<Map<String, dynamic>>> subscribeToCustomers({String? companyId});
}
