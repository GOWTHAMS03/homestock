import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive in-app notification banner matching the signature HomeStock project theme:
/// - Rounded 20 container with soft multi-layer shadow and subtle semantic border
/// - 44x44 pastel squircle icon container
/// - Semantic pill badges (LOW STOCK, EXPIRING SOON, SHOPPING, RESTOCKED)
/// - Bold typography with high contrast
/// - Direct action buttons (+ Add to Shopping, Inspect Item, View Details)
/// - Slide-down spring animation, swipe-up dismiss, and auto-dismiss timer
class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final String? entityId;
  final Map<String, dynamic>? payload;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final VoidCallback onDismiss;
  final String? actionLabel;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    this.type = 'SYSTEM',
    this.entityId,
    this.payload,
    this.onTap,
    this.onActionTap,
    required this.onDismiss,
    this.actionLabel,
  });

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Show a global in-app notification banner on top of the app window
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    String type = 'SYSTEM',
    String? entityId,
    Map<String, dynamic>? payload,
    VoidCallback? onTap,
    VoidCallback? onActionTap,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    dismiss();

    final overlayState = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => InAppNotificationBanner(
        title: title,
        body: body,
        type: type,
        entityId: entityId,
        payload: payload,
        actionLabel: actionLabel,
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onActionTap: () {
          dismiss();
          onActionTap?.call();
        },
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Dismiss the active in-app banner if one is showing
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final styling = _getBannerStyling(widget.type, widget.title);

    return Positioned(
      top: topPadding + 8 + _dragOffsetY,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < 0) {
                setState(() {
                  _dragOffsetY += details.primaryDelta!;
                });
              }
            },
            onVerticalDragEnd: (details) {
              if (_dragOffsetY < -20 ||
                  (details.primaryVelocity != null && details.primaryVelocity! < -200)) {
                _handleDismiss();
              } else {
                setState(() => _dragOffsetY = 0.0);
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: styling.borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: styling.accentColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _handleDismiss().then((_) => widget.onTap?.call());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Icon squircle + Title & Badges + Close button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 44x44 Squircle Container
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: styling.bgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: styling.isEmoji
                                    ? Text(styling.emojiText, style: const TextStyle(fontSize: 22))
                                    : Icon(styling.icon, size: 22, color: styling.iconColor),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge Pill + Timestamp
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: styling.badgeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          styling.badgeText,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: styling.badgeTextColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Just now',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Title
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Close / Dismiss button
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _handleDismiss();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Body text
                        Padding(
                          padding: const EdgeInsets.only(left: 56, top: 4, right: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Quick Action Buttons
                        if (styling.actionLabel != null || widget.actionLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, left: 56),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    _handleDismiss().then((_) {
                                      widget.onActionTap?.call();
                                      widget.onTap?.call();
                                    });
                                  },
                                  icon: Icon(styling.actionIcon, size: 14),
                                  label: Text(
                                    widget.actionLabel ?? styling.actionLabel!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: styling.accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to open >',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: styling.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _InAppBannerStyling _getBannerStyling(String type, String title) {
    final lowerTitle = title.toLowerCase();
    String emoji = '🥛';
    if (lowerTitle.contains('egg')) {
      emoji = '🥚';
    } else if (lowerTitle.contains('onion')) {
      emoji = '🧅';
    } else if (lowerTitle.contains('rice')) {
      emoji = '🍚';
    } else if (lowerTitle.contains('cheese')) {
      emoji = '🧀';
    } else if (lowerTitle.contains('bread')) {
      emoji = '🍞';
    }

    final hasFoodEmoji = lowerTitle.contains('milk') ||
        lowerTitle.contains('egg') ||
        lowerTitle.contains('onion') ||
        lowerTitle.contains('rice') ||
        lowerTitle.contains('cheese') ||
        lowerTitle.contains('bread');

    switch (type.toUpperCase()) {
      case 'OUT_OF_STOCK':
        return _InAppBannerStyling(
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          badgeText: '🔴 OUT OF STOCK',
          badgeBg: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFB91C1C),
          accentColor: const Color(0xFFDC2626),
          actionLabel: '+ Add to Shopping',
          actionIcon: Icons.add_shopping_cart_rounded,
          isEmoji: hasFoodEmoji,
          emojiText: emoji,
        );
      case 'LOW_STOCK':
        return _InAppBannerStyling(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF9C3),
          borderColor: const Color(0xFFFDE68A),
          badgeText: '⚠️ LOW STOCK',
          badgeBg: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFB45309),
          accentColor: const Color(0xFF6366F1),
          actionLabel: '+ Add to Shopping',
          actionIcon: Icons.add_shopping_cart_rounded,
          isEmoji: hasFoodEmoji,
          emojiText: emoji,
        );
      case 'EXPIRY_REMINDER':
      case 'EXPIRING_SOON':
        return _InAppBannerStyling(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: const Color(0xFFEA580C),
          bgColor: const Color(0xFFFFEDD5),
          borderColor: const Color(0xFFFED7AA),
          badgeText: '⏳ EXPIRING SOON',
          badgeBg: const Color(0xFFFFEDD5),
          badgeTextColor: const Color(0xFFC2410C),
          accentColor: const Color(0xFFF59E0B),
          actionLabel: 'Inspect Item',
          actionIcon: Icons.visibility_outlined,
          isEmoji: hasFoodEmoji,
          emojiText: emoji,
        );
      case 'EXPIRED':
        return _InAppBannerStyling(
          icon: Icons.timer_off_outlined,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          badgeText: '⏰ EXPIRED',
          badgeBg: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFB91C1C),
          accentColor: const Color(0xFFDC2626),
          actionLabel: 'Inspect Item',
          actionIcon: Icons.visibility_outlined,
          isEmoji: hasFoodEmoji,
          emojiText: emoji,
        );
      case 'SHOPPING_LIST_UPDATE':
        return _InAppBannerStyling(
          icon: Icons.shopping_bag_outlined,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF3E8FF),
          borderColor: const Color(0xFFDDD6FE),
          badgeText: '🛒 SHOPPING LIST',
          badgeBg: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF6D28D9),
          accentColor: const Color(0xFF6366F1),
          actionLabel: 'View Shopping List',
          actionIcon: Icons.shopping_bag_outlined,
        );
      case 'STOCK_UPDATED':
      case 'PURCHASE_RECORDED':
        return _InAppBannerStyling(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
          borderColor: const Color(0xFFBBF7D0),
          badgeText: '✓ RESTOCKED',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF15803D),
          accentColor: const Color(0xFF16A34A),
          actionLabel: 'View Item',
          actionIcon: Icons.inventory_2_outlined,
        );
      case 'SMART_RESTOCK_SUGGESTION':
      case 'WEEKLY_INSIGHT':
      case 'MONTHLY_REPORT':
        return _InAppBannerStyling(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF6D28D9),
          bgColor: const Color(0xFFEDE9FE),
          borderColor: const Color(0xFFDDD6FE),
          badgeText: '✨ SMART INSIGHT',
          badgeBg: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF5B21B6),
          accentColor: const Color(0xFF6366F1),
          actionLabel: 'View Insights',
          actionIcon: Icons.insights_rounded,
        );
      case 'SYNC_COMPLETED':
        return _InAppBannerStyling(
          icon: Icons.cloud_done_outlined,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
          borderColor: const Color(0xFFBBF7D0),
          badgeText: '☁️ SYNCED',
          badgeBg: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF15803D),
          accentColor: const Color(0xFF16A34A),
        );
      case 'FAMILY_ACTIVITY':
      default:
        return _InAppBannerStyling(
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFE0F2FE),
          borderColor: const Color(0xFFBAE6FD),
          badgeText: '🏠 HOUSEHOLD',
          badgeBg: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF0369A1),
          accentColor: const Color(0xFF6366F1),
          actionLabel: 'View Notification',
          actionIcon: Icons.arrow_forward_rounded,
        );
    }
  }
}

class _InAppBannerStyling {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String badgeText;
  final Color badgeBg;
  final Color badgeTextColor;
  final Color accentColor;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool isEmoji;
  final String emojiText;

  _InAppBannerStyling({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.accentColor,
    this.actionLabel,
    this.actionIcon,
    this.isEmoji = false,
    this.emojiText = '🥛',
  });
}
