import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/user.dart';
import 'package:flutter_sabohub/models/business_type.dart';
import 'package:flutter_sabohub/constants/roles.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('parses basic employee JSON correctly', () {
        final json = {
          'id': 'emp-001',
          'full_name': 'Nguyễn Văn A',
          'email': 'a@sabohub.com',
          'role': 'CEO',
          'phone': '0909123456',
          'company_id': 'comp-001',
          'is_active': true,
        };

        final user = User.fromJson(json);

        expect(user.id, 'emp-001');
        expect(user.name, 'Nguyễn Văn A');
        expect(user.email, 'a@sabohub.com');
        expect(user.role, SaboRole.ceo);
        expect(user.phone, '0909123456');
        expect(user.companyId, 'comp-001');
        expect(user.isActive, true);
      });

      test('parses business type from joined company data', () {
        final json = {
          'id': 'emp-002',
          'full_name': 'Trần B',
          'role': 'MANAGER',
          'company_id': 'comp-002',
          'companies': {
            'name': 'SABO Billiards',
            'business_type': 'billiards',
          },
        };

        final user = User.fromJson(json);

        expect(user.businessType, BusinessType.billiards);
        expect(user.companyName, 'SABO Billiards');
      });

      test('parses business type from direct field (local storage restore)', () {
        final json = {
          'id': 'emp-003',
          'full_name': 'Lê C',
          'role': 'STAFF',
          'business_type': 'distribution',
          'company_name': 'Odori',
        };

        final user = User.fromJson(json);

        expect(user.businessType, BusinessType.distribution);
        expect(user.companyName, 'Odori');
      });

      test('handles null name and email gracefully', () {
        final json = {
          'id': 'emp-004',
          'role': 'STAFF',
        };

        final user = User.fromJson(json);

        expect(user.name, isNull);
        expect(user.email, isNull);
      });

      test('falls back to username when email is null', () {
        final json = {
          'id': 'emp-005',
          'full_name': 'Test User',
          'username': 'testuser',
          'role': 'STAFF',
        };

        final user = User.fromJson(json);

        expect(user.email, 'testuser');
      });

      test('falls back to name when full_name is null', () {
        final json = {
          'id': 'emp-006',
          'name': 'Fallback Name',
          'role': 'DRIVER',
        };

        final user = User.fromJson(json);

        expect(user.name, 'Fallback Name');
      });

      test('parses invite/onboarding dates correctly', () {
        final json = {
          'id': 'emp-007',
          'role': 'STAFF',
          'invite_token': 'abc123',
          'invite_expires_at': '2026-03-01T00:00:00.000Z',
          'invited_at': '2026-02-20T10:00:00.000Z',
          'onboarded_at': '2026-02-21T14:30:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.inviteToken, 'abc123');
        expect(user.inviteExpiresAt, isNotNull);
        expect(user.invitedAt, isNotNull);
        expect(user.onboardedAt, isNotNull);
        expect(user.onboardedAt!.day, 21);
      });

      test('defaults business type to billiards for unknown company type', () {
        final json = {
          'id': 'emp-008',
          'role': 'STAFF',
          'companies': {
            'name': 'Unknown Corp',
            'business_type': 'unknown_type',
          },
        };

        final user = User.fromJson(json);

        expect(user.businessType, BusinessType.billiards);
      });
    });

    group('toJson', () {
      test('serializes user correctly', () {
        final user = User(
          id: 'emp-001',
          name: 'Test User',
          email: 'test@sabohub.com',
          role: SaboRole.manager,
          companyId: 'comp-001',
          businessType: BusinessType.restaurant,
          isActive: true,
        );

        final json = user.toJson();

        expect(json['id'], 'emp-001');
        expect(json['full_name'], 'Test User');
        expect(json['email'], 'test@sabohub.com');
        expect(json['role'], 'manager');
        expect(json['company_id'], 'comp-001');
        expect(json['business_type'], 'restaurant');
        expect(json['is_active'], true);
      });

      test('roundtrip fromJson → toJson → fromJson preserves data', () {
        final original = User(
          id: 'emp-round',
          name: 'Roundtrip User',
          email: 'round@sabohub.com',
          role: SaboRole.ceo,
          companyId: 'comp-rt',
          companyName: 'My Company',
          businessType: BusinessType.distribution,
          department: 'sales',
          isActive: true,
        );

        final json = original.toJson();
        final restored = User.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.email, original.email);
        expect(restored.role, original.role);
        expect(restored.companyId, original.companyId);
        expect(restored.companyName, original.companyName);
        expect(restored.businessType, original.businessType);
        expect(restored.department, original.department);
        expect(restored.isActive, original.isActive);
      });
    });

    group('hasRole', () {
      test('CEO has access to all roles', () {
        final ceo = User(id: '1', role: SaboRole.ceo);

        expect(ceo.hasRole(SaboRole.ceo), true);
        expect(ceo.hasRole(SaboRole.manager), true);
        expect(ceo.hasRole(SaboRole.shiftLeader), true);
        expect(ceo.hasRole(SaboRole.staff), true);
        expect(ceo.hasRole(SaboRole.driver), true);
        expect(ceo.hasRole(SaboRole.warehouse), true);
      });

      test('Manager has access to manager, shiftLeader, staff only', () {
        final manager = User(id: '2', role: SaboRole.manager);

        expect(manager.hasRole(SaboRole.manager), true);
        expect(manager.hasRole(SaboRole.shiftLeader), true);
        expect(manager.hasRole(SaboRole.staff), true);
        expect(manager.hasRole(SaboRole.ceo), false);
        expect(manager.hasRole(SaboRole.driver), false);
      });

      test('ShiftLeader has access to shiftLeader, staff only', () {
        final leader = User(id: '3', role: SaboRole.shiftLeader);

        expect(leader.hasRole(SaboRole.shiftLeader), true);
        expect(leader.hasRole(SaboRole.staff), true);
        expect(leader.hasRole(SaboRole.manager), false);
        expect(leader.hasRole(SaboRole.ceo), false);
      });

      test('Staff only has access to staff', () {
        final staff = User(id: '4', role: SaboRole.staff);

        expect(staff.hasRole(SaboRole.staff), true);
        expect(staff.hasRole(SaboRole.shiftLeader), false);
        expect(staff.hasRole(SaboRole.manager), false);
      });
    });

    group('hasAnyRole', () {
      test('returns true when user has at least one required role', () {
        final manager = User(id: '1', role: SaboRole.manager);

        expect(manager.hasAnyRole([SaboRole.ceo, SaboRole.manager]), true);
        expect(manager.hasAnyRole([SaboRole.staff, SaboRole.shiftLeader]), true);
      });

      test('returns false when user has none of required roles', () {
        final staff = User(id: '2', role: SaboRole.staff);

        expect(staff.hasAnyRole([SaboRole.ceo, SaboRole.manager]), false);
      });
    });

    group('displayName', () {
      test('adds role emoji prefix', () {
        final ceo = User(id: '1', name: 'Boss', role: SaboRole.ceo);
        expect(ceo.displayName, '👔 Boss (CEO)');

        final driver = User(id: '2', name: 'Anh Tài', role: SaboRole.driver);
        expect(driver.displayName, '🚗 Anh Tài (Tài xế)');
      });
    });

    group('copyWith', () {
      test('creates a copy with updated fields', () {
        final user = User(
          id: '1',
          name: 'Original',
          role: SaboRole.staff,
          isActive: true,
        );

        final updated = user.copyWith(
          name: 'Updated',
          role: SaboRole.manager,
        );

        expect(updated.name, 'Updated');
        expect(updated.role, SaboRole.manager);
        expect(updated.id, '1'); // Unchanged
        expect(updated.isActive, true); // Unchanged
      });
    });

    group('Equatable', () {
      test('two users with same data are equal', () {
        final user1 = User(id: '1', name: 'Test', role: SaboRole.staff);
        final user2 = User(id: '1', name: 'Test', role: SaboRole.staff);

        expect(user1, equals(user2));
      });

      test('two users with different data are not equal', () {
        final user1 = User(id: '1', name: 'Test', role: SaboRole.staff);
        final user2 = User(id: '2', name: 'Test', role: SaboRole.staff);

        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
