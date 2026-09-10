import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';

class RecordingApi extends ApiService {
  final paths = <String>[];
  dynamic body;
  Map<String, File>? uploads;
  http.Response? next = http.Response(
    jsonEncode({
      'statusCode': 1,
      'data': {'valid': true},
    }),
    200,
  );
  @override
  Future<http.Response?> postRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
    String? bearerToken,
    bool skipUnauthorizedHandling = false,
  }) async {
    paths.add(endPoint);
    body = requestModel;
    return next;
  }

  @override
  Future<http.Response?> multipartFormRequest({
    required String endPoint,
    required Map<String, String> fields,
    List<File>? files,
    String fileFieldName = 'image',
    Map<String, File>? namedFiles,
    String method = 'POST',
    bool isShowLoader = true,
  }) async {
    paths.add(endPoint);
    body = fields;
    uploads = namedFiles;
    return next;
  }
}

void main() {
  test(
    'code verification uses documented authenticated POST endpoints',
    () async {
      final api = RecordingApi();
      final repo = AgencyRepo(apiService: api);
      await repo.verifySuperAdminCode(' SA-ABC ');
      expect(api.paths.last, '/api/agency/verify-super-admin-code');
      expect(api.body, {'code': 'SA-ABC'});
      await repo.verifyAgencyCode(' APEX99 ');
      expect(api.paths.last, '/api/agency/verify-agency-code');
      expect(api.body, {'code': 'APEX99'});
    },
  );
  test(
    'manual creation sends decimal commission to dedicated endpoint',
    () async {
      final api = RecordingApi();
      await SuperAdminRepo(apiService: api).addAgencyManual(
        name: 'Apex',
        ownerName: 'Mark',
        email: 'mark@example.com',
        phone: '+919876543210',
        commissionRate: 0.10,
      );
      expect(api.paths.single, '/api/super-admin/add-agency-manual');
      expect(api.body, {
        'name': 'Apex',
        'ownerName': 'Mark',
        'email': 'mark@example.com',
        'phone': '+919876543210',
        'commissionRate': 0.10,
      });
    },
  );
  test(
    'agency approval uses guide endpoint and never retries an unknown result',
    () async {
      final api = RecordingApi()..next = null;
      await SuperAdminRepo(
        apiService: api,
      ).processAgency(agencyId: 'agency-1', status: 'approved');
      expect(api.paths, ['/api/super-admin/agency/process']);
      expect(api.body['agencyId'], 'agency-1');
    },
  );
  test('legacy approval fallback is limited to an explicit 404', () async {
    final api = RecordingApi()..next = http.Response('{}', 404);
    await SuperAdminRepo(
      apiService: api,
    ).processAgency(agencyId: 'agency-1', status: 'rejected');
    expect(api.paths, [
      '/api/super-admin/agency/process',
      '/api/super-admin/agencies/process-request',
    ]);
  });
  test(
    'agency application sends verified sponsor and named documents',
    () async {
      final api = RecordingApi();
      final file = File('/tmp/test-document.jpg');
      await AgencyRepo(apiService: api).registerAgencyPublic(
        agencyName: 'Apex',
        ownerName: 'Mark',
        email: 'm@example.com',
        phone: '9876543210',
        countryCode: '+91',
        password: 'example-password',
        invitedBy: 'SA-ABC',
        country: 'India',
        state: 'Gujarat',
        city: 'Surat',
        address: 'Example',
        agencyLogo: file,
        docPhotoFront: file,
        docPhotoBack: file,
      );
      expect(api.paths.single, '/api/agency/register-public');
      expect(api.body['invitedBy'], 'SA-ABC');
      expect(
        api.uploads!.keys,
        containsAll(['agency_logo', 'doc_photo_front', 'doc_photo_back']),
      );
    },
  );
  test(
    'host onboarding includes new guide names and old compatibility fields',
    () async {
      final api = RecordingApi();
      final file = File('/tmp/test-document.jpg');
      await AgencyRepo(apiService: api).hostOnboarding(
        agencyCode: 'APEX99',
        hostName: 'Clara',
        gmail: 'c@example.com',
        whatsapp: '9876543210',
        type: 'audio',
        category: 'Singing',
        countryRegion: 'India',
        state: 'Gujarat',
        city: 'Surat',
        address: 'Example',
        hostRealPhoto: file,
        docPhotoFront: file,
        docPhotoBack: file,
      );
      expect(api.body['agencyCode'], 'APEX99');
      expect(api.body['host_name'], 'Clara');
      expect(api.body['name'], 'Clara');
      expect(api.body['whatsapp'], '9876543210');
    },
  );
  test(
    'five approved host rewards display five dollars when reported by server',
    () {
      final data = AgencyDashboardData.fromJson({
        'summary': {'activeHosts': 5, 'hostRecruitmentEarningsCoins': 50000},
      });
      expect(data.hostRecruitmentEarningsDollars, 5);
    },
  );
  test('active hosts alone cannot manufacture recruitment earnings', () {
    final data = AgencyDashboardData.fromJson({
      'summary': {'activeHosts': 5},
    });
    expect(data.hostRecruitmentEarningsCoins, 0);
    expect(data.hostRecruitmentEarningsDollars, 0);
  });
}
