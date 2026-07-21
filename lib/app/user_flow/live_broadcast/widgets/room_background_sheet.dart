import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_broadcast_controller.dart';
import '../models/room_background_theme.dart';

/// Host picker for `GET /api/room/backgrounds` catalog themes.
class RoomBackgroundSheet extends StatefulWidget {
  const RoomBackgroundSheet({super.key});

  @override
  State<RoomBackgroundSheet> createState() => _RoomBackgroundSheetState();
}

class _RoomBackgroundSheetState extends State<RoomBackgroundSheet> {
  String? _pendingThemeId;

  @override
  void initState() {
    super.initState();
    Get.find<LiveBroadcastController>().loadRoomBackgroundCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    final height = MediaQuery.of(context).size.height * 0.58;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Spacing.v12,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Spacing.v16,
          const SemiBoldText(
            text: 'Room Background',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.v4,
          AppText(
            text: 'Pick a theme for everyone in this room',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          ),
          Spacing.v16,
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRoomBackgrounds.value &&
                  controller.roomBackgroundCatalog.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                );
              }
              final themes = controller.roomBackgroundCatalog.toList();
              if (themes.isEmpty) {
                return Center(
                  child: AppText(
                    text: 'No backgrounds available yet.',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.7),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  return Obx(() {
                    final selected =
                        controller.roomBackgroundId.value == theme.id ||
                        (controller.roomBackgroundId.value == null &&
                            controller.roomBackgroundUrl.value ==
                                theme.imageUrl);
                    final applying = _pendingThemeId == theme.id &&
                        controller.isChangingRoomBackground.value;
                    return _BackgroundTile(
                      theme: theme,
                      selected: selected,
                      applying: applying,
                      onTap: () async {
                        setState(() => _pendingThemeId = theme.id);
                        await controller.applyRoomBackground(theme);
                        if (mounted) {
                          setState(() => _pendingThemeId = null);
                        }
                      },
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.theme,
    required this.selected,
    required this.applying,
    required this.onTap,
  });

  final RoomBackgroundTheme theme;
  final bool selected;
  final bool applying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: applying ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF3F7F)
                : kColorWhite.withValues(alpha: 0.1),
            width: selected ? 2.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              theme.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2A2038),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white54,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0A0614)],
                  ),
                ),
                child: SemiBoldText(
                  text: theme.name,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (theme.isDefault)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const AppText(
                    text: 'Default',
                    fontSize: 10,
                    color: kColorWhite,
                  ),
                ),
              ),
            if (applying)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: kColorWhite,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
