import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/global_top_nav.dart';
import '../widgets/main_header.dart';
import '../widgets/activity_chip.dart';
import '../widgets/activity_picker_sheet.dart';
import '../constants/university_activities.dart';
import '../routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../utils/image_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRevealHour = false;
  bool _isEditing = false;
  final TextEditingController _usernameController = TextEditingController();
  List<String> _selectedTags = [];
  Uint8List? _imageBytes;
  List<Map<String, dynamic>> _memories = [];

  // Real-time Stats
  int _upvotesCount = 0;
  int _globalRank = 0;
  StreamSubscription? _votesSubscription;

  String? _targetUserId;
  bool _isSelfProfile = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _targetUserId = args != null && args['userId'] != null
        ? args['userId'] as String
        : currentUserId;

    _isSelfProfile = _targetUserId == currentUserId;

    _fetchUserData();
    _checkRevealStatus();
    _fetchVoteCount(); // Fetch initial count manually
    _initRealtimeVotes();
  }

  @override
  void dispose() {
    _votesSubscription?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  void _checkRevealStatus() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _isRevealHour = (now.day == lastDay.day && now.hour == 20);
    });
  }

  void _initRealtimeVotes() {
    if (_targetUserId == null) return;

    debugPrint('Profile - Initializing Real-time Votes for: $_targetUserId');

    _votesSubscription = Supabase.instance.client
        .from('votes')
        .stream(primaryKey: ['id'])
        .eq('target_id', _targetUserId!)
        .listen(
          (List<Map<String, dynamic>> data) {
            final count = data.where((v) => v['is_recognized'] == true).length;
            debugPrint('Profile - Stream Update: $count recognized votes found');
            if (mounted) {
              setState(() {
                _upvotesCount = count;
              });
              _fetchUserRank();
            }
          },
          onError: (error) {
            debugPrint('Profile - Stream Error: $error');
          },
        );
  }

  Future<void> _fetchVoteCount() async {
    if (_targetUserId == null) return;

    try {
      // Debug: Check table columns
      final debugRes = await Supabase.instance.client.from('votes').select().limit(1);
      if (debugRes.isNotEmpty) {
        debugPrint('Profile - Votes Table Columns: ${debugRes.first.keys.toList()}');
      }

      final response = await Supabase.instance.client
          .from('votes')
          .select('target_id')
          .eq('target_id', _targetUserId!)
          .eq('is_recognized', true);

      final count = (response as List).length;
      debugPrint('Profile - Initial Fetch: $count recognized votes found');

      if (mounted) {
        setState(() {
          _upvotesCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vote count: $e');
    }
  }

  Future<void> _fetchUserRank() async {
    if (_targetUserId == null) return;

    try {
      // NEW: Using RPC for scalable server-side rank calculation
      final response = await Supabase.instance.client.rpc(
        'get_user_stats',
        params: {'target_user_id': _targetUserId},
      );

      if (mounted && response != null && (response as List).isNotEmpty) {
        final stats = response[0];
        setState(() {
          _upvotesCount = int.parse(stats['total_votes'].toString());
          _globalRank = int.parse(stats['global_rank'].toString());
        });
      }
    } catch (e) {
      debugPrint('Error fetching rank via RPC: $e');
    }
  }

  Future<void> _fetchUserData() async {
    if (_targetUserId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', _targetUserId!)
          .single();

      final memoriesResponse = await Supabase.instance.client
          .from('memories')
          .select()
          .eq('user_id', _targetUserId!)
          .order('created_at', ascending: false);

      setState(() {
        _userData = response;
        _selectedTags = List<String>.from(response['vibe_tags'] ?? []);
        _memories =
            (memoriesResponse as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        _isLoading = false;
      });
      debugPrint(
        'Profile - Data Fetched: ${response['username']}, Memories: ${_memories.length}',
      );
      _fetchVoteCount(); // Refresh vote count as well
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _usernameController.text = _userData?['username'] ?? '';
        _selectedTags = List<String>.from(_userData?['vibe_tags'] ?? []);
        _imageBytes = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      debugPrint('Selected image: ${image.name}, size: ${bytes.length} bytes');
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveChanges() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _userData?['avatar_url'];
      if (_imageBytes != null) {
        final filePath =
            '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint('Uploading to Supabase (Web Binary): $filePath');

        // NEW: Compress avatar before upload
        final compressedBytes = await ImageUtils.compressAvatar(_imageBytes!);

        await (Supabase.instance.client.storage.from('avatars') as dynamic)
            .uploadBinary(
              filePath,
              compressedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        avatarUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(filePath);

        debugPrint('Generated Public URL: $avatarUrl');
      }

      await Supabase.instance.client
          .from('users')
          .update({
            'username': _usernameController.text.trim(),
            'vibe_tags': _selectedTags,
            'avatar_url': avatarUrl,
          })
          .eq('id', user.id);

      debugPrint('Profile - User DB updated successfully');
      await _fetchUserData();
      await Get.find<AuthController>().refreshUserProfile();

      setState(() => _isEditing = false);
      Get.snackbar(
        'Success',
        'Profile updated!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleUploadMemory(Uint8List bytes, String description) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final filePath =
          '${user.id}/memory_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // NEW: Compress memory image before upload
      final compressedBytes = await ImageUtils.compressImage(bytes);

      await (Supabase.instance.client.storage.from('memories') as dynamic)
          .uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('memories')
          .getPublicUrl(filePath);

      await Supabase.instance.client.from('memories').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'description': description,
      });

      debugPrint('Profile - Memory DB entry created');
      await _fetchUserData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload memory: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteMemory(int id) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      debugPrint('Profile - Deleting memory ID: $id');
      await Supabase.instance.client.from('memories').delete().eq('id', id);
      await _fetchUserData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete memory: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'LOGOUT',
          style: AppTextStyles.label(
            18,
            weight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        content: Text(
          'Are you sure you want to end your session?',
          style: AppTextStyles.body(16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'CANCEL',
              style: AppTextStyles.label(
                12,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<AuthController>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              elevation: 0,
            ),
            child: Text(
              'LOGOUT',
              style: AppTextStyles.label(
                12,
                weight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      barrierColor: Colors.black87,
    );
  }

  void _showDeleteConfirmationDialog() {
    final passwordController = TextEditingController();
    final RxBool isConfirming = false.obs;
    final RxString errorMessage = ''.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'DELETE ACCOUNT',
          style: AppTextStyles.label(
            18,
            weight: FontWeight.w900,
            color: Colors.redAccent,
          ),
        ),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your memories, votes, and profile data will be permanently erased.',
              style: AppTextStyles.body(14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter your password to confirm:',
              style: AppTextStyles.label(12, color: Colors.white54, weight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white30),
              ),
            ),
            if (errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage.value,
                style: AppTextStyles.body(14, color: Colors.redAccent),
              ),
            ],
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'CANCEL',
              style: AppTextStyles.label(
                12,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Obx(() => ElevatedButton(
            onPressed: isConfirming.value ? null : () async {
              if (passwordController.text.isEmpty) {
                errorMessage.value = 'Please enter your password.';
                return;
              }
              isConfirming.value = true;
              errorMessage.value = '';
              final success = await _handleDeleteAccount(passwordController.text);
              if (!success) {
                isConfirming.value = false;
                errorMessage.value = 'Incorrect password or an error occurred.';
              } else {
                Get.back(); // Close dialog
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              elevation: 0,
            ),
            child: isConfirming.value
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
                )
              : Text(
              'DELETE FOREVER',
              style: AppTextStyles.label(
                12,
                weight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          )),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      barrierColor: Colors.black87,
    );
  }

  Future<bool> _handleDeleteAccount(String password) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      // 1. Verify password
      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email,
        password: password,
      );

      // 2. Delete from Storage: Avatars bucket
      final avatarList = await Supabase.instance.client.storage.from('avatars').list(path: user.id);
      if (avatarList.isNotEmpty) {
        final List<String> paths = avatarList.map((file) => '${user.id}/${file.name}').toList();
        await Supabase.instance.client.storage.from('avatars').remove(paths);
      }

      // 3. Delete from Storage: Memories bucket
      final memoryList = await Supabase.instance.client.storage.from('memories').list(path: user.id);
      if (memoryList.isNotEmpty) {
        final List<String> paths = memoryList.map((file) => '${user.id}/${file.name}').toList();
        await Supabase.instance.client.storage.from('memories').remove(paths);
      }

      // 4. Delete DB rows manually to be safe
      await Supabase.instance.client.from('memories').delete().eq('user_id', user.id);
      await Supabase.instance.client.from('users').delete().eq('id', user.id);

      // 5. Delete Supabase Auth User via RPC
      try {
        await Supabase.instance.client.rpc('delete_user_account');
      } catch (rpcError) {
        debugPrint('RPC error (non-fatal if you just wiped data): $rpcError');
      }
      
      // 6. Logout
      Get.find<AuthController>().signOut();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundImage(),
          const _BackgroundBlobs(),
          const _GrainOverlay(),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: MainHeader(title: 'CAMPUS VIBE')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Builder(
                    builder: (_) {
                      final isSpecialAdmin =
                          Supabase.instance.client.auth.currentUser?.email ==
                          'sp24-bse-082@cuilahore.edu.pk';
                      if (!isSpecialAdmin) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.ADMIN),
                          icon: const Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            "ADMIN DASHBOARD",
                            style: AppTextStyles.label(
                              12,
                              color: AppColors.secondary,
                              weight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.secondary.withOpacity(
                              0.1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: AppColors.secondary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 24,
                  right: 24,
                  bottom: 48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return _DesktopLayout(
                              userData: _userData,
                              isRevealHour: _isRevealHour,
                              isEditing: _isEditing,
                              usernameController: _usernameController,
                              selectedTags: _selectedTags,
                              imageBytes: _imageBytes,
                              upvotesCount: _upvotesCount,
                              globalRank: _globalRank,
                              onToggleEdit: _toggleEdit,
                              onPickImage: _pickImage,
                              onSave: _saveChanges,
                              onTagsChanged: (tags) =>
                                  setState(() => _selectedTags = tags),
                              isSaving: _isSaving,
                              isSelfProfile: _isSelfProfile,
                              onLogout: _handleLogout,
                              onDeleteAccount: _showDeleteConfirmationDialog,
                            );
                          } else {
                            return _MobileLayout(
                              userData: _userData,
                              isRevealHour: _isRevealHour,
                              isEditing: _isEditing,
                              usernameController: _usernameController,
                              selectedTags: _selectedTags,
                              imageBytes: _imageBytes,
                              upvotesCount: _upvotesCount,
                              globalRank: _globalRank,
                              onToggleEdit: _toggleEdit,
                              onPickImage: _pickImage,
                              onSave: _saveChanges,
                              onTagsChanged: (tags) =>
                                  setState(() => _selectedTags = tags),
                              isSaving: _isSaving,
                              isSelfProfile: _isSelfProfile,
                              onLogout: _handleLogout,
                              onDeleteAccount: _showDeleteConfirmationDialog,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _MemoriesSection(
                  memories: _memories,
                  onUpload: _handleUploadMemory,
                  onDelete: _handleDeleteMemory,
                  isSelfProfile: _isSelfProfile,
                ),
              ),
              const SliverToBoxAdapter(child: _Footer()),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/profile_background.jfif', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.8),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
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
              color: AppColors.primary.withOpacity(0.12),
            ),
          ).withBlur(120),
        ),
        Positioned(
          bottom: 100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.08),
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

class _HeroSection extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isRevealHour;
  final bool isMobile;
  final bool isEditing;
  final VoidCallback? onPickImage;
  final Uint8List? imageBytes;
  final bool isSelfProfile;

  const _HeroSection({
    this.userData,
    required this.isRevealHour,
    this.isMobile = false,
    this.isEditing = false,
    this.onPickImage,
    this.imageBytes,
    this.isSelfProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        (userData?['avatar_url'] != null &&
            userData!['avatar_url'].toString().isNotEmpty) ||
        imageBytes != null;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Circular Profile Image
          GestureDetector(
            onTap: isEditing ? onPickImage : null,
            child: Container(
              width: isMobile ? 240 : 300,
              height: isMobile ? 240 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: isEditing
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.2),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              // FIX: Single unified child using Stack for overlay support
              child: hasAvatar
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        imageBytes != null
                            ? Image.memory(imageBytes!, fit: BoxFit.cover)
                            : Image.network(
                                userData!['avatar_url'],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 80,
                                      color: Colors.white10,
                                    ),
                              ),
                        // Camera overlay when editing
                        if (isEditing)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white70,
                              size: 40,
                            ),
                          ),
                      ],
                    )
                  : Icon(
                      isEditing
                          ? Icons.add_a_photo_rounded
                          : Icons.person_outline_rounded,
                      size: 80,
                      color: Colors.white10,
                    ),
            ),
          ),
          // Edit Pen Icon — shown only when not editing and it's self profile
          if (!isEditing && isSelfProfile)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isRevealHour;
  final bool isEditing;
  final TextEditingController usernameController;
  final List<String> selectedTags;
  final Uint8List? imageBytes;
  final int upvotesCount;
  final int globalRank;
  final VoidCallback onToggleEdit;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final Function(List<String>) onTagsChanged;
  final bool isSaving;
  final bool isSelfProfile;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _MobileLayout({
    this.userData,
    required this.isRevealHour,
    required this.isEditing,
    required this.usernameController,
    required this.selectedTags,
    this.imageBytes,
    required this.upvotesCount,
    required this.globalRank,
    required this.onToggleEdit,
    required this.onPickImage,
    required this.onSave,
    required this.onTagsChanged,
    required this.isSaving,
    this.isSelfProfile = true,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (MediaQuery.of(context).size.width < 768)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: GlobalTopNav(),
          ),
        GestureDetector(
          onTap: onToggleEdit,
          child: _HeroSection(
            userData: userData,
            isRevealHour: isRevealHour,
            isMobile: true,
            isEditing: isEditing,
            onPickImage: onPickImage,
            imageBytes: imageBytes,
            isSelfProfile: isSelfProfile,
          ),
        ),
        const SizedBox(height: 48),
        _ContentSection(
          userData: userData,
          isEditing: isEditing,
          usernameController: usernameController,
          selectedTags: selectedTags,
          onSave: onSave,
          onCancel: onToggleEdit,
          onTagsChanged: onTagsChanged,
          isSaving: isSaving,
          upvotesCount: upvotesCount,
          globalRank: globalRank,
          isSelfProfile: isSelfProfile,
          onLogout: onLogout,
          onDeleteAccount: onDeleteAccount,
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isRevealHour;
  final bool isEditing;
  final TextEditingController usernameController;
  final List<String> selectedTags;
  final Uint8List? imageBytes;
  final int upvotesCount;
  final int globalRank;
  final VoidCallback onToggleEdit;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final Function(List<String>) onTagsChanged;
  final bool isSaving;
  final bool isSelfProfile;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _DesktopLayout({
    this.userData,
    required this.isRevealHour,
    required this.isEditing,
    required this.usernameController,
    required this.selectedTags,
    this.imageBytes,
    required this.upvotesCount,
    required this.globalRank,
    required this.onToggleEdit,
    required this.onPickImage,
    required this.onSave,
    required this.onTagsChanged,
    required this.isSaving,
    this.isSelfProfile = true,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: GestureDetector(
            onTap: onToggleEdit,
            child: _HeroSection(
              userData: userData,
              isRevealHour: isRevealHour,
              isEditing: isEditing,
              onPickImage: onPickImage,
              imageBytes: imageBytes,
              isSelfProfile: isSelfProfile,
            ),
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          flex: 5,
          child: _ContentSection(
            userData: userData,
            isEditing: isEditing,
            usernameController: usernameController,
            selectedTags: selectedTags,
            onSave: onSave,
            onCancel: onToggleEdit,
            onTagsChanged: onTagsChanged,
            isSaving: isSaving,
            upvotesCount: upvotesCount,
            globalRank: globalRank,
            isSelfProfile: isSelfProfile,
            onLogout: onLogout,
            onDeleteAccount: onDeleteAccount,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isOutlined;

  const _Tag({required this.label, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined
            ? Colors.transparent
            : (AppColors.surfaceContainerHigh).withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isOutlined
              ? AppColors.onSurfaceVariant.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label(
          8,
          color: AppColors.onSurfaceVariant,
          weight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isEditing;
  final TextEditingController? usernameController;
  final List<String> selectedTags;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final Function(List<String>)? onTagsChanged;
  final bool isSaving;
  final int upvotesCount;
  final int globalRank;
  final bool isSelfProfile;
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;

  const _ContentSection({
    this.userData,
    this.isEditing = false,
    this.usernameController,
    this.selectedTags = const [],
    this.onSave,
    this.onCancel,
    this.onTagsChanged,
    this.isSaving = false,
    required this.upvotesCount,
    required this.globalRank,
    this.isSelfProfile = true,
    this.onLogout,
    this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          const SizedBox(height: 8),
          if (isEditing)
            TextField(
              controller: usernameController,
              style: AppTextStyles.headline(60, weight: FontWeight.w900),
              decoration: const InputDecoration(
                hintText: 'USERNAME',
                border: InputBorder.none,
              ),
            )
          else
            FittedBox(
              child: Text(
                (userData?['username'] ?? 'User').toUpperCase(),
                style: AppTextStyles.headline(100, weight: FontWeight.w900),
              ),
            ),
          const SizedBox(height: 22),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE ORIGIN STORY',
                    style: AppTextStyles.label(
                      10,
                      color: AppColors.primary,
                      letterSpacing: 3.0,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isEditing && isSelfProfile)
                    GestureDetector(
                      onTap: () {
                        Get.bottomSheet(
                          ActivityPickerSheet(
                            initialSelected: selectedTags,
                            onSave: onTagsChanged ?? (_) {},
                          ),
                          isScrollControlled: true,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              selectedTags.isEmpty
                                  ? 'ADD YOUR CAMPUS ACTIVITIES'
                                  : '${selectedTags.length} ACTIVITIES SELECTED',
                              style: AppTextStyles.label(
                                12,
                                color: AppColors.primary,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (selectedTags.isEmpty)
                    Text(
                      'No activities selected yet.',
                      style: AppTextStyles.body(
                        18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: selectedTags.map((tag) {
                        final activity = UniversityActivities.fromLabel(tag);
                        return ActivityChip(
                          label: tag,
                          icon: activity?.icon ?? '✨',
                          isCompact: true,
                        );
                      }).toList(),
                    ),
                  if (isEditing && isSelfProfile) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'SAVE CHANGES',
                                    style: AppTextStyles.label(
                                      12,
                                      color: Colors.white,
                                      weight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: isSaving ? null : onCancel,
                          child: Text(
                            'CANCEL',
                            style: AppTextStyles.label(
                              12,
                              color: Colors.white54,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!isSelfProfile) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.ARENA,
                            arguments: {
                              'initialProfile': {
                                'id': userData?['id'],
                                'username': userData?['username'],
                                'avatar_url': userData?['avatar_url'],
                                'vibe_tags': userData?['vibe_tags'],
                              },
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 20,
                          shadowColor: AppColors.secondary.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.electric_bolt_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'VOTE FOR THIS USER',
                              style: AppTextStyles.label(
                                12,
                                color: Colors.black,
                                weight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatBadge(
                        label: 'TOTAL VOTES',
                        value: upvotesCount.toString(),
                      ),
                      _StatBadge(
                        label: 'GLOBAL RANK',
                        value: '#$globalRank',
                        isSecondary: true,
                      ),
                      if (isSelfProfile)
                        _StatActionBadge(
                          label: 'RECOGNITIONS',
                          value: 'SEE YOUR VOTES',
                          onTap: () {
                            Get.toNamed(AppRoutes.VOTES_HISTORY);
                          },
                        ),
                    ],
                  ),
                  if (isSelfProfile && !isEditing) ...[
                    const SizedBox(height: 48),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onLogout,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.redAccent.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          backgroundColor: Colors.redAccent.withOpacity(0.03),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'LOGOUT FROM CAMPUS',
                              style: AppTextStyles.label(
                                14,
                                color: Colors.white.withOpacity(0.8),
                                weight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onDeleteAccount,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red.withOpacity(0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'DELETE ACCOUNT',
                              style: AppTextStyles.label(
                                14,
                                color: Colors.white,
                                weight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!isDesktop && isEditing) ...[
          const SizedBox(height: 24),
          TextField(
            controller: usernameController,
            style: AppTextStyles.headline(32, weight: FontWeight.w900),
            decoration: const InputDecoration(
              hintText: 'USERNAME',
              border: InputBorder.none,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;

  const _StatBadge({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label(
              8,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
              letterSpacing: 2.0,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline(
              24,
              color: isSecondary ? AppColors.secondary : Colors.white,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatActionBadge extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatActionBadge({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.label(
                8,
                color: AppColors.secondary,
                letterSpacing: 2.0,
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.label(
                    14,
                    color: Colors.white,
                    weight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemoryDialog extends StatefulWidget {
  final Future<void> Function(Uint8List, String) onUpload;

  const _AddMemoryDialog({required this.onUpload});

  @override
  State<_AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends State<_AddMemoryDialog> {
  final _captionController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _handleUpload() async {
    if (_imageBytes == null || _captionController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Image and caption are required');
      return;
    }
    setState(() => _isUploading = true);
    await widget.onUpload(_imageBytes!, _captionController.text.trim());
    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COLLECTIONS',
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.primary,
                              letterSpacing: 3.0,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ADD MEMORY',
                            style: AppTextStyles.headline(
                              24,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _imageBytes != null
                              ? AppColors.primary.withOpacity(0.5)
                              : Colors.white10,
                        ),
                        image: _imageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageBytes == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 48,
                                    color: AppColors.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'SELECT A PHOTO',
                                    style: AppTextStyles.label(
                                      10,
                                      color: Colors.white38,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _captionController,
                    style: AppTextStyles.body(16),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share the vibe of this moment...',
                      hintStyle: AppTextStyles.body(
                        16,
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handleUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'POST MEMORY',
                              style: AppTextStyles.label(
                                12,
                                color: Colors.white,
                                weight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories;
  final Future<void> Function(Uint8List, String) onUpload;
  final Future<void> Function(int) onDelete;
  final bool isSelfProfile;

  const _MemoriesSection({
    required this.memories,
    required this.onUpload,
    required this.onDelete,
    this.isSelfProfile = true,
  });

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddMemoryDialog(onUpload: onUpload),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Delete Memory?', style: AppTextStyles.headline(20)),
        content: Text(
          'This action cannot be undone.',
          style: AppTextStyles.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.label(12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(id);
            },
            child: Text(
              'Delete',
              style: AppTextStyles.label(12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemoryDetail(BuildContext context, Map<String, dynamic> memory) {
    Get.bottomSheet(
      _MemoryDetailSheet(memory: memory),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COLLECTIONS',
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.primary,
                              letterSpacing: 3.0,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SOME MEMORIES FROM UOL',
                            style: AppTextStyles.headline(
                              24,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (isSelfProfile)
                        IconButton(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 280,
                  child: memories.isEmpty
                      ? (isSelfProfile
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: index == 0
                                        ? () => _showAddDialog(context)
                                        : null,
                                    child: Container(
                                      width: 220,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 24,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color:
                                            AppColors.surfaceContainerHighest,
                                        border: index == 0
                                            ? Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.5),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: index == 0
                                          ? const Center(
                                              child: Icon(
                                                Icons.add,
                                                size: 48,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 48,
                                                color: Colors.white10,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  'NO MEMORIES SHARED YET',
                                  style: AppTextStyles.label(
                                    12,
                                    color: Colors.white24,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: memories.length,
                          itemBuilder: (context, index) {
                            final memory = memories[index];
                            return GestureDetector(
                              onTap: () => _showMemoryDetail(context, memory),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 220,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: AppColors.surfaceContainerHighest,
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          memory['image_url'],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primary
                                                    .withOpacity(0.2),
                                                strokeWidth: 2,
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                memory['description'],
                                                style: AppTextStyles.body(
                                                  12,
                                                  color: Colors.white,
                                                  weight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelfProfile)
                                    Positioned(
                                      top: 32,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () => _showDeleteDialog(
                                          context,
                                          memory['id'],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10,
                                              sigmaY: 10,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white10,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> memory;

  const _MemoryDetailSheet({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COLLECTIONS',
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.primary,
                              letterSpacing: 3.0,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MEMORY DETAIL',
                            style: AppTextStyles.headline(
                              24,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      memory['image_url'],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          width: double.infinity,
                          color: AppColors.surfaceContainerHighest,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary.withOpacity(0.5),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      memory['description'],
                      style: AppTextStyles.body(
                        18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 20,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Text(
                        'CLOSE',
                        style: AppTextStyles.label(
                          12,
                          weight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
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
          const SizedBox(height: 24),
          Text(
            '© 2024 MAIN CHARACTER ENERGY. .EDU VERIFIED.',
            style: AppTextStyles.label(
              10,
              letterSpacing: 2.0,
              weight: FontWeight.bold,
            ),
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
