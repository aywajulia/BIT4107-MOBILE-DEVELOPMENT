/// swipe_controller.dart
/// Location: lib/handlers/swipe_controller.dart
library;

class SwipeController {
  final int totalTabs;
  int _currentIndex;

  SwipeController({required this.totalTabs, int initialIndex = 0})
      : _currentIndex = initialIndex.clamp(0, totalTabs - 1);

  int get currentIndex => _currentIndex;

  int onSwipeLeft() {
    _currentIndex = (_currentIndex + 1) % totalTabs;
    return _currentIndex;
  }

  int onSwipeRight() {
    _currentIndex = (_currentIndex - 1) % totalTabs;
    if (_currentIndex < 0) _currentIndex = totalTabs - 1;
    return _currentIndex;
  }

  void setIndex(int index) {
    _currentIndex = index.clamp(0, totalTabs - 1);
  }
}