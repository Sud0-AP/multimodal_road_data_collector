import 'package:flutter/material.dart';

/// Placeholder for the onboarding screen that will guide new users through
/// the app's features and request necessary permissions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // For controlling the page view
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  // Will be replaced with actual onboarding pages
                  Center(child: Text('Welcome Page')),
                  Center(child: Text('Mounting Instructions')),
                  Center(child: Text('Data Explanation')),
                  Center(child: Text('Permissions Rationale')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button (only on first pages)
                  _currentPage < 3
                      ? TextButton(
                        onPressed: () {
                          // Skip to the last page
                          _pageController.animateToPage(
                            3,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Skip'),
                      )
                      : const SizedBox.shrink(),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        // Go to next page
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // On the last page, will implement onboarding completion logic
                        // TODO: Implement onboarding completion with preferences service
                      }
                    },
                    child: Text(_currentPage < 3 ? 'Next' : 'Get Started'),
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
