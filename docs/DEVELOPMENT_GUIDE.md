# SABOHUB Development Guide

> Hướng dẫn phát triển, conventions, và workflow cho developer/AI.
> Cập nhật: 2026-02-07

## 1. Environment Setup

### Prerequisites
- Flutter SDK >= 3.5.0 (Dart >= 3.5.0)
- Chrome (cho web target)
- Git
- Python 3.x + venv (cho DB scripts)

### Project Paths
```
Workspace root:   d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\
Flutter project:  d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\
Python venv:      d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\.venv\
```

### First Time Setup
```bash
cd sabohub-app/SABOHUB
flutter pub get
```

### Environment Variables
File: `sabohub-app/SABOHUB/.env.local`
```
SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

### Database Connection (Python scripts)
```
Host: aws-1-ap-southeast-2.pooler.supabase.com
Port: 6543
Database: postgres
User: postgres.dqddxowyikefqcdiioyh
Password: Acookingoil123
```

## 2. Build & Run

### Web (Primary target)
```bash
cd sabohub-app/SABOHUB
flutter build web --no-tree-shake-icons
```

### Run in Chrome
```bash
flutter run -d chrome
```

### Analyze
```bash
flutter analyze
```

### Clean Rebuild
```bash
flutter clean && flutter pub get && flutter build web --no-tree-shake-icons
```

## 3. Project Structure

```
lib/
├── main.dart                    # Entry point, Supabase init
├── constants/                   # Enums, role definitions
│   └── roles.dart               # SaboRole enum
├── models/                      # Shared data models
│   ├── user.dart                # User model (role, department, businessType)
│   └── business_type.dart       # BusinessType enum
├── core/                        # Infrastructure layer
│   ├── config/                  # supabase_config.dart
│   ├── router/                  # app_router.dart (GoRouter)
│   ├── theme/                   # App themes
│   └── errors/                  # Error handling
├── services/                    # Shared Supabase service layer
├── providers/                   # Shared Riverpod providers
├── pages/                       # Shared pages (auth, common UI)
│   └── role_based_dashboard.dart # ROUTING HUB
├── layouts/                     # Shared default layouts
├── widgets/                     # Shared reusable widgets
├── business_types/              # Business-specific code
│   ├── distribution/            # 97 files (Odori)
│   │   ├── layouts/             # Distribution-specific layouts
│   │   ├── pages/               # Distribution-specific pages
│   │   ├── models/              # OdoriCustomer, OdoriProduct, etc.
│   │   ├── services/            # Supabase services for distribution
│   │   ├── providers/           # Riverpod providers
│   │   └── widgets/             # Distribution UI components
│   ├── entertainment/           # 19 files (Billiards/F&B)
│   └── manufacturing/           # 10 files
└── utils/, shared/, features/, mixins/
```

## 4. Coding Conventions

### Naming
| Type | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `customer_detail_page.dart` |
| Classes | PascalCase | `CustomerDetailPage` |
| Variables | camelCase | `customerName` |
| Constants | camelCase | `defaultPageSize` |
| Providers | camelCase + Provider | `currentUserProvider` |
| DB tables | snake_case (plural) | `sales_orders` |
| DB columns | snake_case | `company_id` |

### File Naming Pattern
```
{feature}_{type}.dart

Types: page, layout, service, provider, model, widget, screen
Examples: order_detail_page.dart, inventory_service.dart, order_provider.dart
```

### Distribution-specific files prefix
- Models: `odori_*.dart` (e.g., `odori_customer.dart`)
- Services: `odori_*_service.dart` (e.g., `odori_notification_service.dart`)

## 5. Import Patterns

### Từ shared → shared
```dart
import 'package:flutter_sabohub/models/user.dart';
import 'package:flutter_sabohub/services/supabase_service.dart';
```

### Từ shared → business_types
```dart
import 'package:flutter_sabohub/business_types/distribution/models/odori_customer.dart';
```

### Từ business_types → shared
```dart
import 'package:flutter_sabohub/models/user.dart';
import 'package:flutter_sabohub/constants/roles.dart';
```

### ⚠️ KHÔNG BAO GIỜ giữa business types
```dart
// ❌ NEVER: distribution importing entertainment
import 'package:flutter_sabohub/business_types/entertainment/...';
```

## 6. Supabase Query Patterns

### Basic Select
```dart
final response = await Supabase.instance.client
    .from('customers')
    .select()
    .eq('company_id', companyId)
    .eq('is_active', true)
    .order('created_at', ascending: false);
```

### Select with Join
```dart
final response = await Supabase.instance.client
    .from('sales_orders')
    .select('*, customers(name, phone), employees(name)')
    .eq('company_id', companyId);
