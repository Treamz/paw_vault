import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/features/vet_summary_export/presentation/cubit/vet_summary_export_cubit.dart';

void main() {
  group('VetSummaryExportCubit.sanitizeFileName', () {
    test('returns null for blank input', () {
      expect(VetSummaryExportCubit.sanitizeFileName(null), isNull);
      expect(VetSummaryExportCubit.sanitizeFileName('   '), isNull);
    });

    test('appends .pdf when missing', () {
      expect(
        VetSummaryExportCubit.sanitizeFileName('Rex summary'),
        'Rex summary.pdf',
      );
    });

    test('keeps an existing .pdf extension', () {
      expect(
        VetSummaryExportCubit.sanitizeFileName('rex_vet_summary.PDF'),
        'rex_vet_summary.PDF',
      );
    });

    test('strips path separators', () {
      expect(
        VetSummaryExportCubit.sanitizeFileName('a/b\\c:d'),
        'a_b_c_d.pdf',
      );
    });
  });
}
