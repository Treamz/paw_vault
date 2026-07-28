import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/utils/parse_decimal.dart';

void main() {
  group('parseDecimal', () {
    test('parses dot decimals', () {
      expect(parseDecimal('12.7'), 12.7);
    });

    test('parses comma decimals', () {
      expect(parseDecimal('12,7'), 12.7);
    });

    test('parses integers and trims whitespace', () {
      expect(parseDecimal(' 5 '), 5);
    });

    test('returns null for invalid or empty input', () {
      expect(parseDecimal(''), isNull);
      expect(parseDecimal('abc'), isNull);
      expect(parseDecimal(null), isNull);
    });
  });
}
