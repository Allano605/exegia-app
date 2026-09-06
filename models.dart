// Exegia -- all data models, matching exegia_schema.sql field-for-field.

import 'package:equatable/equatable.dart';

// ---- from bible_structure.dart ----
enum Testament { old, newT }

Testament testamentFromString(String value) => switch (value) {
      'old' => Testament.old,
      'new' => Testament.newT,
      _ => throw ArgumentError('Unknown testament value from Supabase: $value'),
    };

String testamentToString(Testament t) => t == Testament.old ? 'old' : 'new';

class Book extends Equatable {
  final int id;
  final Testament testament;
  final int bookOrder;
  final String osisCode;
  final String nameEn;
  final String? nameYo;
  final String? nameIg;
  final String? nameHa;
  final int chapterCount;

  const Book({
    required this.id,
    required this.testament,
    required this.bookOrder,
    required this.osisCode,
    required this.nameEn,
    this.nameYo,
    this.nameIg,
    this.nameHa,
    required this.chapterCount,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        testament: testamentFromString(json['testament'] as String),
        bookOrder: json['book_order'] as int,
        osisCode: json['osis_code'] as String,
        nameEn: json['name_en'] as String,
        nameYo: json['name_yo'] as String?,
        nameIg: json['name_ig'] as String?,
        nameHa: json['name_ha'] as String?,
        chapterCount: json['chapter_count'] as int,
      );

  /// Returns the display name for a given language, falling back to English
  /// if a translated name hasn't been seeded yet — never silently blank.
  String nameFor(String languageCode) => switch (languageCode) {
        'yo' => nameYo ?? nameEn,
        'ig' => nameIg ?? nameEn,
        'ha' => nameHa ?? nameEn,
        _ => nameEn,
      };

  @override
  List<Object?> get props => [id, testament, bookOrder, osisCode, nameEn, nameYo, nameIg, nameHa, chapterCount];
}

class Verse extends Equatable {
  final int id;
  final int bookId;
  final int chapter;
  final int verse;
  final String canonicalRef;

  const Verse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.canonicalRef,
  });

  factory Verse.fromJson(Map<String, dynamic> json) => Verse(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        canonicalRef: json['canonical_ref'] as String,
      );

  @override
  List<Object?> get props => [id, bookId, chapter, verse, canonicalRef];
}

// ---- from commentary.dart ----
class Commentary extends Equatable {
  final int id;
  final String author;
  final String title;
  final int publicationYear;
  final String? publisher;
  final bool isPublicDomain;
  final String? sourceUrl;

  const Commentary({
    required this.id,
    required this.author,
    required this.title,
    required this.publicationYear,
    this.publisher,
    required this.isPublicDomain,
    this.sourceUrl,
  });

  factory Commentary.fromJson(Map<String, dynamic> json) => Commentary(
        id: json['id'] as int,
        author: json['author'] as String,
        title: json['title'] as String,
        publicationYear: json['publication_year'] as int,
        publisher: json['publisher'] as String?,
        isPublicDomain: json['is_public_domain'] as bool,
        sourceUrl: json['source_url'] as String?,
      );

  @override
  List<Object?> get props => [id, author, title, publicationYear, publisher, isPublicDomain, sourceUrl];
}

class ContextCard extends Equatable {
  final int id;
  final int bookId;
  final int? chapterStart;
  final int? chapterEnd;
  final String? authorOfBook;
  final String? audience;
  final String? dateWritten;
  final String? locationWritten;
  final int? commentaryId;
  final String? citedPage;
  final String contentEn;

  const ContextCard({
    required this.id,
    required this.bookId,
    this.chapterStart,
    this.chapterEnd,
    this.authorOfBook,
    this.audience,
    this.dateWritten,
    this.locationWritten,
    this.commentaryId,
    this.citedPage,
    required this.contentEn,
  });

