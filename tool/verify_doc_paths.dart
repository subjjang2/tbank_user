// Verifies that file paths referenced in context/docs markdown actually exist.
// Catches stale references (hallucinated paths) before they reach main.
//
// Usage: dart run tool/verify_doc_paths.dart
// Exit 0 = all references resolve · Exit 1 = broken references found.
//
// Scanned: CLAUDE.md, lib/**/CLAUDE.md, docs/**/*.md, test/README.md
// Checked:
//   1. markdown links `[text](path)` -> resolved relative to the doc file.
//   2. backtick inline code that looks like a repo file path
//      (`lib/service/auth_service.dart`) -> resolved relative to repo root,
//      with a fallback relative to the doc file.
// URI-scheme links (http:, mailto:, tel:, ...), pure #anchors, commands, and
// globs are skipped.

import 'dart:io';

// Join + unify separators so Windows back-slashed dirs don't mix with the
// forward-slashed targets parsed from markdown (e.g. `C:\repo\docs/x.md`).
// Dart IO accepts `/` on every platform, so normalising to `/` is portable.
String _join(String base, String target) =>
    '$base/$target'.replaceAll('\\', '/');

final _linkRe = RegExp(r'\]\(([^)]+)\)');
final _codeRe = RegExp(r'`([^`\n]+)`');

// Reject tokens that are clearly not a plain path (commands, globs, shell).
final _notPathRe = RegExp(r'[*?$|&<>(){}\[\]!]');
// A path's final segment must carry a file extension, e.g. `.dart`, `.md`.
final _hasExtRe = RegExp(r'\.[A-Za-z0-9_]+$');
// Any URI scheme (http:, mailto:, tel:, ftp:, ...). 2+ chars avoids matching a
// Windows drive letter like `C:`.
final _schemeRe = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]+:');

bool _isExternal(String target) =>
    target.startsWith('#') || _schemeRe.hasMatch(target);

// True when a backtick token reads like a relative repo file path worth
// checking. Conservative: only file references (with extension) containing a
// path separator are checked, so bare dirs/identifiers/commands are skipped.
bool _looksLikeFilePath(String t) {
  if (t.contains(' ') || t.contains('\t')) return false;
  if (_notPathRe.hasMatch(t)) return false;
  if (!t.contains('/')) return false;
  if (t.startsWith('/') || t.contains('://')) return false;
  // `...` is a docs ellipsis (abbreviated prefix), not a real path.
  if (t.contains('..')) return false;
  final last = t.split('/').last;
  return _hasExtRe.hasMatch(last);
}

Future<List<File>> _collectDocs(Directory root) async {
  final docs = <File>[];
  final rootMd = File(_join(root.path, 'CLAUDE.md'));
  if (rootMd.existsSync()) docs.add(rootMd);

  for (final sub in ['lib', 'docs', 'test']) {
    final dir = Directory(_join(root.path, sub));
    if (!dir.existsSync()) continue;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File &&
          (e.path.endsWith('CLAUDE.md') || e.path.endsWith('.md'))) {
        docs.add(e);
      }
    }
  }
  return docs;
}

void main() async {
  final root = Directory.current;
  final docs = await _collectDocs(root);
  final broken = <String>[];
  var total = 0;

  // Run from the repo root; otherwise we'd scan nothing and "pass" silently.
  if (docs.isEmpty) {
    stderr.writeln(
      'No context/doc files found under ${root.path}. '
      'Run from the repository root (where CLAUDE.md lives).',
    );
    exit(2);
  }

  bool exists(String base, String target) {
    final path = _join(base, target);
    return File(path).existsSync() || Directory(path).existsSync();
  }

  for (final doc in docs) {
    final dir = File(doc.path).parent.path;
    final content = doc.readAsStringSync();
    final rel = doc.path.replaceFirst(
      '${root.path}${Platform.pathSeparator}',
      '',
    );

    // 1. markdown links: resolved relative to the doc file.
    for (final m in _linkRe.allMatches(content)) {
      var target = m.group(1)!.trim();
      // CommonMark allows `[t](path "title")`; keep only the URL part.
      target = target.split(RegExp(r'\s')).first;
      if (_isExternal(target)) continue;
      // strip anchor / query
      target = target.split('#').first.split('?').first;
      if (target.isEmpty) continue;
      total++;
      if (!exists(dir, target)) {
        broken.add('$rel  ->  $target');
      }
    }

    // 2. backtick inline-code paths. CLAUDE.md documents paths relative to the
    // source root (`lib/`), so try root, the doc's dir, then `lib/`.
    for (final m in _codeRe.allMatches(content)) {
      final target = m.group(1)!.trim();
      if (!_looksLikeFilePath(target)) continue;
      total++;
      if (!exists(root.path, target) &&
          !exists(dir, target) &&
          !exists(_join(root.path, 'lib'), target)) {
        broken.add('$rel  ->  `$target`');
      }
    }
  }

  stdout.writeln(
    'Checked $total path reference(s) across ${docs.length} doc file(s).',
  );
  if (broken.isEmpty) {
    stdout.writeln('OK: all context/doc paths resolve.');
    exit(0);
  }
  stderr.writeln('BROKEN context/doc references (${broken.length}):');
  for (final b in broken) {
    stderr.writeln('  - $b');
  }
  exit(1);
}
