/// Whether every term in [query] turns up somewhere in [fields].
///
/// Terms are matched one at a time and across the whole of [fields] rather
/// than within a single one, so "rabies certificate" finds a document titled
/// "Rabies booster" whose type is a vaccination certificate -- no one field
/// holds the whole phrase. An archive gets searched by what its owner
/// remembers about a record, and what they remember is rarely all in one
/// column.
///
/// Matching is case-insensitive and on substrings, so "vacc" finds
/// "Vaccination" and a half-typed query narrows as it is typed.
///
/// A blank query matches everything. That lets a screen hand its search box
/// straight through without special-casing the empty case, which is also the
/// case it spends most of its life in.
bool matchesSearchQuery(String query, Iterable<String?> fields) {
  final terms = searchTerms(query);
  if (terms.isEmpty) return true;

  final haystack = fields
      .whereType<String>()
      .map(_normalize)
      .where((field) => field.isNotEmpty)
      .toList(growable: false);

  return terms.every((term) => haystack.any((field) => field.contains(term)));
}

/// The terms [query] breaks down into, normalised for matching.
///
/// Exposed so a caller that already holds the terms can avoid splitting the
/// same query once per row.
List<String> searchTerms(String query) => _normalize(query)
    .split(_whitespace)
    .where((term) => term.isNotEmpty)
    .toList(growable: false);

/// Lower-cases [value] and splits camelCase into separate words.
///
/// The split is what makes an enum searchable. Document and event types reach
/// here as their Dart names -- `vaccinationCertificate`, `vetVisit` -- and
/// without it a search for "vaccination certificate" would miss exactly the
/// documents it names, while "vet visit" would match nothing at all. Going
/// through the name rather than the screen's label also keeps this out of the
/// presentation layer, where those labels live.
String _normalize(String value) => value
    .replaceAllMapped(_camelBoundary, (match) => '${match[1]} ${match[2]}')
    .toLowerCase();

final _camelBoundary = RegExp(r'([a-z0-9])([A-Z])');
final _whitespace = RegExp(r'\s+');
