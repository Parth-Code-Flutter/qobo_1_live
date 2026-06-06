import 'package:flutter/material.dart';

/// Host node on the heart-tab live map.
class LiveMapHost {
  const LiveMapHost({
    required this.name,
    required this.levelBadge,
    required this.imageAsset,
    required this.alignment,
    this.isAgencyHost = false,
    this.isPlaceholder = false,
    this.avatarUrl,
    this.hostId,
    this.level = 0,
    this.isPending = false,
  });

  final String name;
  final String levelBadge;
  final String imageAsset;
  final Alignment alignment;
  final bool isAgencyHost;

  /// Decorative empty slot — keeps the tree layout visible with few hosts.
  final bool isPlaceholder;

  /// Network avatar when available (agency host list).
  final String? avatarUrl;
  final String? hostId;

  /// Sort key — higher value = higher rank in agency tree.
  final int level;

  /// Pending review — shows orange status dot on agency tree.
  final bool isPending;
}
