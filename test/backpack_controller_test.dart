import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/backpack/controllers/backpack_controller.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('loads and equips purchased avatar frames from my-backpack', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    final frameRepo = _FakeFrameRepo();
    final controller = BackpackController(
      userRepo: _FakeUserRepo(),
      frameRepo: frameRepo,
    );

    await controller.fetchBackpack();

    final frame = controller.mockItems[2]!.single;
    expect(frame['id'], 'backpack-1');
    expect(frame['name'], 'Rose Love Frame');
    expect(frame['svgaUrl'], 'https://cdn.example.com/rose-love.svga');
    expect(frame['imageUrl'], 'https://cdn.example.com/rose-love.png');
    expect(controller.equippedFrame.value, isNull);

    await controller.equipItem(2, frame);
    await tester.pump();

    expect(frameRepo.lastBackpackItemId, 'backpack-1');
    expect(frameRepo.lastEquipValue, isTrue);
    expect(controller.equippedFrame.value, 'backpack-1');
    expect(controller.equippedFrameName.value, 'Rose Love Frame');

    // Let the success snackbar finish so GetX leaves no pending timers.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

class _FakeUserRepo extends UserRepo {
  @override
  Future<Map<String, dynamic>?> getBackpack({bool isShowLoader = true}) async {
    return <String, dynamic>{'statusCode': 200, 'data': <String, dynamic>{}};
  }
}

class _FakeFrameRepo extends FrameRepo {
  bool isEquipped = false;
  String? lastBackpackItemId;
  bool? lastEquipValue;

  @override
  Future<Map<String, dynamic>?> getMyBackpack({
    bool isShowLoader = true,
  }) async {
    return <String, dynamic>{
      'statusCode': 200,
      'data': [
        {
          'id': 'backpack-1',
          'itemId': 'frame-1',
          'isEquipped': isEquipped,
          'expiresAt': '2026-08-14T00:00:00.000Z',
          'frameDetails': {
            'id': 'frame-1',
            'name': 'Rose Love Frame',
            'animationUrl': 'https://cdn.example.com/rose-love.svga',
            'image': 'https://cdn.example.com/rose-love.png',
          },
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>?> equipFrame({
    required String backpackItemId,
    required bool equip,
    bool isShowLoader = true,
  }) async {
    lastBackpackItemId = backpackItemId;
    lastEquipValue = equip;
    isEquipped = equip;
    return <String, dynamic>{'statusCode': 200};
  }
}
