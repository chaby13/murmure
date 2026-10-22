import 'package:flutter/material.dart';

/// Logo original Chabane DEV, affiché sans recoloration ni déformation.
/// L'asset a un vrai fond transparent : le faux damier du fichier source
/// (docs/brand/chabane_dev_source.png) a été retiré par tool/clean_logo.py.
class ChabaneLogo extends StatelessWidget {
  const ChabaneLogo({super.key, required this.width});

  static const assetPath = 'assets/brand/chabane_dev.png';
  static const _aspectRatio = 714 / 669;

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: width / _aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo Chabane DEV',
    );
  }
}
