library;

/// Dedicated High-Fidelity SVG Icon Vectors & Strings for HomeStock Dashboard
/// Clean, resolution-independent vectors for Crowns, Categories, Cards, and Greetings.

class DashboardSvgIcons {
  // ──── GREETING & HELLO ICONS ────

  /// Animated Waving Hand ("Say Hello") — High-Fidelity Golden Vector with Natural Palm & Fingers
  static const String wavingHand = '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="waveGold" x1="4" y1="4" x2="32" y2="34" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FFE082"/>
      <stop offset="35%" stop-color="#FFCA28"/>
      <stop offset="75%" stop-color="#FFA000"/>
      <stop offset="100%" stop-color="#E65100"/>
    </linearGradient>
    <linearGradient id="fingerHi" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFF9C4"/>
      <stop offset="100%" stop-color="#FFD54F"/>
    </linearGradient>
  </defs>
  <!-- Cheerful Motion Wind Breeze Lines -->
  <path d="M28.5 5C32.5 8.5 34.5 13.5 33.8 18" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" stroke-dasharray="1 3"/>
  <path d="M31.5 9.5C34.5 12.5 35.5 16.5 35 20.5" stroke="#FBBF24" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Smooth Organic Waving Hand (Fanned fingers + Natural thumb + Rounded palm) -->
  <path d="M12.5 32C14.5 33.5 18 34 21 33C25.5 31.5 28.5 27 28.5 21.5V15C28.5 13.6 27.4 12.5 26 12.5C24.6 12.5 23.5 13.6 23.5 15V11C23.5 9.6 22.4 8.5 21 8.5C19.6 8.5 18.5 9.6 18.5 11V7.5C18.5 6.1 17.4 5 16 5C14.6 5 13.5 6.1 13.5 7.5V11.5C13.5 10.1 12.4 9 11 9C9.6 9 8.5 10.1 8.5 11.5V20.5C6.5 18.5 4.8 18 3.8 19.2C2.5 20.8 3.8 23.5 6.5 25.8L12.5 32Z" fill="url(#waveGold)" stroke="#FFA000" stroke-width="0.8" stroke-linejoin="round"/>
  <!-- Finger Tips Highlight Glow -->
  <circle cx="11" cy="11.5" r="1.5" fill="url(#fingerHi)"/>
  <circle cx="16" cy="7.5" r="1.5" fill="url(#fingerHi)"/>
  <circle cx="21" cy="11" r="1.5" fill="url(#fingerHi)"/>
  <circle cx="26" cy="15" r="1.5" fill="url(#fingerHi)"/>
  <!-- Finger Separation Creases -->
  <line x1="13.5" y1="13" x2="13.5" y2="19" stroke="#BF360C" stroke-width="0.9" stroke-linecap="round" opacity="0.3"/>
  <line x1="18.5" y1="12" x2="18.5" y2="19" stroke="#BF360C" stroke-width="0.9" stroke-linecap="round" opacity="0.3"/>
  <line x1="23.5" y1="14" x2="23.5" y2="20" stroke="#BF360C" stroke-width="0.9" stroke-linecap="round" opacity="0.3"/>
  <!-- Curved Palm Crease -->
  <path d="M10 21C12.5 23.5 15.5 25.5 19.5 26.5" stroke="#FFE082" stroke-width="1.3" stroke-linecap="round" opacity="0.6"/>
</svg>
''';

  /// Sun Morning SVG
  static const String sunMorning = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="5" fill="#F59E0B"/>
  <path d="M12 2V4M12 20V22M4 12H2M22 12H20M5 5L6.5 6.5M17.5 17.5L19 19M5 19L6.5 17.5M17.5 6.5L19 5" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  /// Sun Afternoon SVG
  static const String sunAfternoon = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="6" fill="#EA580C"/>
  <circle cx="12" cy="12" r="4" fill="#FBBF24"/>
  <path d="M12 1V3.5M12 20.5V23M3.5 12H1M23 12H20.5M4.5 4.5L6.5 6.5M17.5 17.5L19.5 19.5M4.5 19.5L6.5 17.5M17.5 6.5L19.5 4.5" stroke="#EA580C" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

  /// Moon Evening SVG
  static const String moonEvening = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z" fill="#6366F1" stroke="#818CF8" stroke-width="1.5"/>
  <circle cx="17" cy="8" r="1" fill="#FDE047"/>
  <circle cx="19" cy="12" r="0.8" fill="#FDE047"/>
</svg>
''';

