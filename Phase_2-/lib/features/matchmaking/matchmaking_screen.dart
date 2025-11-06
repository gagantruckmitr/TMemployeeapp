import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../models/dummy_data.dart';
import 'widgets/match_card.dart';
import 'widgets/confetti_animation.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showConfetti = false;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _handleSwipe(DismissDirection direction) {
    if (direction == DismissDirection.endToStart) {
      // Rejected
      _nextCard();
    } else if (direction == DismissDirection.startToEnd) {
      // Accepted - Show confetti
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showConfetti = false);
          _nextCard();
        }
      });
    }
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < DummyData.matchSuggestions.length - 1) {
        _currentIndex++;
        _cardController.reset();
        _cardController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Matchmaking Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip('Matches Today', '24', AppColors.success),
                      _buildStatChip('Pending', '${DummyData.matchSuggestions.length - _currentIndex}', AppColors.warning),
                      _buildStatChip('Success Rate', '78%', AppColors.info),
                    ],
                  ),
                ),
                
                // Match cards stack
                Expanded(
                  child: _currentIndex < DummyData.matchSuggestions.length
                      ? Center(
                          child: ScaleTransition(
                            scale: _cardAnimation,
                            child: Dismissible(
                              key: ValueKey(_currentIndex),
                              onDismissed: _handleSwipe,
                              child: MatchCard(
                                match: DummyData.matchSuggestions[_currentIndex],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'All matches reviewed!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                
                // Action buttons
                if (_currentIndex < DummyData.matchSuggestions.length)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.close,
                          color: AppColors.error,
                          onPressed: () => _handleSwipe(DismissDirection.endToStart),
                        ),
                        _buildActionButton(
                          icon: Icons.info_outline,
                          color: AppColors.info,
                          onPressed: () {},
                          size: 50,
                        ),
                        _buildActionButton(
                          icon: Icons.check,
                          color: AppColors.success,
                          onPressed: () => _handleSwipe(DismissDirection.startToEnd),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Confetti overlay
          if (_showConfetti)
            const ConfettiAnimation(),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
