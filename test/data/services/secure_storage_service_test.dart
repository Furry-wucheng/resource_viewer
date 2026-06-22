import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:resource_viewer/data/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService', () {
    const sourceId = 'test-source-123';
    const password = 'test-password-456';
    const key = 'smb_pwd_$sourceId';

    test('savePassword calls storage.write with correct key', () async {
      when(() => mockStorage.write(key: key, value: password))
          .thenAnswer((_) async {});

      await service.savePassword(sourceId, password);

      verify(() => mockStorage.write(key: key, value: password)).called(1);
    });

    test('getPassword returns password from storage', () async {
      when(() => mockStorage.read(key: key))
          .thenAnswer((_) async => password);

      final result = await service.getPassword(sourceId);

      expect(result, password);
      verify(() => mockStorage.read(key: key)).called(1);
    });

    test('getPassword returns null when not stored', () async {
      when(() => mockStorage.read(key: key))
          .thenAnswer((_) async => null);

      final result = await service.getPassword(sourceId);

      expect(result, isNull);
    });

    test('deletePassword calls storage.delete with correct key', () async {
      when(() => mockStorage.delete(key: key))
          .thenAnswer((_) async {});

      await service.deletePassword(sourceId);

      verify(() => mockStorage.delete(key: key)).called(1);
    });

    test('hasPassword returns true when key exists', () async {
      when(() => mockStorage.containsKey(key: key))
          .thenAnswer((_) async => true);

      final result = await service.hasPassword(sourceId);

      expect(result, true);
      verify(() => mockStorage.containsKey(key: key)).called(1);
    });

    test('hasPassword returns false when key does not exist', () async {
      when(() => mockStorage.containsKey(key: key))
          .thenAnswer((_) async => false);

      final result = await service.hasPassword(sourceId);

      expect(result, false);
    });

    test('deleteAllPasswords deletes only SMB password keys', () async {
      when(() => mockStorage.readAll()).thenAnswer((_) async => {
            'smb_pwd_source1': 'pass1',
            'smb_pwd_source2': 'pass2',
            'other_key': 'value',
          });
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deleteAllPasswords();

      verify(() => mockStorage.delete(key: 'smb_pwd_source1')).called(1);
      verify(() => mockStorage.delete(key: 'smb_pwd_source2')).called(1);
      verifyNever(() => mockStorage.delete(key: 'other_key'));
    });

    test('key naming convention uses smb_pwd_ prefix', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await service.savePassword('abc-123', 'mypassword');

      final captured = verify(() => mockStorage.write(
            key: captureAny(named: 'key'),
            value: any(named: 'value'),
          )).captured;

      expect(captured.single, 'smb_pwd_abc-123');
    });
  });
}