  /// Home Cottage Location SVG
  static const String homeCottage = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 10.5L12 3L21 10.5V20C21 20.5523 20.5523 21 20 21H4C3.44772 21 3 20.5523 3 20V10.5Z" fill="#EEF2FF" stroke="#4F46E5" stroke-width="2"/>
  <rect x="9.5" y="13.5" width="5" height="7.5" rx="1" fill="#6366F1"/>
  <circle cx="10.5" cy="7" r="1.5" fill="#FBBF24"/>
</svg>
''';

  // ──── PROGRESS CROWNS (GAMIFIED TIERS) ────

  /// 1. King Gold Royal Crown (Health >= 85%)
  static const String kingCrown = '''
<svg viewBox="0 0 36 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="goldGrad" x1="0" y1="0" x2="36" y2="28" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FDE047"/>
      <stop offset="40%" stop-color="#EAB308"/>
      <stop offset="100%" stop-color="#CA8A04"/>
    </linearGradient>
    <linearGradient id="baseGrad" x1="4" y1="22" x2="32" y2="26" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#EAB308"/>
      <stop offset="100%" stop-color="#A16207"/>
    </linearGradient>
  </defs>
  <!-- Crown Base Band -->
  <rect x="4" y="21" width="28" height="5" rx="2.5" fill="url(#baseGrad)" stroke="#FEF08A" stroke-width="0.8"/>
  <circle cx="10" cy="23.5" r="1.3" fill="#EF4444"/>
  <circle cx="18" cy="23.5" r="1.5" fill="#3B82F6"/>
  <circle cx="26" cy="23.5" r="1.3" fill="#10B981"/>
  <!-- Crown Body with 5 Royal Peaks -->
  <path d="M5 21L7 9L13 15L18 4L23 15L29 9L31 21H5Z" fill="url(#goldGrad)" stroke="#FEF08A" stroke-width="0.8" stroke-linejoin="round"/>
  <!-- Jewels on Peaks -->
  <circle cx="7" cy="8" r="2.2" fill="#EF4444" stroke="#FFFFFF" stroke-width="0.8"/>
  <circle cx="13" cy="14" r="1.8" fill="#10B981" stroke="#FFFFFF" stroke-width="0.6"/>
  <!-- Center Jewel (Diamond/Ruby) -->
  <circle cx="18" cy="3.5" r="3" fill="#EF4444" stroke="#FEF08A" stroke-width="1"/>
  <circle cx="18" cy="3.5" r="1.2" fill="#FFFFFF"/>
  <circle cx="23" cy="14" r="1.8" fill="#10B981" stroke="#FFFFFF" stroke-width="0.6"/>
  <circle cx="29" cy="8" r="2.2" fill="#3B82F6" stroke="#FFFFFF" stroke-width="0.8"/>
  <!-- Sparkles -->
  <path d="M18 10L18.8 12.2L21 13L18.8 13.8L18 16L17.2 13.8L15 13L17.2 12.2L18 10Z" fill="#FFFFFF" opacity="0.9"/>
</svg>
''';

  /// 2. Master Silver/Emerald Crown (Health 65% - 84%)
  static const String masterCrown = '''
<svg viewBox="0 0 34 26" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="silverGrad" x1="0" y1="0" x2="34" y2="26" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#F1F5F9"/>
      <stop offset="50%" stop-color="#CBD5E1"/>
      <stop offset="100%" stop-color="#94A3B8"/>
    </linearGradient>
  </defs>
  <rect x="5" y="19" width="24" height="4.5" rx="2" fill="#94A3B8" stroke="#E2E8F0" stroke-width="0.7"/>
  <circle cx="17" cy="21.2" r="1.4" fill="#10B981"/>
  <circle cx="11" cy="21.2" r="1" fill="#38BDF8"/>
  <circle cx="23" cy="21.2" r="1" fill="#38BDF8"/>
  <path d="M6 19L8 10L13 14L17 6L21 14L26 10L28 19H6Z" fill="url(#silverGrad)" stroke="#F8FAFC" stroke-width="0.8"/>
  <circle cx="8" cy="9.5" r="1.8" fill="#38BDF8" stroke="#FFFFFF" stroke-width="0.5"/>
  <circle cx="17" cy="5.5" r="2.4" fill="#10B981" stroke="#FFFFFF" stroke-width="0.8"/>
  <circle cx="26" cy="9.5" r="1.8" fill="#38BDF8" stroke="#FFFFFF" stroke-width="0.5"/>
</svg>
''';

  /// 3. Normal Bronze / Starting Crown (Health < 65%)
  static const String normalCrown = '''
<svg viewBox="0 0 32 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bronzeGrad" x1="0" y1="0" x2="32" y2="24" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FDBA74"/>
      <stop offset="50%" stop-color="#EA580C"/>
      <stop offset="100%" stop-color="#9A3412"/>
    </linearGradient>
  </defs>
  <rect x="6" y="18" width="20" height="4" rx="2" fill="#9A3412" stroke="#FED7AA" stroke-width="0.6"/>
  <path d="M7 18L9 11L13 14L16 8L19 14L23 11L25 18H7Z" fill="url(#bronzeGrad)" stroke="#FED7AA" stroke-width="0.8"/>
  <circle cx="9" cy="10.5" r="1.5" fill="#FED7AA"/>
  <circle cx="16" cy="7.5" r="2" fill="#FED7AA"/>
  <circle cx="23" cy="10.5" r="1.5" fill="#FED7AA"/>
</svg>
''';

  // ──── PROMO DUAL CARDS ICONS ────

  /// Shopping List Promo Card SVG
  static const String shoppingBagCard = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="shopGrad" x1="4" y1="4" x2="24" y2="26" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#8B5CF6"/>
      <stop offset="100%" stop-color="#6D28D9"/>
    </linearGradient>
  </defs>
  <!-- Bag Handle -->
  <path d="M10 9V7C10 4.79086 11.7909 3 14 3C16.2091 3 18 4.79086 18 7V9" stroke="#7C3AED" stroke-width="2.2" stroke-linecap="round"/>
  <!-- Bag Body -->
  <rect x="5" y="8" width="18" height="17" rx="4" fill="url(#shopGrad)"/>
  <!-- Front Fold Highlight -->
  <path d="M9 13C11 15 17 15 19 13" stroke="#DDD6FE" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Little Item Peek -->
  <circle cx="11.5" cy="18.5" r="1.5" fill="#FFFFFF" fill-opacity="0.8"/>
  <circle cx="16.5" cy="18.5" r="1.5" fill="#FFFFFF" fill-opacity="0.8"/>
</svg>
''';

