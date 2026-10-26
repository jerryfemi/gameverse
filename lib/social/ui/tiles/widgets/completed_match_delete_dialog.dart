import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Shows a stylized confirmation dialog to remove a completed match from history.
Future<void> showCompletedMatchDeleteDialog(
  BuildContext context, {
  required String matchId,
  required String myUid,
  VoidCallback? onDelete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: const Color(0xFF131826),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFF2E3954),
          width: 1.5,
        ),
      ),
      title: Text(
        'REMOVE MATCH',
        style: UiFont.style(
          size: 16.0,
          weight: 900,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
      content: Text(
        'Remove this finished match from your history?',
        style: UiFont.style(
          size: 13.0,
          weight: 500,
          color: const Color(0xFF94A3B8),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(
            'CANCEL',
            style: UiFont.style(
              size: 13.0,
              weight: 700,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'REMOVE',
            style: UiFont.style(
              size: 13.0,
              weight: 800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && myUid.isNotEmpty) {
    await FirestoreMatchService.instance.leaveOrDismissMatch(
      matchId: matchId,
      myUid: myUid,
    );
    onDelete?.call();
  }
}
