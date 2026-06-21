import 'package:flutter/material.dart';

void showTopNotif(
  BuildContext context, {
  required String message,
  Color backgroundColor = const Color.fromARGB(255, 76, 132, 175),
  Duration displayDuration = const Duration(seconds: 2),
}) {
  final overlayState = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (context) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlayState.insert(entry);
  Future.delayed(displayDuration, () {
    entry.remove();
  });
}