  factory ContextCard.fromJson(Map<String, dynamic> json) => ContextCard(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        chapterStart: json['chapter_start'] as int?,
        chapterEnd: json['chapter_end'] as int?,
        authorOfBook: json['author_of_book'] as String?,
        audience: json['audience'] as String?,
        dateWritten: json['date_written'] as String?,
        locationWritten: json['location_written'] as String?,
        commentaryId: json['commentary_id'] as int?,
        citedPage: json['cited_page'] as String?,
        contentEn: json['content_en'] as String,
      );

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterStart,
        chapterEnd,
        authorOfBook,
        audience,
        dateWritten,
        locationWritten,
        commentaryId,
        citedPage,
        contentEn,
      ];
}

// ---- from cross_reference.dart ----
class CrossReference extends Equatable {
  final int id;
  final int fromVerseId;
  final int toVerseId;
  final String source;
  final int? relevanceRank;

  const CrossReference({
    required this.id,
    required this.fromVerseId,
    required this.toVerseId,
    required this.source,
    this.relevanceRank,
  });

  factory CrossReference.fromJson(Map<String, dynamic> json) => CrossReference(
        id: json['id'] as int,
        fromVerseId: json['from_verse_id'] as int,
        toVerseId: json['to_verse_id'] as int,
        source: json['source'] as String,
        relevanceRank: json['relevance_rank'] as int?,
      );

  @override
  List<Object?> get props => [id, fromVerseId, toVerseId, source, relevanceRank];
}

// ---- from lexicon.dart ----
enum LexiconSource { strongs, bdb, thayers }

LexiconSource lexiconSourceFromString(String value) => switch (value) {
      'strongs' => LexiconSource.strongs,
      'bdb' => LexiconSource.bdb,
      'thayers' => LexiconSource.thayers,
      _ => throw ArgumentError('Unknown lexicon source from Supabase: $value'),
    };

String lexiconSourceToString(LexiconSource s) => switch (s) {
      LexiconSource.strongs => 'strongs',
      LexiconSource.bdb => 'bdb',
      LexiconSource.thayers => 'thayers',
    };

String lexiconSourceLabel(LexiconSource s) => switch (s) {
      LexiconSource.strongs => "Strong's Concordance",
      LexiconSource.bdb => 'Brown-Driver-Briggs',
      LexiconSource.thayers => "Thayer's Lexicon",
    };

class LexiconEntry extends Equatable {
  final int id;
  final String strongNumber;
  final LexiconSource source;
  final String headword;
  final String? transliteration;
  final String? pronunciationIpa;
  final String? partOfSpeech;
  final String? shortDefinition;
  final String fullDefinition;

  const LexiconEntry({
    required this.id,
    required this.strongNumber,
    required this.source,
    required this.headword,
    this.transliteration,
    this.pronunciationIpa,
    this.partOfSpeech,
    this.shortDefinition,
    required this.fullDefinition,
  });

  factory LexiconEntry.fromJson(Map<String, dynamic> json) => LexiconEntry(
        id: json['id'] as int,
        strongNumber: json['strong_number'] as String,
        source: lexiconSourceFromString(json['source'] as String),
        headword: json['headword'] as String,
        transliteration: json['transliteration'] as String?,
        pronunciationIpa: json['pronunciation_ipa'] as String?,
        partOfSpeech: json['part_of_speech'] as String?,
        shortDefinition: json['short_definition'] as String?,
        fullDefinition: json['full_definition'] as String,
      );

  @override
  List<Object?> get props => [
        id,
        strongNumber,
        source,
        headword,
        transliteration,
        pronunciationIpa,
        partOfSpeech,
        shortDefinition,
        fullDefinition,
      ];
}

class PronunciationAudio extends Equatable {
  final int id;
  final int lexiconEntryId;
  final String audioUrl;
  final String? dialect;
  final String sourceInstitution;

  const PronunciationAudio({
    required this.id,
    required this.lexiconEntryId,
    required this.audioUrl,
    this.dialect,
    required this.sourceInstitution,
  });

