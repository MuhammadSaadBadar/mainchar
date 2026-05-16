import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:mainchar/routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_header.dart';
import '../../controllers/announcement_controller.dart';
import '../../models/announcement.dart';
import '../../widgets/global_top_nav.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AnnouncementController _controller = Get.find<AnnouncementController>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.markAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'myRequestsBtn',
            onPressed: () => Get.toNamed(AppRoutes.MY_REQUESTS),
            backgroundColor: AppColors.surfaceContainerHigh,
            foregroundColor: AppColors.onSurface,
            icon: const Icon(Icons.list_alt, size: 20),
            label: Text(
              "MY REQUESTS",
              style: AppTextStyles.label(
                12,
                weight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'newRequestBtn',
            onPressed: () => Get.toNamed(AppRoutes.REQUEST_EVENT),
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              "NEW REQUEST",
              style: AppTextStyles.label(
                12,
                weight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          
          PointerInterceptor(child: const _GrainOverlay()),
          PointerInterceptor(
            child: Column(
              children: [
                const MainHeader(title: "CAMPUS MUSE"),
                if (MediaQuery.of(context).size.width < 768)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: const GlobalTopNav(),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 900;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Panel - Timeline
                            SizedBox(
                              width: isDesktop ? 320.0 : constraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Let's Get Together",
                                          style: AppTextStyles.headline(
                                            isDesktop ? 28 : 36,
                                            weight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6.0,
                                          ),
                                          child: Text(
                                            "LIVE UPDATES",
                                            style: AppTextStyles.label(
                                              12,
                                              color: AppColors.secondary,
                                              letterSpacing: 2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Obx(() {
                                      if (_controller
                                          .approvedAnnouncements
                                          .isEmpty) {
                                        return const _EmptyWireState();
                                      }
                                      return ListView.separated(
                                        itemCount: _controller
                                            .approvedAnnouncements
                                            .length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final item = _controller
                                              .approvedAnnouncements[index];
                                          final isSelected =
                                              isDesktop &&
                                              _selectedIndex == index;
                                          return _AnnouncementTile(
                                            announcement: item,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setState(
                                                () => _selectedIndex = index,
                                              );
                                              if (!isDesktop) {
                                                Get.bottomSheet(
                                                  _MobileDetailSheet(
                                                    announcement: item,
                                                  ),
                                                  isScrollControlled: true,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 24),
                              // Right Panel - Detail View
                              Expanded(
                                child: Obx(() {
                                  if (_controller
                                      .approvedAnnouncements
                                      .isEmpty) {
                                    return const SizedBox();
                                  }
                                  if (_selectedIndex >=
                                      _controller
                                          .approvedAnnouncements
                                          .length) {
                                    _selectedIndex = 0;
                                  }
                                  return _DetailView(
                                    announcement: _controller
                                        .approvedAnnouncements[_selectedIndex],
                                  );
                                }),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnnouncementTile({
    required this.announcement,
    required this.isSelected,
    required this.onTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return "${diff.inMinutes} MINS AGO";
    if (diff.inHours < 24) return "${diff.inHours} HOURS AGO";
    return "${diff.inDays} DAYS AGO";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: AppColors.secondary.withOpacity(0.5),
                  width: 2,
                )
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      announcement.category.toUpperCase(),
                      style: AppTextStyles.label(
                        10,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.title,
                    style: AppTextStyles.headline(18, weight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (announcement.location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            announcement.location,
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (announcement.eventDate.isNotEmpty ||
                      announcement.eventTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 11,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            [
                              announcement.eventDate,
                              announcement.eventTime,
                            ].where((s) => s.isNotEmpty).join('  •  '),
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimeAgo(announcement.createdAt),
                        style: AppTextStyles.label(
                          10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (DateTime.now()
                              .difference(announcement.createdAt)
                              .inHours <
                          24)
                        const Icon(
                          Icons.bolt,
                          color: AppColors.secondary,
                          size: 14,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Announcement announcement;

  const _DetailView({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline.withOpacity(0.1)),
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [AppColors.primary.withOpacity(0.05), Colors.transparent],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Vertical Accent Line
          Positioned(
            left: 0,
            top: 40,
            bottom: 40,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.secondary.withOpacity(0.5),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          announcement.category.toUpperCase(),
                          style: AppTextStyles.label(
                            10,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        announcement.title,
                        style: AppTextStyles.headline(
                          36,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.description,
                        style: AppTextStyles.body(
                          18,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (announcement.location.isNotEmpty ||
                          announcement.eventDate.isNotEmpty ||
                          announcement.eventTime.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (announcement.location.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: _InfoBox(
                                  icon: Icons.location_on,
                                  iconColor: AppColors.primary,
                                  label: "LOCATION",
                                  value: announcement.location,
                                ),
                              ),
                            if (announcement.eventDate.isNotEmpty)
                              _InfoBox(
                                icon: Icons.calendar_today,
                                iconColor: AppColors.secondary,
                                label: "DATE",
                                value: announcement.eventDate,
                              ),
                            if (announcement.eventTime.isNotEmpty)
                              _InfoBox(
                                icon: Icons.schedule,
                                iconColor: AppColors.secondary,
                                label: "TIME",
                                value: announcement.eventTime,
                              ),
                          ],
                        ),
                      ],
                      if (announcement.rules.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _RulesBlock(rules: announcement.rules),
                      ],
                    ],
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

class _MobileDetailSheet extends StatelessWidget {
  final Announcement announcement;

  const _MobileDetailSheet({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            announcement.category.toUpperCase(),
                            style: AppTextStyles.label(
                              9,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Get.back(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcement.title,
                      style: AppTextStyles.headline(
                        28,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.description,
                      style: AppTextStyles.body(
                        16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (announcement.location.isNotEmpty) ...[
                      _InfoBox(
                        icon: Icons.location_on,
                        iconColor: AppColors.primary,
                        label: "LOCATION",
                        value: announcement.location,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (announcement.eventDate.isNotEmpty) ...[
                      _InfoBox(
                        icon: Icons.calendar_today,
                        iconColor: AppColors.secondary,
                        label: "DATE",
                        value: announcement.eventDate,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (announcement.eventTime.isNotEmpty) ...[
                      _InfoBox(
                        icon: Icons.schedule,
                        iconColor: AppColors.secondary,
                        label: "TIME",
                        value: announcement.eventTime,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (announcement.rules.isNotEmpty) ...[
                      _RulesBlock(rules: announcement.rules),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesBlock extends StatelessWidget {
  final String rules;

  const _RulesBlock({required this.rules});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "RULES & GUIDELINES",
                style: AppTextStyles.label(
                  12,
                  color: AppColors.primary,
                  weight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rules,
            style: AppTextStyles.body(16, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label(
                    10,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.headline(16, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-D Flip Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyWireState extends StatefulWidget {
  const _EmptyWireState();

  @override
  State<_EmptyWireState> createState() => _EmptyWireStateState();
}

class _EmptyWireStateState extends State<_EmptyWireState>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _flipCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late final Animation<double> _flipAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  int _currentIndex = 0;

  // ── Items: emoji · label · accent colour ─────────────────────────────────
  static const _items = [
    (emoji: '🎸', label: 'MUSIC & CULTURE', color: Color(0xFFD394FF)),
    (emoji: '🏏', label: 'SPORTS & CLUBS', color: Color(0xFFC3F400)),
    (emoji: '⚽', label: 'EVENTS & FESTS', color: Color(0xFF00F4FE)),
  ];

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Smooth vertical float
    _floatCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -12,
      end: 12,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Pulsing glow intensity
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Y-axis 3-D flip (0 → 1 maps to 0 → π)
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);

    _flipCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Advance index at the midpoint (already visible after flip completes)
        _flipCtrl.reset();
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _items.length;
          });
        }
        // Pause 2 s, then flip to next
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _flipCtrl.forward();
        });
      }
    });

    // Start first flip after 2 s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _flipCtrl.forward();
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── 3-D Flip Orb ───────────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_flipAnim, _floatAnim, _glowAnim]),
              builder: (context, _) {
                final flipAngle = _flipAnim.value * pi; // 0 → π
                final isFirstHalf = flipAngle < pi / 2;

                // During the second half we show the NEXT item's colour/emoji
                // but at a mirrored angle so it appears to "unwrap" from 90°
                final nextIndex = (_currentIndex + 1) % _items.length;
                final visibleItem = isFirstHalf
                    ? _items[_currentIndex]
                    : _items[nextIndex];
                // Remap angle so second half runs from π/2 back toward 0
                final displayAngle = isFirstHalf ? flipAngle : flipAngle - pi;

                final accentColor = visibleItem.color;

                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Ambient glow blob ──────────────────────────────
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(
                                _glowAnim.value * 0.35,
                              ),
                              blurRadius: 80,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      ),

                      // ── Outer orbit ring ───────────────────────────────
                      Container(
                        width: 196,
                        height: 196,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withOpacity(0.18),
                            width: 1,
                          ),
                        ),
                      ),

                      // ── Middle orbit ring (tilted) ─────────────────────
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(0.8),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // ── Inner orbit ring (counter-tilt) ───────────────
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(-0.5)
                          ..rotateZ(0.4),
                        child: Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // ── 3-D flipping card ─────────────────────────────
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.003) // perspective
                          ..rotateY(displayAngle),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceContainerHigh,
                            border: Border.all(
                              color: accentColor.withOpacity(0.55),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              visibleItem.emoji,
                              style: const TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Dot indicators ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _flipAnim,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_items.length, (i) {
                    final active = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? _items[i].color
                            : AppColors.onSurfaceVariant.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Animated label ─────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _items[_currentIndex].label,
                key: ValueKey(_currentIndex),
                style: AppTextStyles.label(
                  11,
                  color: _items[_currentIndex].color,
                  letterSpacing: 2.5,
                  weight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'NO LIVE ANNOUNCEMENTS',
              style: AppTextStyles.headline(
                18,
                weight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'No live broadcasts at the moment.\nBe the one to break the silence.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                12,
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 28),

            // ── CTA button ─────────────────────────────────────────────────
            TextButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.REQUEST_EVENT),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'CREATE ANNOUNCEMENT',
                style: AppTextStyles.label(
                  10,
                  weight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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