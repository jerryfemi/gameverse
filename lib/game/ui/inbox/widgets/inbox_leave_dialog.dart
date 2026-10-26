import 'package:flutter/material.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Displays a confirmation dialog to forfeit an active match or remove a finished match.
Future<void> showInboxLeaveDialog({
  required BuildContext context,
  required CloudMatch match,
  required String myUid,
}) async {
  final isDone = match.isFinished;

  return showDialog<void>(
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
        isDone ? 'REMOVE MATCH' : 'LEAVE MATCH',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      content: Text(
        isDone
            ? 'Remove this finished match from your history?'
            : 'Are you sure you want to forfeit and leave this match? It will be removed from your active matches.',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(dialogCtx).pop();
            await FirestoreMatchService.instance.leaveOrDismissMatch(
              matchId: match.id,
              myUid: myUid,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            isDone ? 'REMOVE' : 'LEAVE',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    ),
  );
}
