import 'package:flutter/material.dart';

/// An editable-dialogue cinematic panel backed by a separately verified PNG.
/// The text is an overlay, never burned into source artwork.
class MoonveilComicPanel extends StatelessWidget {
  const MoonveilComicPanel({
    super.key,
    required this.assetPath,
    required this.speaker,
    required this.dialogue,
    this.fallbackTitle = 'Artwork not installed',
  });

  final String assetPath;
  final String speaker;
  final String dialogue;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF191426),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(fallbackTitle,
                  style: const TextStyle(color: Colors.amberAccent)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speaker, style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                const SizedBox(height: 4),
                Text(dialogue, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Image-backed VTT token. Caller supplies actual game coordinates and size.
/// A portrait crop is not treated as a transparent cutout without validation.
class MoonveilMapToken extends StatelessWidget {
  const MoonveilMapToken({
    super.key,
    required this.assetPath,
    required this.label,
    this.gridFootprint = 1,
    this.onTap,
  });

  final String assetPath;
  final String label;
  final int gridFootprint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final side = (gridFootprint.clamp(1, 8) * 56).toDouble();
    return Semantics(
      label: '$label, $gridFootprint by $gridFootprint grid squares',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: side, height: side,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(assetPath, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_outline, color: Colors.amber)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: const Color(0xCC100C1A),
                  child: Text(label, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
