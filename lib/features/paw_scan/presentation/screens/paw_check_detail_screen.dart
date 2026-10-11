import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/core/presentation/widgets/adaptive_body.dart';
import 'package:paw_vault/core/presentation/widgets/full_screen_image.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_attention_badge.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_scan_disclaimer.dart';

/// A saved paw check, opened from History.
///
/// History only listed its checks, so the photos — the thing an owner
/// actually wants to look at again, and the thing they would show a vet —
/// could not be seen at all once a check was saved. The row's summary stays a
/// summary; this is the whole record.
@RoutePage()
class PawCheckDetailScreen extends StatelessWidget {
  const PawCheckDetailScreen({required this.check, super.key});

  final PawCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedAt = check.checkedAt.value.toLocal();

    return Scaffold(
      appBar: AppBar(title: Text(formatPawLocation(check.location))),
      body: AdaptiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PawScanDisclaimer(),
            const SizedBox(height: 16),
            Text(
              DateFormat.yMMMMd().add_jm().format(checkedAt),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PawAttentionCard(level: check.attentionLevel),
            if (check.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                check.photoUrls.length == 1 ? 'Photo' : 'Photos',
                style: theme.textTheme.titleSmall,
              ),
              for (final url in check.photoUrls) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => showFullScreenImage(
                    context,
                    CachedNetworkImageProvider(url.toString()),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url.toString(),
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Says a photo is on its way rather than leaving an empty
                      // box, as the documents and Smart Input previews do.
                      placeholder: (context, _) => Container(
                        height: 240,
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      fadeInDuration: const Duration(milliseconds: 120),
                      errorWidget: (context, _, __) => Container(
                        height: 240,
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            if (check.observations.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                PawScanCopy.whatPawScanCanSee,
                style: theme.textTheme.titleSmall,
              ),
              for (final observation in check.observations) ...[
                const SizedBox(height: 8),
                Text(observation, style: theme.textTheme.bodyMedium),
              ],
            ],
            if (check.summary != null) ...[
              const SizedBox(height: 16),
              Text(check.summary!, style: theme.textTheme.bodyMedium),
            ],
            if (check.ownerNote != null) ...[
              const SizedBox(height: 24),
              Text('Your note', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(check.ownerNote!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  check.includeInVetSummary
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    check.includeInVetSummary
                        ? 'Included in the vet summary'
                        : 'Not included in the vet summary',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
