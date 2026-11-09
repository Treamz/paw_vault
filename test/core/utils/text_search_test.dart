import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/utils/text_search.dart';

void main() {
  group('matchesSearchQuery', () {
    test('a blank query matches anything', () {
      expect(matchesSearchQuery('', ['Rabies booster']), isTrue);
      expect(matchesSearchQuery('   ', ['Rabies booster']), isTrue);
    });

    test('matches a substring regardless of case', () {
      expect(matchesSearchQuery('rab', ['Rabies booster']), isTrue);
      expect(matchesSearchQuery('BOOST', ['Rabies booster']), isTrue);
    });

    test('every term has to match, and may match a different field', () {
      const fields = ['Rabies booster', 'vaccinationCertificate'];

      expect(matchesSearchQuery('rabies certificate', fields), isTrue);
      expect(matchesSearchQuery('rabies insurance', fields), isFalse);
    });

    test('splits camelCase so an enum name reads as words', () {
      expect(matchesSearchQuery('vet visit', ['vetVisit']), isTrue);
      expect(matchesSearchQuery('visit', ['vetVisit']), isTrue);
      expect(
        matchesSearchQuery('vaccination certificate', [
          'vaccinationCertificate',
        ]),
        isTrue,
      );
    });

    test('skips null fields instead of throwing on them', () {
      expect(matchesSearchQuery('rabies', [null, 'Rabies booster']), isTrue);
      expect(matchesSearchQuery('rabies', [null]), isFalse);
    });

    test('does not match on words that are not there', () {
      expect(matchesSearchQuery('surgery', ['Rabies booster']), isFalse);
    });
  });

  group('searchTerms', () {
    test('splits on any run of whitespace and lower-cases', () {
      expect(searchTerms('  Rabies   BOOSTER '), ['rabies', 'booster']);
    });

    test('is empty for a blank query, which is what makes it match all', () {
      expect(searchTerms('   '), isEmpty);
    });
  });
}
