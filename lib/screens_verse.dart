// Exegia -- book/chapter/verse browsing, manuscript comparison, and word lookup.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'providers.dart';

// ---- from word_lookup_sheet.dart ----
/// Call this from anywhere a tappable original-language word exists.
/// Shows the real Strong's/BDB/Thayer's definition(s) for that word --
/// never an AI-generated guess, per the app's core "no AI invention" promise
/// for this layer.
Future<void> showWordLookupSheet(BuildContext context, int? lexiconEntryId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => WordLookupSheet(lexiconEntryId: lexiconEntryId),
  );
}

class WordLookupSheet extends ConsumerWidget {
  final int? lexiconEntryId;
  const WordLookupSheet({super.key, required this.lexiconEntryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lexiconEntryId == null) {
      return const _SheetScaffold(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "This word hasn't been linked to a lexicon entry yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final entryAsync = ref.watch(lexiconEntryByIdProvider(lexiconEntryId));
    // Also fetch sibling entries (e.g. BDB alongside Strong's) for the same
    // Strong's number, once the primary entry resolves.
    return entryAsync.when(
      data: (entry) {
        if (entry == null) {
          return const _SheetScaffold(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text("Lexicon entry not found."),
            ),
          );
        }
        return _LexiconEntryView(primaryEntry: entry);
      },
      loading: () => const _SheetScaffold(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => _SheetScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load definition: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _LexiconEntryView extends ConsumerWidget {
  final LexiconEntry primaryEntry;
  const _LexiconEntryView({required this.primaryEntry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntriesAsync = ref.watch(lexiconEntriesForStrongNumberProvider(primaryEntry.strongNumber));

    return _SheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  primaryEntry.headword,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    primaryEntry.strongNumber,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
            ),
            if (primaryEntry.transliteration != null) ...[
              const SizedBox(height: 4),
              Text(
                primaryEntry.transliteration!,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 20),
            allEntriesAsync.when(
              data: (entries) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((e) => _SourceDefinitionBlock(entry: e)).toList(),
              ),
              loading: () => _SourceDefinitionBlock(entry: primaryEntry),
              error: (_, __) => _SourceDefinitionBlock(entry: primaryEntry),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceDefinitionBlock extends StatelessWidget {
  final LexiconEntry entry;
  const _SourceDefinitionBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lexiconSourceLabel(entry.source),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blueGrey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(entry.fullDefinition, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final Widget child;
  const _SheetScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ---- from verse_detail_screen.dart ----
/// The core screen: real manuscript texts for one verse, side by side via
/// tabs, with tap-to-lookup on every original-language word. Every text
/// shown here comes directly from `manuscript_texts` -- nothing on this
/// screen is AI-generated, matching the app's Tier 1 promise.
class VerseDetailScreen extends ConsumerWidget {
  final int verseId;
  final String canonicalRef; // e.g. "GEN.1.1", shown in the app bar

  const VerseDetailScreen({
    super.key,
    required this.verseId,
    required this.canonicalRef,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuscriptsAsync = ref.watch(manuscriptsForVerseProvider(verseId));

    return Scaffold(
      appBar: AppBar(title: Text(canonicalRef)),
      body: manuscriptsAsync.when(
        data: (manuscripts) {
          if (manuscripts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No manuscript texts found for this verse yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          const order = [
            ManuscriptSource.hebrewLeningrad,
            ManuscriptSource.greekSblgnt,
            ManuscriptSource.latinVulgate,
            ManuscriptSource.kjv,
          ];
          final sorted = [...manuscripts]
            ..sort((a, b) => order.indexOf(a.source).compareTo(order.indexOf(b.source)));

          return DefaultTabController(
            length: sorted.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: sorted.map((m) => Tab(text: manuscriptSourceLabel(m.source))).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: sorted.map((m) => _ManuscriptTab(verseId: verseId, manuscript: m)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load this verse: $error', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

class _ManuscriptTab extends ConsumerWidget {
  final int verseId;
  final ManuscriptText manuscript;
  const _ManuscriptTab({required this.verseId, required this.manuscript});

  bool get _isOriginalLanguage =>
      manuscript.source == ManuscriptSource.hebrewLeningrad || manuscript.source == ManuscriptSource.greekSblgnt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOriginalLanguage)
            _TappableWords(verseId: verseId, source: manuscript.source)
          else
            SelectableText(
              manuscript.textContent,
              style: const TextStyle(fontSize: 20, height: 1.6),
            ),
          const SizedBox(height: 20),
          if (manuscript.sourceEdition != null)
            Text(
              manuscript.sourceEdition!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          if (_isOriginalLanguage) ...[
            const SizedBox(height: 4),
            Text(
              "Tap any word for its real Strong's / BDB definition.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _TappableWords extends ConsumerWidget {
  final int verseId;
  final ManuscriptSource source;
  const _TappableWords({required this.verseId, required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsForVerseProvider((verseId: verseId, source: source)));

    return wordsAsync.when(
      data: (words) {
        if (words.isEmpty) {
          return const Text('No word-level data available for this manuscript yet.');
        }
        final isRtl = source == ManuscriptSource.hebrewLeningrad;
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Wrap(
            spacing: 6,
            runSpacing: 10,
            children: words.map((word) {
              return InkWell(
                onTap: () => showWordLookupSheet(context, word.lexiconEntryId),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: word.hasLexiconLink ? Colors.blue.shade200 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    word.surfaceForm,
                    style: const TextStyle(fontSize: 22, height: 1.8),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Failed to load words: $error', style: const TextStyle(color: Colors.red)),
    );
  }
}

// ---- from book_list_screen.dart ----
class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exegia')),
      body: booksAsync.when(
        data: (books) => ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              title: Text(book.nameEn),
              subtitle: Text('${book.chapterCount} chapters'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChapterListScreen(book: book)),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load books: $error')),
      ),
    );
  }
}

class ChapterListScreen extends StatelessWidget {
  final Book book;
  const ChapterListScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.nameEn)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: book.chapterCount,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerseListScreen(book: book, chapter: chapter),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('$chapter'),
            ),
          );
        },
      ),
    );
  }
}

class VerseListScreen extends ConsumerWidget {
  final Book book;
  final int chapter;
  const VerseListScreen({super.key, required this.book, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(versesForChapterProvider((bookId: book.id, chapter: chapter)));

    return Scaffold(
      appBar: AppBar(title: Text('${book.nameEn} $chapter')),
      body: versesAsync.when(
        data: (verses) => ListView.builder(
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final verse = verses[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${verse.verse}')),
              title: Text(verse.canonicalRef),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VerseDetailScreen(
                    verseId: verse.id,
                    canonicalRef: verse.canonicalRef,
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load verses: $error')),
      ),
    );
  }
}
