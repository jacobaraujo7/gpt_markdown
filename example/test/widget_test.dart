// Smoke test for the gpt_markdown example app.

import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('example app renders markdown and its frontmatter', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // The markdown body is rendered.
    expect(find.byType(GptMarkdown), findsOneWidget);

    // The leading YAML frontmatter is parsed and shown via the
    // FrontmatterCard rather than rendered as raw markdown.
    expect(find.text('Frontmatter'), findsOneWidget);
    expect(find.text('GPT Markdown'), findsWidgets);
  });
}