  factory PronunciationAudio.fromJson(Map<String, dynamic> json) => PronunciationAudio(
        id: json['id'] as int,
        lexiconEntryId: json['lexicon_entry_id'] as int,
        audioUrl: json['audio_url'] as String,
        dialect: json['dialect'] as String?,
        sourceInstitution: json['source_institution'] as String,
      );

  @override
  List<Object?> get props => [id, lexiconEntryId, audioUrl, dialect, sourceInstitution];
}

// ---- from manuscript.dart ----
/// Matches the `manuscript_source` Postgres enum exactly.
enum ManuscriptSource { hebrewLeningrad, greekSblgnt, latinVulgate, kjv }

ManuscriptSource manuscriptSourceFromString(String value) => switch (value) {
      'hebrew_leningrad' => ManuscriptSource.hebrewLeningrad,
      'greek_sblgnt' => ManuscriptSource.greekSblgnt,
      'latin_vulgate' => ManuscriptSource.latinVulgate,
      'kjv' => ManuscriptSource.kjv,
      _ => throw ArgumentError('Unknown manuscript_source from Supabase: $value'),
    };

String manuscriptSourceToString(ManuscriptSource s) => switch (s) {
      ManuscriptSource.hebrewLeningrad => 'hebrew_leningrad',
      ManuscriptSource.greekSblgnt => 'greek_sblgnt',
      ManuscriptSource.latinVulgate => 'latin_vulgate',
      ManuscriptSource.kjv => 'kjv',
    };

/// Human-readable label for the manuscript-comparison slider UI.
String manuscriptSourceLabel(ManuscriptSource s) => switch (s) {
      ManuscriptSource.hebrewLeningrad => 'Hebrew (Leningrad Codex)',
      ManuscriptSource.greekSblgnt => 'Greek (SBLGNT)',
      ManuscriptSource.latinVulgate => 'Latin (Vulgate)',
      ManuscriptSource.kjv => 'English (KJV)',
    };

class ManuscriptText extends Equatable {
  final int id;
  final int verseId;
  final ManuscriptSource source;
  final String textContent;
  final String? sourceEdition;
  final String? licenseNote;

  const ManuscriptText({
    required this.id,
    required this.verseId,
    required this.source,
    required this.textContent,
    this.sourceEdition,
    this.licenseNote,
  });

  factory ManuscriptText.fromJson(Map<String, dynamic> json) => ManuscriptText(
        id: json['id'] as int,
        verseId: json['verse_id'] as int,
        source: manuscriptSourceFromString(json['source'] as String),
        textContent: json['text_content'] as String,
        sourceEdition: json['source_edition'] as String?,
        licenseNote: json['license_note'] as String?,
      );

  @override
  List<Object?> get props => [id, verseId, source, textContent, sourceEdition, licenseNote];
}

class WordOccurrence extends Equatable {
  final int id;
  final int verseId;
  final ManuscriptSource manuscriptSource;
  final int wordOrder;
  final String surfaceForm;
  final int? lexiconEntryId;

  const WordOccurrence({
    required this.id,
    required this.verseId,
    required this.manuscriptSource,
    required this.wordOrder,
    required this.surfaceForm,
    this.lexiconEntryId,
  });

  factory WordOccurrence.fromJson(Map<String, dynamic> json) => WordOccurrence(
        id: json['id'] as int,
        verseId: json['verse_id'] as int,
        manuscriptSource: manuscriptSourceFromString(json['manuscript_source'] as String),
        wordOrder: json['word_order'] as int,
        surfaceForm: json['surface_form'] as String,
        lexiconEntryId: json['lexicon_entry_id'] as int?,
      );

  /// True when this word has no linked lexicon entry — the UI should show a
  /// clear "not yet linked" state rather than a silently blank tap target.
  bool get hasLexiconLink => lexiconEntryId != null;

