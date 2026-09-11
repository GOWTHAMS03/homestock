import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/in_app_notification_banner.dart';
import 'notification_controller.dart';
import 'notification_preference_model.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _osPermissionEnabled = true;
  bool _isTestingPush = false;
  String _previewScenario = 'LOW_STOCK'; // 'LOW_STOCK', 'EXPIRING', 'SHOPPING'

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
                const SizedBox(height: 16),

                // 2b. Firebase Test Card
                _buildTestPushCard(),
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

  Widget _buildTestPushCard() {
    final token = NotificationService.instance.fcmToken;
    final hasToken = token != null && token.isNotEmpty;

    // Determine current preview metadata based on selected scenario
    final String previewEmoji;
    final Color previewBg;
    final Color previewBorder;
    final String previewBadge;
    final Color previewBadgeBg;
    final Color previewBadgeTextColor;
    final String previewTitle;
    final String previewSubtitle;
    final String previewAction;
    final Color previewActionColor;

    if (_previewScenario == 'EXPIRING') {
      previewEmoji = '🥚';
      previewBg = const Color(0xFFFFEDD5);
      previewBorder = const Color(0xFFFED7AA);
      previewBadge = '⏳ EXPIRING SOON';
      previewBadgeBg = const Color(0xFFFFEDD5);
      previewBadgeTextColor = const Color(0xFFC2410C);
      previewTitle = 'Eggs Expiring in 3 Days';
      previewSubtitle = '24 pcs remaining • Use soon to avoid waste';
      previewAction = 'Inspect Item';
      previewActionColor = const Color(0xFFF59E0B);
    } else if (_previewScenario == 'SHOPPING') {
      previewEmoji = '🛒';
      previewBg = const Color(0xFFF3E8FF);
      previewBorder = const Color(0xFFDDD6FE);
      previewBadge = '🛒 SHOPPING LIST';
      previewBadgeBg = const Color(0xFFEDE9FE);
      previewBadgeTextColor = const Color(0xFF6D28D9);
      previewTitle = 'Shopping List Updated';
      previewSubtitle = 'Gowtham added Rice (2 kg) & Milk (1 L)';
      previewAction = 'View List';
      previewActionColor = const Color(0xFF6366F1);
    } else {
      previewEmoji = '🥛';
      previewBg = const Color(0xFFFEF9C3);
      previewBorder = const Color(0xFFFDE68A);
      previewBadge = '⚠️ LOW STOCK';
      previewBadgeBg = const Color(0xFFFEF3C7);
      previewBadgeTextColor = const Color(0xFFB45309);
      previewTitle = 'Milk (பால்) is running low';
      previewSubtitle = 'Only 0.5 L left • Min reserve: 2 L';
      previewAction = '+ Add to Shopping';
      previewActionColor = const Color(0xFF6366F1);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFAF9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDDD6FE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP ROW: Firebase Flame Squircle + Title & Subtitle + Active Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 48x48 Multi-tone flame squircle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFEA580C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 13),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Cloud Push',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Realtime alerts for stockouts, expiries & sync',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: hasToken ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasToken ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasToken ? '🟢' : '🟡',
                      style: const TextStyle(fontSize: 8.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasToken ? 'Connected' : 'Local Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hasToken ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. CARD THEME SHOWCASE / LIVE PREVIEW
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subheader with icon
                Row(
                  children: [
                    const Icon(
                      Icons.preview_rounded,
                      size: 13,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'NOTIFICATION CARD PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Project Theme',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Nested Interactive Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: previewBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 40x40 Food Emoji Squircle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: previewBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                previewEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Metadata + Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: previewBadgeBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        previewBadge,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: previewBadgeTextColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Just now',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6366F1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  previewTitle,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFFCBD5E1),
                          ),
                        ],
                      ),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.only(left: 50, top: 3),
                        child: Text(
                          previewSubtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Action Button in Preview Card
                      Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: previewActionColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.touch_app_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    previewAction,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '⚡ Realtime Push',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. SCENARIO SELECTOR CHIPS
                Row(
                  children: [
                    const Text(
                      'Scenario: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildScenarioChip('LOW_STOCK', '🥛 Low Stock'),
                            const SizedBox(width: 6),
                            _buildScenarioChip('EXPIRING', '⏳ Expiry'),
                            const SizedBox(width: 6),
                            _buildScenarioChip('SHOPPING', '🛒 Shopping'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. TOKEN DIAGNOSTICS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasToken
                        ? 'Token: ${token.substring(0, 8)}...${token.substring(token.length - 6)}'
                        : 'Token: Initialized with Mock/Local Fallback',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasToken)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: token));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FCM Device Token copied to clipboard!'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 12, color: Color(0xFF6366F1)),
                          SizedBox(width: 3),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. PRIMARY SEND TEST BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isTestingPush ? null : _sendTestPush,
              icon: _isTestingPush
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 17),
              label: Text(
                _isTestingPush ? 'Dispatching Firebase Alert...' : 'Send Test Notification',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioChip(String key, String label) {
    final isSelected = _previewScenario == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _previewScenario = key);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestPush() async {
    setState(() => _isTestingPush = true);
    HapticFeedback.mediumImpact();

    String title;
    String body;
    String type;
    String? entityId;

    if (_previewScenario == 'EXPIRING') {
      title = 'Eggs Expiring in 3 Days';
      body = '24 pcs of fresh eggs will expire soon. Consider using to avoid waste!';
      type = 'EXPIRING_SOON';
      entityId = 'item-eggs';
    } else if (_previewScenario == 'SHOPPING') {
      title = 'Shopping List Updated';
      body = 'Gowtham added Rice (2 kg) and Milk (1 L) to household shopping list.';
      type = 'SHOPPING_LIST_UPDATE';
      entityId = null;
    } else {
      title = 'Low stock: Milk (பால்)';
      body = 'Only 0.5 L remaining in Refrigerator. Recommended minimum: 2 L.';
      type = 'LOW_STOCK';
      entityId = 'item-milk';
    }

    // Immediately show the in-app foreground notification card with project theme
    InAppNotificationBanner.show(
      context: context,
      title: title,
      body: body,
      type: type,
      entityId: entityId,
      onTap: () {
        if (entityId != null && entityId.isNotEmpty) {
          context.push('/inventory/detail/$entityId');
        } else if (type == 'SHOPPING_LIST_UPDATE') {
          context.push('/shopping');
        } else {
          context.push('/notifications');
        }
      },
      onActionTap: () {
        if (type == 'LOW_STOCK') {
          context.push('/shopping');
        } else if (type == 'EXPIRING_SOON' && entityId != null) {
          context.push('/inventory/detail/$entityId');
        } else {
          context.push('/shopping');
        }
      },
    );

    try {
      // Ensure token is registered first
      String? token = NotificationService.instance.fcmToken;
      if (token == null || token.isEmpty) {
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
      }
      if (token != null && token.isNotEmpty) {
        await ref.read(notificationRepositoryProvider).registerDeviceToken(
          token: token,
          platform: 'ANDROID',
        );
      }

      final result = await ref.read(notificationRepositoryProvider).sendTestNotification(
        title: title,
        message: body,
        type: type,
        entityId: entityId,
      );
      if (!mounted) return;
      final tokensCount = result?['tokensCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tokensCount > 0
                      ? 'Test push sent to $tokensCount device(s)! Banner displayed.'
                      : 'Test alert triggered with foreground card preview!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'In-app notification card shown. (Backend notice: $e)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingPush = false);
    }
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
