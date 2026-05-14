import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:mainchar/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/global_top_nav.dart';
import '../widgets/main_header.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _topUsers = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentUserProfile;
  bool _isRevealHour = true;  //for testing
  late Timer _timer;
  Duration _timeLeft = const Duration(days: 0);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _checkRevealStatus();
    _fetchLeaderboard();
    _startTimer();
  }

  void _checkRevealStatus() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _isRevealHour = (now.day == lastDay.day && now.hour == 20);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final nextReveal = DateTime(now.year, now.month + 1, 0, 20);
      if (mounted) {
        setState(() {
          _timeLeft = nextReveal.difference(now);
        });
      }
    });
  }

  Future<void> _fetchLeaderboard() async {
    try {
      // NEW: Using RPC for scalable, server-side sorted rankings
      final response = await Supabase.instance.client.rpc(
        'get_leaderboard',
        params: {'limit_val': 50},
      );

      if (mounted) {
        setState(() {
          _topUsers = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _currentUserProfile = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundBlobs(),
          const _GrainOverlay(),
          CustomScrollView(
            slivers: [
              // Top Navigation Bar (Integrated directly into sliver)
              SliverToBoxAdapter(child: const MainHeader(title: 'CAMPUS VIBE')),

              if (MediaQuery.of(context).size.width < 768)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: GlobalTopNav()),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          _CountdownSection(timeLeft: _timeLeft),
                          if (_isRevealHour)
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child: _LiveRevealCTA(
                                onTap: () => Get.toNamed(AppRoutes.REVEAL_ARENA),
                              ),
                            ),
                          const SizedBox(height: 64),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          else if (_topUsers.isNotEmpty)
                            Column(
                              children: [
                                _Podium(
                                  rank1: _topUsers.length > 0
                                      ? _topUsers[0]
                                      : null,
                                  rank2: _topUsers.length > 1
                                      ? _topUsers[1]
                                      : null,
                                  rank3: _topUsers.length > 2
                                      ? _topUsers[2]
                                      : null,
                                  isRevealHour: _isRevealHour,
                                ),
                                const SizedBox(height: 80),
                                _ChallengerList(
                                  challengers: _topUsers.length > 3
                                      ? _topUsers.sublist(3)
                                      : [],
                                  isRevealHour: _isRevealHour,
                                ),
                              ],
                            ),
                          const _Footer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ).withBlur(120),
        ),
        Positioned(
          bottom: 200,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.06),
            ),
          ).withBlur(120),
        ),
      ],
    );
  }
}

extension _BlurExtension on Widget {
  Widget withBlur(double sigma) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: this,
  );
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

