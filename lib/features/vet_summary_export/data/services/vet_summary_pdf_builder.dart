import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_data.dart';
import 'package:paw_vault/features/vet_summary_export/domain/services/vet_summary_pdf_generator.dart';
import 'package:pdf/widgets.dart' as pw;

/// [VetSummaryPdfGenerator] backed by the `pdf` package.
class VetSummaryPdfBuilder implements VetSummaryPdfGenerator {
  const VetSummaryPdfBuilder();

  @override
  Future<Uint8List> build(VetSummaryData data) async {
    final dateFormat = DateFormat.yMMMd();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Vet Summary - ${data.pet.name}',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          _profileSection(data.pet, dateFormat),
          if (data.events.isNotEmpty)
            _section(
              'Timeline events',
              data.events
                  .map((e) =>
                      '${dateFormat.format(e.date.value)} - ${_label(e.type.name)}: ${e.title}')
                  .toList(),
            ),
          if (data.documents.isNotEmpty)
            _section(
              'Documents',
              data.documents.map((d) {
                final expiry = d.expiryDate;
                final suffix =
                    expiry != null ? ' (expires ${expiry.toString()})' : '';
                return '${d.title} - ${_label(d.type.name)}$suffix';
              }).toList(),
            ),
          if (data.reminders.isNotEmpty)
            _section(
              'Reminders',
              data.reminders.map((r) {
                final status = r.isCompleted ? ' [done]' : '';
                final repeat = r.repeatType != null
                    ? ' (repeats ${r.repeatType!.name})'
                    : '';
                return '${dateFormat.format(r.dateTime.value)} - ${r.title}$repeat$status';
              }).toList(),
            ),
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

  pw.Widget _profileSection(Pet pet, DateFormat dateFormat) {
    final lines = <String>[
      if (pet.species != null) 'Species: ${pet.species}',
      if (pet.breed != null) 'Breed: ${pet.breed}',
      if (pet.gender != null) 'Gender: ${_label(pet.gender!.name)}',
      if (pet.birthDate != null) 'Birth date: ${pet.birthDate}',
      if (pet.weight != null)
        'Weight: ${pet.weight!.value} ${pet.weight!.unit.name}',
      if (pet.microchipNumber != null) 'Microchip: ${pet.microchipNumber}',
      if (pet.allergies.isNotEmpty) 'Allergies: ${pet.allergies.join(', ')}',
      if (pet.chronicConditions.isNotEmpty)
        'Chronic conditions: ${pet.chronicConditions.join(', ')}',
      if (pet.notes != null) 'Notes: ${pet.notes}',
    ];

    return _section('Profile', lines.isEmpty ? ['Name: ${pet.name}'] : lines);
  }

  pw.Widget _section(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        for (final line in lines) pw.Bullet(text: line),
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
