/// The chrome every page of the project site shares (head, hero, rail, foot).
///
/// ⚠️ **Written once because it drifted.** `items.html` and `loot.html` were
/// each given their own hand-rolled header, and both lost the index rail — and
/// `.layout` at 64 rem is `var(--rail) minmax(0,1fr)`, so a `<main>` with no
/// rail beside it lands in the *rail's* column and renders in a strip about a
/// sixth of the page wide. The pages did not look "slightly different" from the
/// front page; they looked broken, and nothing in either generator said what
/// was missing.
///
/// So the skeleton lives here and both generators ask for it. A page supplies
/// what is actually its own — its title, its rail entries, its sections — and
/// cannot forget the parts that make it the same page as `index.html`.
library;

/// One entry in the sticky index rail (and in the narrow-screen jump list).
class RailEntry {
  const RailEntry({required this.anchor, required this.label});

  /// The id it scrolls to, without the `#`.
  final String anchor;

  final String label;
}

/// Everything from `<!doctype>` down to the opening of `<main>`.
///
/// [thesis] paragraphs are written straight into the hero as HTML — they carry
/// links and `<strong>`, so they are not escaped. [subtitle] is optional: the
/// front page uses it for the full name of the game.
String sitePageOpen({
  required bool pl,
  required String pageFile,
  required String title,
  required String description,
  required String eyebrow,
  required List<String> thesis,
  required String railTitle,
  required List<RailEntry> rail,
  String? subtitle,
}) {
  final root = pl ? '../' : '';
  final buffer = StringBuffer();

  buffer.writeln('<!doctype html>');
  buffer.writeln('<html lang="${pl ? 'pl' : 'en'}">');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="utf-8">');
  buffer.writeln(
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
  );
  buffer.writeln('<title>${escapeHtml(title)} — ARLS-ZA</title>');
  buffer.writeln(
    '<meta name="description" content="${escapeHtml(description)}">',
  );
  buffer.writeln('<meta name="color-scheme" content="light">');
  buffer.writeln(
    '<meta property="og:title" content="${escapeHtml(title)} — ARLS-ZA">',
  );
  buffer.writeln(
    '<meta property="og:description" content="${escapeHtml(description)}">',
  );
  buffer.writeln('<meta property="og:type" content="website">');
  buffer.writeln(
    '<link rel="alternate" hreflang="en" href="${pl ? '../$pageFile' : pageFile}">',
  );
  buffer.writeln(
    '<link rel="alternate" hreflang="pl" href="${pl ? pageFile : 'pl/$pageFile'}">',
  );
  buffer.writeln(
    '<link rel="alternate" hreflang="x-default" href="${pl ? '../$pageFile' : pageFile}">',
  );
  buffer.writeln('<link rel="icon" href="$_favicon">');
  buffer.writeln('<link rel="stylesheet" href="${root}assets/site.css">');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln(
    '<a class="skip" href="#content">${pl ? 'Przejdź do treści' : 'Skip to content'}</a>',
  );
  buffer.writeln();

  buffer.writeln('<header class="hero">');
  buffer.writeln(_contour);
  buffer.writeln();
  buffer.writeln('  <div class="hero__inner">');
  buffer.writeln('    <div class="hero__meta eyebrow">');
  buffer.writeln(
    '      <span><a href="${root}index.html">← ARLS-ZA</a></span>',
  );
  buffer.writeln('      <span>${escapeHtml(eyebrow)}</span>');
  buffer.writeln('      <nav class="langs" aria-label="Language">');
  buffer.writeln(
    '        <a href="${pl ? '../$pageFile' : pageFile}"'
    '${pl ? '' : ' aria-current="true"'} data-lang-link hreflang="en">EN</a>',
  );
  buffer.writeln(
    '        <a href="${pl ? pageFile : 'pl/$pageFile'}"'
    '${pl ? ' aria-current="true"' : ''} data-lang-link hreflang="pl">PL</a>',
  );
  buffer.writeln('      </nav>');
  buffer.writeln('    </div>');
  buffer.writeln();
  buffer.writeln('    <h1>');
  buffer.writeln('      <span class="hero__title">${escapeHtml(title)}</span>');
  if (subtitle != null) {
    buffer.writeln(
      '      <span class="hero__sub">${escapeHtml(subtitle)}</span>',
    );
  }
  buffer.writeln('    </h1>');
  for (final paragraph in thesis) {
    buffer.writeln('    <p class="thesis">');
    buffer.writeln('      $paragraph');
    buffer.writeln('    </p>');
  }
  buffer.writeln('  </div>');
  buffer.writeln('</header>');
  buffer.writeln();

  buffer.writeln('<div class="shell">');
  buffer.writeln('  <div class="layout">');
  buffer.writeln();

  // ⚠️ The rail is not decoration. Without it `<main>` sits in a 14 rem column.
  buffer.writeln(
    '    <nav class="rail" aria-label="${escapeHtml(railTitle)}">',
  );
  buffer.writeln('      <p class="rail__t">${escapeHtml(railTitle)}</p>');
  buffer.writeln('      <ol id="rail-list">');
  for (var index = 0; index < rail.length; index++) {
    buffer.writeln(
      '        <li><a href="#${rail[index].anchor}">'
      '<span>${_two(index)}</span>'
      '<span>${escapeHtml(rail[index].label)}</span></a></li>',
    );
  }
  buffer.writeln('      </ol>');
  buffer.writeln('    </nav>');
  buffer.writeln();

  buffer.writeln('    <main id="content">');
  buffer.writeln();
  buffer.writeln('      <div class="jump">');
  buffer.writeln(
    '        <label class="eyebrow" for="jump-sel">'
    '${pl ? 'Skocz do' : 'Jump to'}</label>',
  );
  buffer.writeln(
    '        <select id="jump-sel" aria-label="${pl ? 'Skocz do' : 'Jump to'}">',
  );
  for (var index = 0; index < rail.length; index++) {
    buffer.writeln(
      '          <option value="#${rail[index].anchor}">'
      '${_two(index)} — ${escapeHtml(rail[index].label)}</option>',
    );
  }
  buffer.writeln('        </select>');
  buffer.writeln('      </div>');
  buffer.writeln();

  return buffer.toString();
}

