import 'package:flutter/material.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';

/// The non-diagnostic notice shown wherever a Paw Scan result appears.
///
/// Deliberately takes no `onDismiss` and renders no close affordance. This
/// notice is the basis on which the feature is allowed to exist at all, so it
/// must not become dismissible, however noisy it looks in review — there is a
/// widget test asserting there is no way to close it.
class PawScanDisclaimer extends StatelessWidget {
  const PawScanDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PawScanCopy.disclaimerTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PawScanCopy.disclaimerBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
