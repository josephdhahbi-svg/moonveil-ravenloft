import 'package:flutter/material.dart';

class MissingImageFallbackWidget extends StatelessWidget {
  const MissingImageFallbackWidget({
    super.key,
    required this.assetPath,
    this.width = 100,
    this.height = 100,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1325),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, color: Colors.amberAccent),
              Text(
                assetPath.split('/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ),
      );
}
