import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_header.dart';
import '../../controllers/announcement_controller.dart';
import '../../models/announcement.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final AnnouncementController _controller = Get.find<AnnouncementController>();
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _GrainOverlay(),
          Column(
            children: [
              const MainHeader(title: "MY REQUESTS"),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Obx(() {
                      // Combine all lists to find the current user's requests
                      final allRequests = [
                        ..._controller.pendingRequests,
                        ..._controller.approvedAnnouncements,
                        ..._controller.historyAnnouncements,
                      ];
                      
                      // Filter by current user and remove duplicates
                      final myRequests = allRequests
                          .where((r) => r.userId == currentUserId)
                          .toSet()
                          .toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      if (myRequests.isEmpty) {
                        return Center(
                          child: Text(
                            "YOU HAVEN'T MADE ANY REQUESTS YET.",
                            style: AppTextStyles.label(
                              12,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 2,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: myRequests.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          return _MyRequestTile(request: myRequests[index]);
                        },
                      );
                    }),
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

class _MyRequestTile extends StatelessWidget {
  final Announcement request;

  const _MyRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (request.status) {
      case 'approved':
        statusColor = AppColors.primary;
        break;
      case 'rejected':
      case 'removed':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: AppTextStyles.label(
                        10,
                        color: statusColor,
                        letterSpacing: 1.5,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (request.status == 'approved') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.isLive ? AppColors.primary.withOpacity(0.15) : AppColors.outline.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request.isLive ? "LIVE" : "EXPIRED",
                        style: AppTextStyles.label(
                          10,
                          color: request.isLive ? AppColors.primary : AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                "CREATED: ${request.createdAt.toString().split('.').first}",
                style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.title,
            style: AppTextStyles.headline(24, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            request.category.toUpperCase(),
            style: AppTextStyles.label(12, color: AppColors.secondary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 16),
          _buildDetailRow("DATE", request.eventDate.isEmpty ? 'N/A' : request.eventDate),
          const SizedBox(height: 8),
          _buildDetailRow("TIME", request.eventTime.isEmpty ? 'N/A' : request.eventTime),
          const SizedBox(height: 8),
          _buildDetailRow("LOCATION", request.location.isEmpty ? 'N/A' : request.location),
          const SizedBox(height: 16),
          Text(
            "RULES / REQUIREMENTS",
            style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant, letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            request.rules.isEmpty ? 'None specified.' : request.rules,
            style: AppTextStyles.body(14),
          ),
          if (request.status != 'removed' && request.status != 'rejected') ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.defaultDialog(
                    title: "DELETE REQUEST",
                    titleStyle: AppTextStyles.headline(20, color: AppColors.error),
                    middleText: "Are you sure you want to delete this request? This action cannot be undone.",
                    middleTextStyle: AppTextStyles.body(14),
                    backgroundColor: AppColors.surfaceContainer,
                    radius: 8,
                    textConfirm: "DELETE",
                    textCancel: "CANCEL",
                    confirmTextColor: Colors.white,
                    cancelTextColor: AppColors.onSurface,
                    buttonColor: AppColors.error,
                    onConfirm: () async {
                      Get.back(); // Close dialog
                      try {
                        await Get.find<AnnouncementController>().updateStatus(request.id, 'removed');
                        Get.snackbar(
                          "Deleted",
                          "Your request has been successfully deleted.",
                          backgroundColor: AppColors.surfaceContainerHigh,
                          colorText: AppColors.onSurface,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "Failed to delete request. Please try again.",
                          backgroundColor: AppColors.error.withOpacity(0.8),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  "DELETE REQUEST",
                  style: AppTextStyles.label(
                    12,
                    weight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant, letterSpacing: 1.5),
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
