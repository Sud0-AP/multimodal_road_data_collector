// exponential_moving_average.dart
class EMAFilter {
  double _alpha;
  double? _previousEMA;

  EMAFilter({required double alpha}) : _alpha = alpha {
    if (alpha <= 0 || alpha > 1) {
      throw ArgumentError(
        'Alpha must be between 0 (exclusive) and 1 (inclusive).',
      );
    }
  }

  double filter(double currentValue) {
    if (_previousEMA == null) {
      _previousEMA = currentValue;
      return currentValue;
    }
    _previousEMA = _alpha * currentValue + (1 - _alpha) * _previousEMA!;
    return _previousEMA!;
  }

  void reset() {
    _previousEMA = null;
  }

  // Allow updating alpha if needed, e.g., for dynamic adjustments
  set alpha(double newAlpha) {
    if (newAlpha <= 0 || newAlpha > 1) {
      throw ArgumentError(
        'Alpha must be between 0 (exclusive) and 1 (inclusive).',
      );
    }
    _alpha = newAlpha;
  }
}
