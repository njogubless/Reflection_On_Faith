import 'package:flutter/material.dart';

/// Branded loading visual shown from `main.dart` while the initial
/// Firebase auth check (and, if signed in, the user profile fetch) is in
/// flight — replaces a bare `CircularProgressIndicator` on a blank screen.
///
/// This used to be a full screen with its own 3-second `Future.delayed`
/// timer and its own navigation decision (built in `build()`, not
/// `initState()`, so it could re-arm on every rebuild) — and that decision
/// was inverted: it sent an already-signed-in user to `LoginScreen` and a
/// signed-out user to `SignUpScreen`. It was never actually routed to
/// anywhere in the app, so none of that ever ran. `main.dart` already
/// reactively switches routes the moment Firebase's auth state resolves
/// (see `MyApp.build`), which is the correct way to do this — this widget
/// is now just what's on screen while that resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/flower.jpg', fit: BoxFit.cover),
          // Scrim so the title/spinner stay legible regardless of what's
          // underneath them in the source image.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black38, Colors.black54],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reflections on Faith',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