  @override
  List<Object?> get props => [id, verseId, manuscriptSource, wordOrder, surfaceForm, lexiconEntryId];
}

// ---- from maps_and_ocr.dart ----
class OcrScan extends Equatable {
  final int id;
  final String? userId;
  final String imageUrl;
  final int? detectedVerseId;
  final String? rawOcrText;
  final double? confidence;
  final DateTime? createdAt;

  const OcrScan({
    required this.id,
    this.userId,
    required this.imageUrl,
    this.detectedVerseId,
    this.rawOcrText,
    this.confidence,
    this.createdAt,
  });

  factory OcrScan.fromJson(Map<String, dynamic> json) => OcrScan(
        id: json['id'] as int,
        userId: json['user_id'] as String?,
        imageUrl: json['image_url'] as String,
        detectedVerseId: json['detected_verse_id'] as int?,
        rawOcrText: json['raw_ocr_text'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, userId, imageUrl, detectedVerseId, rawOcrText, confidence, createdAt];
}

class MapLocation extends Equatable {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final String source;

  const MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.source,
  });

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        description: json['description'] as String?,
        source: json['source'] as String,
      );

  @override
  List<Object?> get props => [id, name, latitude, longitude, description, source];
}

class Journey extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? source;

  const Journey({
    required this.id,
    required this.name,
    this.description,
    this.source,
  });

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        source: json['source'] as String?,
      );

  @override
  List<Object?> get props => [id, name, description, source];
}

class JourneyStop extends Equatable {
  final int id;
  final int journeyId;
  final int locationId;
  final int stopOrder;
  final String? verseReference;

  const JourneyStop({
    required this.id,
    required this.journeyId,
    required this.locationId,
    required this.stopOrder,
    this.verseReference,
  });

  factory JourneyStop.fromJson(Map<String, dynamic> json) => JourneyStop(
        id: json['id'] as int,
        journeyId: json['journey_id'] as int,
        locationId: json['location_id'] as int,
        stopOrder: json['stop_order'] as int,
        verseReference: json['verse_reference'] as String?,
      );

  @override
  List<Object?> get props => [id, journeyId, locationId, stopOrder, verseReference];
}

// ---- from profile.dart ----
enum PreferredLanguage { en, yo, ig, ha }

PreferredLanguage preferredLanguageFromString(String value) => switch (value) {
      'en' => PreferredLanguage.en,
      'yo' => PreferredLanguage.yo,
      'ig' => PreferredLanguage.ig,
      'ha' => PreferredLanguage.ha,
      _ => throw ArgumentError('Unknown language_code from Supabase: $value'),
    };

String preferredLanguageToString(PreferredLanguage l) => switch (l) {
      PreferredLanguage.en => 'en',
      PreferredLanguage.yo => 'yo',
      PreferredLanguage.ig => 'ig',
      PreferredLanguage.ha => 'ha',
    };

class Profile extends Equatable {
  final String id; // matches auth.users.id (uuid)
  final PreferredLanguage preferredLanguage;
  final String? displayName;
  final bool offlinePackDownloaded;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.preferredLanguage,
    this.displayName,
    required this.offlinePackDownloaded,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        preferredLanguage: preferredLanguageFromString(json['preferred_language'] as String),
        displayName: json['display_name'] as String?,
        offlinePackDownloaded: json['offline_pack_downloaded'] as bool,
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, preferredLanguage, displayName, offlinePackDownloaded, createdAt];
}

// ---- from sermon.dart ----
enum SermonStatus { uploaded, transcribing, transcribed, analyzed, failed }

SermonStatus sermonStatusFromString(String value) => switch (value) {
      'uploaded' => SermonStatus.uploaded,
      'transcribing' => SermonStatus.transcribing,
      'transcribed' => SermonStatus.transcribed,
      'analyzed' => SermonStatus.analyzed,
      'failed' => SermonStatus.failed,
      _ => throw ArgumentError('Unknown sermon_status from Supabase: $value'),
    };