  /// Pantry Stocked Promo Card SVG
  static const String pantryStockedCard = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="pantryGrad" x1="3" y1="3" x2="25" y2="25" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#6366F1"/>
      <stop offset="100%" stop-color="#4338CA"/>
    </linearGradient>
  </defs>
  <!-- Cupboard Outer Frame -->
  <rect x="4" y="3" width="20" height="22" rx="4" fill="url(#pantryGrad)" stroke="#C7D2FE" stroke-width="1.2"/>
  <!-- Middle Shelf Divider -->
  <line x1="4" y1="14" x2="24" y2="14" stroke="#A5B4FC" stroke-width="1.8"/>
  <!-- Top Shelf Items (Jars/Boxes) -->
  <rect x="7" y="6" width="4" height="6.5" rx="1" fill="#FDE047"/>
  <rect x="13" y="7.5" width="3.5" height="5" rx="1.5" fill="#34D399"/>
  <rect x="18.5" y="5.5" width="2.5" height="7" rx="0.8" fill="#F472B6"/>
  <!-- Bottom Shelf Items (Cans/Containers) -->
  <circle cx="9" cy="19.5" r="3" fill="#60A5FA"/>
  <rect x="14.5" y="17" width="5.5" height="5.5" rx="1.2" fill="#FBBF24"/>
  <!-- Sparkle of Freshness -->
  <circle cx="21.5" cy="6" r="1" fill="#FFFFFF"/>
</svg>
''';

  // ──── CATEGORIES MENUS SVGS ────

  /// "All" Category Grid SVG
  static const String catAll = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="4" width="8" height="8" rx="2.5" fill="#FFFFFF"/>
  <rect x="16" y="4" width="8" height="8" rx="2.5" fill="#FFFFFF" fill-opacity="0.85"/>
  <rect x="4" y="16" width="8" height="8" rx="2.5" fill="#FFFFFF" fill-opacity="0.85"/>
  <rect x="16" y="16" width="8" height="8" rx="2.5" fill="#FFFFFF"/>
</svg>
''';

