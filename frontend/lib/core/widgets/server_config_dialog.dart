import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_colors.dart';
import '../network/lan_discovery_service.dart';
import '../../features/auth/auth_controller.dart' show apiClientProvider;
import '../storage/secure_storage_service.dart';
import '../sync/sync_providers.dart';

/// Shows an interactive server configuration dialog for switching between
/// USB Cable (ADB reverse), Local Wi-Fi, and Emulator with 1-tap Auto-Detect.
void showServerConfigDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController(text: ApiEndpoints.baseUrl);
  bool isTesting = false;
  String? testResult;
  bool? testSuccess;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> testConnection() async {
          final targetUrl = controller.text.trim();
          if (targetUrl.isEmpty) return;

          setDialogState(() {
            isTesting = true;
            testResult = 'Testing connection...';
            testSuccess = null;
          });

          try {
            final dio = Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 3),
                receiveTimeout: const Duration(seconds: 3),
                validateStatus: (status) => true,
              ),
            );

            // Probe ping endpoint
            final probeUrl = targetUrl.endsWith('/api/v1')
                ? '$targetUrl/auth/ping'
                : '$targetUrl/api/v1/auth/ping';

            final res = await dio.get(probeUrl);
            setDialogState(() {
              isTesting = false;
              testSuccess = true;
              testResult = '✓ Connected successfully (HTTP ${res.statusCode})';
            });
          } catch (e) {
            setDialogState(() {
              isTesting = false;
              testSuccess = false;
              testResult = '✗ Cannot reach server. Check Wi-Fi or run connect_mobile.bat for USB.';
            });
          }
        }

        Future<void> autoDetect() async {
          setDialogState(() {
            isTesting = true;
            testResult = 'Scanning local network via UDP & subnet probe...';
            testSuccess = null;
          });

          final found = await LanDiscoveryService.discoverServer();
          if (found != null) {
            controller.text = found;
            setDialogState(() {
              isTesting = false;
              testSuccess = true;
              testResult = '✓ Connected to backend: $found';
            });
          } else {
            setDialogState(() {
              isTesting = false;
              testSuccess = false;
              testResult = '✗ No server found on port 8080. Connect phone to same Wi-Fi or USB cable.';
            });
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Backend Server Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your connection method to connect your phone to the PC backend:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Quick presets
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                      label: const Text('Auto-Detect ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      onPressed: isTesting ? null : autoDetect,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.usb_rounded, size: 14),
                      label: const Text('USB Tunnel (127.0.0.1)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          controller.text = ApiEndpoints.usbAdbUrl;
                          testResult = null;
                          testSuccess = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi_rounded, size: 14),
                      label: const Text('Wi-Fi (192.168.0.182)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          controller.text = ApiEndpoints.currentWifiUrl;
                          testResult = null;
                          testSuccess = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.devices_rounded, size: 14),
                      label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          controller.text = ApiEndpoints.emulatorUrl;
                          testResult = null;
                          testSuccess = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://192.168.0.182:8080/api/v1',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Test Connection Button & Status
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isTesting ? null : testConnection,
                      icon: isTesting
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check_rounded, size: 15),
                      label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: testSuccess == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      testResult!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: testSuccess == true ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  ApiEndpoints.setBaseUrl(newUrl);
                  ref.read(apiClientProvider).updateBaseUrl(newUrl);
                  await SecureStorageService().saveBaseUrl(newUrl);
                  await ref.read(connectivityMonitorProvider).checkRealReachability();
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text('Save & Apply'),
            ),
          ],
        );
      },
    ),
  );
}
