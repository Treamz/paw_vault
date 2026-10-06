import 'package:flutter/material.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';

/// The colour and icon for an attention level.
///
/// These are fixed hues rather than `ColorScheme` roles. An attention level
/// means something — like `error` does — and the seeded scheme's secondary and
/// tertiary roles are both teal here, so `vetSoon` came out blue, which reads
/// as positive and draws no attention, and `nothingNotable` shared grey with
/// `undetermined`, which reads as "could not assess".
///
/// They are muted on purpose. `nothingNotable` is a green that says this scan
/// found nothing notable — not a green tick claiming the pet is fine, which is
/// a claim the app cannot make from a photograph; the guidance sentence under
/// the label still says so in words. `vetSoon` is a red that asks to be read,
/// kept below `vetPromptly` so the ladder still rises.
({Color background, Color foreground, IconData icon}) _style(
  ColorScheme scheme,
  PawAttentionLevel level,
) {
  final isDark = scheme.brightness == Brightness.dark;

  return switch (level) {
    PawAttentionLevel.nothingNotable => (
        background: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFDCEFE1),
        foreground: isDark ? const Color(0xFFA8D5B5) : const Color(0xFF1B5E3F),
        icon: Icons.check_circle_outline,
      ),
    PawAttentionLevel.monitor => (
        background: isDark ? const Color(0xFF3D3321) : const Color(0xFFFBF0D5),
        foreground: isDark ? const Color(0xFFE8CE8A) : const Color(0xFF6B5000),
        icon: Icons.visibility_outlined,
      ),
    PawAttentionLevel.vetSoon => (
        background: isDark ? const Color(0xFF4A2420) : const Color(0xFFFBE3E0),
        foreground: isDark ? const Color(0xFFF0B4AE) : const Color(0xFF8C2F26),
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

/// Compact attention chip, for history rows and comparison columns.
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
            // The longest label ("Worth showing a vet soon") does not fit on
            // one line in a narrow column, so let it wrap rather than
            // overflow.
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: style.foreground),
              ),
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
