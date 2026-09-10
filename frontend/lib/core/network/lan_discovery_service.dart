import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';

/// Dynamic local area network discovery service.
/// Automatically locates the HomeStock Spring Boot backend across ANY network:
/// - Home Wi-Fi (192.168.0.x)
/// - Office Wi-Fi (192.168.1.x)
/// - Mobile Hotspot (172.20.10.x / 192.168.43.x)
/// - USB Cable (127.0.0.1 via ADB reverse)
/// - Android Emulator (10.0.2.2)
class LanDiscoveryService {
  static const int discoveryPort = 8888;
  static const String discoveryMessage = 'HOMESTOCK_DISCOVER';
  static const String responsePrefix = 'HOMESTOCK_SERVER:';

  /// Performs multi-phase dynamic discovery and returns the first responsive backend URL.
  static Future<String?> discoverServer({
    Duration timeout = const Duration(milliseconds: 2000),
  }) async {
    // 1. Check all candidate URLs in priority order (baseUrl, USB ADB, current Wi-Fi, emulator, localhost)
    for (final candidate in ApiEndpoints.candidateUrls) {
      final verified = await _probeUrl(candidate, const Duration(milliseconds: 300));
      if (verified != null) {
        if (kDebugMode) print('[LanDiscovery] Connected to candidate URL: $verified');
        return verified;
      }
    }

    // 2. UDP Broadcast Discovery (receives backend's self-announced IP on this network)
    final udpResult = await _discoverViaUdp(timeout: const Duration(milliseconds: 1000));
    if (udpResult != null) {
      final verified = await _probeUrl(udpResult, const Duration(milliseconds: 600));
      if (verified != null) {
        if (kDebugMode) print('[LanDiscovery] Found backend via UDP broadcast: $verified');
        return verified;
      }
    }

    // 3. Subnet Probing based on Phone's active Wi-Fi IP
    final subnetResult = await _probeLocalSubnet();
    if (subnetResult != null) {
      if (kDebugMode) print('[LanDiscovery] Found backend via Subnet scan: $subnetResult');
      return subnetResult;
    }

    return null;
  }

  /// Sends UDP broadcast and awaits reply from LanDiscoveryService
  static Future<String?> _discoverViaUdp({required Duration timeout}) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final completer = Completer<String?>();
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            final text = utf8.decode(datagram.data).trim();
            if (text.startsWith(responsePrefix)) {
              final url = text.substring(responsePrefix.length).trim();
              if (!completer.isCompleted) {
                timer.cancel();
                completer.complete(url);
              }
            }
          }
        }
      });

      // Broadcast to standard 255.255.255.255 (may throw EPERM on Android if global broadcast is blocked)
      final bytes = utf8.encode(discoveryMessage);
      try {
        socket.send(bytes, InternetAddress('255.255.255.255'), discoveryPort);
      } catch (e) {
        if (kDebugMode) print('[LanDiscovery] Global 255.255.255.255 broadcast ignored: $e');
      }

      // Also broadcast to active local interfaces' broadcast addresses
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnetBcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                socket.send(bytes, InternetAddress(subnetBcast), discoveryPort);
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      final result = await completer.future;
      return result;
    } catch (e) {
      if (kDebugMode) print('[LanDiscovery] UDP discovery error: $e');
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Inspects phone's active IP and probes candidate hosts on the same subnet
  static Future<String?> _probeLocalSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final candidateIps = <String>{};

      for (final iface in interfaces) {
        if (iface.name.toLowerCase().contains('wlan') ||
            iface.name.toLowerCase().contains('en') ||
            iface.name.toLowerCase().contains('eth') ||
            iface.name.toLowerCase().contains('wi-fi')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && !addr.address.startsWith('127.')) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
                // Common gateway and server hosts
                candidateIps.add('${prefix}1');
                candidateIps.add('${prefix}2');
                candidateIps.add('${prefix}100');
                candidateIps.add('${prefix}101');
                candidateIps.add('${prefix}102');
                candidateIps.add('${prefix}150');
                candidateIps.add('${prefix}182');
                candidateIps.add('${prefix}200');
                candidateIps.add('${prefix}254');

                // Hosts adjacent to the phone's IP
                final myOctet = int.tryParse(parts[3]) ?? 0;
                for (int offset = -5; offset <= 5; offset++) {
                  final target = myOctet + offset;
                  if (target > 0 && target < 255 && target != myOctet) {
                    candidateIps.add('$prefix$target');
                  }
                }
              }
            }
          }
        }
      }

      // Probe candidate hosts concurrently
      final futures = candidateIps.map((ip) async {
        final url = 'http://$ip:8080/api/v1';
        return await _probeUrl(url, const Duration(milliseconds: 400));
      });

      final results = await Future.wait(futures);
      for (final res in results) {
        if (res != null) return res;
      }
    } catch (_) {}
    return null;
  }

  /// Probes whether a specific URL has port 8080 open and accepts TCP connections
  /// Probes whether a specific URL has the HomeStock Spring Boot API active and responsive
  static Future<String?> _probeUrl(String url, Duration timeout) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || uri.host.isEmpty) return null;
      final port = uri.port > 0 ? uri.port : 8080;

      // Fast TCP check first (sub-50ms fail-fast)
      try {
        final socket = await Socket.connect(uri.host, port, timeout: timeout);
        socket.destroy();
      } catch (_) {
        return null;
      }

      // Verify HTTP /auth/ping to ensure it is genuinely the HomeStock backend
      final cleanBase = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final probeEndpoint = cleanBase.endsWith('/api/v1')
          ? '$cleanBase/auth/ping'
          : '$cleanBase/api/v1/auth/ping';

      final client = HttpClient()..connectionTimeout = timeout;
      final req = await client.getUrl(Uri.parse(probeEndpoint)).timeout(timeout);
      final resp = await req.close().timeout(timeout);
      final isHealthy = resp.statusCode == 200 || resp.statusCode == 401;
      client.close();

      if (isHealthy) {
        return cleanBase.endsWith('/api/v1') ? cleanBase : '$cleanBase/api/v1';
      }
    } catch (_) {}
    return null;
  }
}
