/// Repository layer barrel export
///
/// Repositories provide a clean abstraction over Supabase tables,
/// consolidating scattered .from('table') calls into single access points.
///
/// Priority tables (by access frequency):
/// 1. sales_orders: 115 hits across 39 files → ISalesOrderRepository
/// 2. employees: 101 hits across 46 files → IEmployeeRepository
/// 3. customers: 81 hits across 33 files → ICustomerRepository
/// 4. tasks: 59 hits across 15 files → (Sprint 2)
/// 5. companies: 45 hits across 19 files → (Sprint 2)
library;

export 'base_repository.dart';
export 'i_sales_order_repository.dart';
export 'i_employee_repository.dart';
export 'i_customer_repository.dart';

// Concrete implementations (Sprint 1)
export 'impl/sales_order_repository.dart';
export 'impl/employee_repository.dart';
export 'impl/customer_repository.dart';
