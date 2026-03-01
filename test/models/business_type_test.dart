import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/business_type.dart';

void main() {
  group('BusinessType Enum', () {
    group('isDistribution', () {
      test('distribution is distribution', () {
        expect(BusinessType.distribution.isDistribution, true);
      });

      test('manufacturing is distribution', () {
        expect(BusinessType.manufacturing.isDistribution, true);
      });

      test('billiards is NOT distribution', () {
        expect(BusinessType.billiards.isDistribution, false);
      });

      test('restaurant is NOT distribution', () {
        expect(BusinessType.restaurant.isDistribution, false);
      });

      test('hotel is NOT distribution', () {
        expect(BusinessType.hotel.isDistribution, false);
      });

      test('cafe is NOT distribution', () {
        expect(BusinessType.cafe.isDistribution, false);
      });

      test('retail is NOT distribution', () {
        expect(BusinessType.retail.isDistribution, false);
      });
    });

    group('isManufacturing', () {
      test('manufacturing is manufacturing', () {
        expect(BusinessType.manufacturing.isManufacturing, true);
      });

      test('distribution is NOT manufacturing', () {
        expect(BusinessType.distribution.isManufacturing, false);
      });
    });

    group('isEntertainment', () {
      test('entertainment types return true', () {
        expect(BusinessType.billiards.isEntertainment, true);
        expect(BusinessType.restaurant.isEntertainment, true);
        expect(BusinessType.hotel.isEntertainment, true);
        expect(BusinessType.cafe.isEntertainment, true);
        expect(BusinessType.retail.isEntertainment, true);
      });

      test('distribution types return false', () {
        expect(BusinessType.distribution.isEntertainment, false);
        expect(BusinessType.manufacturing.isEntertainment, false);
      });
    });

    group('ceoLabel', () {
      test('entertainment types return "Vận Hành"', () {
        expect(BusinessType.billiards.ceoLabel, 'Vận Hành');
        expect(BusinessType.restaurant.ceoLabel, 'Vận Hành');
        expect(BusinessType.hotel.ceoLabel, 'Vận Hành');
        expect(BusinessType.cafe.ceoLabel, 'Vận Hành');
        expect(BusinessType.retail.ceoLabel, 'Vận Hành');
      });

      test('distribution returns "Phân Phối"', () {
        expect(BusinessType.distribution.ceoLabel, 'Phân Phối');
      });

      test('manufacturing returns "Sản Xuất"', () {
        expect(BusinessType.manufacturing.ceoLabel, 'Sản Xuất');
      });
    });

    group('label', () {
      test('all types have Vietnamese labels', () {
        expect(BusinessType.billiards.label, 'Quán Bida');
        expect(BusinessType.restaurant.label, 'Nhà Hàng');
        expect(BusinessType.hotel.label, 'Khách Sạn');
        expect(BusinessType.cafe.label, 'Quán Cafe');
        expect(BusinessType.retail.label, 'Cửa Hàng');
        expect(BusinessType.distribution.label, 'Phân Phối');
        expect(BusinessType.manufacturing.label, 'Sản Xuất');
      });
    });

    group('values', () {
      test('has exactly 8 business types', () {
        expect(BusinessType.values.length, 8);
      });
    });
  });
}
