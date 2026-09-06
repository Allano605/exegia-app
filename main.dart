// Exegia -- app entrypoint.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core.dart';
import 'screens_auth.dart';
import 'screens_verse.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ExegiaSupabase.init(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: ExegiaApp()));
}

class ExegiaApp extends StatelessWidget {
  const ExegiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exegia',
      home: AuthGate(
        homeScreen: const BookListScreen(),
      ),
    );
  }
}
