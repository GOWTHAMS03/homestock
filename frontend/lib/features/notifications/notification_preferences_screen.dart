import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import 'notification_controller.dart';
import 'notification_preference_model.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _osPermissionEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _osPermissionEnabled = enabled;
      });
    }
  }

  Future<void> _selectTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Function(String formatted) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      onSelected('$hour:$minute:00');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationControllerProvider);
    final prefs = notifState.preferences;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const HomeStockAppBar(
        title: 'Notification Settings',
        subtitle: 'Customize alerts & quiet hours',
      ),
      body: notifState.isPreferencesLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. OS Permission Banner
                _buildOsPermissionCard(),
                const SizedBox(height: 16),

                // 2. Quiet Hours Card
                _buildQuietHoursCard(prefs),
                const SizedBox(height: 20),

                // 3. Inventory & Restock Alerts
                _buildSectionHeader('INVENTORY & RESTOCK'),
                const SizedBox(height: 8),
                _buildToggleCard([
                  _ToggleItem(
                    title: 'Low Stock Alerts',
                    subtitle: 'Notify when items fall below minimum quantity',
                    value: prefs.lowStockEnabled,
                    onChanged: (val) => _update(prefs.copyWith(lowStockEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Out of Stock Alerts',
                    subtitle: 'Immediate alert when an item reaches 0',
                    value: prefs.outOfStockEnabled,
                    onChanged: (val) => _update(prefs.copyWith(outOfStockEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Expiry Reminders',
                    subtitle: 'Remind 3 days before items expire and upon expiration',
                    value: prefs.expiryEnabled,
                    onChanged: (val) => _update(prefs.copyWith(expiryEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Smart Restock Suggestions',
                    subtitle: 'Predictive alerts based on usage rate',
                    value: prefs.smartSuggestionEnabled,
                    onChanged: (val) => _update(prefs.copyWith(smartSuggestionEnabled: val)),
                  ),
                ]),
                const SizedBox(height: 20),

                // 4. Household & Shopping Activity
                _buildSectionHeader('HOUSEHOLD & SHOPPING'),
                const SizedBox(height: 8),
                _buildToggleCard([
                  _ToggleItem(
                    title: 'Shopping List Updates',
                    subtitle: 'Alerts when family members add or check off items',
                    value: prefs.shoppingListEnabled,
                    onChanged: (val) => _update(prefs.copyWith(shoppingListEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Family Activity',
                    subtitle: 'Notifications for member joins, edits, and invites',
                    value: prefs.familyActivityEnabled,
                    onChanged: (val) => _update(prefs.copyWith(familyActivityEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Purchases Recorded',
                    subtitle: 'Summary when grocery shopping is checked in',
                    value: prefs.purchaseEnabled,
                    onChanged: (val) => _update(prefs.copyWith(purchaseEnabled: val)),
                  ),
                ]),
                const SizedBox(height: 20),

                // 5. Insights & Reports
                _buildSectionHeader('INSIGHTS & REPORTS'),
                const SizedBox(height: 8),
                _buildToggleCard([
                  _ToggleItem(
                    title: 'Weekly Insights',
                    subtitle: 'Weekly consumption and waste summary',
                    value: prefs.weeklyInsightEnabled,
                    onChanged: (val) => _update(prefs.copyWith(weeklyInsightEnabled: val)),
                  ),
                  _ToggleItem(
                    title: 'Monthly Analytics Report',
                    subtitle: 'Comprehensive monthly household spending report',
                    value: prefs.monthlyReportEnabled,
                    onChanged: (val) => _update(prefs.copyWith(monthlyReportEnabled: val)),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _update(NotificationPreferenceModel updated) {
    ref.read(notificationControllerProvider.notifier).updatePreferences(updated);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildOsPermissionCard() {
    return HomeStockCard(
      backgroundColor: _osPermissionEnabled ? Colors.white : const Color(0xFFFFFBEB),
      borderColor: _osPermissionEnabled
          ? AppColors.outline.withValues(alpha: 0.5)
          : Colors.amber.shade300,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _osPermissionEnabled ? const Color(0xFFE6F4EA) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _osPermissionEnabled ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: _osPermissionEnabled ? Colors.green : Colors.amber.shade800,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _osPermissionEnabled
                      ? 'System Notifications Enabled'
                      : 'System Notifications Disabled',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _osPermissionEnabled
                      ? 'Device push notifications are active.'
                      : 'Enable in settings to receive lock-screen alerts.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!_osPermissionEnabled)
            TextButton(
              onPressed: () async {
                await NotificationService.instance.requestPermissions();
                _checkOsPermission();
              },
              child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursCard(NotificationPreferenceModel prefs) {
    return HomeStockCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bedtime_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiet Hours',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Mute non-critical alerts during bedtime',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: prefs.quietHoursEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => _update(prefs.copyWith(quietHoursEnabled: val)),
              ),
            ],
          ),
          if (prefs.quietHoursEnabled) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimePickerButton(
                  label: 'Start Time',
                  time: prefs.startTimeOfDay,
                  onTap: () => _selectTime(
                    context: context,
                    initialTime: prefs.startTimeOfDay,
                    onSelected: (timeStr) => _update(prefs.copyWith(quietHoursStart: timeStr)),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                _buildTimePickerButton(
                  label: 'End Time',
                  time: prefs.endTimeOfDay,
                  onTap: () => _selectTime(
                    context: context,
                    initialTime: prefs.endTimeOfDay,
                    onSelected: (timeStr) => _update(prefs.copyWith(quietHoursEnd: timeStr)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(List<_ToggleItem> items) {
    return HomeStockCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return SwitchListTile(
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            value: item.value,
            activeThumbColor: AppColors.primary,
            onChanged: item.onChanged,
          );
        },
      ),
    );
  }
}

class _ToggleItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
