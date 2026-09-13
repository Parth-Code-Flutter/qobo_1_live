import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

class _Session extends UserSessionController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  String get userName => 'Saved Name';
  @override
  String get email => 'saved@example.com';
  @override
  String get phone => '9876543210';
  @override
  Map<String, dynamic>? get profileData => {'idNumber': 'ID-123'};
  @override
  Future<bool> refreshProfileFromApi({bool isShowLoader = false}) async => true;
}

class _Repo extends RoleApplicationRepo {
  Map<String, dynamic>? existing;
  int submissions = 0;
  final lookups = <String>[];
  @override
  Future<Map<String, dynamic>?> status(
    ApplicationRole role,
    String query,
  ) async {
    lookups.add(query);
    return existing == null ? null : {'statusCode': 1, 'data': existing};
  }

  @override
  Future<Map<String, dynamic>?> submit(
    ApplicationRole role, {
    required String code,
    required String name,
    required String email,
    required String phone,
    File? front,
    File? back,
    String agencyName = '',
    String description = '',
  }) async {
    submissions++;
    expect(
      email,
      role == ApplicationRole.superAdmin ? 'saved@example.com' : '',
    );
    expect(phone, '9876543210');
    expect(name, 'Saved Name');
    return {
      'statusCode': 1,
      'data': {'id': 'app-1', 'status': 'pending', 'alreadySubmitted': true},
    };
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  Future<void> mount(
    WidgetTester tester,
    ApplicationRole role,
    _Repo repo, {
    bool other = false,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, child) => GetMaterialApp(
          home: RoleApplicationView(
            role: role,
            forAnotherUser: other,
            repo: repo,
            pickFiles: () async => ['/tmp/doc.jpg'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final role in ApplicationRole.values) {
    testWidgets('$role reuses profile contacts and name', (tester) async {
      Get.put<UserSessionController>(_Session());
      await mount(tester, role, _Repo());
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Phone number'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Submit application'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final role in [ApplicationRole.superAdmin, ApplicationRole.host]) {
    testWidgets('$role status lookup expands with correct identifier', (
      tester,
    ) async {
      await mount(tester, role, _Repo());
      await tester.ensureVisible(find.text('Already applied?'));
      await tester.tap(find.text('Already applied?'));
      await tester.pumpAndSettle();
      expect(
        find.text('We use your saved phone number to find your application.'),
        findsOneWidget,
      );
      expect(find.text('Application email'), findsNothing);
      expect(find.text('Check status'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('status refresh uses saved phone without editable lookup', (
    tester,
  ) async {
    Get.put<UserSessionController>(_Session());
    final repo = _Repo()..existing = {'status': 'pending'};
    await mount(tester, ApplicationRole.superAdmin, repo);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('Refresh status'));
    await tester.pumpAndSettle();
    expect(repo.lookups, ['9876543210', '9876543210']);
    expect(tester.takeException(), isNull);
  });
  for (final role in [ApplicationRole.superAdmin, ApplicationRole.agency]) {
    testWidgets('$role none status keeps application available', (
      tester,
    ) async {
      Get.put<UserSessionController>(_Session());
      final repo = _Repo()..existing = {'status': 'none'};
      await mount(tester, role, repo);
      expect(find.text('Submit application'), findsOneWidget);
      expect(find.text('NONE'), findsNothing);
      expect(find.text('Under review'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('approval refreshes profile and does not grant an absent role', (
    tester,
  ) async {
    Get.put<UserSessionController>(_Session());
    final repo = _Repo()..existing = {'status': 'approved'};
    await mount(tester, ApplicationRole.superAdmin, repo);
    await tester.ensureVisible(find.text('Continue to dashboard'));
    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your application is approved, but your profile does not yet have dashboard access. Please sign out and sign in again.',
      ),
      findsOneWidget,
    );
    expect(Get.find<UserSessionController>().isSuperAdmin, false);
    expect(tester.takeException(), isNull);
  });
  testWidgets('host has no email input even without saved profile email', (
    tester,
  ) async {
    await mount(tester, ApplicationRole.host, _Repo());
    expect(find.text('Email'), findsNothing);
    expect(find.text('Submit application'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('required missing host contact remains editable', (tester) async {
    await mount(tester, ApplicationRole.host, _Repo());
    expect(find.text('Phone number'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('creating for another user does not reuse operator profile', (
    tester,
  ) async {
    Get.put<UserSessionController>(_Session());
    await mount(tester, ApplicationRole.host, _Repo(), other: true);
    expect(find.text('Phone number'), findsWidgets);
    expect(find.text('Full name'), findsWidgets);
  });
  testWidgets('all existing statuses bypass form and prevent submission', (
    tester,
  ) async {
    Get.put<UserSessionController>(_Session());
    for (final status in ['pending', 'approved', 'rejected']) {
      final repo = _Repo()
        ..existing = {'status': status, 'feedback': 'Review feedback'};
      await tester.pumpWidget(const SizedBox());
      await mount(tester, ApplicationRole.agency, repo);
      expect(
        find.text(
          status == 'pending'
              ? 'Under review'
              : status == 'approved'
              ? 'Application approved'
              : 'Application reviewed',
        ),
        findsOneWidget,
      );
      expect(find.text('Submit application'), findsNothing);
      expect(find.text('Review feedback'), findsOneWidget);
      expect(repo.submissions, 0);
    }
  });
  testWidgets('missing documents block submission', (tester) async {
    Get.put<UserSessionController>(_Session());
    final repo = _Repo();
    await mount(tester, ApplicationRole.superAdmin, repo);
    await tester.ensureVisible(find.text('Submit application'));
    await tester.tap(find.text('Submit application'));
    await tester.pumpAndSettle();
    expect(find.text('Upload both document photos.'), findsOneWidget);
    expect(repo.submissions, 0);
  });
  testWidgets(
    'duplicate submit response opens status and disables resubmission',
    (tester) async {
      Get.put<UserSessionController>(_Session());
      final repo = _Repo();
      await mount(tester, ApplicationRole.superAdmin, repo);
      for (final label in ['Document front', 'Document back']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Submit application'));
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Submit application'), findsNothing);
      expect(repo.submissions, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
