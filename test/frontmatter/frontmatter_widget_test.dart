import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../utils/test_helpers.dart';

// A document whose body is a single paragraph keeps the serialized output
// predictable (headings serialize as LATEX in the test serializer).
const _stripDoc =
    '---\n'
    'title: Secret Meta\n'
    'description: Reviews diffs for bugs.\n'
    'tags: [alpha, beta]\n'
    '---\n'
    'Visible paragraph.';

const _agentMd = '''
---
name: code-reviewer
description: Reviews diffs for bugs.
tags:
  - review
  - quality
---

# Code Reviewer

Body text here.
''';

void main() {
  group('Frontmatter rendering', () {
    testWidgets('strips frontmatter from the rendered body', (tester) async {
      await pumpMarkdown(tester, _stripDoc);
      final output = getSerializedOutput(tester);

      // The body still renders...
      expect(output, 'TEXT("Visible paragraph.")');

      // ...and none of the frontmatter leaks into the rendered output.
      expect(output, isNot(contains('Secret Meta')));
      expect(output, isNot(contains('description')));
      expect(output, isNot(contains('alpha')));
      expect(output, isNot(contains('beta')));
    });

    testWidgets('does not render a stray HR for the fences', (tester) async {
      await pumpMarkdown(tester, _stripDoc);
      final output = getSerializedOutput(tester);
      // If the fences leaked through they would render as horizontal rules.
      expect(output, isNot(contains('HR')));
    });

    testWidgets('renders frontmatterBuilder output above the body', (
      tester,
    ) async {
      GptMarkdownFrontmatter? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                _agentMd,
                frontmatterBuilder: (context, frontmatter) {
                  captured = frontmatter;
                  return Text('AGENT: ${frontmatter.string('name')}');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The builder received the parsed frontmatter.
      expect(captured, isNotNull);
      expect(captured!.string('name'), 'code-reviewer');
      expect(captured!.stringList('tags'), ['review', 'quality']);

      // The builder's widget is in the tree.
      expect(find.text('AGENT: code-reviewer'), findsOneWidget);
    });

    testWidgets('does not call builder when there is no frontmatter', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              'Plain paragraph.',
              frontmatterBuilder: (context, frontmatter) {
                called = true;
                return const Text('SHOULD NOT APPEAR');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.text('SHOULD NOT APPEAR'), findsNothing);
    });

    testWidgets('hides frontmatter when no builder is provided', (
      tester,
    ) async {
      await pumpMarkdown(tester, _stripDoc);
      final output = getSerializedOutput(tester);
      // Still just the body — the frontmatter is silently dropped.
      expect(output, 'TEXT("Visible paragraph.")');
    });

    testWidgets('document without frontmatter renders unchanged', (
      tester,
    ) async {
      await pumpMarkdown(tester, 'Some **bold** text.');
      final output = getSerializedOutput(tester);
      expect(output, contains('TEXT("bold")[bold]'));
    });
  });
}
