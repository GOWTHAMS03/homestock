import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/auth/widgets/invite_qr_scanner_dialog.dart';

void main() {
  group('Invite & QR Code Extraction Tests', () {
    test('Extracts plain uppercase alphanumeric invite code', () {
      expect(InviteQrScannerDialog.extractInviteCode('7KQ9P4M2'), '7KQ9P4M2');
      expect(InviteQrScannerDialog.extractInviteCode('ABCDEF12'), 'ABCDEF12');
    });

    test('Trims and normalizes lowercase invite codes', () {
      expect(InviteQrScannerDialog.extractInviteCode('  7kq9p4m2  '), '7KQ9P4M2');
      expect(InviteQrScannerDialog.extractInviteCode('\nabc12345\t'), 'ABC12345');
    });

    test('Extracts code from URL query parameters', () {
      expect(
        InviteQrScannerDialog.extractInviteCode('https://homestock.app/join?code=7KQ9P4M2'),
        '7KQ9P4M2',
      );
      expect(
        InviteQrScannerDialog.extractInviteCode('http://192.168.1.100:8080/join?invite=XYZ98765'),
        'XYZ98765',
      );
    });

    test('Extracts code from URL path segments', () {
      expect(
        InviteQrScannerDialog.extractInviteCode('https://homestock.app/invite/7KQ9P4M2'),
        '7KQ9P4M2',
      );
      expect(
        InviteQrScannerDialog.extractInviteCode('homestock://join/ROOM1234'),
        'ROOM1234',
      );
    });

    test('Extracts code from JSON payload', () {
      expect(
        InviteQrScannerDialog.extractInviteCode('{"inviteCode":"7KQ9P4M2","homeName":"Main Home"}'),
        '7KQ9P4M2',
      );
      expect(
        InviteQrScannerDialog.extractInviteCode('{"code":"ABCD5678"}'),
        'ABCD5678',
      );
    });

    test('Extracts code from formatted human share message', () {
      const shareMsg = 'Join my household on HomeStock! Use invite code: 7KQ9P4M2 to enter.';
      expect(InviteQrScannerDialog.extractInviteCode(shareMsg), '7KQ9P4M2');
    });

    test('Returns null on invalid or empty codes', () {
      expect(InviteQrScannerDialog.extractInviteCode(''), isNull);
      expect(InviteQrScannerDialog.extractInviteCode('   '), isNull);
      expect(InviteQrScannerDialog.extractInviteCode('123'), isNull); // Too short
      expect(InviteQrScannerDialog.extractInviteCode('INVALID_TOO_LONG_STRING_WITHOUT_CODE_XYZ123456789'), isNull);
    });
  });
}
