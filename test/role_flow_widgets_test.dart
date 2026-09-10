import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/app/user_flow/host_dashboard/host_dashboard_view.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_field.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_verification.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(Get.reset);
  testWidgets('host dashboard is available only for approved host role', (
    tester,
  ) async {
    final session = Get.put(UserSessionController());
    await session.saveProfile({'role': 'user', 'name': 'Clara'});
    await tester.pumpWidget(const GetMaterialApp(home: HostDashboardView()));
    expect(find.text('Host approval is required.'), findsOneWidget);
    expect(find.text('Go live'), findsNothing);
    await session.saveProfile({
      'role': 'host',
      'name': 'Clara',
      'agencyCode': 'APEX99',
    });
    await tester.pump();
    expect(find.text('Clara'), findsOneWidget);
    expect(find.text('Go live'), findsOneWidget);
    expect(find.text('Agency: APEX99'), findsOneWidget);
    expect(find.text('Wallet & withdrawals'), findsOneWidget);
  });
  testWidgets('verification field shows result and clears it on editing', (
    tester,
  ) async {
    final input = TextEditingController();
    final verification = RecruitmentCodeVerification(
      input,
      (_) async => {
        'statusCode': 1,
        'data': {'valid': true, 'superAdminName': 'Alex'},
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecruitmentCodeField(
            verification: verification,
            label: 'Super Admin code',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'SA-ABC');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();
    expect(find.text('Verified: Alex'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'SA-OTHER');
    await tester.pump();
    expect(find.text('Verified: Alex'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    verification.dispose();
    input.dispose();
  });
}
