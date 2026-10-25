import 'package:flutter/material.dart';

/// One food on the demo wheel.
///
/// Icons are emoji stand-ins so the client preview does not need a designer.
/// Swap [emoji] for real assets later without changing the round logic.
class FoodWheelItem {
  const FoodWheelItem({
    required this.name,
    required this.emoji,
    required this.multiplier,
    required this.color,
  });

  final String name;
  final String emoji;
  final int multiplier;
  final Color color;
}

/// Fixed board for the client demo. Payouts stay on the phone until a backend exists.
const List<FoodWheelItem> kFoodWheelItems = [
  FoodWheelItem(
    name: 'Hot Dog',
    emoji: '🌭',
    multiplier: 10,
    color: Color(0xFFE85D4C),
  ),
  FoodWheelItem(
    name: 'Skewer',
    emoji: '🍢',
    multiplier: 15,
    color: Color(0xFF7B3FE4),
  ),
  FoodWheelItem(
    name: 'Drumstick',
    emoji: '🍗',
    multiplier: 25,
    color: Color(0xFFEF8A2A),
  ),
  FoodWheelItem(
    name: 'Steak',
    emoji: '🥩',
    multiplier: 45,
    color: Color(0xFFC23B4A),
  ),
  FoodWheelItem(
    name: 'Carrot',
    emoji: '🥕',
    multiplier: 5,
    color: Color(0xFFF08A24),
  ),
  FoodWheelItem(
    name: 'Corn',
    emoji: '🌽',
    multiplier: 5,
    color: Color(0xFFE2B100),
  ),
  FoodWheelItem(
    name: 'Greens',
    emoji: '🥬',
    multiplier: 5,
    color: Color(0xFF3CAA55),
  ),
  FoodWheelItem(
    name: 'Tomato',
    emoji: '🍅',
    multiplier: 5,
    color: Color(0xFFE23B3B),
  ),
];
