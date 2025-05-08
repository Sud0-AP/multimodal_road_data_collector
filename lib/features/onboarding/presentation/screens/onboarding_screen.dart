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
    // We'll check the onboarding status when the provider is available
    ref.read(onboardingStateProvider.future).then((provider) {
      // Access the notifier from the provider
      final notifier = ref.read(provider.notifier);
      // Check if onboarding is already completed
      notifier.checkOnboardingStatus().then((_) {
        // If onboarding is complete, navigate to the home screen
        if (ref.read(provider).isComplete) {
          // Navigate to home screen
          _navigateToHome();
        }
      });
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
      ref.read(onboardingStateProvider.future).then((provider) {
        ref.read(provider.notifier).setCurrentPage(_currentPage + 1);
      });
    } else {
      // On the last page, complete onboarding
      _completeOnboardingAndRequestPermissions();
    }
  }

  void _completeOnboardingAndRequestPermissions() async {
    final provider = await ref.read(onboardingStateProvider.future);
    final notifier = ref.read(provider.notifier);

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

    ref.read(onboardingStateProvider.future).then((provider) {
      ref.read(provider.notifier).setCurrentPage(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top-right (only on first pages)
            Align(alignment: Alignment.topRight, child: _buildSkipButton()),

            // Page View with onboarding pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const ClampingScrollPhysics(), // For smoother scrolling
                onPageChanged: (index) {
                  // Update the local state
                  setState(() {
                    _currentPage = index;
                  });

                  // Update the provider state
                  ref.read(onboardingStateProvider.future).then((provider) {
                    ref.read(provider.notifier).setCurrentPage(index);
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

            // Bottom navigation section
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicator
                  PageIndicator(
                    pageCount: 4,
                    currentPage: _currentPage,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _currentPage < 3 ? 'Next' : 'Get Started',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Back button (not on first page)
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _animationController.reset();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                        _animationController.forward();
                      },
                      child: const Text('Back'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    if (_currentPage < 3) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextButton(
          onPressed: _skipToLastPage,
          child: const Text('Skip'),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAnimatedPage(Widget page) {
    return AnimatedBuilder(
      animation: _animationController,
      child: page,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(scale: _fadeAnimation.value, child: child),
        );
      },
    );
  }
}
