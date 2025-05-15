import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/app_overview_page.dart';
import '../pages/recording_instructions_page.dart';
import '../pages/calibration_instructions_page.dart';
import '../pages/data_management_page.dart';
import '../../../onboarding/presentation/widgets/page_indicator.dart';

/// Instructions screen that guides users through how to use the app
class InstructionsScreen extends ConsumerStatefulWidget {
  const InstructionsScreen({super.key});

  @override
  ConsumerState<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends ConsumerState<InstructionsScreen>
    with SingleTickerProviderStateMixin {
  // For controlling the page view
  late final PageController _pageController;

  // For page transition animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Track current page in the widget state
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Set up animation controller for transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

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
    } else {
      // On the last page, return to home
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Instructions', style: TextStyle(fontSize: 16)),
        toolbarHeight: 42,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page View with instruction pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  // Update the local state
                  setState(() {
                    _currentPage = index;
                  });

                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildAnimatedPage(const AppOverviewPage()),
                  _buildAnimatedPage(const CalibrationInstructionsPage()),
                  _buildAnimatedPage(const RecordingInstructionsPage()),
                  _buildAnimatedPage(const DataManagementPage()),
                ],
              ),
            ),

            // Page indicators and navigation buttons
            Container(
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: PageIndicator(
                      currentPage: _currentPage,
                      pageCount: 4,
                    ),
                  ),

                  // Navigation button
                  SizedBox(
                    width: 180,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      child: Text(
                        _currentPage < 3 ? 'Next' : 'Done',
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
}
