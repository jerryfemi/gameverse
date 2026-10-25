import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Top bar and search input header for [FriendsPage].
class FriendsSearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onAddFriend;
  final VoidCallback onBack;

  const FriendsSearchHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onAddFriend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: Back, Title, Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2638),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18.0, color: Colors.white),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 14.0),
              Text(
                'Friends',
                style: UiFont.style(
                  size: 26.0,
                  weight: 900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36.0,
                child: ElevatedButton.icon(
                  onPressed: onAddFriend,
                  icon: const Icon(Icons.add_rounded, size: 16.0),
                  label: Text(
                    'Add',
                    style: UiFont.style(
                      size: 13.0,
                      weight: 800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Container(
            height: 44.0,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
            ),
            child: TextField(
              controller: searchController,
              style: UiFont.style(size: 13.5, color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 20.0,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 16.0, color: Color(0xFF64748B)),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                hintText: 'Search friends or a gamer tag',
                hintStyle: UiFont.style(
                  size: 13.5,
                  weight: 500,
                  color: const Color(0xFF64748B),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
