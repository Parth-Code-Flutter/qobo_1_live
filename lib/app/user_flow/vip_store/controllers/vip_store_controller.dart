import 'package:get/get.dart';

class VipStoreController extends GetxController {
  final isLoading = false.obs;

  // Active category index: 0 = Entrances, 1 = Avatar Rings, 2 = Chat Bubbles
  final selectedCategory = 0.obs;

  // Mock User Coin balance
  final userCoins = 8500.obs;

  // Mock Shop items
  final entranceEffects = <Map<String, dynamic>>[
    {
      'title': 'Royal Supercar',
      'desc': 'Arrive in the live room with a roaring luxury sports car animation.',
      'price': 5000,
      'duration': '30 Days',
      'tag': 'Legendary',
      'icon': 'sports_car_rounded',
      'isOwned': false,
    },
    {
      'title': 'Golden Phoenix',
      'desc': 'Unleash a fiery golden phoenix bird entrance effect.',
      'price': 12000,
      'duration': '30 Days',
      'tag': 'Mythic',
      'icon': 'wb_sunny_rounded',
      'isOwned': false,
    },
    {
      'title': 'Glitch Portal',
      'desc': 'Emerge out of a high-tech neon digital glitch portal.',
      'price': 2500,
      'duration': '30 Days',
      'tag': 'Epic',
      'icon': 'electric_bolt_rounded',
      'isOwned': false,
    },
  ].obs;

  final avatarRings = <Map<String, dynamic>>[
    {
      'title': 'Crown Prince Frame',
      'desc': 'Surround your avatar with a sparkling ruby crown and gold ring.',
      'price': 1500,
      'duration': '7 Days',
      'tag': 'Epic',
      'icon': 'brightness_high_rounded',
      'isOwned': false,
    },
    {
      'title': 'Cyber Neon Ring',
      'desc': 'An animated neon future blue ring that pulses over your profile.',
      'price': 3000,
      'duration': '7 Days',
      'tag': 'Legendary',
      'icon': 'change_circle_rounded',
      'isOwned': false,
    },
    {
      'title': 'Pink Sakura Halo',
      'desc': 'A gentle, falling cherry blossom petals ring for your profile.',
      'price': 800,
      'duration': '7 Days',
      'tag': 'Rare',
      'icon': 'filter_vintage_rounded',
      'isOwned': false,
    },
  ].obs;

  final chatBubbles = <Map<String, dynamic>>[
    {
      'title': 'Cyber Matrix Bubble',
      'desc': 'Give your chat messages a dynamic digital green code pattern background.',
      'price': 1800,
      'duration': '30 Days',
      'tag': 'Epic',
      'icon': 'chat_bubble_rounded',
      'isOwned': false,
    },
    {
      'title': 'Sweet Heart Bubble',
      'desc': 'Send messages inside a cute pink bubble scattered with mini-hearts.',
      'price': 600,
      'duration': '30 Days',
      'tag': 'Rare',
      'icon': 'favorite_rounded',
      'isOwned': false,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadStore();
  }

  void loadStore() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    isLoading.value = false;
  }

  void purchaseItem(int index) {
    List<Map<String, dynamic>> list;
    if (selectedCategory.value == 0) {
      list = entranceEffects;
    } else if (selectedCategory.value == 1) {
      list = avatarRings;
    } else {
      list = chatBubbles;
    }

    final item = list[index];

    if (item['isOwned'] == true) {
      Get.snackbar(
        'Already Owned',
        'You already own the "${item['title']}" package!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final int price = item['price'] as int;
    if (userCoins.value >= price) {
      userCoins.value -= price;
      
      // Update owned state reactively
      final Map<String, dynamic> updatedItem = Map.from(item);
      updatedItem['isOwned'] = true;
      list[index] = updatedItem;

      Get.snackbar(
        'Purchase Success!',
        'You purchased "${item['title']}" for $price Coins!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Insufficient Balance',
        'You need ${price - userCoins.value} more Coins to purchase this item.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
