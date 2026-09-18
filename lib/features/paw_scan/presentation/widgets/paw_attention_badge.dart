import 'package:flutter/material.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/presentation/models/paw_scan_labels.dart';

/// The colour and icon for an attention level.
///
/// [PawAttentionLevel.nothingNotable] is deliberately neutral rather than a
/// green tick: a green tick reads as "your pet is fine", which is a claim the
/// app cannot make from one photograph.
({Color background, Color foreground, IconData icon}) _style(
  ColorScheme scheme,
  PawAttentionLevel level,
) {
  return switch (level) {
    PawAttentionLevel.nothingNotable => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.remove_circle_outline,
      ),
    PawAttentionLevel.monitor => (
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        icon: Icons.visibility_outlined,
      ),
    PawAttentionLevel.vetSoon => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        icon: Icons.medical_services_outlined,
      ),
    PawAttentionLevel.vetPromptly => (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        icon: Icons.priority_high,
      ),
    PawAttentionLevel.undetermined => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.help_outline,
      ),
  };
}

/// Compact attention chip, for journal rows and comparison columns.
class PawAttentionBadge extends StatelessWidget {
  const PawAttentionBadge({required this.level, super.key});

  final PawAttentionLevel level;

  @override
  Widget build(BuildContext context) {
    final style = _style(Theme.of(context).colorScheme, level);
    final label = formatPawAttentionLevel(level);

    return Semantics(
      label: 'Attention level: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 16, color: style.foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: style.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full attention card shown on a result: the level plus the app-authored
/// sentence about what to do next.
class PawAttentionCard extends StatelessWidget {
  const PawAttentionCard({required this.level, super.key});

  final PawAttentionLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(theme.colorScheme, level);

    return Card(
      color: style.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(style.icon, color: style.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatPawAttentionLevel(level),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: style.foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatPawAttentionGuidance(level),
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: style.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
