import 'dart:async';

import 'package:flutter/material.dart';

/// Callback type for annotation responses
typedef AnnotationResponseCallback = void Function(String response);

/// A non-blocking overlay widget that prompts the user to annotate a detected spike
/// as a pothole or not
class AnnotationPromptWidget extends StatefulWidget {
  /// Duration for which the prompt is displayed (defaults to 10 seconds)
  final Duration displayDuration;

  /// Callback for when the user responds (Yes/No) or when timeout occurs
  final AnnotationResponseCallback onResponse;

  /// Creates an AnnotationPromptWidget
  const AnnotationPromptWidget({
    super.key,
    this.displayDuration = const Duration(seconds: 10),
    required this.onResponse,
  });

  @override
  State<AnnotationPromptWidget> createState() => _AnnotationPromptWidgetState();
}

class _AnnotationPromptWidgetState extends State<AnnotationPromptWidget>
    with SingleTickerProviderStateMixin {
  /// Timer for automatic dismissal
  Timer? _timer;

  /// Remaining seconds for display
  int _remainingSeconds = 10;

  /// Animation controller for entrance animation
  late AnimationController _animationController;

  /// Animation for the entrance effect
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation for smooth entrance
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();

    // Initialize remaining seconds from the display duration
    _remainingSeconds = widget.displayDuration.inSeconds;

    // Set up the timer to update countdown and dismiss on completion
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _handleTimeout();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Handles user selection of Yes
  void _handleYesResponse() {
    widget.onResponse('Yes');
    _timer?.cancel();
  }

  /// Handles user selection of No
  void _handleNoResponse() {
    widget.onResponse('No');
    _timer?.cancel();
  }

  /// Handles timeout (no user response)
  void _handleTimeout() {
    widget.onResponse('Uncategorized');
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;

    // Container dimensions based on orientation
    final containerWidth =
        isLandscape ? screenSize.width * 0.6 : screenSize.width * 0.85;

    // Use specified height for landscape instead of letting it adjust automatically
    final containerHeight =
        isLandscape
            ? screenSize.height *
                0.6 // 60% of screen height in landscape
            : null; // Auto in portrait

    // Use primary color from the theme
    final primaryColor = theme.colorScheme.primary;

    return Material(
      // Make sure the Material widget covers the entire screen
      type: MaterialType.transparency,
      child: Container(
        // Add the shadow background across the entire screen
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                width: containerWidth,
                height: containerHeight,
                constraints:
                    isLandscape ? const BoxConstraints(minHeight: 230) : null,
                decoration: BoxDecoration(
                  color: Colors.grey[850]?.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.7),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                    isLandscape
                        ? _buildLandscapeLayout(theme, primaryColor)
                        : _buildPortraitLayout(theme, primaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build layout for portrait orientation
  Widget _buildPortraitLayout(ThemeData theme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              'Bump Detected!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Was this a pothole?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Response buttons - larger and more spaced out for easy tapping while driving
        _buildResponseButton(
          label: 'YES - POTHOLE',
          backgroundColor: theme.colorScheme.primary,
          onPressed: _handleYesResponse,
          fullWidth: true,
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 16),
        _buildResponseButton(
          label: 'NO - NOT POTHOLE',
          backgroundColor: theme.colorScheme.secondary,
          onPressed: _handleNoResponse,
          fullWidth: true,
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(height: 16),

        // Timer indicator
        LinearProgressIndicator(
          value: _remainingSeconds / widget.displayDuration.inSeconds,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          'Auto-dismissing in $_remainingSeconds seconds',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build layout for landscape orientation
  Widget _buildLandscapeLayout(ThemeData theme, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side - Information
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Bump Detected!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Was this a pothole?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Timer indicator
                LinearProgressIndicator(
                  value: _remainingSeconds / widget.displayDuration.inSeconds,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_remainingSeconds seconds remaining',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Right side - Buttons
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResponseButton(
                  label: 'YES - POTHOLE',
                  backgroundColor: theme.colorScheme.primary,
                  onPressed: _handleYesResponse,
                  fullWidth: true,
                  icon: Icons.check_circle_outline,
                  height: 70,
                ),
                const SizedBox(height: 20),
                _buildResponseButton(
                  label: 'NO - NOT POTHOLE',
                  backgroundColor: theme.colorScheme.secondary,
                  onPressed: _handleNoResponse,
                  fullWidth: true,
                  icon: Icons.cancel_outlined,
                  height: 70,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build consistent response buttons
  Widget _buildResponseButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool fullWidth = false,
    IconData? icon,
    double? height,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 56, // Increased height for better touchability
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height != null ? 24 : 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: height != null ? 18 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to manage the display and removal of the AnnotationPromptWidget
/// as an overlay
class AnnotationPromptOverlay {
  /// The overlay entry that contains the widget
  OverlayEntry? _overlayEntry;

  /// The BuildContext to use for showing the overlay
  final BuildContext context;

  /// Static flag to prevent multiple overlays from being shown simultaneously
  static bool _isOverlayCurrentlyShowing = false;

  /// Creates an AnnotationPromptOverlay
  AnnotationPromptOverlay(this.context);

  /// Shows the annotation prompt overlay
  ///
  /// [onResponse] is called when the user responds or when timeout occurs
  void show({
    required AnnotationResponseCallback onResponse,
    Duration displayDuration = const Duration(seconds: 10),
  }) {
    // Skip showing if an overlay is already visible
    if (_isOverlayCurrentlyShowing) {
      return;
    }

    // Remove any existing overlay
    hide();

    // Set flag to indicate an overlay is now showing
    _isOverlayCurrentlyShowing = true;

    // Create a new overlay entry
    _overlayEntry = OverlayEntry(
      builder:
          (context) => AnnotationPromptWidget(
            displayDuration: displayDuration,
            onResponse: (response) {
              onResponse(response);
              hide();
            },
          ),
    );

    // Insert the overlay into the navigator
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hides the annotation prompt overlay if it is displayed
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOverlayCurrentlyShowing = false;
  }
}
