import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_header.dart';
import '../../routes/app_routes.dart';
import '../../controllers/announcement_controller.dart';

class RequestEventScreen extends StatefulWidget {
  const RequestEventScreen({super.key});

  @override
  State<RequestEventScreen> createState() => _RequestEventScreenState();
}

class _RequestEventScreenState extends State<RequestEventScreen> {
  final AnnouncementController _controller = Get.put(AnnouncementController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  String _selectedCategory = '';

  final List<String> _categories = [
    'Music',
    'Sport',
    'Tech',
    'Seminar',
    'Play',
    'Others',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerHigh,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerHigh,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        controller.text = "$hour:$minute";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _GrainOverlay(),
          // Neon Glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.075),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: MainHeader(title: "CAMPUS MUSE")),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 900;
                          return Flex(
                            direction: isDesktop
                                ? Axis.horizontal
                                : Axis.vertical,
                            crossAxisAlignment: isDesktop
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              // Left Column: Branding
                              Expanded(
                                flex: isDesktop ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "NEW REQUEST",
                                            style: AppTextStyles.label(
                                              12,
                                              color: AppColors.primary,
                                              weight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      "Give Reality",
                                      style: AppTextStyles.headline(
                                        isDesktop ? 80 : 56,
                                        weight: FontWeight.w900,
                                        color: Colors.white,
                                      ).copyWith(height: 0.85),
                                    ),
                                    Text(
                                      "To Your Ideas",
                                      style: AppTextStyles.headline(
                                        isDesktop ? 80 : 56,
                                        weight: FontWeight.w900,
                                        color: AppColors.secondary,
                                        italic: true,
                                      ).copyWith(height: 0.85),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      "Take the spotlight. Submit your event to the campus feed and let everyone know where the energy is at tonight.",
                                      style: AppTextStyles.body(
                                        18,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                              if (isDesktop) const SizedBox(width: 64),
                              // Right Column: Form Card
                              Expanded(
                                flex: isDesktop ? 1 : 0,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (isDesktop)
                                      Positioned(
                                        top: -48,
                                        right: -32,
                                        child: Transform.rotate(
                                          angle: 0.1,
                                          child: Container(
                                            width: 180,
                                            height: 180,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 30,
                                                  offset: const Offset(0, 15),
                                                ),
                                              ],
                                              image: const DecorationImage(
                                                image: NetworkImage(
                                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAtaXf3l-r_zP8BROR3LkJXVeQUMH2zFAlljaT4oYHtQtXq4b8KKNrVBHPFgz6n42qhcmdWGuKek0FphMnHRCqboNb0Rfr1UwUV9EFSFU_N2cj44LHnjcC3CET6AKAcftoNhJ5v4C8E3Y89HomFf2FeDdljjtvEWzVnjtUc-ddXWj6dyDn9K2CjER6tht7LfmbPgjq7guf1lGVb8zgEv1xlIdzBeE8Kvoadp6_9fSDt3Xx3PNV7iFOCCy7gcvC3Wv7slGJn4tijUik',
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(40),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withOpacity(
                                          0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            blurRadius: 80,
                                            offset: const Offset(0, 40),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _InputField(
                                            label: "EVENT TITLE",
                                            controller: _titleController,
                                            hintText: "WHAT'S THE OCCASION?",
                                          ),
                                          const SizedBox(height: 32),
                                          _InputField(
                                            label: "LOCATION",
                                            controller: _locationController,
                                            hintText: "WHERE IS THE EVENT ?",
                                            icon: Icons.location_on,
                                          ),
                                          const SizedBox(height: 32),
                                          _InputField(
                                            label: "DESCRIPTION",
                                            controller: _descriptionController,
                                            hintText:
                                                "TELL US MORE ABOUT IT...",
                                            maxLines: 3,
                                          ),
                                          const SizedBox(height: 32),
                                          _InputField(
                                            label: "EVENT DATE",
                                            controller: _dateController,
                                            hintText: "SELECT DATE",
                                            icon: Icons.calendar_today,
                                            readOnly: true,
                                            onTap: _selectDate,
                                          ),
                                          const SizedBox(height: 32),
                                          // Time Row
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InputField(
                                                  label: "START TIME",
                                                  controller:
                                                      _startTimeController,
                                                  hintText: "SELECT START",
                                                  readOnly: true,
                                                  onTap: () => _selectTime(
                                                    _startTimeController,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _InputField(
                                                  label: "END TIME",
                                                  controller:
                                                      _endTimeController,
                                                  hintText: "SELECT END",
                                                  readOnly: true,
                                                  onTap: () => _selectTime(
                                                    _endTimeController,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          _InputField(
                                            label: "RULES & GUIDELINES",
                                            controller: _rulesController,
                                            hintText:
                                                "ENTRY REQUIREMENTS, DRESS CODE, ETC.",
                                            maxLines: 4,
                                          ),
                                          const SizedBox(height: 32),
                                          Text(
                                            "CATEGORY",
                                            style: AppTextStyles.label(
                                              12,
                                              color: AppColors.onSurfaceVariant,
                                              weight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _categories.map((cat) {
                                              final isSelected =
                                                  _selectedCategory == cat;
                                              return GestureDetector(
                                                onTap: () => setState(
                                                  () => _selectedCategory = cat,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppColors.secondary
                                                              .withOpacity(0.1)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? AppColors.secondary
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    cat.toUpperCase(),
                                                    style: AppTextStyles.label(
                                                      12,
                                                      color: isSelected
                                                          ? AppColors.secondary
                                                          : AppColors
                                                                .onSurfaceVariant,
                                                      weight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 48),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // ── Validate all mandatory fields ──
                                              final missingFields = <String>[];
                                              if (_titleController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add(
                                                  'Event Title',
                                                );
                                              if (_locationController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add('Location');
                                              if (_descriptionController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add(
                                                  'Description',
                                                );
                                              if (_dateController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add('Event Date');
                                              if (_startTimeController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add('Start Time');
                                              if (_endTimeController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add('End Time');
                                              if (_rulesController.text
                                                  .trim()
                                                  .isEmpty)
                                                missingFields.add(
                                                  'Rules & Guidelines',
                                                );
                                              if (_selectedCategory.isEmpty)
                                                missingFields.add('Category');

                                              if (missingFields.isNotEmpty) {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: AppColors
                                                        .surfaceContainerHigh,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      side: BorderSide(
                                                        color: Colors.redAccent
                                                            .withOpacity(0.4),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .warning_amber_rounded,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 24,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'FILL ALL FIELDS',
                                                          style:
                                                              AppTextStyles.label(
                                                                14,
                                                                color: Colors
                                                                    .redAccent,
                                                                weight:
                                                                    FontWeight
                                                                        .w900,
                                                                letterSpacing:
                                                                    1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Please complete the following required fields:',
                                                          style: AppTextStyles.body(
                                                            14,
                                                            color: AppColors
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        ...missingFields.map(
                                                          (field) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  width: 6,
                                                                  height: 6,
                                                                  decoration: const BoxDecoration(
                                                                    color: Colors
                                                                        .redAccent,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Text(
                                                                  field,
                                                                  style: AppTextStyles.label(
                                                                    13,
                                                                    color: Colors
                                                                        .white,
                                                                    weight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                        style: TextButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.redAccent
                                                                  .withOpacity(
                                                                    0.15,
                                                                  ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  100,
                                                                ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'GOT IT',
                                                          style:
                                                              AppTextStyles.label(
                                                                12,
                                                                color: Colors
                                                                    .redAccent,
                                                                weight:
                                                                    FontWeight
                                                                        .w900,
                                                                letterSpacing:
                                                                    1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                return;
                                              }

                                              try {
                                                await _controller.submitRequest(
                                                  title: _titleController.text
                                                      .trim(),
                                                  category: _selectedCategory,
                                                  description:
                                                      _descriptionController
                                                          .text
                                                          .trim(),
                                                  location: _locationController
                                                      .text
                                                      .trim(),
                                                  eventDate: _dateController
                                                      .text
                                                      .trim(),
                                                  eventTime:
                                                      "${_startTimeController.text.trim()} - ${_endTimeController.text.trim()}",
                                                  rules: _rulesController.text
                                                      .trim(),
                                                );

                                                Get.snackbar(
                                                  "Success",
                                                  "Request submitted for approval!",
                                                  backgroundColor:
                                                      AppColors.secondary,
                                                  colorText: Colors.black,
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                );

                                                Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () {
                                                    Get.until(
                                                      (route) =>
                                                          Get.currentRoute ==
                                                          AppRoutes
                                                              .ANNOUNCEMENTS,
                                                    );
                                                  },
                                                );
                                              } catch (e) {
                                                Get.snackbar(
                                                  "Error",
                                                  e.toString(),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  colorText: Colors.white,
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.secondary,
                                              foregroundColor: Colors.black,
                                              minimumSize: const Size(
                                                double.infinity,
                                                64,
                                              ),
                                              elevation: 10,
                                              shadowColor: AppColors.secondary
                                                  .withOpacity(0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                            ),
                                            child: Text(
                                              "SUBMIT FOR APPROVAL",
                                              style: AppTextStyles.headline(
                                                20,
                                                weight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(
            12,
            color: AppColors.primary,
            weight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.body(16, color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.body(16, color: Colors.white38),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.onSurfaceVariant)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.headline(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.body(14, color: AppColors.onSurfaceVariant),
          ),
        ],
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
