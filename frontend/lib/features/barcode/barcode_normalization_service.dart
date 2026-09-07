import 'barcode_models.dart';

class BarcodeNormalizationService {
  static final RegExp _numericRegex = RegExp(r'^\d+$');
  static final RegExp _prefixRegex = RegExp(
    r'^(?:\][A-Za-z0-9]{2}|(?:EAN[-_]?13|EAN[-_]?8|UPC[-_]?A|UPC[-_]?E|CODE[-_]?128)[:\s]+)',
    caseSensitive: false,
  );

  /// Cleans raw scanned string of prefix artifacts, spaces, hyphens
  String normalizeBarcode(String raw) {
    var cleaned = raw.trim();
    cleaned = cleaned.replaceFirst(_prefixRegex, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\s\-_]+'), '').trim();
    return cleaned;
  }

  /// Detects barcode format type
  BarcodeFormatType detectBarcodeType(String barcode) {
    if (barcode.isEmpty) return BarcodeFormatType.unknown;

    if (!_numericRegex.hasMatch(barcode)) {
      if (barcode.startsWith('http://') || barcode.startsWith('https://') || barcode.length > 30) {
        return BarcodeFormatType.qrCode;
      }
      return BarcodeFormatType.code128;
    }

    switch (barcode.length) {
      case 8:
        return BarcodeFormatType.ean8;
      case 12:
        return BarcodeFormatType.upcA;
      case 13:
        return BarcodeFormatType.ean13;
      case 14:
        return BarcodeFormatType.itf;
      case 6:
      case 7:
        return BarcodeFormatType.upcE;
      default:
        return BarcodeFormatType.code128;
    }
  }

  /// Validates barcode length and standard check digits where applicable
  bool isValidBarcode(String raw) {
    final barcode = normalizeBarcode(raw);
    if (barcode.length < 3 || barcode.length > 50) return false;

    final type = detectBarcodeType(barcode);
    switch (type) {
      case BarcodeFormatType.ean13:
        return validateEan13Checksum(barcode);
      case BarcodeFormatType.ean8:
        return validateEan8Checksum(barcode);
      case BarcodeFormatType.upcA:
        return validateUpcAChecksum(barcode);
      default:
        return true;
    }
  }

  bool validateEan13Checksum(String barcode) {
    if (barcode.length != 13 || !_numericRegex.hasMatch(barcode)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    final check = (10 - (sum % 10)) % 10;
    return check == int.parse(barcode[12]);
  }

  bool validateEan8Checksum(String barcode) {
    if (barcode.length != 8 || !_numericRegex.hasMatch(barcode)) return false;
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      final digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    final check = (10 - (sum % 10)) % 10;
    return check == int.parse(barcode[7]);
  }

  bool validateUpcAChecksum(String barcode) {
    if (barcode.length != 12 || !_numericRegex.hasMatch(barcode)) return false;
    var sum = 0;
    for (var i = 0; i < 11; i++) {
      final digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    final check = (10 - (sum % 10)) % 10;
    return check == int.parse(barcode[11]);
  }
}
