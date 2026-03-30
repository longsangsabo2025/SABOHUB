import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/constants/roles.dart';

void main() {
  group('SaboRole Enum', () {
    group('fromString', () {
      test('parses uppercase role strings', () {
        expect(SaboRole.fromString('CEO'), SaboRole.ceo);
        expect(SaboRole.fromString('MANAGER'), SaboRole.manager);
        expect(SaboRole.fromString('STAFF'), SaboRole.staff);
        expect(SaboRole.fromString('DRIVER'), SaboRole.driver);
        expect(SaboRole.fromString('WAREHOUSE'), SaboRole.warehouse);
        expect(SaboRole.fromString('SHIFT_LEADER'), SaboRole.shiftLeader);
      });

      test('parses SUPER_ADMIN variants', () {
        expect(SaboRole.fromString('SUPER_ADMIN'), SaboRole.superAdmin);
        expect(SaboRole.fromString('SUPERADMIN'), SaboRole.superAdmin);
        expect(SaboRole.fromString('PLATFORM_ADMIN'), SaboRole.superAdmin);
      });

      test('defaults to staff for unknown role', () {
        expect(SaboRole.fromString('UNKNOWN'), SaboRole.staff);
        expect(SaboRole.fromString(''), SaboRole.staff);
        expect(SaboRole.fromString('admin'), SaboRole.staff);
      });

      test('is case-insensitive', () {
        expect(SaboRole.fromString('ceo'), SaboRole.ceo);
        expect(SaboRole.fromString('Ceo'), SaboRole.ceo);
        expect(SaboRole.fromString('manager'), SaboRole.manager);
      });
    });

    group('displayName', () {
      test('returns correct Vietnamese display names', () {
        expect(SaboRole.superAdmin.displayName, 'Super Admin');
        expect(SaboRole.ceo.displayName, 'CEO');
        expect(SaboRole.manager.displayName, 'Quản lý');
        expect(SaboRole.shiftLeader.displayName, 'Tổ trưởng');
        expect(SaboRole.staff.displayName, 'Nhân viên');
        expect(SaboRole.driver.displayName, 'Tài xế');
        expect(SaboRole.warehouse.displayName, 'Nhân viên kho');
      });
    });

    group('toUpperString / toLowerString', () {
      test('converts to db string format (toUpperString is deprecated alias)', () {
        expect(SaboRole.ceo.toUpperString(), 'ceo');
        expect(SaboRole.superAdmin.toUpperString(), 'super_admin');
        expect(SaboRole.shiftLeader.toUpperString(), 'shift_leader');
      });

      test('converts to lowercase', () {
        expect(SaboRole.ceo.toLowerString(), 'ceo');
        expect(SaboRole.superAdmin.toLowerString(), 'superadmin');
      });
    });

    group('Role hierarchy checks', () {
      test('isSuperAdmin', () {
        expect(SaboRole.superAdmin.isSuperAdmin, true);
        expect(SaboRole.ceo.isSuperAdmin, false);
        expect(SaboRole.manager.isSuperAdmin, false);
      });

      test('isManager — includes manager, ceo, superAdmin', () {
        expect(SaboRole.superAdmin.isManager, true);
        expect(SaboRole.ceo.isManager, true);
        expect(SaboRole.manager.isManager, true);
        expect(SaboRole.shiftLeader.isManager, false);
        expect(SaboRole.staff.isManager, false);
        expect(SaboRole.driver.isManager, false);
      });

      test('isExecutive — ceo and superAdmin only', () {
        expect(SaboRole.superAdmin.isExecutive, true);
        expect(SaboRole.ceo.isExecutive, true);
        expect(SaboRole.manager.isExecutive, false);
        expect(SaboRole.staff.isExecutive, false);
      });

      test('canManageEmployees', () {
        expect(SaboRole.superAdmin.canManageEmployees, true);
        expect(SaboRole.ceo.canManageEmployees, true);
        expect(SaboRole.manager.canManageEmployees, true);
        expect(SaboRole.shiftLeader.canManageEmployees, false);
        expect(SaboRole.staff.canManageEmployees, false);
      });

      test('canViewReports', () {
        expect(SaboRole.superAdmin.canViewReports, true);
        expect(SaboRole.ceo.canViewReports, true);
        expect(SaboRole.manager.canViewReports, true);
        expect(SaboRole.staff.canViewReports, false);
        expect(SaboRole.driver.canViewReports, false);
      });

      test('isDeliveryRole', () {
        expect(SaboRole.driver.isDeliveryRole, true);
        expect(SaboRole.staff.isDeliveryRole, false);
        expect(SaboRole.warehouse.isDeliveryRole, false);
      });

      test('isWarehouseRole', () {
        expect(SaboRole.warehouse.isWarehouseRole, true);
        expect(SaboRole.staff.isWarehouseRole, false);
        expect(SaboRole.driver.isWarehouseRole, false);
      });

      test('hasPlatformAccess', () {
        expect(SaboRole.superAdmin.hasPlatformAccess, true);
        expect(SaboRole.ceo.hasPlatformAccess, false);
        expect(SaboRole.manager.hasPlatformAccess, false);
      });
    });

    group('values', () {
      test('has exactly 9 roles', () {
        expect(SaboRole.values.length, 9);
      });

      test('contains all expected roles', () {
        final names = SaboRole.values.map((r) => r.name).toList();
        expect(names, containsAll([
          'superAdmin', 'ceo', 'manager', 'shiftLeader',
          'staff', 'driver', 'warehouse', 'finance', 'shareholder'
        ]));
      });
    });
  });
}
