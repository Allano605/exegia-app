// Exegia -- core utilities: Result type + Supabase client singleton.

import 'package:supabase_flutter/supabase_flutter.dart';

// ---- from result.dart ----
/// A minimal Result type. Repositories return this instead of throwing or
/// returning null-on-error, so the UI layer always has to consciously handle
/// failure — no silent empty states pretending to be "no data" when it was
/// actually a network/auth error. Matches the project's "no fake" principle:
/// don't let a failed fetch quietly look the same as a genuinely empty result.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, [Object? cause]) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        Failure<T>() => null,
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, Object? cause) onFailure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      Failure<T>(message: final m, cause: final c) => onFailure(m, c),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? cause;
  const Failure(this.message, [this.cause]);
}

// ---- from supabase_client.dart ----
/// Initializes the Supabase client once at app startup.
/// Call `await ExegiaSupabase.init(...)` in `main()` before `runApp()`.
class ExegiaSupabase {
  ExegiaSupabase._();

  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Convenience accessor used throughout the repositories.
  static SupabaseClient get client => Supabase.instance.client;
}