String sermonStatusToString(SermonStatus s) => switch (s) {
      SermonStatus.uploaded => 'uploaded',
      SermonStatus.transcribing => 'transcribing',
      SermonStatus.transcribed => 'transcribed',
      SermonStatus.analyzed => 'analyzed',
      SermonStatus.failed => 'failed',
    };

class SermonUpload extends Equatable {
  final int id;
  final String? userId;
  final String audioUrl;
  final int? durationSeconds;
  final SermonStatus status;
  final String? transcriptText;
  final String transcriptLanguage;
  final DateTime? createdAt;

  const SermonUpload({
    required this.id,
    this.userId,
    required this.audioUrl,
    this.durationSeconds,
    required this.status,
    this.transcriptText,
    required this.transcriptLanguage,
    this.createdAt,
  });

  factory SermonUpload.fromJson(Map<String, dynamic> json) => SermonUpload(
        id: json['id'] as int,
        userId: json['user_id'] as String?,
        audioUrl: json['audio_url'] as String,
        durationSeconds: json['duration_seconds'] as int?,
        status: sermonStatusFromString(json['status'] as String),
        transcriptText: json['transcript_text'] as String?,
        transcriptLanguage: json['transcript_language'] as String? ?? 'en',
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props =>
      [id, userId, audioUrl, durationSeconds, status, transcriptText, transcriptLanguage, createdAt];
}

class SermonVerseExtraction extends Equatable {
  final int id;
  final int sermonUploadId;
  final int? verseId;
  final String matchedText;
  final double? timestampSeconds;
  final double? confidence;

  const SermonVerseExtraction({
    required this.id,
    required this.sermonUploadId,
    this.verseId,
    required this.matchedText,
    this.timestampSeconds,
    this.confidence,
  });

