import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/host/quiz_list_screen.dart';
import '../screens/player/join_game_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/profile_screen.dart';

/// Main navigation wrapper with bottom navigation bar
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = [
    const QuizListScreen(), // Host tab
    const JoinGameScreen(), // Join tab
    const DashboardScreen(), // Stats tab
    const ProfileScreen(), // Profile tab
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      activeIcon: Icons.home,
      label: 'Host',
      tooltip: 'Create and manage quizzes',
    ),
    NavigationItem(
      icon: Icons.games_outlined,
      activeIcon: Icons.games,
      label: 'Join',
      tooltip: 'Join existing games',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Stats',
      tooltip: 'View your statistics',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      tooltip: 'Manage your profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          backgroundColor: Colors.white,
          items: _navigationItems.map((item) {
            final isSelected = _navigationItems.indexOf(item) == _currentIndex;
            return BottomNavigationBarItem(
              icon: Tooltip(
                message: item.tooltip,
                child: Icon(isSelected ? item.activeIcon : item.icon),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}

/// Extension to easily navigate to specific tabs
extension MainNavigationExtension on BuildContext {
  void navigateToTab(int index) {
    Navigator.of(this).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  void navigateToHostTab() => navigateToTab(0);
  void navigateToJoinTab() => navigateToTab(1);
  void navigateToStatsTab() => navigateToTab(2);
  void navigateToProfileTab() => navigateToTab(3);
}