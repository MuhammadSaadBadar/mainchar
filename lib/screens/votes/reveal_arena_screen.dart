import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_header.dart';

class RevealArenaScreen extends StatefulWidget {
  const RevealArenaScreen({super.key});

  @override
  State<RevealArenaScreen> createState() => _RevealArenaScreenState();
}

class _RevealArenaScreenState extends State<RevealArenaScreen> {
  List<Map<String, dynamic>> _winners = [];
  bool _isLoading = true;
  int _currentRevealIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchWinners();
  }

  Future<void> _fetchWinners() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_leaderboard',
        params: {'limit_val': 3},
      );

      setState(() {
        _winners = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      // Start sequential reveal after a short delay
      _startRevealSequence();
    } catch (e) {
      debugPrint('Error fetching winners: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startRevealSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    for (int i = 0; i < _winners.length; i++) {
      if (!mounted) return;
      setState(() => _currentRevealIndex = i);
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _RevealBackground(),
          const _GrainOverlay(),
          Column(
            children: [
              const MainHeader(title: 'THE REVEAL'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      )
                    : _winners.isEmpty
                    ? _buildEmptyState()
                    : _buildWinnerStage(),
              ),
            ],
          ),
          // Exit button
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white54, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerStage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'MAIN CHARACTER SEASON 01',
          style: AppTextStyles.label(
            12,
            color: AppColors.secondary,
            weight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ).animate().fadeIn(duration: 800.ms),
        const SizedBox(height: 16),
        Text(
          'THE UNMASKING',
          style: AppTextStyles.headline(48, weight: FontWeight.w900),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 64),
        SizedBox(
          height: 450,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rank 3 (Left)
              if (_winners.length > 2)
                _WinnerSpotlight(
                  profile: _winners[2],
                  rank: 3,
                  isRevealed: _currentRevealIndex >= 2,
                  offset: const Offset(-280, 40),
                  scale: 0.8,
                ),
              // Rank 2 (Right)
              if (_winners.length > 1)
                _WinnerSpotlight(
                  profile: _winners[1],
                  rank: 2,
                  isRevealed: _currentRevealIndex >= 1,
                  offset: const Offset(280, 40),
                  scale: 0.8,
                ),
              // Rank 1 (Center/Top)
              if (_winners.isNotEmpty)
                _WinnerSpotlight(
                  profile: _winners[0],
                  rank: 1,
                  isRevealed: _currentRevealIndex >= 0,
                  offset: const Offset(0, -40),
                  scale: 1.1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'VOTING DATA NOT AVAILABLE',
        style: AppTextStyles.label(14, color: Colors.white24),
      ),
    );
  }
}

class _WinnerSpotlight extends StatelessWidget {
  final Map<String, dynamic> profile;
  final int rank;
  final bool isRevealed;
  final Offset offset;
  final double scale;

  const _WinnerSpotlight({
    required this.profile,
    required this.rank,
    required this.isRevealed,
    required this.offset,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? AppColors.secondary
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown/Rank Badge
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.headline(24, color: Colors.black),
                  ),
                )
                .animate(target: isRevealed ? 1 : 0)
                .scale(duration: 600.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            // Avatar with Blur effect
            Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow
                    Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(
                                  isRevealed ? 0.3 : 0.05,
                                ),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        )
                        .animate(target: isRevealed ? 1 : 0)
                        .shimmer(duration: const Duration(seconds: 2)),
                    // The Photo
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            profile['avatar_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.white10),
                          ),
                          // Blur Overlay
                          if (!isRevealed)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(color: Colors.black45),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
                .animate(target: isRevealed ? 1 : 0)
                .scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            // Name Reveal
            Text(
                  isRevealed
                      ? (profile['username'] ?? '?????')
                            .toString()
                            .toUpperCase()
                      : '?????',
                  style: AppTextStyles.headline(
                    28,
                    color: isRevealed ? Colors.white : Colors.white12,
                  ),
                )
                .animate(target: isRevealed ? 1 : 0)
                .fadeIn(duration: const Duration(seconds: 2))
                .slideY(begin: 0.5, end: 0),
            if (isRevealed)
              Text(
                profile['bio'] ?? 'STUDENT',
                style: AppTextStyles.label(10, color: AppColors.secondary),
              ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _RevealBackground extends StatelessWidget {
  const _RevealBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF1A1A1A), Colors.black],
              ),
            ),
          ),
        ),
        // Moving light blobs
        Positioned(
          top: -100,
          left: -100,
          child: _GlowBlob(color: AppColors.primary.withOpacity(0.1)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _GlowBlob(color: AppColors.secondary.withOpacity(0.05)),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  const _GlowBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: const Duration(seconds: 2))
        .fadeOut(delay: const Duration(seconds: 2));
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.03,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAT_w_ZeV94lSMmj6dQo2D_WDwLvvvFmQzKj7frQuQoMpliedmi0sooCJZUPkZCMJVLdzhig9_Buf2LETpdc7fClZ8Gj5iadPNSWLsOZQF5rnDALFW0hXiKc8EmxRNU0BsM9fWqmkKS75PxkfyZfZVnw0nxoysOHLkqUEec_9dXUKNu_sTJrE1A-ndyzf_36PQkS-eZkesf1KLP0GiXh9m525ZmPtlCOMTniwXxndxDmBnLcadAC59OYpo1czOWZGzo0YM0eKyseio',
              ),
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }
}
