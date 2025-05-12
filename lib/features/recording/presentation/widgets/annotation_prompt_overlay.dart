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

class _AnnotationPromptWidgetState extends State<AnnotationPromptWidget> {
  /// Timer for automatic dismissal
  Timer? _timer;

  /// Remaining seconds for display
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();

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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bump Detected!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Was this a pothole?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please classify the road anomaly:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResponseButton(
                    label: 'Yes, Pothole',
                    backgroundColor: Colors.green,
                    onPressed: _handleYesResponse,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 10),
                  _buildResponseButton(
                    label: 'No, Not Pothole',
                    backgroundColor: Colors.red,
                    onPressed: _handleNoResponse,
                    fullWidth: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Dismissing in $_remainingSeconds seconds...',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build consistent response buttons
  Widget _buildResponseButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
