import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_attention_badge.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_scan_disclaimer.dart';

/// Side-by-side view of two paw checks.
///
/// This is the screen an owner actually shows a vet: not a verdict, but the
/// same paw photographed twice with the dates and what changed between them.
@RoutePage()
class PawCheckComparisonScreen extends StatelessWidget {
  const PawCheckComparisonScreen({
    required this.earlier,
    required this.later,
    super.key,
  });

  final PawCheck earlier;
  final PawCheck later;

  @override
  Widget build(BuildContext context) {
    final dayGap =
        later.checkedAt.value.difference(earlier.checkedAt.value).inDays.abs();
    final mismatched = earlier.location != later.location;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare paw checks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PawScanDisclaimer(),
          const SizedBox(height: 16),
          if (mismatched) ...[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'These checks are of different paws, so they may not be '
                  'comparable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            dayGap == 0
                ? 'Both checks are from the same day.'
                : '$dayGap ${dayGap == 1 ? 'day' : 'days'} apart',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = [
                _CheckColumn(check: earlier, label: 'Earlier'),
                _CheckColumn(check: later, label: 'Later'),
              ];

              // Side by side on anything wider than a small phone; stacked
              // below that, so neither column becomes unreadable.
              if (constraints.maxWidth < 380) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    columns.first,
                    const SizedBox(height: 24),
                    columns.last,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: columns.first),
                  const SizedBox(width: 16),
                  Expanded(child: columns.last),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckColumn extends StatelessWidget {
  const _CheckColumn({required this.check, required this.label});

  final PawCheck check;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd().format(check.checkedAt.value.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(date, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          formatPawLocation(check.location),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (check.photoUrls.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: check.photoUrls.first.toString(),
                fit: BoxFit.cover,
                // The journal can hold many checks; decoding at display size
                // keeps a long comparison from churning memory.
                memCacheWidth: 600,
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        PawAttentionBadge(level: check.attentionLevel),
        const SizedBox(height: 8),
        for (final observation in check.observations)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $observation', style: theme.textTheme.bodySmall),
          ),
        if (check.ownerNote != null) ...[
          const SizedBox(height: 4),
          Text(
            'Your note: ${check.ownerNote}',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}
