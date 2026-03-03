/// Test driver for running integration tests on web via `flutter drive`.
///
/// Usage:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/employee_flow_test.dart \
///     -d chrome
library;

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
