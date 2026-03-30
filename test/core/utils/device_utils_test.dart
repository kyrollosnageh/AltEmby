// test/core/utils/device_utils_test.dart

import 'package:altemby/core/utils/device_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late DeviceUtils deviceUtils;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    deviceUtils = DeviceUtils(secureStorage: mockStorage);
  });

  group('getOrCreateDeviceId', () {
    test('returns existing device ID when stored', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'existing-id-123');

      final id = await deviceUtils.getOrCreateDeviceId();

      expect(id, 'existing-id-123');
      verifyNever(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('creates and stores new device ID when none exists', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final id = await deviceUtils.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      expect(id.length, greaterThanOrEqualTo(32));
      verify(() => mockStorage.write(key: 'device_id', value: id)).called(1);
    });
  });

  group('getDeviceName', () {
    test('returns a non-empty string', () {
      final name = DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);
    });
  });
}
