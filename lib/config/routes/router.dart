import 'package:devotion/core/common/navigation/main_layout.dart';
import 'package:devotion/core/providers/audio_screen.dart';
import 'package:devotion/features/Q&A/presentation/screens/question_page.dart';
import 'package:devotion/features/articles/presentation/screens/article_screen.dart';
import 'package:devotion/features/audio/presentation/screens/audio_list_page.dart';
import 'package:devotion/features/auth/presentation/screen/home_screen.dart';
import 'package:devotion/features/auth/presentation/screen/login_screen.dart';
import 'package:devotion/features/auth/presentation/screen/sign_up.dart';
import 'package:devotion/features/books/presentation/screen/book_screen.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

final loggedOutRoute = RouteMap(routes: {
  '/': (_) => const MaterialPage(child: SignUpScreen()),
  '/login': (_) => const MaterialPage(child: LoginScreen()),
  //'/signup': (_) => const MaterialPage(child: SignUpScreen()),
  '/signup': (_) => const MaterialPage(child: SignUpScreen()),
  '/homeScreen': (_) => MaterialPage(child: HomeScreen()),
});

final loggedInRoute = RouteMap(
  routes: {
    '/': (_) => MaterialPage(child: MainLayout()),
    '/home': (_) => const MaterialPage(child: HomeScreen()),
    '/audio': (_) => const MaterialPage(child: AudioScreen()),
    '/devotion': (_) => const MaterialPage(child: DevotionPage()),
    '/articles': (_) => MaterialPage(child: ArticlePage()),
    '/books': (_) => MaterialPage(child: BookScreen()),
    '/questions': (_) => const MaterialPage(child: QuestionPage()),
  },
);
