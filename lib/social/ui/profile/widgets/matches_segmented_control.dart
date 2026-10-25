import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Pill segmented control switching between Active and Completed match tabs in [MatchesPage].
class MatchesSegmentedControl extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const MatchesSegmentedControl({
    super.key,
    required this.activeCount,
    required this.completedCount,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              title: 'Active · $activeCount',
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: _buildSegmentButton(
              title: 'Completed · $completedCount',
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF1E2638) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Center(
          child: Text(
            title,
            style: UiFont.style(
              size: 13.0,
              weight: isSelected ? 800 : 600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
