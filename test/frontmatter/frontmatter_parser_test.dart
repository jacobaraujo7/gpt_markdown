import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('GptMarkdownFrontmatter.split', () {
    test('returns null frontmatter when document has none', () {
      const source = '# Hello\n\nNo frontmatter here.';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNull);
      expect(result.body, source);
    });

    test('splits frontmatter from the body', () {
      const source = '---\ntitle: Hello\n---\n# Body';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNotNull);
      expect(result.frontmatter!.string('title'), 'Hello');
      expect(result.body.trim(), '# Body');
    });

    test('accepts the "..." closing fence', () {
      const source = '---\ntitle: Hello\n...\n# Body';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNotNull);
      expect(result.frontmatter!.string('title'), 'Hello');
      expect(result.body.trim(), '# Body');
    });

    test('handles CRLF line endings', () {
      const source = '---\r\ntitle: Hello\r\n---\r\n# Body';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter!.string('title'), 'Hello');
      expect(result.body.trim(), '# Body');
    });

    test('tolerates leading blank lines before the fence', () {
      const source = '\n\n---\ntitle: Hello\n---\n# Body';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNotNull);
      expect(result.frontmatter!.string('title'), 'Hello');
    });

    test('treats an unterminated fence as a normal document', () {
      const source = '---\ntitle: Hello\n# Body';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNull);
      expect(result.body, source);
    });

    test('does not treat a mid-document --- as frontmatter', () {
      const source = '# Title\n\n---\n\nMore text';
      final result = GptMarkdownFrontmatter.split(source);
      expect(result.frontmatter, isNull);
      expect(result.body, source);
    });

    test('treats an empty/fieldless block as not frontmatter', () {
      // `---\n---` and `---\n\n---` are adjacent horizontal rules, not an empty
      // frontmatter block, so they must render as markdown.
      for (final source in ['---\n---\n# Body', '---\n\n---']) {
        final result = GptMarkdownFrontmatter.split(source);
        expect(result.frontmatter, isNull, reason: source);
        expect(result.body, source);
      }
    });
  });

  group('GptMarkdownFrontmatter.parse scalars', () {
    test('coerces types', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
title: My Doc
count: 42
ratio: 3.14
published: true
draft: false
deleted: null
empty: ~
version: 1.2.0
---
''');
      expect(fm, isNotNull);
      expect(fm!['title'], 'My Doc');
      expect(fm['count'], 42);
      expect(fm['ratio'], 3.14);
      expect(fm['published'], isTrue);
      expect(fm['draft'], isFalse);
      expect(fm['deleted'], isNull);
      expect(fm['empty'], isNull);
      // Looks like a version, not a number — stays a string.
      expect(fm['version'], '1.2.0');
    });

    test('handles quoted strings', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
double: "hello: world"
single: 'it''s here'
colon_value: time is 12:30
escaped: "line1\\nline2"
---
''');
      expect(fm!['double'], 'hello: world');
      expect(fm['single'], "it's here");
      expect(fm['colon_value'], 'time is 12:30');
      expect(fm['escaped'], 'line1\nline2');
    });

    test('strips inline comments on unquoted scalars', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
name: value # this is a comment
url: https://example.com#anchor
---
''');
      expect(fm!['name'], 'value');
      // No space before '#', so it is part of the value.
      expect(fm['url'], 'https://example.com#anchor');
    });

    test('ignores full-line comments', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
# leading comment
name: value
# trailing comment
---
''');
      expect(fm!.keys, ['name']);
      expect(fm['name'], 'value');
    });
  });

  group('GptMarkdownFrontmatter.parse collections', () {
    test('parses a block sequence at the key indent', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
tags:
- flutter
- markdown
- yaml
---
''');
      expect(fm!['tags'], ['flutter', 'markdown', 'yaml']);
      expect(fm.stringList('tags'), ['flutter', 'markdown', 'yaml']);
    });

    test('parses an indented block sequence', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
tags:
  - flutter
  - markdown
---
''');
      expect(fm!['tags'], ['flutter', 'markdown']);
    });

    test('parses a flow sequence', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
tags: [flutter, markdown, "yaml, too"]
nums: [1, 2, 3]
---
''');
      expect(fm!['tags'], ['flutter', 'markdown', 'yaml, too']);
      expect(fm['nums'], [1, 2, 3]);
    });

    test('parses a nested mapping', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
author:
  name: Jacob
  email: jacob@example.com
  social:
    github: jacob
---
''');
      final author = fm!['author'] as Map;
      expect(author['name'], 'Jacob');
      expect(author['email'], 'jacob@example.com');
      expect((author['social'] as Map)['github'], 'jacob');
    });

    test('parses a flow mapping', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
point: {x: 1, y: 2}
---
''');
      final point = fm!['point'] as Map;
      expect(point['x'], 1);
      expect(point['y'], 2);
    });

    test('parses a sequence of compact mappings', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
tools:
  - name: Read
    enabled: true
  - name: Write
    enabled: false
---
''');
      final tools = fm!['tools'] as List;
      expect(tools.length, 2);
      expect((tools[0] as Map)['name'], 'Read');
      expect((tools[0] as Map)['enabled'], isTrue);
      expect((tools[1] as Map)['name'], 'Write');
      expect((tools[1] as Map)['enabled'], isFalse);
    });
  });

  group('GptMarkdownFrontmatter.parse block scalars', () {
    test('literal block scalar preserves line breaks', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
description: |
  Line one
  Line two
---
''');
      expect(fm!['description'], 'Line one\nLine two');
    });

    test('folded block scalar joins lines with spaces', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
description: >
  Line one
  Line two
---
''');
      expect(fm!['description'], 'Line one Line two');
    });
  });

  group('GptMarkdownFrontmatter helpers', () {
    test('stringList wraps scalars and tolerates missing keys', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
single: hello
---
''');
      expect(fm!.stringList('single'), ['hello']);
      expect(fm.stringList('missing'), isEmpty);
    });

    test('string() coerces and containsKey works', () {
      final fm = GptMarkdownFrontmatter.parse('''
---
count: 7
---
''');
      expect(fm!.string('count'), '7');
      expect(fm.containsKey('count'), isTrue);
      expect(fm.containsKey('nope'), isFalse);
    });

    test('exposes raw text', () {
      final fm = GptMarkdownFrontmatter.parse('---\na: 1\nb: 2\n---\n');
      expect(fm!.raw, 'a: 1\nb: 2');
    });
  });

  group('GptMarkdownFrontmatter realistic agent.md', () {
    test('parses values with punctuation, quotes and em dashes', () {
      const src = '''
---
name: backend-scout
description: Scout read-only do backend .NET (BackOfficeHub). Use para localizar código — endpoints, handlers — e responder "onde está X?", "quem chama Y?". Não edita arquivos; retorna paths.
tools: Read, Grep, Glob, Bash
model: sonnet
---

Você é um agente scout.
''';
      final result = GptMarkdownFrontmatter.split(src);
      final fm = result.frontmatter;
      expect(fm, isNotNull);
      expect(fm!.keys.toList(), ['name', 'description', 'tools', 'model']);
      expect(fm['name'], 'backend-scout');
      expect(fm['model'], 'sonnet');
      // Comma-separated (non-flow) values stay as a single string.
      expect(fm['tools'], 'Read, Grep, Glob, Bash');
      expect(
        fm.string('description'),
        startsWith('Scout read-only do backend .NET (BackOfficeHub).'),
      );
      expect(fm.string('description'), contains('"onde está X?"'));
      expect(result.body.trim(), 'Você é um agente scout.');
    });
  });
}
