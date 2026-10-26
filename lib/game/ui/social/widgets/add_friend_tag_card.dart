import 'package:flutter/material.dart';

/// "YOUR TAG" card in the Add Friend dialog, matching Template 13.
class AddFriendTagCard extends StatelessWidget {
  final String displayName;
  final bool isCopied;
  final VoidCallback onCopy;

  const AddFriendTagCard({
    super.key,
    required this.displayName,
    required this.isCopied,
    required this.onCopy,
  });

  String _extractInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'PL';
    final parts = clean.split(RegExp(r'[\s#_-]+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean
        .substring(0, clean.length >= 2 ? 2 : clean.length)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(displayName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8),
              border: Border.all(color: const Color(0xFF0A0E1A), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
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
                const Text(
                  'YOUR TAG',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(20.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.5,
              ),
              decoration: BoxDecoration(
                color: isCopied
                    ? const Color(0xFF042F2E)
                    : const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isCopied
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF334155),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    color: isCopied
                        ? const Color(0xFF00FFCC)
                        : const Color(0xFF38BDF8),
                    size: 13.0,
                  ),
                  const SizedBox(width: 4.5),
                  Text(
                    isCopied ? 'COPIED' : 'COPY',
                    style: TextStyle(
                      color: isCopied
                          ? const Color(0xFF00FFCC)
                          : const Color(0xFF38BDF8),
                      fontSize: 11.0,
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
  }
}
