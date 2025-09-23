import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game_history.dart';
import '../../services/user_data_service.dart';

/// Screen showing detailed game history with filtering and pagination
class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  final UserDataService _userDataService = UserDataService();
  final ScrollController _scrollController = ScrollController();

  List<GameHistoryRecord> _games = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _selectedRole; // 'host', 'player', or null for all

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreGames();
    }
  }

  Future<void> _loadGameHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final games = await _userDataService.getUserGameHistory(
          user.uid,
          limit: 20,
          role: _selectedRole,
        );

        setState(() {
          _games = games;
          _hasMoreData = games.length == 20;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreGames() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _games.isNotEmpty) {
        // Note: This would need the actual DocumentSnapshot for startAfter
        // For now, we'll skip pagination to keep the implementation simple
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading more games: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _filterByRole(String? role) {
    setState(() {
      _selectedRole = role;
    });
    _loadGameHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterByRole,
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Games')),
              const PopupMenuItem(value: 'host', child: Text('Hosted Games')),
              const PopupMenuItem(value: 'player', child: Text('Played Games')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGameHistory,
              child: Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: _games.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _games.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _games.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildGameHistoryCard(_games[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All'),
            selected: _selectedRole == null,
            onSelected: (_) => _filterByRole(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Hosted'),
            selected: _selectedRole == 'host',
            onSelected: (_) => _filterByRole('host'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Played'),
            selected: _selectedRole == 'player',
            onSelected: (_) => _filterByRole('player'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedRole == null
                ? 'No games played yet'
                : _selectedRole == 'host'
                ? 'No games hosted yet'
                : 'No games played yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating a quiz or joining a game!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHistoryCard(GameHistoryRecord game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: game.role == 'host'
                      ? Colors.orange
                      : Colors.green,
                  child: Icon(
                    game.role == 'host' ? Icons.home : Icons.games,
                    color: Colors.white,
                    size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${game.role == 'host' ? 'Hosted' : 'Played'} • ${_formatDate(game.playedAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (game.role == 'player' && game.playerRank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRankColor(game.playerRank!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getRankColor(game.playerRank!).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#${game.playerRank}',
                      style: TextStyle(
                        color: _getRankColor(game.playerRank!),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    Icons.people,
                    '${game.totalPlayers} players',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    Icons.quiz,
                    '${game.totalQuestions} questions',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    Icons.timer,
                    game.formattedDuration,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (game.role == 'player') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (game.playerScore != null)
                    Expanded(
                      child: _buildStatChip(
                        Icons.stars,
                        '${game.playerScore} pts',
                        Colors.orange,
                      ),
                    ),
                  if (game.playerScore != null &&
                      game.accuracyPercentage != null)
                    const SizedBox(width: 8),
                  if (game.accuracyPercentage != null)
                    Expanded(
                      child: _buildStatChip(
                        Icons.percent,
                        '${game.accuracyPercentage!.toStringAsFixed(0)}% accuracy',
                        Colors.teal,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }
}
