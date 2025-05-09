import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../pages/welcome_page.dart';
import '../pages/mounting_instructions_page.dart';
import '../pages/data_explanation_page.dart';
import '../pages/permissions_rationale_page.dart';
import '../widgets/page_indicator.dart';
import '../state/onboarding_state.dart';

/// Onboarding screen that guides new users through the app's features
/// and requests necessary permissions
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // For controlling the page view
  late final PageController _pageController;

  // For page transition animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Directly track the current page in the widget state
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Set up animation controller for transitions with longer duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Initialize the onboarding state
    _initOnboarding();

    // Add listener to page controller to update local state
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    if (_pageController.page != null &&
        _pageController.page!.round() != _currentPage) {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    }
  }

  // Initialize onboarding state and check status
  Future<void> _initOnboarding() async {
    // Use Future.microtask to ensure we're not modifying providers during build
    Future.microtask(() async {
      if (!mounted) return;

      // Check if onboarding is already completed
      final notifier = ref.read(onboardingNotifierProvider.notifier);
      await notifier.checkOnboardingStatus();

      // If onboarding is complete, navigate to the home screen
      if (mounted && ref.read(onboardingNotifierProvider).isComplete) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      context.go(AppRoutes.homePath);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 3) {
      _animationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();

      // Update the state with the new page
      // Use Future.microtask to avoid updating state during build
      Future.microtask(() {
        ref
            .read(onboardingNotifierProvider.notifier)
            .setCurrentPage(_currentPage + 1);
      });
    } else {
      // On the last page, complete onboarding
      _completeOnboardingAndRequestPermissions();
    }
  }

  void _completeOnboardingAndRequestPermissions() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Request permissions
    await notifier.requestAllPermissions();

    // Complete onboarding
    await notifier.completeOnboarding();

    // Dismiss loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Always navigate to home regardless of permission status
    // The app will handle permission checks in the features that need them
    _navigateToHome();
  }

  void _skipToLastPage() {
    _animationController.reset();
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();

    // Update the state with the new page
    setState(() {
      _currentPage = 3;
    });

    // Use Future.microtask to avoid updating state during build
    Future.microtask(() {
      ref.read(onboardingNotifierProvider.notifier).setCurrentPage(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen to the onboarding state
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top-right (only on first pages) - reduced padding
            SizedBox(
              height: 40, // Reduced fixed height for top slab
              child: Align(
                alignment: Alignment.topRight,
                child: _buildSkipButton(),
              ),
            ),

            // Page View with onboarding pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  // Update the local state
                  setState(() {
                    _currentPage = index;
                  });

                  // Update the provider state - use Future.microtask to avoid build-time updates
                  Future.microtask(() {
                    ref
                        .read(onboardingNotifierProvider.notifier)
                        .setCurrentPage(index);
                  });

                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildAnimatedPage(const WelcomePage()),
                  _buildAnimatedPage(const MountingInstructionsPage()),
                  _buildAnimatedPage(const DataExplanationPage()),
                  _buildAnimatedPage(const PermissionsRationalePage()),
                ],
              ),
            ),

            // Page indicators and navigation buttons - reduced bottom padding
            Container(
              padding: const EdgeInsets.only(
                bottom: 16.0,
                top: 8.0,
              ), // Reduced padding
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Make it take minimum vertical space
                children: [
                  // Page indicators - reduced vertical padding
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ), // Reduced padding
                    child: PageIndicator(
                      currentPage: _currentPage,
                      pageCount: 4,
                    ),
                  ),

                  // Navigation button - slightly smaller
                  SizedBox(
                    width: 180, // Slightly narrower
                    height: 46, // Slightly shorter
                    child: ElevatedButton(
                      onPressed:
                          onboardingState.isLoading ? null : _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                        ), // Reduced padding
                      ),
                      child:
                          onboardingState.isLoading
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _currentPage < 3 ? 'Next' : 'Get Started',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPage(Widget page) {
    return FadeTransition(opacity: _fadeAnimation, child: page);
  }

  Widget _buildSkipButton() {
    // Only show Skip button on pages 0, 1, 2 (not on the last page)
    if (_currentPage < 3) {
      return Padding(
        padding: const EdgeInsets.only(
          right: 10.0,
          top: 6.0,
        ), // Reduced padding
        child: TextButton(
          onPressed: _skipToLastPage,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ), // Reduced padding
          ),
          child: const Text('Skip', style: TextStyle(fontSize: 14)),
        ),
      );
    } else {
      // Return an empty container instead of SizedBox.shrink() to maintain layout
      return Container();
    }
  }
}
