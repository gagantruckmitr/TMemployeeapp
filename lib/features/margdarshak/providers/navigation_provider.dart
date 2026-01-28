import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation state for Margdarshak module
class MargdarshakNavigationState {
  final int currentTabIndex;
  final String? activeFilter;

  MargdarshakNavigationState({this.currentTabIndex = 0, this.activeFilter});

  MargdarshakNavigationState copyWith({
    int? currentTabIndex,
    String? activeFilter,
  }) {
    return MargdarshakNavigationState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class MargdarshakNavigationNotifier
    extends StateNotifier<MargdarshakNavigationState> {
  MargdarshakNavigationNotifier() : super(MargdarshakNavigationState());

  void switchToTab(int index) {
    state = state.copyWith(currentTabIndex: index);
  }

  void setActiveFilter(String? filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void navigateToDriversWithFilter(String filter) {
    state = state.copyWith(currentTabIndex: 3, activeFilter: filter);
  }
}

// Provider
final margdarshakNavigationProvider =
    StateNotifierProvider<
      MargdarshakNavigationNotifier,
      MargdarshakNavigationState
    >((ref) {
      return MargdarshakNavigationNotifier();
    });
