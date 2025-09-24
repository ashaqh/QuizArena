import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../models/game_history.dart';
import '../../services/user_data_service.dart';
import '../../widgets/main_navigation.dart';
import 'game_history_screen.dart';

/// Personal dashboard showing user statistics and recent activity
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final UserDataService _userDataService = UserDataService();
  UserProfile? _userProfile;
  List<GameHistoryRecord> _recentGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user profile
        _userProfile = await _userDataService.getOrCreateUserProfile(
          user.uid,
          user.displayName ?? 'User',
          user.email ?? '',
        );

        debugPrint('🏠 DASHBOARD: Loaded user profile for ${user.uid}');
        debugPrint(
          '🏠 DASHBOARD STATS: totalGamesPlayed=${_userProfile?.statistics.totalGamesPlayed}, totalGamesHosted=${_userProfile?.statistics.totalGamesHosted}',
        );
        debugPrint(
          '🏠 DASHBOARD STATS: averageScoreAsPlayer=${_userProfile?.statistics.averageScoreAsPlayer}, currentWinStreak=${_userProfile?.statistics.currentWinStreak}',
        );

        // Load recent games
        debugPrint('Dashboard: Loading game history for user: ${user.uid}');
        _recentGames = await _userDataService.getUserGameHistory(
          user.uid,
          limit: 5,
        );
        debugPrint('Dashboard: Loaded ${_recentGames.length} recent games');
        for (final game in _recentGames) {
          debugPrint(
            'Dashboard: Game - ${game.quizTitle}, Role: ${game.role}, Score: ${game.playerScore}, PlayedAt: ${game.playedAt}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 16),
                    _buildQuickStatsCard(),
                    const SizedBox(height: 16),
                    _buildRecentActivityCard(),
                    const SizedBox(height: 16),
                    _buildAchievementsCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _userProfile?.name ?? user?.displayName ?? 'User';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userProfile?.joinDate != null)
                    Text(
                      'Member since ${_formatDate(_userProfile!.joinDate)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final stats = _userProfile?.statistics;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Games Hosted',
                    '${stats.totalGamesHosted}',
                    Icons.home,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Games Played',
                    '${stats.totalGamesPlayed}',
                    Icons.games,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg Score',
                    '${stats.averageScoreAsPlayer.toStringAsFixed(0)}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Win Streak',
                    '${stats.currentWinStreak}🔥',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentGames.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No recent games. Join or host a game to get started!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._recentGames.take(3).map((game) => _buildRecentGameItem(game)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGameItem(GameHistoryRecord game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: game.role == 'host' ? Colors.orange : Colors.green,
            child: Icon(
              game.role == 'host' ? Icons.home : Icons.games,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.quizTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${game.role == 'host' ? 'Hosted' : 'Played'} • ${_formatDate(game.playedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (game.role == 'player' && game.playerScore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getScoreColor(game.performanceLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getScoreColor(game.performanceLevel).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${game.playerScore} pts',
                style: TextStyle(
                  color: _getScoreColor(game.performanceLevel),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final achievements = _userProfile?.statistics.achievements ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Complete games to unlock achievements!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: achievements.take(6).map((achievement) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _getAchievementTitle(achievement),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to Host tab
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      const MainNavigationScreen(initialIndex: 0),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to Join tab
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      const MainNavigationScreen(initialIndex: 1),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.games),
            label: const Text('Join Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getScoreColor(String performanceLevel) {
    switch (performanceLevel) {
      case 'Excellent':
        return Colors.green;
      case 'Great':
        return Colors.lightGreen;
      case 'Good':
        return Colors.orange;
      case 'Fair':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  String _getAchievementTitle(String achievementId) {
    switch (achievementId) {
      case 'first_game':
        return 'First Game';
      case 'first_host':
        return 'First Host';
      case 'win_streak_3':
        return 'Win Streak x3';
      case 'win_streak_5':
        return 'Win Streak x5';
      case 'high_scorer':
        return 'High Scorer';
      case 'perfect_game':
        return 'Perfect Game';
      case 'veteran_player':
        return 'Veteran Player';
      case 'experienced_host':
        return 'Experienced Host';
      default:
        return 'Achievement';
    }
  }
}