```

### RPC Call
```dart
final response = await Supabase.instance.client
    .rpc('employee_login', params: {
      'p_email': email,
      'p_password': password,
    });
```

### Insert
```dart
await Supabase.instance.client
    .from('customers')
    .insert({
      'name': name,
      'company_id': companyId,
      'created_by': userId,
    });
```

### Update
```dart
await Supabase.instance.client
    .from('customers')
    .update({'name': newName})
    .eq('id', customerId);
```

### ⚠️ Common Query Pitfalls
| Wrong | Correct | Note |
|-------|---------|------|
| `.from('users')` | `.from('employees')` | Table `users` không tồn tại |
| `.select('total_amount')` | `.select('total')` | Column name khác |
| `.eq('status', 'active')` | `.eq('is_active', true)` | Boolean, not string |
| `.from('daily_reports')` | N/A | Table không tồn tại |

## 7. Riverpod State Management

### Provider Types Used
```dart
// Simple provider
final someProvider = Provider<Type>((ref) => ...);

// State notifier
final someProvider = StateNotifierProvider<Notifier, State>((ref) => ...);

// Future provider
final someProvider = FutureProvider<Type>((ref) async => ...);

// Family provider (parameterized)
final someProvider = FutureProvider.family<Type, Param>((ref, param) async => ...);
```

### Core Provider
```dart
// Current logged-in user
final currentUserProvider = StateProvider<User?>((ref) => null);
```

### Pattern: Service + Provider
```dart
// 1. Service (handles Supabase calls)
class OrderService {
  Future<List<Order>> getOrders(String companyId) async { ... }
}

// 2. Provider (exposes service + state)
final orderServiceProvider = Provider((ref) => OrderService());
final ordersProvider = FutureProvider.family<List<Order>, String>((ref, companyId) {
  return ref.read(orderServiceProvider).getOrders(companyId);
});
```

## 8. Adding New Features

### New Page for Existing Business Type
1. Create `business_types/{type}/pages/new_feature_page.dart`
2. Add route in `core/router/app_router.dart`
3. Add tab/navigation in layout if needed

### New Shared Feature
1. Create page in `pages/`
2. Create service in `services/`
3. Create provider in `providers/`
4. Add route in `app_router.dart`

### New Business Type
1. Create `business_types/{new_type}/` directory structure
2. Add enum value in `models/business_type.dart`
3. Add routing case in `pages/role_based_dashboard.dart`
4. Create layouts for each role

## 9. Database Scripts (Python)

### Location
Root workspace: `d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\`

### Activate venv
```bash
.venv\Scripts\activate
```

### Run script
```bash
python check_schema_pooler.py
python fix_inventory_quantities.py
```

### Script Template
```python
import psycopg2

DB_CONFIG = {
    'host': 'aws-1-ap-southeast-2.pooler.supabase.com',
    'port': 6543,
    'dbname': 'postgres',
    'user': 'postgres.dqddxowyikefqcdiioyh',
    'password': 'Acookingoil123',
}

def main():
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM employees LIMIT 5;")
        rows = cur.fetchall()
        for row in rows:
            print(row)
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
```

## 10. Debugging Tips

### Common Issues
1. **"Table not found"**: Check DATABASE_SCHEMA.md for actual table names
2. **"Column not found"**: Run `python check_schema_pooler.py` to verify
3. **Import errors after moving files**: Check relative vs package imports
4. **Build fails with icon errors**: Use `--no-tree-shake-icons` flag
5. **RPC 404**: Check if RPC exists, verify param names match exactly

### Verify DB Schema
```bash
cd d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub
python check_schema_pooler.py
```

### Flutter DevTools
```bash
flutter run -d chrome --start-paused
# Open DevTools URL in browser
```

## 11. Key Supabase Config

| Setting | Value |
|---------|-------|
| Project ID | `dqddxowyikefqcdiioyh` |
| Region | `ap-southeast-2` (Sydney) |
| Auth | PKCE flow |
| Storage | Supabase Storage (avatars, documents) |
| RLS | Enabled on all tables |
| Pooler | Port 6543, Transaction mode |

## 12. Don'ts

- ❌ KHÔNG tạo `CosmosClient` mới mỗi lần (dùng singleton)
- ❌ KHÔNG dùng `users` table (dùng `employees`)
- ❌ KHÔNG dùng `status = 'active'` (dùng `is_active = true`)
- ❌ KHÔNG import cross business_types
- ❌ KHÔNG hardcode Supabase URL/key (dùng `.env.local`)
- ❌ KHÔNG xóa record (dùng soft delete: `is_active = false`)
- ❌ KHÔNG tạo folder mới ngoài structure hiện tại
- ❌ KHÔNG dùng `flutter build web` thiếu `--no-tree-shake-icons`
