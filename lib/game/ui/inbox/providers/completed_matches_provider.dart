import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/providers/app_providers.dart';

/// Immutable state holding lazy-loaded, paginated completed matches.
class CompletedMatchesState {
  final List<CloudMatch> matches;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const CompletedMatchesState({
    this.matches = const [],
    this.lastDoc,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  CompletedMatchesState copyWith({
    List<CloudMatch>? matches,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return CompletedMatchesState(
      matches: matches ?? this.matches,
      lastDoc: lastDoc ?? this.lastDoc,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier managing on-demand cursor-based pagination
/// for finished / forfeited matches.
class CompletedMatchesNotifier extends Notifier<CompletedMatchesState> {
  @override
  CompletedMatchesState build() {
    // Initial state is empty and un-loaded so zero Firestore reads occur
    // until the user actually taps into the Completed tab.
    return const CompletedMatchesState();
  }

  /// Loads the first page of 20 completed matches if not already loaded.
  Future<void> loadInitial() async {
    if (state.isLoading || state.matches.isNotEmpty) return;
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null || user.uid.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(matchServiceProvider);
      final result = await service.fetchCompletedMatches(user.uid, limit: 20);
      state = state.copyWith(
        matches: result.matches,
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Loads the next page of 20 matches starting after [state.lastDoc].
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.lastDoc == null) {
      return;
    }
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null || user.uid.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final service = ref.read(matchServiceProvider);
      final result = await service.fetchCompletedMatches(
        user.uid,
        lastDoc: state.lastDoc,
        limit: 20,
      );
      state = state.copyWith(
        matches: [...state.matches, ...result.matches],
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Forces a complete re-fetch of the first page.
  Future<void> refresh() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null || user.uid.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(matchServiceProvider);
      final result = await service.fetchCompletedMatches(user.uid, limit: 20);
      state = state.copyWith(
        matches: result.matches,
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for lazily paginating completed matches.
final completedMatchesProvider = NotifierProvider<
    CompletedMatchesNotifier, CompletedMatchesState>(
  CompletedMatchesNotifier.new,
);
