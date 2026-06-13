import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:intl/intl.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// [VetSummaryPdfGenerator] backed by the `pdf` package.
///
/// Produces a vet-ready summary: profile, a clinical "health overview"
/// (allergies, chronic conditions, current medications, recent symptoms and
/// vaccinations derived from the timeline), the full health timeline with
/// descriptions, medium-length document overviews, and upcoming reminders.
class VetSummaryPdfBuilder implements VetSummaryPdfGenerator {
  /// [assetBundle] is injectable for tests; production uses [rootBundle].
  const VetSummaryPdfBuilder({AssetBundle? assetBundle})
      : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;

  static const _documentOverviewMaxChars = 320;
  static const _eventDescriptionMaxChars = 240;
  static const _muted = PdfColors.grey700;
  static const _regularFontAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const _boldFontAsset = 'assets/fonts/NotoSans-Bold.ttf';

  @override
  Future<Uint8List> build(VetSummaryData data) async {
    final dateFormat = DateFormat.yMMMd();
    final doc = pw.Document(theme: await _loadTheme());
    final overview = _healthOverviewSection(data, dateFormat);

    doc.addPage(
      pw.MultiPage(
        footer: _footer,
        build: (context) => [
          _title(data.pet),
          _profileSection(data.pet, dateFormat),
          if (overview != null) overview,
          if (data.events.isNotEmpty)
            _timelineSection(_eventsNewestFirst(data.events), dateFormat),
          if (data.documents.isNotEmpty)
            _documentsSection(data.documents, dateFormat),
          if (data.reminders.isNotEmpty)
            _remindersSection(data.reminders, dateFormat),
          if (!data.hasRecords)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text('No records have been added for this pet yet.'),
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Loads a Unicode-capable font (Noto Sans) so characters outside Latin-1
  /// (em dashes, smart quotes, accents, Greek/Cyrillic, etc.) render instead of
  /// being dropped. Falls back to the built-in Helvetica when the asset bundle
  /// is unavailable (e.g. plain unit tests).
  Future<pw.ThemeData?> _loadTheme() async {
    final bundle = _assetBundle ?? rootBundle;
    try {
      final base = pw.Font.ttf(await bundle.load(_regularFontAsset));
      final bold = pw.Font.ttf(await bundle.load(_boldFontAsset));
      return pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _title(Pet pet) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vet Summary - ${pet.name}',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Generated ${DateFormat.yMMMd().add_jm().format(DateTime.now())} '
            '- owner-entered records',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _profileSection(Pet pet, DateFormat dateFormat) {
    final birth = pet.birthDate;
    final lines = <String>[
      if (pet.species != null) 'Species: ${pet.species}',
      if (pet.breed != null) 'Breed: ${pet.breed}',
      if (pet.gender != null) 'Sex: ${_label(pet.gender!.name)}',
      if (birth != null)
        'Date of birth: ${_formatDate(birth, dateFormat)}${_ageSuffix(birth)}',
      if (pet.weight != null)
        'Weight: ${pet.weight!.value} ${pet.weight!.unit.name}',
      if (pet.microchipNumber != null) 'Microchip: ${pet.microchipNumber}',
    ];

    return _section('Profile', lines.isEmpty ? ['Name: ${pet.name}'] : lines);
  }

  /// Clinical snapshot the vet sees first: allergies, chronic conditions,
  /// current medications, recent symptoms and vaccinations. Returns null when
  /// there is nothing to show so the section is omitted entirely.
  pw.Widget? _healthOverviewSection(
    VetSummaryData data,
    DateFormat dateFormat,
  ) {
    final events = _eventsNewestFirst(data.events);

    final allergies = <String>{
      ...data.pet.allergies,
      ...events
          .where((e) => e.type == PetEventType.allergy)
          .map((e) => e.title),
    };
    final medications = _uniqueTitles(events, PetEventType.medication);
    final symptoms = events
        .where((e) => e.type == PetEventType.symptom)
        .take(5)
        .map((e) => '${e.title} (${_formatUtc(e.date, dateFormat)})')
        .toList();
    final vaccinations = events
        .where((e) => e.type == PetEventType.vaccination)
        .take(5)
        .map((e) => '${e.title} (${_formatUtc(e.date, dateFormat)})')
        .toList();
    final notes = data.pet.notes?.trim();

    final entries = <_OverviewEntry>[
      if (allergies.isNotEmpty)
        _OverviewEntry('Allergies', allergies.join(', ')),
      if (data.pet.chronicConditions.isNotEmpty)
        _OverviewEntry(
          'Chronic conditions',
          data.pet.chronicConditions.join(', '),
        ),
      if (medications.isNotEmpty)
        _OverviewEntry('Medications', medications.join(', ')),
      if (symptoms.isNotEmpty)
        _OverviewEntry('Recent symptoms', symptoms.join('; ')),
      if (vaccinations.isNotEmpty)
        _OverviewEntry('Vaccinations', vaccinations.join('; ')),
      if (notes != null && notes.isNotEmpty)
        _OverviewEntry('Owner notes', notes),
    ];

    if (entries.isEmpty) return null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Health overview'),
        for (final entry in entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${entry.label}: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: entry.value),
                ],
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _timelineSection(List<PetEvent> events, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Health timeline'),
        for (final event in events) _timelineEntry(event, dateFormat),
      ],
    );
  }

  pw.Widget _timelineEntry(PetEvent event, DateFormat dateFormat) {
    final description = event.description?.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '${_formatUtc(event.date, dateFormat)} - '
                      '${_label(event.type.name)}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: event.title),
              ],
            ),
          ),
          if (description != null && description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, left: 8),
              child: pw.Text(
                _trim(description, _eventDescriptionMaxChars),
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _documentsSection(
    List<PetDocument> documents,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Documents'),
        for (final document in documents) _documentEntry(document, dateFormat),
      ],
    );
  }

  pw.Widget _documentEntry(PetDocument document, DateFormat dateFormat) {
    final dates = _documentDates(document, dateFormat);
    final notes = document.notes?.trim();
    final overview = _documentOverview(document);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${document.title} (${_label(document.type.name)})',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (dates != null)
            pw.Text(dates, style: const pw.TextStyle(fontSize: 10)),
          if (notes != null && notes.isNotEmpty)
            pw.Text(
              'Notes: $notes',
              style: const pw.TextStyle(fontSize: 10),
            ),
          if (overview != null)
            pw.Text(
              overview,
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
        ],
      ),
    );
  }

  pw.Widget _remindersSection(List<Reminder> reminders, DateFormat dateFormat) {
    final sorted = [...reminders]
      ..sort((a, b) => a.dateTime.value.compareTo(b.dateTime.value));
    return _section(
      'Reminders',
      sorted.map((r) {
        final status = r.isCompleted ? ' [done]' : '';
        final repeat =
            r.repeatType != null ? ' (repeats ${r.repeatType!.name})' : '';
        return '${_formatUtc(r.dateTime, dateFormat)} - '
            '${r.title}$repeat$status';
      }).toList(),
    );
  }

  // --- helpers -------------------------------------------------------------

  String? _documentDates(PetDocument document, DateFormat dateFormat) {
    final parts = <String>[
      if (document.issueDate != null)
        'Issued ${_formatDate(document.issueDate!, dateFormat)}',
      if (document.expiryDate != null)
        'Expires ${_formatDate(document.expiryDate!, dateFormat)}',
    ];
    return parts.isEmpty ? null : parts.join('  -  ');
  }

  String? _documentOverview(PetDocument document) {
    final source = document.extractedText;
    if (source == null || source.trim().isEmpty) return null;
    return 'Overview: ${_trim(source, _documentOverviewMaxChars)}';
  }

  List<String> _uniqueTitles(List<PetEvent> events, PetEventType type) {
    final seen = <String>{};
    for (final event in events.where((e) => e.type == type)) {
      seen.add(event.title);
    }
    return seen.toList();
  }

  List<PetEvent> _eventsNewestFirst(List<PetEvent> events) {
    return [...events]..sort((a, b) => b.date.value.compareTo(a.date.value));
  }

  String _trim(String value, int maxChars) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= maxChars) return collapsed;
    final cut = collapsed.substring(0, maxChars);
    final lastSpace = cut.lastIndexOf(' ');
    final base = lastSpace > maxChars * 0.6 ? cut.substring(0, lastSpace) : cut;
    return '${base.trimRight()}...';
  }

  String _formatDate(DateOnly date, DateFormat dateFormat) {
    return dateFormat.format(date.toUtcDateTime());
  }

  String _formatUtc(UtcDateTime value, DateFormat dateFormat) {
    return dateFormat.format(value.value.toLocal());
  }

  String _ageSuffix(DateOnly birth) {
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years -= 1;
    }
    if (years < 0) return '';
    if (years == 0) return ' (under 1 year)';
    return ' ($years ${years == 1 ? 'year' : 'years'} old)';
  }

  pw.Widget _section(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        for (final line in lines) pw.Bullet(text: line),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 0.5),
        pw.Text(
          'This summary was generated from records entered by the pet owner in '
          'PawVault. It is not a medical record or veterinary diagnosis.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.SizedBox(height: 2),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
      ],
    );
  }

  String _label(String enumName) {
    final spaced = enumName.replaceAllMapped(
      RegExp('([A-Z])'),
      (m) => ' ${m.group(0)}',
    );
    final trimmed = spaced.trim();
    if (trimmed.isEmpty) return enumName;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

class _OverviewEntry {
  const _OverviewEntry(this.label, this.value);

  final String label;
  final String value;
}