/// The footer, the closing tags, and the shared script the rail needs.
///
/// [note] is HTML: it carries the links back to the design document.
///
/// ⚠️ The language links go to *this* page in the other language, not to the
/// site root. `index.html` can point at `./` and `pl/` because it is the root;
/// a catalogue that did the same would answer "read this in Polish" by
/// throwing the reader back to the front page.
String sitePageClose({
  required bool pl,
  required String pageFile,
  required String note,
}) {
  final root = pl ? '../' : '';
  final buffer = StringBuffer();

  buffer.writeln('      <footer class="foot">');
  buffer.writeln('        <nav class="foot__langs" aria-label="Language">');
  buffer.writeln(
    '          <a href="${pl ? '../$pageFile' : pageFile}" data-lang-link hreflang="en">English</a>',
  );
  buffer.writeln(
    '          <a href="${pl ? pageFile : 'pl/$pageFile'}" data-lang-link hreflang="pl">Polski</a>',
  );
  buffer.writeln('        </nav>');
  buffer.writeln('        <p class="foot__note">');
  buffer.writeln('          $note');
  buffer.writeln('        </p>');
  buffer.writeln('      </footer>');
  buffer.writeln();
  buffer.writeln('    </main>');
  buffer.writeln('  </div>');
  buffer.writeln('</div>');
  buffer.writeln();
  buffer.writeln('<script src="${root}assets/site.js"></script>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}

String escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _two(int index) => index.toString().padLeft(2, '0');

/// The same contour rings the front page opens with, byte for byte.
const String _contour = '''
  <svg class="hero__contour" viewBox="0 0 900 500" aria-hidden="true" preserveAspectRatio="xMidYMid slice">
    <g fill="none" stroke="currentColor" stroke-width="1">
      <g id="c"><path d="M120 250c40-95 175-160 300-150 130 10 235 78 268 165 30 80-25 160-140 186-140 32-300 10-378-62-52-48-72-99-50-139z"/></g>
      <use href="#c" transform="translate(450 250) scale(.86) translate(-450 -250)"/>
      <use href="#c" transform="translate(450 250) scale(.72) translate(-450 -250)"/>
      <use href="#c" transform="translate(450 250) scale(.58) translate(-450 -250)"/>
      <use href="#c" transform="translate(450 250) scale(.44) translate(-450 -250)"/>
      <use href="#c" transform="translate(450 250) scale(.30) translate(-450 -250)"/>
      <use href="#c" transform="translate(450 250) scale(.17) translate(-450 -250)"/>
    </g>
  </svg>''';

const String _favicon =
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' "
    "viewBox='0 0 32 32'%3E%3Crect width='32' height='32' fill='%23E4E5DF'/%3E"
    "%3Ccircle cx='16' cy='16' r='4' fill='none' stroke='%23A82D17' "
    "stroke-width='1.5'/%3E%3Ccircle cx='16' cy='16' r='9' fill='none' "
    "stroke='%23A82D17' stroke-width='1.2' opacity='.6'/%3E%3Ccircle cx='16' "
    "cy='16' r='14' fill='none' stroke='%23A82D17' stroke-width='1' "
    "opacity='.35'/%3E%3C/svg%3E";
