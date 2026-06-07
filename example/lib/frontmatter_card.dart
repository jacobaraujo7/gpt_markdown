import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// A small card that renders parsed [GptMarkdownFrontmatter] as document
/// metadata — a title, description, tag chips and any remaining key/value
/// pairs. Pass it to `GptMarkdown(frontmatterBuilder: ...)`.
///
/// ```dart
/// GptMarkdown(
///   agentMarkdown,
///   frontmatterBuilder: (context, frontmatter) =>
///       FrontmatterCard(frontmatter: frontmatter),
/// )
/// ```
class FrontmatterCard extends StatelessWidget {
  const FrontmatterCard({super.key, required this.frontmatter});

  final GptMarkdownFrontmatter frontmatter;

  // Keys that get special, prominent treatment.
  static const _titleKeys = ['name', 'title'];
  static const _descriptionKeys = ['description', 'summary'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = _firstOf(_titleKeys);
    final description = _firstOf(_descriptionKeys);
    final handledKeys = {..._titleKeys, ..._descriptionKeys};

    // Everything else, in document order.
    final rest = frontmatter.fields.entries
        .where((e) => !handledKeys.contains(e.key))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Frontmatter',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          for (final entry in rest) ...[
            const SizedBox(height: 10),
            _Field(label: entry.key, value: entry.value),
          ],
        ],
      ),
    );
  }

  String? _firstOf(List<String> keys) {
    for (final key in keys) {
      final value = frontmatter.string(key);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 4),
        if (value is List)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in value as List) _Chip(label: '$item'),
            ],
          )
        else if (value is Map)
          Text(
            (value as Map).entries.map((e) => '${e.key}: ${e.value}').join(', '),
            style: theme.textTheme.bodyMedium,
          )
        else
          Text('$value', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