class _CountdownSection extends StatelessWidget {
  final Duration timeLeft;
  const _CountdownSection({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            border: Border.all(
              color: AppColors.onSurfaceVariant.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'PHASE ONE ENDING',
            style: AppTextStyles.label(
              10,
              color: AppColors.secondary,
              weight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'The Reveal in ',
                style: AppTextStyles.headline(
                  MediaQuery.of(context).size.width > 768 ? 84 : 48,
                  weight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: '${timeLeft.inDays} Days',
                style: AppTextStyles.headline(
                  MediaQuery.of(context).size.width > 768 ? 84 : 48,
                  weight: FontWeight.w900,
                  color: AppColors.primary,
                  italic: true,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 800.ms),
        const SizedBox(height: 16),
        Text(
          'MAIN CHARACTER SEASON 01 • TOP 50 QUALIFY',
          style: AppTextStyles.label(
            12,
            color: AppColors.onSurfaceVariant,
            weight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final Map<String, dynamic>? rank1;
  final Map<String, dynamic>? rank2;
  final Map<String, dynamic>? rank3;
  final bool isRevealHour;

  const _Podium({
    this.rank1,
    this.rank2,
    this.rank3,
    required this.isRevealHour,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: isMobile
            ? Column(
                children: [
                  if (rank1 != null)
                    _PodiumItem(
                      rank: 1,
                      profile: rank1!,
                      isRevealHour: isRevealHour,
                    ),
                  if (rank2 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: _PodiumItem(
                        rank: 2,
                        profile: rank2!,
                        isRevealHour: isRevealHour,
                      ),
                    ),
                  if (rank3 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: _PodiumItem(
                        rank: 3,
                        profile: rank3!,
                        isRevealHour: isRevealHour,
                      ),
                    ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (rank2 != null)
                    Expanded(
                      child:
                          _PodiumItem(
                                rank: 2,
                                profile: rank2!,
                                isRevealHour: isRevealHour,
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                    ),
                  const SizedBox(width: 32),
                  if (rank1 != null)
                    Expanded(
                      child: _PodiumItem(
                        rank: 1,
                        profile: rank1!,
                        isRevealHour: isRevealHour,
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    ),
                  const SizedBox(width: 32),
                  if (rank3 != null)
                    Expanded(
                      child:
                          _PodiumItem(
                                rank: 3,
                                profile: rank3!,
                                isRevealHour: isRevealHour,
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> profile;
  final bool isRevealHour;

  const _PodiumItem({
    required this.rank,
    required this.profile,
    required this.isRevealHour,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return AppColors.secondary;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = rank == 1 ? 160.0 : 120.0;
    final padding = rank == 1 ? 40.0 : 32.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.surfaceContainer
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 1
                  ? AppColors.secondary.withOpacity(0.2)
                  : Colors.white10,
            ),
            boxShadow: rank == 1
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.1),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _Avatar(
                url: profile['avatar_url'] ?? '',
                size: avatarSize,
                color: _rankColor,
                isRevealHour: isRevealHour,
                rank: rank,
              ),
              const SizedBox(height: 24),
              Text(
                isRevealHour
                    ? (profile['username'] ?? '?????').toUpperCase()
                    : '?????',
                style: AppTextStyles.headline(
                  rank == 1 ? 28 : 20,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (profile['bio'] ?? 'Unknown Major')
                    .split(' ')
                    .first
                    .toUpperCase(),
                style: AppTextStyles.label(
                  10,
                  color: AppColors.secondary,
                  weight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              _HypeBar(
                percentage: rank == 1 ? 0.96 : (rank == 2 ? 0.88 : 0.74),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HYPE LEVEL',
                    style: AppTextStyles.label(
                      8,
                      color: AppColors.onSurfaceVariant,
                      weight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rank == 1 ? '96%' : (rank == 2 ? '88%' : '74%'),
                    style: AppTextStyles.label(8, weight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _rankColor,
                boxShadow: [
                  BoxShadow(
                    color: _rankColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                '#$rank',
                style: AppTextStyles.headline(
                  24,
                  color: Colors.black,
                  weight: FontWeight.w900,
                  italic: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final double size;
  final Color color;
  final bool isRevealHour;
  final int rank;

  const _Avatar({
    required this.url,
    required this.size,
    required this.color,
    required this.isRevealHour,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (rank == 1)
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .fadeOut(),
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url.isNotEmpty)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: color.withOpacity(0.5),
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (c, e, s) =>
                        Container(color: AppColors.surfaceContainerHighest),
                  )
                else
                  Container(color: AppColors.surfaceContainerHighest),
                if (!isRevealHour)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HypeBar extends StatelessWidget {
  final double percentage;
  const _HypeBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengerList extends StatelessWidget {
  final List<Map<String, dynamic>> challengers;
  final bool isRevealHour;

  const _ChallengerList({
    required this.challengers,
    required this.isRevealHour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOP 50 CHALLENGERS',
                  style: AppTextStyles.label(
                    10,
                    color: AppColors.onSurfaceVariant,
                    weight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                ),
                const Icon(Icons.sort_rounded, color: AppColors.secondary),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: challengers.length,
            itemBuilder: (context, index) {
              return _ChallengerItem(
                rank: index + 4,
                profile: challengers[index],
                isRevealHour: isRevealHour,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'SCROLL FOR MORE RANKING',
              style: AppTextStyles.label(
                8,
                color: AppColors.onSurfaceVariant,
                weight: FontWeight.bold,
                letterSpacing: 5.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengerItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> profile;
  final bool isRevealHour;

  const _ChallengerItem({
    required this.rank,
    required this.profile,
    required this.isRevealHour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: AppTextStyles.headline(16, weight: FontWeight.w900),
          ),
          const SizedBox(width: 24),
          _Avatar(
            url: profile['avatar_url'] ?? '',
            size: 40,
            color: Colors.white10,
            isRevealHour: isRevealHour,
            rank: rank,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRevealHour
                      ? (profile['username'] ?? '?????').toUpperCase()
                      : '?????',
                  style: AppTextStyles.label(12, weight: FontWeight.bold),
                ),
                Text(
                  'STUDENT',
                  style: AppTextStyles.label(
                    8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _HypeMiniBar(percentage: 0.4 + (0.5 * (1 - (rank / 50)))),
        ],
      ),
    );
  }
}

class _HypeMiniBar extends StatelessWidget {
  final double percentage;
  const _HypeMiniBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Text(
            'CAMPUS VIBE',
            style: AppTextStyles.label(
              12,
              color: AppColors.secondary,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(label: 'Support'),
              const SizedBox(width: 32),
              _FooterLink(label: 'Privacy'),
              const SizedBox(width: 32),
              _FooterLink(label: 'Terms'),
            ],
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.label(
        10,
        letterSpacing: 2.0,
        weight: FontWeight.bold,
      ),
    );
  }
}

class _LiveRevealCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _LiveRevealCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_filled_rounded, color: Colors.black, size: 32),
            const SizedBox(width: 16),
            Text(
              "ENTER REVEAL ARENA",
              style: AppTextStyles.headline(20, color: Colors.black, weight: FontWeight.w900),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.05, 1.05),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      ),
    );
  }
}
