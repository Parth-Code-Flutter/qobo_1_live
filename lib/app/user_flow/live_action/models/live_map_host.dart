import 'package:flutter/material.dart';

/// Host node on the heart-tab live map.
class LiveMapHost {
  const LiveMapHost({
    required this.name,
    required this.levelBadge,
    required this.imageAsset,
    required this.alignment,
    this.isAgencyHost = false,
  });

  final String name;
  final String levelBadge;
  final String imageAsset;
  final Alignment alignment;
  final bool isAgencyHost;
}
