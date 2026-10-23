import 'package:flutter/material.dart';
import '../services/moonveil_asset_gateway.dart';

/// A catalog-backed image control. It never changes campaign state itself.
class MoonveilAssetButton extends StatefulWidget {
  const MoonveilAssetButton({
    super.key,
    required this.category,
    required this.assetName,
    required this.label,
    required this.onPressed,
    this.gateway,
  });
  final String category;
  final String assetName;
  final String label;
  final VoidCallback onPressed;
  final MoonveilAssetGateway? gateway;

  @override
  State<MoonveilAssetButton> createState() => _MoonveilAssetButtonState();
}

class _MoonveilAssetButtonState extends State<MoonveilAssetButton> {
  late Future<String?> _image;

  @override
  void initState() {
    super.initState();
    _image = (widget.gateway ?? MoonveilAssetGateway())
        .resolve(widget.category, widget.assetName);
  }

  @override
  void didUpdateWidget(covariant MoonveilAssetButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.assetName != widget.assetName ||
        oldWidget.gateway != widget.gateway) {
      _image = (widget.gateway ?? MoonveilAssetGateway())
          .resolve(widget.category, widget.assetName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: widget.onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<String?>(
            future: _image,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 80, height: 80,
                  child: Center(child: Icon(Icons.image_not_supported_outlined)),
                );
              }
              return Image.asset(
                snapshot.data!, width: 80, height: 80, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 80, height: 80,
                      child: Icon(Icons.image_not_supported_outlined)),
              );
            },
          ),
          Text(widget.label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
