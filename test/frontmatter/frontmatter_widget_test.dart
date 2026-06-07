import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

const _agentMd = '''
---
name: code-reviewer
description: Reviews diffs for bugs.
tools: Read, Grep, Glob, Bash
model: sonnet
---

Body paragraph.
''';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Frontmatter rendering', () {
    testWidgets('renders frontmatter as a table by default', (tester) async {
      await _pump(tester, GptMarkdown(_agentMd));

      // The default renderer is a table of key/value rows.
      expect(find.byType(GptMarkdownFrontmatterTable), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);

      // Keys and values are visible in the table.
      expect(find.text('name'), findsOneWidget);
      expect(find.text('code-reviewer'), findsOneWidget);
      expect(find.text('tools'), findsOneWidget);
      expect(find.text('Read, Grep, Glob, Bash'), findsOneWidget);
      expect(find.text('model'), findsOneWidget);

      // The body still renders.
      expect(find.textContaining('Body paragraph.'), findsOneWidget);
    });

    testWidgets('key cells stretch to fill the row height', (tester) async {
      await _pump(tester, GptMarkdown(_agentMd));
      // The colored key cells use fill alignment so their background covers the
      // whole cell even when the value wraps onto several lines.
      final keyCells = tester.widgetList<TableCell>(find.byType(TableCell));
      expect(keyCells, isNotEmpty);
      expect(
        keyCells.every(
          (c) => c.verticalAlignment == TableCellVerticalAlignment.fill,
        ),
        isTrue,
      );
    });

    testWidgets('does not re-render frontmatter in the markdown body', (
      tester,
    ) async {
      await _pump(tester, GptMarkdown(_agentMd));
      // If the fences leaked into the body, the raw YAML line would render.
      expect(find.textContaining('name: code-reviewer'), findsNothing);
      // The fences must not become horizontal rules.
      expect(find.byType(CustomDivider), findsNothing);
    });

    testWidgets('frontmatterBuilder overrides the default table', (
      tester,
    ) async {
      GptMarkdownFrontmatter? captured;
      await _pump(
        tester,
        GptMarkdown(
          _agentMd,
          frontmatterBuilder: (context, frontmatter) {
            captured = frontmatter;
            return Text('AGENT: ${frontmatter.string('name')}');
          },
        ),
      );

      // The builder received the parsed frontmatter.
      expect(captured, isNotNull);
      expect(captured!.string('name'), 'code-reviewer');

      // The custom widget replaces the default table.
      expect(find.text('AGENT: code-reviewer'), findsOneWidget);
      expect(find.byType(GptMarkdownFrontmatterTable), findsNothing);
    });

    testWidgets('builder can hide the frontmatter', (tester) async {
      await _pump(
        tester,
        GptMarkdown(
          _agentMd,
          frontmatterBuilder: (context, frontmatter) =>
              const SizedBox.shrink(),
        ),
      );
      expect(find.byType(GptMarkdownFrontmatterTable), findsNothing);
      expect(find.text('code-reviewer'), findsNothing);
      expect(find.textContaining('Body paragraph.'), findsOneWidget);
    });

    testWidgets('no frontmatter → no table, builder not called', (
      tester,
    ) async {
      var called = false;
      await _pump(
        tester,
        GptMarkdown(
          'Plain paragraph.',
          frontmatterBuilder: (context, frontmatter) {
            called = true;
            return const Text('SHOULD NOT APPEAR');
          },
        ),
      );
      expect(called, isFalse);
      expect(find.byType(GptMarkdownFrontmatterTable), findsNothing);
      expect(find.text('SHOULD NOT APPEAR'), findsNothing);
      expect(find.textContaining('Plain paragraph.'), findsOneWidget);
    });
  });
}
