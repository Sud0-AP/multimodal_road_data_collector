import 'package:flutter/material.dart';
import '../pages/welcome_page.dart';
import '../pages/mounting_instructions_page.dart';
import '../pages/data_explanation_page.dart';
import '../pages/permissions_rationale_page.dart';
import '../widgets/page_indicator.dart';

/// Onboarding screen that guides new users through the app's features
/// and requests necessary permissions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // For controlling the page view
  late final PageController _pageController;
  int _currentPage = 0;

  // Preload all pages to avoid rebuilding during transitions
  late final List<Widget> _pages;

  // For page transition animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize pages
    _pages = [
      const WelcomePage(),
      const MountingInstructionsPage(),
      const DataExplanationPage(),
      const PermissionsRationalePage(),
    ];

    // Set up animation controller for transitions with longer duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
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
    } else {
      // On the last page, will implement onboarding completion logic
      // TODO: Implement onboarding completion with preferences service
    }
  }

  void _skipToLastPage() {
    _animationController.reset();
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top-right (only on first pages)
            Align(
              alignment: Alignment.topRight,
              child:
                  _currentPage < 3
                      ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: _skipToLastPage,
                          child: const Text('Skip'),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            // Page View with onboarding pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const ClampingScrollPhysics(), // For smoother scrolling
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                children: List.generate(_pages.length, (index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    child: _pages[index],
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.scale(
                          scale: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                  );
                }),
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
}
