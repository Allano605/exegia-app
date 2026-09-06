// Exegia -- all Riverpod providers (repositories + feature-level data providers + auth state).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core.dart';
import 'models.dart';
import 'repositories.dart';

// ---- from repository_providers.dart ----
/// Single source of truth for the Supabase client — everything else depends
/// on this rather than calling `Supabase.instance.client` directly, so tests
/// can override it with a fake.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final bibleStructureRepositoryProvider = Provider<BibleStructureRepository>(
  (ref) => BibleStructureRepository(ref.watch(supabaseClientProvider)),
);

final manuscriptRepositoryProvider = Provider<ManuscriptRepository>(
  (ref) => ManuscriptRepository(ref.watch(supabaseClientProvider)),
);

final lexiconRepositoryProvider = Provider<LexiconRepository>(
  (ref) => LexiconRepository(ref.watch(supabaseClientProvider)),
);

final contextCardRepositoryProvider = Provider<ContextCardRepository>(
  (ref) => ContextCardRepository(ref.watch(supabaseClientProvider)),
);

final crossReferenceRepositoryProvider = Provider<CrossReferenceRepository>(
  (ref) => CrossReferenceRepository(ref.watch(supabaseClientProvider)),
);

final translationRepositoryProvider = Provider<TranslationRepository>(
  (ref) => TranslationRepository(ref.watch(supabaseClientProvider)),
);

final sermonRepositoryProvider = Provider<SermonRepository>(
  (ref) => SermonRepository(ref.watch(supabaseClientProvider)),
);

final mapsRepositoryProvider = Provider<MapsRepository>(
  (ref) => MapsRepository(ref.watch(supabaseClientProvider)),
);

final ocrRepositoryProvider = Provider<OcrRepository>(
  (ref) => OcrRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

// ---- from data_providers.dart ----
/// Unwraps a Result into a thrown exception carrying the real failure
/// message, so Riverpod's AsyncValue.error shows the actual cause rather
/// than a generic "something went wrong" — consistent with never hiding a
/// real error behind a fake-looking state.
extension _ResultUnwrap<T> on Result<T> {
  T unwrapOrThrow() => fold(
        onSuccess: (data) => data,
        onFailure: (message, cause) => throw Exception('$message${cause != null ? ' ($cause)' : ''}'),
      );
}

// ---------------------------------------------------------------------------
// Books & verses
// ---------------------------------------------------------------------------

final allBooksProvider = FutureProvider<List<Book>>((ref) async {
  final result = await ref.watch(bibleStructureRepositoryProvider).getAllBooks();
  return result.unwrapOrThrow();
});

final bookByOsisProvider = FutureProvider.family<Book, String>((ref, osisCode) async {
  final result = await ref.watch(bibleStructureRepositoryProvider).getBookByOsisCode(osisCode);
  return result.unwrapOrThrow();
});

typedef ChapterKey = ({int bookId, int chapter});

final versesForChapterProvider = FutureProvider.family<List<Verse>, ChapterKey>((ref, key) async {
  final result = await ref
      .watch(bibleStructureRepositoryProvider)
      .getVersesForChapter(bookId: key.bookId, chapter: key.chapter);
  return result.unwrapOrThrow();
});

// ---------------------------------------------------------------------------
// Manuscript comparison + word lookup
// ---------------------------------------------------------------------------

final manuscriptsForVerseProvider = FutureProvider.family<List<ManuscriptText>, int>((ref, verseId) async {
  final result = await ref.watch(manuscriptRepositoryProvider).getManuscriptsForVerse(verseId);
  return result.unwrapOrThrow();
});

typedef WordsKey = ({int verseId, ManuscriptSource source});

final wordsForVerseProvider = FutureProvider.family<List<WordOccurrence>, WordsKey>((ref, key) async {
  final result = await ref
      .watch(manuscriptRepositoryProvider)
      .getWordsForVerse(verseId: key.verseId, manuscriptSource: key.source);
  return result.unwrapOrThrow();
});

/// The core "tap a word" provider: given a WordOccurrence's lexiconEntryId,
/// fetch the real Strong's/BDB/Thayer's definition. Returns null (not an
/// error) when the word has no lexicon link yet — the UI should show "not
/// yet linked" rather than crash or show a fake definition.
final lexiconEntryByIdProvider = FutureProvider.family<LexiconEntry?, int?>((ref, id) async {
  if (id == null) return null;
  final result = await ref.watch(lexiconRepositoryProvider).getById(id);
  return result.unwrapOrThrow();
});

final lexiconEntriesForStrongNumberProvider =
    FutureProvider.family<List<LexiconEntry>, String>((ref, strongNumber) async {
  final result = await ref.watch(lexiconRepositoryProvider).getAllForStrongNumber(strongNumber);
  return result.unwrapOrThrow();
});

// ---------------------------------------------------------------------------
// Context cards + cross-references
// ---------------------------------------------------------------------------

typedef ContextCardKey = ({int bookId, int? chapter});

final contextCardsProvider = FutureProvider.family<List<ContextCard>, ContextCardKey>((ref, key) async {
  final result = await ref
      .watch(contextCardRepositoryProvider)
      .getForBookAndChapter(bookId: key.bookId, chapter: key.chapter);
  return result.unwrapOrThrow();
});

final crossReferencesForVerseProvider = FutureProvider.family<List<CrossReference>, int>((ref, verseId) async {
  final result = await ref.watch(crossReferenceRepositoryProvider).getFromVerse(verseId);
  return result.unwrapOrThrow();
});

// ---------------------------------------------------------------------------
// Translations (AI-assisted language layer)
// ---------------------------------------------------------------------------

typedef VerseTranslationKey = ({int verseId, TranslationLanguage language});

final verseTranslationProvider =
    FutureProvider.family<Translation?, VerseTranslationKey>((ref, key) async {
  final result = await ref
      .watch(translationRepositoryProvider)
      .getForVerse(verseId: key.verseId, language: key.language);
  return result.unwrapOrThrow();
});

// ---- from auth_providers.dart ----
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Live auth state stream — the app's top-level widget watches this to
/// decide whether to show the sign-in screen or the main app.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Convenience: the current signed-in user, or null. Derived from
/// authStateProvider so it updates automatically on sign-in/out.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user) ??
      ref.watch(authRepositoryProvider).currentUser;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
