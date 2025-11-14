import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatingController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_onboarding', true);
                    if (mounted) context.go(AppRouter.login);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.gray,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _scaleController.forward(from: 0);
                },
                itemCount: AppConstants.onboardingPages.length,
                itemBuilder: (context, index) {
                  final page = AppConstants.onboardingPages[index];
                  return _buildOnboardingSlide(page, index);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSlide(OnboardingContent content, int index) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Animated illustration container with custom animations per page
            if (index == 0)
              _buildTruckAnimation()
            else if (index == 1)
              _buildCallAnimation()
            else
              _buildChartAnimation(),

            const SizedBox(height: 40),

            // Title with shimmer effect
            Text(
              content.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut)
                .then()
                .shimmer(duration: 2000.ms, color: _getColorForIndex(index).withValues(alpha: 0.3)),

            const SizedBox(height: 16),

            // Subtitle with typing effect
            Text(
              content.subtitle,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.gray.withValues(alpha: 0.8),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Truck animation with moving effect
  Widget _buildTruckAnimation() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            100 * (1 - _floatingController.value) - 50, // Move left to right
            10 * _floatingController.value,
          ),
          child: child,
        );
      },
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                // Road lines animation
                ...List.generate(3, (i) => Positioned(
                  left: 40 + (i * 80.0),
                  bottom: 120,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .slideX(
                        begin: 0,
                        end: -2,
                        duration: 1000.ms,
                        curve: Curves.linear,
                      ),
                )),
                // Truck Lottie
                Center(
                  child: Lottie.asset(
                    AppConstants.onboardingPages[0].lottieAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_shipping_rounded,
                        size: 140,
                        color: AppTheme.primaryBlue,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 100.ms)
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }

  // Call animation with pulse effect
  Widget _buildCallAnimation() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * _floatingController.value),
          child: Transform.scale(
            scale: 1.0 + (0.05 * _floatingController.value),
            child: child,
          ),
        );
      },
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          color: AppTheme.accentPurple.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings
              ...List.generate(3, (i) => Container(
                height: 220 + (i * 25.0),
                width: 220 + (i * 25.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentPurple.withValues(alpha: 0.3 - (i * 0.1)),
                    width: 2,
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(duration: 1000.ms, delay: (i * 300).ms)
                  .then()
                  .fadeOut(duration: 1000.ms)),
              // Call Lottie
              Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Lottie.asset(
                    AppConstants.onboardingPages[1].lottieAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.phone_in_talk_rounded,
                        size: 140,
                        color: AppTheme.accentPurple,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 100.ms)
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }

  // Chart animation with live data effect
  Widget _buildChartAnimation() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * _floatingController.value),
          child: child,
        );
      },
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          color: AppTheme.accentBlue.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated chart bars
              Positioned(
                bottom: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (i) {
                    final heights = [60.0, 90.0, 75.0, 110.0, 85.0];
                    return Container(
                      width: 20,
                      height: heights[i],
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scaleY(
                          begin: 0.5,
                          end: 1.0,
                          duration: (1000 + i * 200).ms,
                          curve: Curves.easeInOut,
                        );
                  }),
                ),
              ),
              // Analytics Lottie
              Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Lottie.asset(
                    AppConstants.onboardingPages[2].lottieAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.analytics_rounded,
                        size: 140,
                        color: AppTheme.accentBlue,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 100.ms)
        .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Column(
        children: [
          // Page Indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: AppConstants.onboardingPages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppTheme.primaryBlue,
              dotColor: AppTheme.gray.withValues(alpha: 0.2),
              dotHeight: 10,
              dotWidth: 10,
              expansionFactor: 4,
              spacing: 8,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 700.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 40),

          // Action Button
          if (_currentPage == AppConstants.onboardingPages.length - 1)
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeOut,
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_seen_onboarding', true);
                      if (mounted) context.go(AppRouter.login);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 900.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut)
          else
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 900.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    switch (index) {
      case 0:
        return AppTheme.primaryBlue;
      case 1:
        return AppTheme.accentPurple;
      case 2:
        return AppTheme.accentBlue;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
