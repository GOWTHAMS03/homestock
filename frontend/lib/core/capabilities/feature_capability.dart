import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bill/screens/bill_scanner_screen.dart';
import '../../features/inventory/add_edit_item_screen.dart';
import '../../features/smart_shopping/nearby_grocery_shops_screen.dart';
import '../../features/smart_shopping/product_deal_search_screen.dart';
import '../../features/voice/widgets/voice_command_sheet.dart';

/// All capabilities of the HomeStock application.
/// Strictly drives UI rendering: if a capability cannot work,
/// it must NEVER be displayed on screen.
enum FeatureCapability {
  // ── Offline Supported Capabilities ──
  /// View and manage kitchen and pantry inventory items locally.
  inventory,

  /// View, check off, and manage shopping list items offline.
  shoppingList,

  /// View recorded past purchases, spending, and local stock history.
  history,

  /// View expiry alerts, low stock warnings, and attention reminders.
  reminders,

  /// Manually create or edit items in the inventory.
  manualAddEdit,

  // ── Online-Only Capabilities ──
  /// Homie AI Voice commands (requires online speech & intent backend).
  voice,

  /// Grocery bill receipt scanning & OCR item extraction.
  billScan,

  /// Smart deal comparison and lowest price discovery across stores.
  deals,

  /// Nearby grocery shop discovery via OpenStreetMap & Overpass.
  nearbyShops,

  /// Live multi-store search & real market lookup.
  onlineSearch,

  /// Cloud data synchronization with Spring Boot backend.
  sync;

  /// Whether this capability works 100% offline using local SQLite / heuristics.
  bool get isOfflineSupported {
    switch (this) {
      case FeatureCapability.inventory:
      case FeatureCapability.shoppingList:
      case FeatureCapability.history:
      case FeatureCapability.reminders:
      case FeatureCapability.manualAddEdit:
        return true;
      case FeatureCapability.voice:
      case FeatureCapability.billScan:
      case FeatureCapability.deals:
      case FeatureCapability.nearbyShops:
      case FeatureCapability.onlineSearch:
      case FeatureCapability.sync:
        return false;
    }
  }

  /// The backend service identifier associated with this capability (if any).
  String? get requiredServiceKey {
    switch (this) {
      case FeatureCapability.voice:
        return 'voice';
      case FeatureCapability.billScan:
        return 'ocr';
      case FeatureCapability.deals:
        return 'deals';
      case FeatureCapability.nearbyShops:
        return 'nearby';
      case FeatureCapability.onlineSearch:
        return 'search';
      case FeatureCapability.sync:
        return 'sync';
      default:
        return null;
    }
  }
}

/// Rich metadata descriptor for a capability, used for rendering
/// capability-aware cards, pills, and action items.
class CapabilityDescriptor {
  final FeatureCapability capability;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final void Function(BuildContext context, WidgetRef ref) onAction;

  const CapabilityDescriptor({
    required this.capability,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onAction,
  });

  /// Standard descriptor definitions for all application capabilities.
  static final Map<FeatureCapability, CapabilityDescriptor> descriptors = {
    FeatureCapability.voice: CapabilityDescriptor(
      capability: FeatureCapability.voice,
      title: 'Homie Voice',
      subtitle: 'Instant AI voice assistant',
      icon: Icons.mic_rounded,
      primaryColor: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFFEEF2FF),
      borderColor: const Color(0xFFC7D2FE),
      onAction: (context, ref) => VoiceCommandSheet.show(context),
    ),
    FeatureCapability.billScan: CapabilityDescriptor(
      capability: FeatureCapability.billScan,
      title: 'Bill Scan',
      subtitle: 'Extract receipts via OCR',
      icon: Icons.document_scanner_rounded,
      primaryColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      onAction: (context, ref) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BillScannerScreen()),
        );
      },
    ),
    FeatureCapability.deals: CapabilityDescriptor(
      capability: FeatureCapability.deals,
      title: 'Smart Deals',
      subtitle: 'Compare store prices & save',
      icon: Icons.local_offer_rounded,
      primaryColor: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      onAction: (context, ref) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDealSearchScreen()),
        );
      },
    ),
    FeatureCapability.nearbyShops: CapabilityDescriptor(
      capability: FeatureCapability.nearbyShops,
      title: 'Nearby Shops',
      subtitle: 'Local grocery discovery',
      icon: Icons.storefront_rounded,
      primaryColor: const Color(0xFF0EA5E9),
      backgroundColor: const Color(0xFFF0F9FF),
      borderColor: const Color(0xFFBAE6FD),
      onAction: (context, ref) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NearbyGroceryShopsScreen()),
        );
      },
    ),
    FeatureCapability.onlineSearch: CapabilityDescriptor(
      capability: FeatureCapability.onlineSearch,
      title: 'Online Search',
      subtitle: 'Find items across markets',
      icon: Icons.travel_explore_rounded,
      primaryColor: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFDDD6FE),
      onAction: (context, ref) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDealSearchScreen()),
        );
      },
    ),
    FeatureCapability.inventory: CapabilityDescriptor(
      capability: FeatureCapability.inventory,
      title: 'Pantry Inventory',
      subtitle: 'Manage food & stock levels',
      icon: Icons.inventory_2_rounded,
      primaryColor: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFFEEF2FF),
      borderColor: const Color(0xFFC7D2FE),
      onAction: (context, ref) => context.go('/inventory'),
    ),
    FeatureCapability.shoppingList: CapabilityDescriptor(
      capability: FeatureCapability.shoppingList,
      title: 'Shopping List',
      subtitle: 'Pending household staples',
      icon: Icons.shopping_bag_rounded,
      primaryColor: const Color(0xFF059669),
      backgroundColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      onAction: (context, ref) => context.go('/shopping'),
    ),
    FeatureCapability.history: CapabilityDescriptor(
      capability: FeatureCapability.history,
      title: 'Purchase History',
      subtitle: 'Logged receipts & bills',
      icon: Icons.receipt_long_rounded,
      primaryColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF0F9FF),
      borderColor: const Color(0xFFBAE6FD),
      onAction: (context, ref) => context.push('/analytics/expenses'),
    ),
    FeatureCapability.reminders: CapabilityDescriptor(
      capability: FeatureCapability.reminders,
      title: 'Expiry Alerts',
      subtitle: 'Attention & shelf-life items',
      icon: Icons.access_time_filled_rounded,
      primaryColor: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFEF9C3),
      borderColor: const Color(0xFFFEF08A),
      onAction: (context, ref) => context.push('/attention'),
    ),
    FeatureCapability.manualAddEdit: CapabilityDescriptor(
      capability: FeatureCapability.manualAddEdit,
      title: 'Manual Add',
      subtitle: 'Add new pantry item directly',
      icon: Icons.edit_note_rounded,
      primaryColor: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFFFAF5FF),
      borderColor: const Color(0xFFE9D5FF),
      onAction: (context, ref) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
        );
      },
    ),
    FeatureCapability.sync: CapabilityDescriptor(
      capability: FeatureCapability.sync,
      title: 'Cloud Sync',
      subtitle: 'Real-time multi-device sync',
      icon: Icons.sync_rounded,
      primaryColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      onAction: (context, ref) {},
    ),
  };
}