  /// "Low Stock" Alert SVG
  static const String catLowStock = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 3L26 24H2L14 3Z" fill="#EF4444" stroke="#FFFFFF" stroke-width="1.5" stroke-linejoin="round"/>
  <line x1="14" y1="10" x2="14" y2="16" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="14" cy="20" r="1.3" fill="#FFFFFF"/>
</svg>
''';

  /// Fresh Produce (Veg & Fruits) SVG
  static const String catProduce = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Apple/Fruit Body -->
  <path d="M14 8C10 5 4 8 4 15C4 22 11 25 14 25C17 25 24 22 24 15C24 8 18 5 14 8Z" fill="#EF4444"/>
  <!-- Leaf -->
  <path d="M14 8C14 4 18 3 19 3C19 6 16 8 14 8Z" fill="#10B981"/>
  <!-- Stem -->
  <path d="M14 8V5" stroke="#78350F" stroke-width="1.8" stroke-linecap="round"/>
  <!-- Highlight -->
  <path d="M8 12C7 14 7 17 8 19" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" opacity="0.6"/>
</svg>
''';

  /// Dairy & Bakery SVG (Milk Bottle & Croissant)
  static const String catDairy = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Milk Bottle -->
  <rect x="9" y="8" width="10" height="17" rx="3" fill="#FFFFFF"/>
  <path d="M11 8V4H17V8" fill="#93C5FD"/>
  <rect x="10" y="3" width="8" height="2" rx="1" fill="#3B82F6"/>
  <!-- Milk Label Droplet -->
  <circle cx="14" cy="17" r="2.5" fill="#3B82F6"/>
  <path d="M14 13L15.8 16H12.2L14 13Z" fill="#3B82F6"/>
</svg>
''';

  /// Grains & Rice / Flours SVG
  static const String catGrains = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Bowl -->
  <path d="M4 14C4 20.5 8.5 24 14 24C19.5 24 24 20.5 24 14H4Z" fill="#F59E0B"/>
  <rect x="10" y="24" width="8" height="2" rx="1" fill="#D97706"/>
  <!-- Rice Pile -->
  <path d="M5 14C5 10 9 7 14 7C19 7 23 10 23 14H5Z" fill="#FEF3C7"/>
  <!-- Chopsticks / Steam -->
  <path d="M11 4C11 5.5 12 6 12 7" stroke="#FDE68A" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M16 3C16 4.5 17 5 17 6" stroke="#FDE68A" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  /// Oils & Ghee SVG
  static const String catOils = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Oil Canister / Bottle -->
  <rect x="7" y="9" width="14" height="16" rx="4" fill="#FBBF24"/>
  <path d="M11 9V5H17V9" fill="#D97706"/>
  <rect x="10" y="3.5" width="8" height="2" rx="1" fill="#B45309"/>
  <!-- Droplet on front -->
  <path d="M14 13C14 13 17 17 17 18.5C17 20.1569 15.6569 21.5 14 21.5C12.3431 21.5 11 20.1569 11 18.5C11 17 14 13 14 13Z" fill="#78350F"/>
</svg>
''';

  /// Spices & Masala SVG
  static const String catSpices = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Mortar Bowl -->
  <path d="M5 12C5 18 8.5 22 14 22C19.5 22 23 18 23 12H5Z" fill="#EA580C"/>
  <rect x="9" y="22" width="10" height="2.5" rx="1.2" fill="#C2410C"/>
  <!-- Pestle Stick -->
  <path d="M17 5L12 15" stroke="#FDBA74" stroke-width="3" stroke-linecap="round"/>
  <!-- Spice Sparkle -->
  <circle cx="8" cy="8" r="1.5" fill="#EF4444"/>
  <circle cx="21" cy="7" r="1.2" fill="#F59E0B"/>
</svg>
''';

  /// Snacks & Bakery SVG
  static const String catSnacks = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Choco Chip Cookie -->
  <circle cx="14" cy="14" r="10.5" fill="#D97706"/>
  <!-- Choco Chips -->
  <circle cx="10" cy="10" r="1.8" fill="#451A03"/>
  <circle cx="16" cy="9" r="1.5" fill="#451A03"/>
  <circle cx="12" cy="15" r="2" fill="#451A03"/>
  <circle cx="18" cy="14" r="1.6" fill="#451A03"/>
  <circle cx="15" cy="19" r="1.7" fill="#451A03"/>
</svg>
''';

