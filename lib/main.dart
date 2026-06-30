import 'package:devotion/core/common/loader.dart';
import 'package:devotion/core/error/error_text.dart';
import 'package:devotion/features/auth/controller/auth_controller.dart';
import 'package:devotion/firebase_options.dart';
import 'package:devotion/config/routes/router.dart';
import 'package:devotion/theme/theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:routemaster/routemaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider =
    StateProvider<SharedPreferences?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authStateChangeProvider);

    return authState.when(
      // Firebase User stream has emitted — determine which route map to use.
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // Not authenticated — show logged-out routes.
          return _buildApp(themeState.theme, loggedOutRoute);
        }

        // Authenticated — load full UserModel from Firestore.
        return ref.watch(getUserDataProvider(firebaseUser.uid)).when(
              data: (userModel) {
              
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ref.read(userProvider) != userModel) {
                    ref.read(userProvider.notifier).state = userModel;
                  }
                });
                return _buildApp(themeState.theme, loggedInRoute);
              },
              loading: () => _buildLoadingApp(themeState.theme),
              error: (e, _) => _buildErrorApp(e.toString()),
            );
      },
      loading: () => _buildLoadingApp(themeState.theme),
      error: (e, _) => _buildErrorApp(e.toString()),
    );
  }

  MaterialApp _buildApp(ThemeData theme, RouteMap routes) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Reflection On Faith',
      theme: theme,
      routerDelegate: RoutemasterDelegate(routesBuilder: (_) => routes),
      routeInformationParser: const RoutemasterParser(),
    );
  }

  Widget _buildLoadingApp(ThemeData theme) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const Loader(),
    );
  }

  Widget _buildErrorApp(String error) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ErrorText(error: error),
    );
  }
}
