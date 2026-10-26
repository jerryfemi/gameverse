import 'package:flutter/material.dart';

/// Modal dialog confirming match forfeit.
class PauseForfeitDialog extends StatelessWidget {
  const PauseForfeitDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const PauseForfeitDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24.0),
          SizedBox(width: 10.0),
          Text(
            'Forfeit Match?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      content: const Text(
        'Leaving mid-game will forfeit this match and award the victory to your opponent. Are you sure you want to forfeit?',
        style: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 13.5,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'CONFIRM FORFEIT',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