  factory SermonVerseExtraction.fromJson(Map<String, dynamic> json) => SermonVerseExtraction(
        id: json['id'] as int,
        sermonUploadId: json['sermon_upload_id'] as int,
        verseId: json['verse_id'] as int?,
        matchedText: json['matched_text'] as String,
        timestampSeconds: (json['timestamp_seconds'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [id, sermonUploadId, verseId, matchedText, timestampSeconds, confidence];
}

// ---- from translation.dart ----
/// Matches `content_source_type` — this is the field the UI uses to decide
/// whether to show the "AI-assisted" badge. Never hide or default this away.
enum ContentSourceType { scholarly, aiGenerated, humanReviewed }

ContentSourceType contentSourceTypeFromString(String value) => switch (value) {
      'scholarly' => ContentSourceType.scholarly,
      'ai_generated' => ContentSourceType.aiGenerated,
      'human_reviewed' => ContentSourceType.humanReviewed,
      _ => throw ArgumentError('Unknown content_source_type from Supabase: $value'),
    };

String contentSourceTypeToString(ContentSourceType t) => switch (t) {
      ContentSourceType.scholarly => 'scholarly',
      ContentSourceType.aiGenerated => 'ai_generated',
      ContentSourceType.humanReviewed => 'human_reviewed',
    };

/// Only yo/ig/ha are valid here per the schema's CHECK constraint — English
/// content lives directly on the parent record (verse/context_card/lexicon),
/// not in this table.
enum TranslationLanguage { yo, ig, ha }

TranslationLanguage translationLanguageFromString(String value) => switch (value) {
      'yo' => TranslationLanguage.yo,
      'ig' => TranslationLanguage.ig,
      'ha' => TranslationLanguage.ha,
      _ => throw ArgumentError('Unknown translation language from Supabase: $value'),
    };

String translationLanguageToString(TranslationLanguage l) => switch (l) {
      TranslationLanguage.yo => 'yo',
      TranslationLanguage.ig => 'ig',
      TranslationLanguage.ha => 'ha',
    };

enum FlagStatus { open, reviewed, corrected, dismissed }

FlagStatus flagStatusFromString(String value) => switch (value) {
      'open' => FlagStatus.open,
      'reviewed' => FlagStatus.reviewed,
      'corrected' => FlagStatus.corrected,
      'dismissed' => FlagStatus.dismissed,
      _ => throw ArgumentError('Unknown flag_status from Supabase: $value'),
    };

String flagStatusToString(FlagStatus s) => switch (s) {
      FlagStatus.open => 'open',
      FlagStatus.reviewed => 'reviewed',
      FlagStatus.corrected => 'corrected',
      FlagStatus.dismissed => 'dismissed',
    };

class Translation extends Equatable {
  final int id;
  final int? verseId;
  final int? contextCardId;
  final int? lexiconEntryId;
  final TranslationLanguage language;
  final String content;
  final ContentSourceType sourceType;
  final String sourceEnglishText;
  final String? aiModel;
  final DateTime? generatedAt;
  final bool humanReviewed;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final int flagCount;

  const Translation({
    required this.id,
    this.verseId,
    this.contextCardId,
    this.lexiconEntryId,
    required this.language,
    required this.content,
    required this.sourceType,
    required this.sourceEnglishText,
    this.aiModel,
    this.generatedAt,
    required this.humanReviewed,
    this.reviewedBy,
    this.reviewedAt,
    required this.flagCount,
  });

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
        id: json['id'] as int,
        verseId: json['verse_id'] as int?,
        contextCardId: json['context_card_id'] as int?,
        lexiconEntryId: json['lexicon_entry_id'] as int?,
        language: translationLanguageFromString(json['language'] as String),
        content: json['content'] as String,
        sourceType: contentSourceTypeFromString(json['source_type'] as String),
        sourceEnglishText: json['source_english_text'] as String,
        aiModel: json['ai_model'] as String?,
        generatedAt: json['generated_at'] == null ? null : DateTime.parse(json['generated_at'] as String),
        humanReviewed: json['human_reviewed'] as bool,
        reviewedBy: json['reviewed_by'] as String?,
        reviewedAt: json['reviewed_at'] == null ? null : DateTime.parse(json['reviewed_at'] as String),
        flagCount: json['flag_count'] as int,
      );

  /// UI helper: whether to show the "AI-assisted, not yet human-reviewed"
  /// badge. Deliberately conservative — only scholarly content skips the badge.
  bool get needsAiBadge => sourceType != ContentSourceType.scholarly;

  @override
  List<Object?> get props => [
        id,
        verseId,
        contextCardId,
        lexiconEntryId,
        language,
        content,
        sourceType,
        sourceEnglishText,
        aiModel,
        generatedAt,
        humanReviewed,
        reviewedBy,
        reviewedAt,
        flagCount,
      ];
}

class TranslationFlag extends Equatable {
  final int id;
  final int translationId;
  final String? userId;
  final String reason;
  final String? suggestedCorrection;
  final FlagStatus status;
  final DateTime? createdAt;

  const TranslationFlag({
    required this.id,
    required this.translationId,
    this.userId,
    required this.reason,
    this.suggestedCorrection,
    required this.status,
    this.createdAt,
  });

  factory TranslationFlag.fromJson(Map<String, dynamic> json) => TranslationFlag(
        id: json['id'] as int,
        translationId: json['translation_id'] as int,
        userId: json['user_id'] as String?,
        reason: json['reason'] as String,
        suggestedCorrection: json['suggested_correction'] as String?,
        status: flagStatusFromString(json['status'] as String),
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      );

  /// What gets sent on insert — id/status/created_at are server-assigned/defaulted.
  Map<String, dynamic> toInsertJson() => {
        'translation_id': translationId,
        'reason': reason,
        if (suggestedCorrection != null) 'suggested_correction': suggestedCorrection,
      };

  @override
  List<Object?> get props => [id, translationId, userId, reason, suggestedCorrection, status, createdAt];
}
