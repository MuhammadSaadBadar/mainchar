import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.signIn(email: email, password: password);
      // Success redirection is handled by AuthController listener
    } on AuthException catch (e) {
      String message = e.message;
      if (message.contains('Email not confirmed')) {
        message =
            'Please verify your email before logging in. Check your inbox!';
      }
      Get.snackbar(
        'Login Failed',
        message,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Error',
        message,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _AuthBackground(),
          const _GrainOverlay(),
          // Demo Button Top Left
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.DEMO_EXPLORE),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DEMO',
                      style: AppTextStyles.label(
                        12,
                        color: Colors.black,
                        weight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const AuthHeader(activeLink: 'Login'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 900) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(
                                    flex: 5,
                                    child: _EditorialContent(),
                                  ),
                                  const SizedBox(width: 64),
                                  Expanded(
                                    flex: 6,
                                    child: _LoginCard(
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      obscurePassword: _obscurePassword,
                                      isLoading: _isLoading,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      onLogin: _handleLogin,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  const _EditorialContent(),
                                  const SizedBox(height: 48),
                                  _LoginCard(
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    obscurePassword: _obscurePassword,
                                    isLoading: _isLoading,
                                    onTogglePassword: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    onLogin: _handleLogin,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _ImageGrid()),
                const SliverToBoxAdapter(child: _Footer()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/login_register_background.webp',
            fit: BoxFit.cover,
            cacheWidth: 1080, // Memory optimization
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
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
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAsFuPGoD8EWDRhr46-2THU1ZUJHhIyYy6eJmVTFLynTqQt_fdMoxdiH6GeyRJu_2kDySQThUyGMh8fDDwazhz-TbouWTjdyZ9kLUImZoTooPt5YnkgoX38DddcHi_xlZjD7IkaGAsb8bWmzCG-2Z3GxtMzRP7AiCRmGIKMWP-XgUHTRvlS8dy2NBq_UiiDVB4RxySSQ4BgV1xvoS5OWyvR_HKQpWj4Sp2k6sJXhibJWuj1xGxVeLPl1K72Jqh99BHL0oiF8zBpFaU',
              ),
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialContent extends StatefulWidget {
  const _EditorialContent();

  @override
  State<_EditorialContent> createState() => _EditorialContentState();
}

class _EditorialContentState extends State<_EditorialContent>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _jumpController;
  late Animation<Offset> _jumpAnimation;

  @override
  void initState() {
    super.initState();
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _jumpAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.15),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_jumpController);

    // Initial delay then start periodic jump
    _startPeriodicJump();
  }

  void _startPeriodicJump() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted && !_isHovered) {
        await _jumpController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.DEMO_EXPLORE),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: _isHovered ? 32 : 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.secondary.withOpacity(0.2)
                    : AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.secondary
                      : AppColors.secondary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(
                      _isHovered ? 0.3 : 0.05,
                    ),
                    blurRadius: _isHovered ? 40 : 20,
                    spreadRadius: _isHovered ? 5 : 2,
                  ),
                ],
              ),
              child: SlideTransition(
                position: _jumpAnimation,
                child: Text(
                  'TAKE A TOUR',
                  style: AppTextStyles.headline(
                    32,
                    color: AppColors.secondary,
                    italic: true,
                    weight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 56),

        RichText(
          text: TextSpan(
            style: AppTextStyles.headline(64, weight: FontWeight.w900),
            children: [
              const TextSpan(text: 'Step in\n'),
              TextSpan(
                text: 'To Your People',
                style: AppTextStyles.headline(
                  64,
                  color: AppColors.secondary,
                  italic: true,
                  weight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Welcome back to the spotlight. Dive back into the hype.",
          style: AppTextStyles.body(18, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            _AvatarStack(),
            SizedBox(width: 16),
            Text(
              'Ready to see who\'s around?',
              style: AppTextStyles.label(
                12.0,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BentoStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.headline(32, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.label(
              10,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    final avatars = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDmqQA5SsZLwR6_moht9xBQPVuNS_-Dg2N3wAAEnvqHnD3m3t0C2tkfIbjtn5kiN2Ix8en9Il3jg4F9V06wX3VdfNQcJOgIDR5AiYS1Wxim49sd7h3N51y9P5DcrSSf1rbfD1z3eJUgbelbjf1LWPaYsMmosDwvw3-xCVX3FLy_H3JfEF2hvveGWTJgqX9eZfN4LBRsFYW_u9OVdfxrpe67BDgtrP_c0AqTZ_awAD0x0rQbi1e7W3iE_9DONTHtuVBZO4A_0PddBL4',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDKEi8RqKptMwqe1cKfqgUTvjyWAdaeEGU-g1ft8cLMiCUly6r3kFaM21GykDFddGry8OGODNfY3F6RWXTisNW6J155aigpXzpzhVbiaJbFPWDlektj_c6yOpKep2bdh9K47TDSIsjO_s8aTjOuprEABbTpZEDLJoK6Bjokmu1QOYRJskOEPO4XXFgITC19ocaaxXpX7FAXoqYw19XBM44YnYkKma3jCKdWD9qeGuzQukaTcckl2o-_5F_HIpxeQNO9L6gfoDmccf4',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBVvzD0coY5HMwlxsIs85hLWEdH3nrrLFC6SEjNnTRCGYPUYT0j7KFhYfcsN-58onXZ3pEVGSGqG23nsVZgp7qJLjqkQRBiMsbQwTw9qEcCUkeK5RSwGPJRHb4rsdSP4q0-Ss_gl4uaV5zWbH4j-LwzDJ0uEoLdF2QF7OuyZ6zMq0_aJxoEiuFdU6gSvjRIX8Xae8K3tgZrlBudE9gzcG_zbaAa4Q8BKyCkATO4rWQ7fsrDMmJRQxsdoAmRriTvNPwwgVQs32kqATk',
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < avatars.length; i++)
          Transform.translate(
            offset: Offset(i * -12.0, 0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
                image: DecorationImage(
                  image: NetworkImage(avatars[i]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset((avatars.length) * -12.0, 0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: Center(
              child: Text(
                '+',
                style: AppTextStyles.label(
                  10,
                  color: AppColors.secondary,
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF262626).withOpacity(0.7),
                const Color(0xFF141414).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: AppTextStyles.headline(32, weight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your campus credentials to dive back into the hype.',
                style: AppTextStyles.body(
                  14,
                  color: AppColors.onSurfaceVariant,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _FormField(
                label: 'UNIVERSITY EMAIL',
                hint: '000000000@student.uol.edu.pk',
                icon: Icons.alternate_email,
                controller: emailController,
              ),
              const SizedBox(height: 24),
              _FormField(
                label: 'PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_outline,
                controller: passwordController,
                isPassword: true,
                obscureText: obscurePassword,
                onToggleVisibility: onTogglePassword,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.FORGOT_PASSWORD),
                  icon: const Icon(
                    Icons.lock_reset,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  label: Text(
                    'FORGOT PASSWORD?',
                    style: AppTextStyles.label(
                      10,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: const Color(0xFF354500),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 10,
                    shadowColor: AppColors.secondary.withOpacity(0.25),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF354500),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GET THE VIBE',
                              style: AppTextStyles.headline(
                                18,
                                weight: FontWeight.w900,
                                color: const Color(0xFF354500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white12),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    _SmallLink(
                      label: "Don't have access yet?",
                      icon: Icons.lock_outline_rounded,
                      color: AppColors.onSurfaceVariant,
                      onTap: () => Get.toNamed(AppRoutes.REGISTER),
                    ),
                    const SizedBox(height: 16),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     _SmallLink(
                    //       label: 'Need an Invite?',
                    //       icon: Icons.mail_rounded,
                    //       color: AppColors.primary,
                    //       onTap: () => Get.toNamed(AppRoutes.REGISTER),
                    //     ),
                    //     const SizedBox(width: 32),
                    //     const _SmallLink(
                    //       label: 'Need Help?',
                    //       icon: Icons.help_outline_rounded,
                    //       color: AppColors.onSurfaceVariant,
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallLink({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.label(
              10,
              color: color,
              weight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 16),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: AppTextStyles.label(
              10,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2.0,
              weight: FontWeight.bold,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(16, color: AppColors.outline),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: AppColors.outline, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          style: AppTextStyles.body(16, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid();

  @override
  Widget build(BuildContext context) {
    final images = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuApHi-ygDUtsfchU7gA3GciF9-mGioHuz0axDSoOQv8GcwI9Pj6UKyZM86_ElEz6BA5MAUDZ18js4ys9kK4fImRPkLoNKf1YQJMslFPePk9WGlfDv3srAJUReGsbyGVLurG_YZD6xibLr2IiGApGG5xmAw6-RXUPZJcfWuP1TerqUlGRHMw1oTRz7ijXQwfAIRU9z4NMy_AgSciesYN05xSB5C5teR1PJZvg3HXHICkB0Yxf56kgrUaKqdHcVbJzJQMo-izCKmDn1M',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAcIn9Yu_h_uI_c2Z9ybed61Gx__O5WH1mzNy_Du8CbMo3qG6K7-DfgeztuHW-drUhM7gfpRSdva2THkvtodZ8kRyDiOFFiGf6VZl9-EcYrEK1u_TDMBT7N22_xvFb8ixb1pSwPP80RrI-oO1bW6jxF_7cfnzPFse0nSmZ0rzTG8srb5JNuqFQewbqMHwu2Z6j70Z9yyd_lBVrCERCcTlpwhtafXVWfFqiVl8bo4smpvxJN4D8o26fC0GjyNS_fsK-Quvj-JNHI5j8',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCYdEpIhds_x2zPtXOuNuPWuVTGU9vEtrqYJzZUHWL5E-cQYl4X-urPGngKFMFxglZhfsZ5JdXabaLMqdjaD_yS7fXVT2U-5gK7haaZMPg0gAb9uQXUL9i3vQS5ocQcha-ViIAEzOHRil6bTr9IVnvORFTEysYcqa_gRYR9tlk65jRaiQubOOnQUxGr0G8IrxGuMJfXyBq_utAOw5UPY-SlAhsBWTKG5ZuyndJ9rq8bWk-imCN9JDax8yqfoES0oJ9-pTQEUynC7-o',
    ];

    return Opacity(
      opacity: 0.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              children: images
                  .map(
                    (url) => Expanded(
                      child: Container(
                        height: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFF20201F),
          ),
          const SizedBox(height: 48),
          Text(
            'CAMPUS VIBE',
            style: AppTextStyles.headline(
              20,
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
          Container(height: 1, width: 96, color: const Color(0xFF1A1A1A)),
          const SizedBox(height: 24),
          Text(
            '© 2024 MAIN CHARACTER ENERGY. .EDU VERIFIED.',
            style: AppTextStyles.label(
              10,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2.0,
            ),
          ),
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
        color: AppColors.onSurfaceVariant,
        letterSpacing: 2.0,
        weight: FontWeight.bold,
      ),
    );
  }
}
