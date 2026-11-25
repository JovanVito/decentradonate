import 'package:decentradonate/features/access/domain/email_otp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a trimmed address and rejects malformed addresses', () {
    expect(EmailOtp.validEmail(' donor@example.test '), isTrue);
    expect(EmailOtp.validEmail('donor @example.test'), isFalse);
    expect(EmailOtp.validEmail('donor@example'), isFalse);
    expect(EmailOtp.validEmail(null), isFalse);
  });

  test('requires exactly six ASCII digits, preserving leading zero', () {
    expect(EmailOtp.validCode('012345'), isTrue);
    for (final code in ['12345', '1234567', '12345a', '１２３４５６']) {
      expect(EmailOtp.validCode(code), isFalse, reason: code);
    }
  });
}
