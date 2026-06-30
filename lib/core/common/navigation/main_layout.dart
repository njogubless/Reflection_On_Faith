import 'package:devotion/core/providers/audio_screen.dart';
import 'package:devotion/features/Q&A/presentation/screens/question_page.dart';
import 'package:devotion/features/articles/presentation/screens/article_screen.dart';
import 'package:devotion/features/audio/presentation/screens/audio_list_page.dart';
import 'package:devotion/features/auth/presentation/screen/home_screen.dart';
import 'package:devotion/features/books/presentation/screen/book_screen.dart';
import 'package:devotion/widget/app_drawer.dart';
import 'package:devotion/widget/custom_App_Bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  late List<Widget> _screens;

  int _unreadArticlesCount = 1;

  final List<String> _titles = [
    'Home',
    'Audio',
    'Devotion',
    'Articles',
    'Books',
    'Q&A',
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.audiotrack_rounded,
    Icons.mic_rounded,
    Icons.article_rounded,
    Icons.book_rounded,
    Icons.question_answer_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _screens = [
      const HomeScreen(),
      AudioScreen(),
      const DevotionPage(),
      ArticlePage(),
      BookScreen(),
      const QuestionPage(),
    ];

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animations = List.generate(
      _screens.length,
      (index) => Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index / _screens.length,
            (index + 1) / _screens.length,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 3) {
        _unreadArticlesCount = 0;
      }

      _controller
        ..reset()
        ..forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: CustomAppBar(
        // FIX #7: Title reflects the active tab.
        title: _titles[_selectedIndex],
        screens: _screens,
        selectedIndex: _selectedIndex,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 104, 165, 214).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: _screens[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 5,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            items: List.generate(_screens.length, _buildNavItem),
            selectedItemColor: const Color.fromARGB(255, 82, 169, 240),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(int index) {
    // FIX #1: Badge driven by _unreadArticlesCount state, not a hardcoded '1'.
    final bool showBadge = index == 3 && _unreadArticlesCount > 0;

    return BottomNavigationBarItem(
      icon: ScaleTransition(
        scale: _animations[index],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(_icons[index]),
            if (showBadge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadArticlesCount > 99 ? '99+' : '$_unreadArticlesCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      label: _titles[index],
    );
  }
}
