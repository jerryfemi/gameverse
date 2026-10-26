import 'package:flutter/material.dart';

import 'package:b_ball/models/friend_profile.dart';

/// Renders player rows in Add Friend dialog with +ADD / SENT actions,
/// matching Template 13.
class AddFriendRecentCard extends StatelessWidget {
  final List<({FriendProfile profile, String subtitle})> items;
  final Set<String> invitedUids;
  final Set<String> friendUids;
  final ValueChanged<FriendProfile> onAdd;

  const AddFriendRecentCard({
    super.key,
    required this.items,
    required this.invitedUids,
    required this.friendUids,
    required this.onAdd,
  });

  static const List<Color> _avatarColors = [
    Color(0xFFA855F7), // purple
    Color(0xFFF59E0B), // orange
    Color(0xFF10B981), // emerald
    Color(0xFF38BDF8), // blue
    Color(0xFFEC4899), // pink
  ];

  String _extractInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'PL';
    final parts = clean.split(RegExp(r'[\s#_-]+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : clean.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(
          color: Color(0xFF1E2638),
          height: 1.0,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final p = item.profile;
          final isInvited = invitedUids.contains(p.uid);
          final isFriend = friendUids.contains(p.uid);
          final color = _avatarColors[index % _avatarColors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: const Color(0xFF0A0E1A), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _extractInitials(p.displayName),
                    style: const TextStyle(
                      color: Color(0xFF0A0E1A),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                if (isFriend)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Text(
                      'FRIEND',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (isInvited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Color(0xFF94A3B8), size: 13.0),
                        SizedBox(width: 4.0),
                        Text(
                          'SENT',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () => onAdd(p),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFCC),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF0A0E1A), size: 14.0),
                          SizedBox(width: 3.0),
                          Text(
                            'ADD',
                            style: TextStyle(
                              color: Color(0xFF0A0E1A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
