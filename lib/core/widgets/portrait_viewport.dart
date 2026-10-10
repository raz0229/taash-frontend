import 'package:flutter/material.dart';

/// Anchors the whole app to a phone-shaped portrait canvas.
///
/// TaashOnline is designed for portrait phones. On tablets — and on Android 16+
/// large screens, where the system ignores the portrait lock — the screen can
/// be landscape or much wider than a phone. Instead of stretching the layout,
/// this widget:
///
///  * caps the canvas at a portrait aspect ratio ([maxAspect]) and centres it,
///    letterboxing the sides; and
///  * scales the canvas up uniformly once it is wider than a phone, so cards,
///    text and touch targets grow with the screen rather than spreading out.
///
/// Phones in portrait are passed through untouched. It wraps the Navigator
/// (via MaterialApp.builder), so dialogs, sheets and overlays are anchored too.
class PortraitViewport extends StatelessWidget {
  const PortraitViewport({super.key, required this.child});
  final Widget child;

  /// Widest canvas allowed, as width / height (3:5).
  static const maxAspect = 0.6;

  /// Canvases at most this wide are shown at 1:1 — every phone fits here.
  static const maxUnscaledWidth = 520.0;

  /// Logical width the canvas is laid out at once it is being scaled.
  static const designWidth = 460.0;

  static const _letterbox = Color(0xFF0B0A16);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    if (screen.isEmpty) return child;

    final letterboxed = screen.width / screen.height > maxAspect;
    final width = letterboxed ? screen.height * maxAspect : screen.width;
    final height = screen.height;
    final scale = width > maxUnscaledWidth ? width / designWidth : 1.0;
    if (!letterboxed && scale == 1.0) return child;

    // Insets are re-expressed in the canvas's logical pixels. The canvas spans
    // the full height, so top/bottom insets still apply; when it is
    // letterboxed it no longer touches the side edges, so those drop out.
    EdgeInsets fit(EdgeInsets insets) => EdgeInsets.fromLTRB(
      letterboxed ? 0 : insets.left / scale,
      insets.top / scale,
      letterboxed ? 0 : insets.right / scale,
      insets.bottom / scale,
    );

    final canvas = Size(width / scale, height / scale);
    return ColoredBox(
      color: _letterbox,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: canvas,
              child: MediaQuery(
                data: media.copyWith(
                  size: canvas,
                  devicePixelRatio: media.devicePixelRatio * scale,
                  padding: fit(media.padding),
                  viewPadding: fit(media.viewPadding),
                  viewInsets: fit(media.viewInsets),
                  systemGestureInsets: fit(media.systemGestureInsets),
                ),
                child: ClipRect(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
