import 'quantity_parser.dart';
import 'unit_parser.dart';

/// Container for extracted entities
class ExtractedEntities {
  final double? quantity;
  final double quantityConfidence;
  final String? unit;
  final double unitConfidence;
  final String? brand;
  final double? price;
  final String productQuery;

  const ExtractedEntities({
    this.quantity,
    this.quantityConfidence = 1.0,
    this.unit,
    this.unitConfidence = 1.0,
    this.brand,
    this.price,
    required this.productQuery,
  });
}

/// Extracts quantity, unit, brand, price, and clean product query from text
class EntityExtractor {
  static const List<String> _knownBrands = [
    'Aashirvaad', 'India Gate', 'Fortune', 'Tata', 'Gold Winner',
    'Amul', 'Nandini', 'Heritage', 'Sunfeast', 'Britannia', 'Parle',
    'Aavin', 'Idhayam', 'Dawat', 'Patanjali', 'Everest', 'MDH',
  ];

  static ExtractedEntities extract(String text) {
    if (text.trim().isEmpty) {
      return const ExtractedEntities(productQuery: '');
    }

    // 1. Extract Price (e.g. "50 rupees", "rs 100", "₹ 200", "50 rooba", "ரூபாய் 50")
    double? price;
    String cleanForProcessing = text;
    final priceRegex = RegExp(
      r'(?:rs\.?|rupees?|rooba|ரூபாய்|₹)\s*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:rs\.?|rupees?|rooba|ரூபாய்|₹)',
      caseSensitive: false,
    );
    final priceMatch = priceRegex.firstMatch(cleanForProcessing);
    if (priceMatch != null) {
      final pStr = priceMatch.group(1) ?? priceMatch.group(2);
      if (pStr != null) {
        price = double.tryParse(pStr);
      }
      cleanForProcessing = cleanForProcessing.replaceRange(priceMatch.start, priceMatch.end, ' ');
    }

    // 2. Extract Brand
    String? brand;
    for (final b in _knownBrands) {
      final pattern = RegExp('\\b${RegExp.escape(b)}\\b', caseSensitive: false);
      if (pattern.hasMatch(cleanForProcessing)) {
        brand = b;
        cleanForProcessing = cleanForProcessing.replaceAll(pattern, ' ');
        break;
      }
    }

    // 3. Extract Quantity
    final qtyResult = QuantityParser.parse(cleanForProcessing);
    final double? quantity = qtyResult.quantity;
    final double qtyConf = qtyResult.confidence;
    final textWithoutQty = qtyResult.textWithoutQuantity;

    // 4. Extract Unit
    final unitResult = UnitParser.parse(textWithoutQty);
    final String? unit = unitResult.unit;
    final double unitConf = unitResult.confidence;
    final textWithoutUnit = unitResult.textWithoutUnit;

    // 5. Clean remaining string into Product Query
    String productCandidate = textWithoutUnit;

    // Remove common voice command stopwords, target indicators, and conversational padding
    productCandidate = productCandidate.replaceAll(
      RegExp(
        r'\b(?:add|put|buy|remove|delete|used|consumed|stock|inventory|in|out|quantity|shopping|list|la|le|ula|ku|ukku|lerundhu|irundhu|podu|podunga|pannu|pannunga|panu|irukku|irukka|theendhuduchu|vaanganum|vaangu|venum|eduthachu|bought|update|set|mathu|to|from|for|me|please|show|find|search|cheapest|price|where|enga|veetla|veetil|kaatu|solla|சேர்க்கவும்|போடு|நீக்கு|காட்டு)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    // Clean punctuation and excess whitespace
    productCandidate = productCandidate.replaceAll(RegExp(r'[,;.!?\-_]'), ' ');
    productCandidate = productCandidate.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ExtractedEntities(
      quantity: quantity,
      quantityConfidence: qtyConf,
      unit: unit,
      unitConfidence: unitConf,
      brand: brand,
      price: price,
      productQuery: productCandidate,
    );
  }
}
