// Exegia -- all Supabase-backed repositories.

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core.dart';
import 'models.dart';

// ---- from auth_repository.dart ----
class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes — sign in, sign out, token refresh.
  /// The UI's top-level auth gate watches this to decide which screen to show.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Result<User>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      final user = response.user;
      if (user == null) {
        return const Result.failure('Sign up did not return a user — check your email to confirm, if confirmation is required.');
      }
      return Result.success(user);
    } on AuthException catch (e) {
      return Result.failure(e.message, e);
    } catch (e) {
      return Result.failure('Sign up failed', e);
    }
  }

  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const Result.failure('Sign in did not return a user');
      }
      return Result.success(user);
    } on AuthException catch (e) {
      return Result.failure(e.message, e);
    } catch (e) {
      return Result.failure('Sign in failed', e);
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Sign out failed', e);
    }
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to send password reset email', e);
    }
  }
}

// ---- from bible_structure_repository.dart ----
class BibleStructureRepository {
  final SupabaseClient _client;
  BibleStructureRepository(this._client);

  Future<Result<List<Book>>> getAllBooks() async {
    try {
      final rows = await _client.from('books').select().order('book_order');
      return Result.success((rows as List).map((r) => Book.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load books', e);
    }
  }

  Future<Result<Book>> getBookByOsisCode(String osisCode) async {
    try {
      final row = await _client.from('books').select().eq('osis_code', osisCode).single();
      return Result.success(Book.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load book $osisCode', e);
    }
  }

  Future<Result<List<Verse>>> getVersesForChapter({
    required int bookId,
    required int chapter,
  }) async {
    try {
      final rows = await _client
          .from('verses')
          .select()
          .eq('book_id', bookId)
          .eq('chapter', chapter)
          .order('verse');
      return Result.success((rows as List).map((r) => Verse.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load chapter $bookId:$chapter', e);
    }
  }

  Future<Result<Verse>> getVerseByCanonicalRef(String canonicalRef) async {
    try {
      final row = await _client.from('verses').select().eq('canonical_ref', canonicalRef).single();
      return Result.success(Verse.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load verse $canonicalRef', e);
    }
  }
}

// ---- from context_and_crossref_repository.dart ----
class ContextCardRepository {
  final SupabaseClient _client;
  ContextCardRepository(this._client);

  /// Context cards for a book, optionally narrowed to a chapter — a card may
  /// cover a chapter range (chapterStart/chapterEnd), so this returns every
  /// card whose range includes the given chapter, not just an exact match.
  Future<Result<List<ContextCard>>> getForBookAndChapter({
    required int bookId,
    int? chapter,
  }) async {
    try {
      var query = _client.from('context_cards').select().eq('book_id', bookId);
      final rows = await query;
      var cards = (rows as List).map((r) => ContextCard.fromJson(r)).toList();
      if (chapter != null) {
        cards = cards.where((c) {
          final start = c.chapterStart ?? 1;
          final end = c.chapterEnd ?? 999;
          return chapter >= start && chapter <= end;
        }).toList();
      }
      return Result.success(cards);
    } catch (e) {
      return Result.failure('Failed to load context cards for book $bookId', e);
    }
  }

  Future<Result<Commentary>> getCommentary(int commentaryId) async {
    try {
      final row = await _client.from('commentaries').select().eq('id', commentaryId).single();
      return Result.success(Commentary.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load commentary $commentaryId', e);
    }
  }
}

class CrossReferenceRepository {
  final SupabaseClient _client;
  CrossReferenceRepository(this._client);

  /// TSK cross-references originating from a verse, best matches first.
  Future<Result<List<CrossReference>>> getFromVerse(int verseId, {int limit = 50}) async {
    try {
      final rows = await _client
          .from('cross_references')
          .select()
          .eq('from_verse_id', verseId)
          .order('relevance_rank', ascending: false)
          .limit(limit);
      return Result.success((rows as List).map((r) => CrossReference.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load cross-references for verse $verseId', e);
    }
  }
}

// ---- from lexicon_repository.dart ----
class LexiconRepository {
  final SupabaseClient _client;
  LexiconRepository(this._client);

  /// Gets one lexicon entry by its database id — used when a WordOccurrence
  /// already carries a lexiconEntryId (the common tap-to-lookup path).
  Future<Result<LexiconEntry>> getById(int id) async {
    try {
      final row = await _client.from('lexicon_entries').select().eq('id', id).single();
      return Result.success(LexiconEntry.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load lexicon entry $id', e);
    }
  }

  /// Gets every lexicon entry across sources (Strong's/BDB/Thayer's) for a
  /// given Strong's number — used to show all available scholarly cross-
  /// references for one word, e.g. Strong's H0430 alongside its BDB article.
  Future<Result<List<LexiconEntry>>> getAllForStrongNumber(String strongNumber) async {
    try {
      final rows = await _client.from('lexicon_entries').select().eq('strong_number', strongNumber);
      return Result.success((rows as List).map((r) => LexiconEntry.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load lexicon entries for $strongNumber', e);
    }
  }

  /// Fuzzy headword search — powers a "search the lexicon directly" screen,
  /// independent of tapping a word in a verse.
  Future<Result<List<LexiconEntry>>> searchByHeadword(String query, {int limit = 20}) async {
    try {
      final rows = await _client
          .from('lexicon_entries')
          .select()
          .ilike('headword', '%$query%')
          .limit(limit);
      return Result.success((rows as List).map((r) => LexiconEntry.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Lexicon search failed for "$query"', e);
    }
  }

  Future<Result<List<PronunciationAudio>>> getPronunciations(int lexiconEntryId) async {
    try {
      final rows =
          await _client.from('pronunciation_audio').select().eq('lexicon_entry_id', lexiconEntryId);
      return Result.success((rows as List).map((r) => PronunciationAudio.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load pronunciation audio for $lexiconEntryId', e);
    }
  }
}

// ---- from manuscript_repository.dart ----
class ManuscriptRepository {
  final SupabaseClient _client;
  ManuscriptRepository(this._client);

  /// Powers the manuscript-comparison slider: all real published texts for
  /// one verse, side by side (Hebrew/Greek/Latin/KJV — whichever exist).
  Future<Result<List<ManuscriptText>>> getManuscriptsForVerse(int verseId) async {
    try {
      final rows = await _client.from('manuscript_texts').select().eq('verse_id', verseId);
      return Result.success((rows as List).map((r) => ManuscriptText.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load manuscript texts for verse $verseId', e);
    }
  }

  /// Powers tap-to-lookup: ordered words for one verse in one original-
  /// language manuscript, each carrying its lexicon link (or null if this
  /// word hasn't been linked yet — surfaced honestly, not hidden).
  Future<Result<List<WordOccurrence>>> getWordsForVerse({
    required int verseId,
    required ManuscriptSource manuscriptSource,
  }) async {
    try {
      final rows = await _client
          .from('word_occurrences')
          .select()
          .eq('verse_id', verseId)
          .eq('manuscript_source', manuscriptSourceToString(manuscriptSource))
          .order('word_order');
      return Result.success((rows as List).map((r) => WordOccurrence.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load words for verse $verseId', e);
    }
  }
}

// ---- from maps_and_ocr_repository.dart ----
class MapsRepository {
  final SupabaseClient _client;
  MapsRepository(this._client);

  Future<Result<Journey>> getJourney(int journeyId) async {
    try {
      final row = await _client.from('journeys').select().eq('id', journeyId).single();
      return Result.success(Journey.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load journey $journeyId', e);
    }
  }

  Future<Result<List<Journey>>> getAllJourneys() async {
    try {
      final rows = await _client.from('journeys').select();
      return Result.success((rows as List).map((r) => Journey.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load journeys', e);
    }
  }

  /// Stops in order, each carrying its own location and (if known) the verse
  /// reference that mentions it — this is what draws Paul's journey on a map.
  Future<Result<List<JourneyStop>>> getStopsForJourney(int journeyId) async {
    try {
      final rows = await _client
          .from('journey_stops')
          .select()
          .eq('journey_id', journeyId)
          .order('stop_order');
      return Result.success((rows as List).map((r) => JourneyStop.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load stops for journey $journeyId', e);
    }
  }

  Future<Result<MapLocation>> getLocation(int locationId) async {
    try {
      final row = await _client.from('map_locations').select().eq('id', locationId).single();
      return Result.success(MapLocation.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load location $locationId', e);
    }
  }
}

class OcrRepository {
  final SupabaseClient _client;
  OcrRepository(this._client);

  static const _bucket = 'ocr-scans'; // ASSUMPTION — create this bucket before use.

  /// Uploads a photo of a physical Bible page, creates the ocr_scans row.
  /// Actual OCR text extraction happens server-side (Edge Function or your
  /// backend) — this only handles the client upload half, same pattern as
  /// SermonRepository.uploadSermon.
  Future<Result<OcrScan>> submitScan(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Must be signed in to submit a scan');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
      final storagePath = '$userId/$fileName';

      await _client.storage.from(_bucket).upload(storagePath, imageFile);
      final imageUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

      final row = await _client
          .from('ocr_scans')
          .insert({'user_id': userId, 'image_url': imageUrl})
          .select()
          .single();

      return Result.success(OcrScan.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to submit scan', e);
    }
  }

  Future<Result<OcrScan>> getScanResult(int scanId) async {
    try {
      final row = await _client.from('ocr_scans').select().eq('id', scanId).single();
      return Result.success(OcrScan.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load scan result $scanId', e);
    }
  }
}

// ---- from profile_repository.dart ----
class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<Result<Profile>> getCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Not signed in');
      }
      final row = await _client.from('profiles').select().eq('id', userId).single();
      return Result.success(Profile.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load profile', e);
    }
  }

  Future<Result<Profile>> updatePreferredLanguage(PreferredLanguage language) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Not signed in');
      }
      final row = await _client
          .from('profiles')
          .update({'preferred_language': preferredLanguageToString(language)})
          .eq('id', userId)
          .select()
          .single();
      return Result.success(Profile.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to update preferred language', e);
    }
  }

  Future<Result<Profile>> markOfflinePackDownloaded() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Not signed in');
      }
      final row = await _client
          .from('profiles')
          .update({'offline_pack_downloaded': true})
          .eq('id', userId)
          .select()
          .single();
      return Result.success(Profile.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to update offline pack status', e);
    }
  }
}

// ---- from sermon_repository.dart ----
class SermonRepository {
  final SupabaseClient _client;
  SermonRepository(this._client);

  /// Storage bucket name — ASSUMPTION, not verified against a real bucket:
  /// create a 'sermon-audio' bucket in your Supabase project's Storage
  /// section before this will work, with an RLS policy restricting each
  /// user to their own folder (e.g. path prefixed by their user id).
  static const _bucket = 'sermon-audio';

  /// Uploads the raw audio file to Storage, then creates the sermon_uploads
  /// row. Transcription itself happens server-side (a Supabase Edge Function
  /// or your own backend calling Whisper) — this repository only handles the
  /// client-side upload + row creation, matching how the schema separates
  /// "uploaded" from "transcribed"/"analyzed" status.
  Future<Result<SermonUpload>> uploadSermon(File audioFile, {int? durationSeconds}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Must be signed in to upload a sermon');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${audioFile.uri.pathSegments.last}';
      final storagePath = '$userId/$fileName';

      await _client.storage.from(_bucket).upload(storagePath, audioFile);
      final audioUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

      final row = await _client
          .from('sermon_uploads')
          .insert({
            'user_id': userId,
            'audio_url': audioUrl,
            if (durationSeconds != null) 'duration_seconds': durationSeconds,
            'status': 'uploaded',
          })
          .select()
          .single();

      return Result.success(SermonUpload.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to upload sermon', e);
    }
  }

  /// Poll this after upload to watch status move
  /// uploaded -> transcribing -> transcribed -> analyzed (set by your backend
  /// processing pipeline, not by the client).
  Future<Result<SermonUpload>> getStatus(int sermonUploadId) async {
    try {
      final row = await _client.from('sermon_uploads').select().eq('id', sermonUploadId).single();
      return Result.success(SermonUpload.fromJson(row));
    } catch (e) {
      return Result.failure('Failed to load sermon status $sermonUploadId', e);
    }
  }

  /// Once status is 'analyzed', this returns the verses the backend detected
  /// in the transcript — each with its timestamp in the audio, so the UI can
  /// jump straight to that moment. Never includes any judgment on the
  /// sermon's content, per the "we don't say your pastor is wrong" principle
  /// — that's enforced by what the backend writes here, not by this repo,
  /// but worth remembering when building the screen that renders this.
  Future<Result<List<SermonVerseExtraction>>> getVerseExtractions(int sermonUploadId) async {
    try {
      final rows = await _client
          .from('sermon_verse_extractions')
          .select()
          .eq('sermon_upload_id', sermonUploadId)
          .order('timestamp_seconds');
      return Result.success((rows as List).map((r) => SermonVerseExtraction.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load verse extractions for sermon $sermonUploadId', e);
    }
  }

  Future<Result<List<SermonUpload>>> getMyUploads() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure('Must be signed in');
      }
      final rows = await _client
          .from('sermon_uploads')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return Result.success((rows as List).map((r) => SermonUpload.fromJson(r)).toList());
    } catch (e) {
      return Result.failure('Failed to load your sermon uploads', e);
    }
  }
}

// ---- from translation_repository.dart ----
class TranslationRepository {
  final SupabaseClient _client;
  TranslationRepository(this._client);

  /// Gets the translation for a verse in a given language, if one exists.
  /// Returns null (wrapped in Success) rather than failing when there's
  /// simply no translation yet — that's a real, distinct state from an error,
  /// and the UI should be able to tell "not translated yet" apart from
  /// "something went wrong fetching it."
  Future<Result<Translation?>> getForVerse({
    required int verseId,
    required TranslationLanguage language,
  }) async {
    try {
      final rows = await _client
          .from('translations')
          .select()
          .eq('verse_id', verseId)
          .eq('language', translationLanguageToString(language))
          .limit(1);
      final list = rows as List;
      return Result.success(list.isEmpty ? null : Translation.fromJson(list.first));
    } catch (e) {
      return Result.failure('Failed to load translation for verse $verseId', e);
    }
  }

  Future<Result<Translation?>> getForContextCard({
    required int contextCardId,
    required TranslationLanguage language,
  }) async {
    try {
      final rows = await _client
          .from('translations')
          .select()
          .eq('context_card_id', contextCardId)
          .eq('language', translationLanguageToString(language))
          .limit(1);
      final list = rows as List;
      return Result.success(list.isEmpty ? null : Translation.fromJson(list.first));
    } catch (e) {
      return Result.failure('Failed to load translation for context card $contextCardId', e);
    }
  }

  Future<Result<Translation?>> getForLexiconEntry({
    required int lexiconEntryId,
    required TranslationLanguage language,
  }) async {
    try {
      final rows = await _client
          .from('translations')
          .select()
          .eq('lexicon_entry_id', lexiconEntryId)
          .eq('language', translationLanguageToString(language))
          .limit(1);
      final list = rows as List;
      return Result.success(list.isEmpty ? null : Translation.fromJson(list.first));
    } catch (e) {
      return Result.failure('Failed to load translation for lexicon entry $lexiconEntryId', e);
    }
  }

  /// Submits a user correction/flag on an AI-generated translation — the
  /// trust-loop feature. Requires the user to be signed in (RLS enforces
  /// auth.uid() = user_id on insert, matching the schema's policy).
  Future<Result<void>> flagTranslation({
    required int translationId,
    required String reason,
    String? suggestedCorrection,
  }) async {
    try {
      await _client.from('translation_flags').insert({
        'translation_id': translationId,
        'reason': reason,
        if (suggestedCorrection != null) 'suggested_correction': suggestedCorrection,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to submit flag for translation $translationId', e);
    }
  }
}
