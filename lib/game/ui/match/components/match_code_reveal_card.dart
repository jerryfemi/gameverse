import 'package:flutter/material.dart';

/// Big code reveal card matching Design Template 16 with COPY and SHARE buttons.
class MatchCodeRevealCard extends StatelessWidget {
  final String code;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const MatchCodeRevealCard({
    super.key,
    required this.code,
    required this.copied,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          SelectableText(
            code,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00FFCC),
              fontSize: 34.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 8.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            copied ? '✓ CODE COPIED' : 'Send this code to your opponent',
            style: TextStyle(
              color: copied ? const Color(0xFF00FFCC) : const Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: copied ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white, size: 14.0),
                        SizedBox(width: 5.0),
                        Text(
                          'COPY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ios_share_rounded, color: Colors.white, size: 14.0),
                        SizedBox(width: 5.0),
                        Text(
                          'SHARE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
