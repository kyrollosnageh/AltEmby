import 'package:altemby/features/auth/data/emby_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectServer', () {
    test('parses from JSON', () {
      final server = ConnectServer.fromJson({
        'SystemId': 'sys-1',
        'AccessKey': 'key-1',
        'Name': 'My Server',
        'Url': 'https://remote.example.com',
        'LocalAddress': 'http://192.168.1.100:8096',
      });
      expect(server.systemId, 'sys-1');
      expect(server.accessKey, 'key-1');
      expect(server.name, 'My Server');
      expect(server.remoteUrl, 'https://remote.example.com');
      expect(server.localUrl, 'http://192.168.1.100:8096');
    });

    test('urls lists local first, then remote', () {
      final server = ConnectServer.fromJson({
        'SystemId': 's1',
        'AccessKey': 'k1',
        'Name': 'S',
        'Url': 'https://remote.com',
        'LocalAddress': 'http://192.168.1.1:8096',
      });
      expect(server.urls, ['http://192.168.1.1:8096', 'https://remote.com']);
    });

    test('urls contains only remote when no local', () {
      final server = ConnectServer.fromJson({
        'SystemId': 's1',
        'AccessKey': 'k1',
        'Name': 'S',
        'Url': 'https://remote.com',
      });
      expect(server.urls, ['https://remote.com']);
    });

    test('urls is empty when no addresses', () {
      final server = ConnectServer.fromJson({
        'SystemId': 's1',
        'AccessKey': 'k1',
        'Name': 'S',
      });
      expect(server.urls, isEmpty);
    });
  });
}
