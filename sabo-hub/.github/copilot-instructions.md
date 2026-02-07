# SABOHUB - Copilot Instructions

## Project Overview
SABOHUB là hệ thống quản lý doanh nghiệp đa ngành (distribution, entertainment, manufacturing).
Flutter web app + Supabase backend.

## CRITICAL: Đọc docs trước khi làm việc
Trước khi bắt đầu bất kỳ task nào, ĐỌC các file sau:
- `sabohub-app/SABOHUB/docs/ARCHITECTURE.md` — Cấu trúc codebase, routing, state management
- `sabohub-app/SABOHUB/docs/DATABASE_SCHEMA.md` — Schema DB, table names, column names, RPCs
- `sabohub-app/SABOHUB/docs/BUSINESS_LOGIC.md` — Business rules, role permissions, workflows
- `sabohub-app/SABOHUB/docs/DEVELOPMENT_GUIDE.md` — Build commands, conventions, patterns

## Quick Reference

### Project Paths
- Flutter project: `sabohub-app/SABOHUB/`
- Python scripts: workspace root (`d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\`)
- Python venv: `.venv\` at workspace root

### Build
```bash
cd sabohub-app/SABOHUB
flutter build web --no-tree-shake-icons
```

### Tech Stack
- Flutter 3.5+ / Dart 3.5+, Web target
- Supabase (project: dqddxowyikefqcdiioyh, region: ap-southeast-2)
- State: Riverpod (flutter_riverpod)
- Routing: GoRouter (go_router)
- Package name: flutter_sabohub

### Codebase Structure
```
lib/
├── business_types/           # Business-specific code (126 files)
│   ├── distribution/         # 97 files (Odori prefix)
│   ├── entertainment/        # 19 files
│   └── manufacturing/        # 10 files
├── pages/                    # Shared pages
│   └── role_based_dashboard.dart  # ROUTING HUB
├── models/                   # Shared models
├── services/                 # Shared services
├── providers/                # Shared providers
├── core/                     # Router, config, theme
├── constants/                # roles.dart, enums
└── widgets/, layouts/, utils/
```

### Key Rules
1. Table `users` KHÔNG TỒN TẠI → dùng `employees`
2. Column `status` = `is_active` (boolean, not string)
3. Column `total_amount` = `total` trong sales_orders
4. KHÔNG import cross business_types (distribution ↔ entertainment)
5. Soft delete: `is_active = false`, KHÔNG xóa record
6. Build LUÔN dùng `--no-tree-shake-icons`
7. Auth: `employee_login` RPC, KHÔNG phải Supabase auth trực tiếp
8. Password: `change_employee_password` RPC

### Roles
superAdmin, ceo, manager, shiftLeader, staff, driver, warehouse

### Business Types
billiards, restaurant, hotel, cafe, retail, distribution, manufacturing
- isDistribution = distribution || manufacturing
- isEntertainment = all others

### DB Connection (Python)
```
Host: aws-1-ap-southeast-2.pooler.supabase.com:6543
DB: postgres
User: postgres.dqddxowyikefqcdiioyh
Pass: Acookingoil123
```
- If any of the scaffolding commands mention that the folder name is not correct, let the user know to create a new folder with the correct name and then reopen it again in vscode.

EXTENSION INSTALLATION RULES:
- Only install extension specified by the get_project_setup_info tool. DO NOT INSTALL any other extensions.

PROJECT CONTENT RULES:
- If the user has not specified project details, assume they want a "Hello World" project as a starting point.
- Avoid adding links of any type (URLs, files, folders, etc.) or integrations that are not explicitly required.
- Avoid generating images, videos, or any other media files unless explicitly requested.
