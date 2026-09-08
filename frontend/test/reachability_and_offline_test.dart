import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_status.dart';

void main() {
  group('Fast Reachability & Offline Detection Tests', () {
    test('ConnectivityMonitor starts offline by default and emits status changes', () async {
      final monitor = ConnectivityMonitor();
      expect(monitor.currentStatus, NetworkStatus.offline);
      expect(monitor.isOnline, isFalse);

      bool restoredCalled = false;
      monitor.onConnectivityRestored = () {
        restoredCalled = true;
      };

      // Mark online (e.g. successful reachability probe)
      monitor.markOnline();
      expect(monitor.isOnline, isTrue);
      expect(monitor.currentStatus, NetworkStatus.online);
      expect(restoredCalled, isTrue);

      // Mark offline immediately (e.g. socket/connect error)
      monitor.markOffline();
      expect(monitor.isOnline, isFalse);
      expect(monitor.currentStatus, NetworkStatus.offline);

      monitor.dispose();
    });

    test('ApiClient configures fast failover connectTimeout of 3500ms', () {
      final storage = SecureStorageService();
      final monitor = ConnectivityMonitor();
      final client = ApiClient(
        secureStorage: storage,
        connectivityMonitor: monitor,
      );

      expect(client.dio.options.connectTimeout, const Duration(milliseconds: 3500));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 10));
      expect(client.connectivityMonitor, equals(monitor));

      monitor.dispose();
    });

    test('ApiClient interceptor marks offline immediately on connection timeout', () async {
      final storage = SecureStorageService();
      final monitor = ConnectivityMonitor();
      monitor.markOnline();
      expect(monitor.isOnline, isTrue);

      final client = ApiClient(
        secureStorage: storage,
        connectivityMonitor: monitor,
      );

      client.dio.httpClientAdapter = _TimeoutAdapter();

      try {
        await client.dio.get('/test');
      } catch (_) {}

      // Connectivity monitor must immediately switch to offline
      expect(monitor.isOnline, isFalse);
      expect(monitor.currentStatus, NetworkStatus.offline);

      monitor.dispose();
    });

    test('Syncing state transitions maintain consistency', () {
      final monitor = ConnectivityMonitor();
      monitor.markOnline();
      expect(monitor.currentStatus, NetworkStatus.online);

      monitor.setSyncing();
      expect(monitor.currentStatus, NetworkStatus.syncing);

      monitor.setSyncComplete();
      expect(monitor.currentStatus, NetworkStatus.online);

      monitor.dispose();
    });
  });
}

class _TimeoutAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
      message: 'Connection timed out',
    );
  }

  @override
  void close({bool force = false}) {}
}
