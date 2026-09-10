import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_host_list/controllers/agency_host_list_controller.dart';
import 'package:qobo_one_live/app/user_flow/agency_host_list/views/agency_host_list_view.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';

class _Repo extends AgencyRepo {
  bool failPending = false;
  @override
  Future<Map<String, dynamic>?> getAgencyHostsList({
    String? agencyId,
    String status = 'all',
    bool isShowLoader = true,
  }) async => {
    'statusCode': 1,
    'data': {
      'hosts': [
        {'id': 'host-1', 'name': 'Approved Host', 'status': 'approved'},
      ],
    },
  };
  @override
  Future<Map<String, dynamic>?> getHostApplications({
    String status = 'pending',
    int page = 1,
    int limit = 20,
    bool isShowLoader = true,
  }) async {
    if (failPending && status == 'pending') return {'statusCode': 0};
    return {
      'statusCode': 1,
      'data': {
        'applications': [
          if (status == 'pending')
            {'id': 'app-1', 'hostName': 'Pending Host', 'status': 'pending'},
          if (status == 'rejected')
            {'id': 'app-2', 'hostName': 'Rejected Host', 'status': 'rejected'},
        ],
        'totalPages': 1,
      },
    };
  }
}

class _Controller extends AgencyHostListController {
  _Controller(AgencyRepo repo) : super(agencyRepo: repo);
  // Avoid automatic network loading; each test explicitly refreshes its fake repo.
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test(
    'loads pending and rejected applications separately from approved hosts',
    () async {
      final controller = _Controller(_Repo());
      await controller.refreshList();
      expect(controller.hostsForTab(pending: true).map((h) => h.name), [
        'Pending Host',
      ]);
      expect(controller.hostsForTab(pending: false).map((h) => h.name), [
        'Approved Host',
        'Rejected Host',
      ]);
      expect(
        controller.hostsForTab(pending: true).single.reviewApplicationId,
        'app-1',
      );
      controller.searchQuery.value = 'REJECTED';
      expect(
        controller.hostsForTab(pending: false).single.name,
        'Rejected Host',
      );
      expect(controller.hostsForTab(pending: true), isEmpty);
    },
  );

  test(
    'pending endpoint failure is visible without hiding approved hosts',
    () async {
      final controller = _Controller(_Repo()..failPending = true);
      await controller.refreshList();
      expect(controller.loadError.value, contains('pending'));
      expect(controller.hostsForTab(pending: false), hasLength(2));
      expect(controller.isLoading.value, isFalse);
    },
  );

  testWidgets(
    'two tabs show host lists and pending review actions at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = Get.put<AgencyHostListController>(
        _Controller(_Repo()),
      );
      await controller.refreshList();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) =>
              const GetMaterialApp(home: AgencyHostListView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pending Host'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      await tester.tap(find.text('Approved / Rejected'));
      await tester.pumpAndSettle();
      expect(find.text('Approved Host'), findsOneWidget);
      expect(find.text('Rejected Host'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
