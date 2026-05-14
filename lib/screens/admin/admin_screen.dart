import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_header.dart';
import '../../controllers/announcement_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/announcement.dart';

// Private model removed in favor of models/announcement.dart

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AnnouncementController _controller = Get.find<AnnouncementController>();
  String _activeTab = 'pending'; // 'pending' or 'approved'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _GrainOverlay(),
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: MainHeader(title: "CAMPUS MUSE")),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 700;
                            return Flex(
                              direction: isMobile
                                  ? Axis.vertical
                                  : Axis.horizontal,
                              crossAxisAlignment: isMobile
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "COMMAND\nCENTER",
                                      style: AppTextStyles.headline(
                                        isMobile ? 48 : 80,
                                        weight: FontWeight.w900,
                                        color: AppColors.onSurface,
                                      ).copyWith(height: 0.9),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "MANAGEMENT & QUALITY ASSURANCE DASHBOARD",
                                      style: AppTextStyles.label(
                                        12,
                                        color: AppColors.onSurfaceVariant,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isMobile) const SizedBox(height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    Obx(
                                      () => _StatCard(
                                        count: _controller
                                            .pendingRequests
                                            .length
                                            .toString(),
                                        label: "PENDING",
                                        color: AppColors.secondary,
                                        isActive: _activeTab == 'pending',
                                        onTap: () => setState(
                                          () => _activeTab = 'pending',
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => _StatCard(
                                        count: _controller
                                            .approvedAnnouncements
                                            .length
                                            .toString(),
                                        label: "APPROVED",
                                        color: AppColors.primary,
                                        isActive: _activeTab == 'approved',
                                        onTap: () => setState(
                                          () => _activeTab = 'approved',
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => _StatCard(
                                        count: _controller
                                            .historyAnnouncements
                                            .length
                                            .toString(),
                                        label: "HISTORY",
                                        color: Colors.grey,
                                        isActive: _activeTab == 'history',
                                        onTap: () => setState(
                                          () => _activeTab = 'history',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 48),

                        // Search & Filters
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  hintText: 'SEARCH ANNOUNCEMENTS...',
                                  hintStyle: AppTextStyles.label(
                                    10,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 1.5,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: AppTextStyles.label(12),
                              ),
                            ),
                            _FilterChip(
                              label: 'ALL CATEGORIES',
                              isSelected: true,
                            ),
                            _FilterChip(label: 'EVENTS', isSelected: false),
                            _FilterChip(label: 'ACADEMICS', isSelected: false),
                            _FilterChip(label: 'SOCIAL', isSelected: false),
                            IconButton(
                              onPressed: () {
                                _controller.refreshAnnouncements();
                                Get.snackbar(
                                  "Refreshing",
                                  "Synchronizing with Supabase real-time...",
                                  backgroundColor: AppColors.secondary,
                                  colorText: Colors.black,
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 1),
                                  icon: const Icon(
                                    Icons.sync,
                                    color: Colors.black,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.onSurface,
                              ),
                              tooltip: 'Manual Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Approval Grid
                        Obx(() {
                          final list = _activeTab == 'pending'
                              ? _controller.pendingRequests
                              : _activeTab == 'history'
                              ? _controller.historyAnnouncements
                              : _controller.approvedAnnouncements;

                          if (list.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48.0,
                                ),
                                child: Text(
                                  _activeTab == 'pending'
                                      ? "NO PENDING REQUESTS"
                                      : "NO APPROVED ANNOUNCEMENTS",
                                  style: AppTextStyles.label(
                                    12,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 24),
                            itemBuilder: (context, index) {
                              final item = list[index];
                              if (_activeTab == 'history') {
                                return _HistoryTile(request: item);
                              }
                              return _RequestTile(
                                request: item,
                                showActions: _activeTab == 'pending',
                                onApprove: () async {
                                  print(
                                    "Approving event: ${item.id} (${item.title})",
                                  );
                                  try {
                                    await _controller.updateStatus(
                                      item.id,
                                      'approved',
                                    );
                                    print("Approval successful.");
                                    Get.snackbar(
                                      "Accepted",
                                      "The event is now live!",
                                      backgroundColor: AppColors.secondary,
                                      colorText: Colors.black,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } catch (e) {
                                    print("Approval failed: $e");
                                  }
                                },
                                onReject: () async {
                                  final action = _activeTab == 'pending'
                                      ? 'rejected'
                                      : 'removed';
                                  print(
                                    "${action.capitalizeFirst} event: ${item.id}",
                                  );
                                  try {
                                    await _controller.updateStatus(
                                      item.id,
                                      action,
                                    );
                                    Get.snackbar(
                                      action.capitalizeFirst!,
                                      "Event has been $action.",
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } catch (e) {
                                    print("Action failed: $e");
                                  }
                                },
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 48),

                        // Load More Button
                        Center(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              side: BorderSide(
                                color: AppColors.outline.withOpacity(0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Text(
                              "LOAD MORE CONTENT",
                              style: AppTextStyles.label(
                                12,
                                color: AppColors.onSurface,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.15)
              : AppColors.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.outline.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.headline(
                24,
                color: isActive ? color : color.withOpacity(0.5),
                weight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.label(
                10,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(100),
        border: isSelected
            ? Border.all(color: AppColors.primary.withOpacity(0.2))
            : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.label(
          10,
          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final Announcement request;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestTile({
    required this.request,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            request.status ==
                'urgent' // status logic update if needed
            ? const Border(
                left: BorderSide(color: AppColors.secondary, width: 4),
              )
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: request.status == 'urgent'
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.outline.withOpacity(0.2),
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(
                          request.bannerUrl.isNotEmpty
                              ? request.bannerUrl
                              : 'https://via.placeholder.com/150',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (false) // Request no longer has isUrgent in model, using category instead
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.black,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 16 : 0),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: request.status == 'urgent'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            request.category.toUpperCase(),
                            style: AppTextStyles.label(
                              9,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Text(
                          "SUBMITTED BY SYSTEM",
                          style: AppTextStyles.label(
                            9,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.title,
                      style: AppTextStyles.headline(
                        24,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.description,
                      style: AppTextStyles.body(
                        14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: request.status == 'urgent'
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              request.category.toUpperCase(),
                              style: AppTextStyles.label(
                                9,
                                color: AppColors.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Text(
                            "SUBMITTED BY SYSTEM",
                            style: AppTextStyles.label(
                              9,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.title,
                        style: AppTextStyles.headline(
                          24,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.description,
                        style: AppTextStyles.body(
                          14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(
                      showActions ? Icons.close : Icons.delete_outline,
                      size: 16,
                    ),
                    label: Text(
                      showActions ? "REJECT" : "REMOVE",
                      style: AppTextStyles.label(
                        11,
                        weight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      backgroundColor: AppColors.error.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (showActions) ...[
                    SizedBox(
                      width: isMobile ? 0 : 12,
                      height: isMobile ? 12 : 0,
                    ),
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: Text(
                        "APPROVE",
                        style: AppTextStyles.label(
                          11,
                          color: Colors.black,
                          weight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Announcement request;

  const _HistoryTile({required this.request});

  Future<Map<String, dynamic>?> _fetchUserDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username, email')
          .eq('id', request.userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: request.status == 'approved'
              ? AppColors.primary.withOpacity(0.5)
              : request.status == 'rejected' || request.status == 'removed'
              ? AppColors.error.withOpacity(0.5)
              : AppColors.outline.withOpacity(0.2),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          final username = snapshot.data?['username'] ?? 'Unknown User';
          final email = snapshot.data?['email'] ?? 'Unknown Email';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: request.status == 'approved'
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: AppTextStyles.label(
                        10,
                        color: request.status == 'approved'
                            ? AppColors.primary
                            : AppColors.error,
                        letterSpacing: 1.5,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "CREATED: ${request.createdAt.toString().split('.').first}",
                    style: AppTextStyles.label(
                      10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                request.title,
                style: AppTextStyles.headline(20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                "Requested by: $username ($email)",
                style: AppTextStyles.label(12, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 16),
              _buildDetailRow("CATEGORY", request.category),
              const SizedBox(height: 8),
              _buildDetailRow(
                "LOCATION",
                request.location.isEmpty ? 'N/A' : request.location,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                "DATE",
                request.eventDate.isEmpty ? 'N/A' : request.eventDate,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                "TIME",
                request.eventTime.isEmpty ? 'N/A' : request.eventTime,
              ),
              const SizedBox(height: 16),
              Text(
                "DESCRIPTION",
                style: AppTextStyles.label(
                  10,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.description.isEmpty
                    ? 'No description provided.'
                    : request.description,
                style: AppTextStyles.body(14),
              ),
              const SizedBox(height: 16),
              Text(
                "RULES / REQUIREMENTS",
                style: AppTextStyles.label(
                  10,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.rules.isEmpty ? 'None specified.' : request.rules,
                style: AppTextStyles.body(14),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.label(
              10,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body(14, color: AppColors.onSurface),
          ),
        ),
      ],
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