  /// Beverages & Tea/Coffee SVG
  static const String catBeverages = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Mug Body -->
  <rect x="5" y="8" width="14" height="15" rx="3.5" fill="#3B82F6"/>
  <!-- Handle -->
  <path d="M19 11C21.5 11 23 12.5 23 15C23 17.5 21.5 19 19 19" stroke="#3B82F6" stroke-width="2.5" stroke-linecap="round"/>
  <!-- Hot Steam -->
  <path d="M8 4C8 5.5 9 6 9 7" stroke="#93C5FD" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M13 3C13 4.5 14 5 14 6" stroke="#93C5FD" stroke-width="1.6" stroke-linecap="round"/>
</svg>
''';

  /// Cleaning & Laundry SVG
  static const String catCleaning = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Spray Bottle -->
  <rect x="9" y="11" width="10" height="14" rx="3" fill="#0284C7"/>
  <!-- Trigger Neck -->
  <rect x="11.5" y="6.5" width="5" height="4.5" fill="#38BDF8"/>
  <path d="M12 6.5L7 9.5" stroke="#38BDF8" stroke-width="2" stroke-linecap="round"/>
  <!-- Sparkles -->
  <path d="M21 4L21.7 5.8L23.5 6.5L21.7 7.2L21 9L20.3 7.2L18.5 6.5L20.3 5.8L21 4Z" fill="#FDE047"/>
  <circle cx="23" cy="13" r="1.5" fill="#38BDF8"/>
</svg>
''';

  /// Personal Care & Bath SVG
  static const String catPersonal = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Lotus Petals / Spa Drops -->
  <path d="M14 6C14 6 8 13 8 17C8 20.3137 10.6863 23 14 23C17.3137 23 20 20.3137 20 17C20 13 14 6 14 6Z" fill="#EC4899"/>
  <circle cx="14" cy="18" r="3" fill="#FBCFE8"/>
  <circle cx="14" cy="11" r="1.5" fill="#FFFFFF"/>
</svg>
''';

  /// General / Pantry Shelves SVG
  static const String catGeneral = '''
<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Storage Container Box -->
  <rect x="4" y="6" width="20" height="17" rx="3.5" fill="#6366F1"/>
  <rect x="3" y="5" width="22" height="4" rx="1.5" fill="#4F46E5"/>
  <rect x="10" y="12" width="8" height="3" rx="1.5" fill="#C7D2FE"/>
</svg>
''';

  /// Helper to get Category SVG String based on name
  static String getCategorySvg(String catName) {
    final lower = catName.trim().toLowerCase();
    if (lower == 'all') return catAll;
    if (lower.contains('low stock') || lower.contains('out of stock')) return catLowStock;
    if (lower.contains('veg') || lower.contains('fruit') || lower.contains('produce')) return catProduce;
    if (lower.contains('milk') || lower.contains('dair') || lower.contains('egg') || lower.contains('bakery') || lower.contains('bread')) return catDairy;
    if (lower.contains('grain') || lower.contains('rice') || lower.contains('dal') || lower.contains('flour') || lower.contains('atta')) return catGrains;
    if (lower.contains('oil') || lower.contains('ghee')) return catOils;
    if (lower.contains('spice') || lower.contains('masala') || lower.contains('salt') || lower.contains('chilli')) return catSpices;
    if (lower.contains('snack') || lower.contains('biscuit') || lower.contains('sweet') || lower.contains('cookie')) return catSnacks;
    if (lower.contains('beverag') || lower.contains('tea') || lower.contains('coffee') || lower.contains('drink')) return catBeverages;
    if (lower.contains('clean') || lower.contains('wash') || lower.contains('detergent') || lower.contains('dish')) return catCleaning;
    if (lower.contains('person') || lower.contains('care') || lower.contains('bath') || lower.contains('beauty') || lower.contains('soap')) return catPersonal;
    return catGeneral;
  }
}

