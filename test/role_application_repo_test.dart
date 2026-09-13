import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:qobo_one_live/services/api_service.dart';

class _Api extends ApiService {
  String path = '';
  String? responseBody;
  int responseStatus = 200;
  Map<String, String> fields = {};
  Map<String, File> uploads = {};
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
    path = endPoint;
    this.fields = fields;
    uploads = namedFiles ?? {};
    return http.Response(
      responseBody ??
          '{"statusCode":1,"data":{"id":"app-1","alreadySubmitted":true,"status":"pending"}}',
      responseStatus,
    );
  }

  @override
  Future<http.Response?> getRequest({
    required String endPoint,
    Map<String, dynamic>? params,
    Map<String, String>? queryParams,
    bool isShowLoader = true,
    String? baseUrl,
    String? bearerToken,
    bool skipUnauthorizedHandling = false,
  }) async {
    path = endPoint;
    return http.Response(
      responseBody ?? '{"statusCode":1,"data":{"status":"approved"}}',
      responseStatus,
    );
  }
}

void main() {
  test(
    'bare status and duplicate responses normalize; HTTP errors stay failures',
    () async {
      final api = _Api()
        ..responseBody = '{"status":"pending","alreadySubmitted":true}';
      final repo = RoleApplicationRepo(apiService: api);
      expect(
        (await repo.status(
          ApplicationRole.host,
          '9876543210',
        ))?['data']['alreadySubmitted'],
        true,
      );
      api.responseStatus = 400;
      expect(
        (await repo.status(ApplicationRole.host, '9876543210'))?['statusCode'],
        400,
      );
    },
  );
  for (final role in [ApplicationRole.agency, ApplicationRole.host]) {
    test(
      '$role verifies with GET and supports application without photos',
      () async {
        final api = _Api()..responseBody = '{"valid":true}';
        final repo = RoleApplicationRepo(apiService: api);
        final verified = await repo.verifyCode(role, ' CODE+1 ');
        expect(
          Uri.parse(api.path).path,
          role == ApplicationRole.agency
              ? '/api/agency/verify-super-admin-code'
              : '/api/agency/verify-code',
        );
        expect(Uri.parse(api.path).queryParameters, {'code': 'CODE+1'});
        expect(verified?['data']['valid'], true);
        api.responseBody = '{"status":"pending","alreadySubmitted":true}';
        final response = await repo.submit(
          role,
          code: 'CODE',
          name: 'Name',
          email: 'name@example.com',
          phone: '9876543210',
          agencyName: 'Agency',
          description: ' Notes ',
        );
        expect(api.uploads, isEmpty);
        expect(api.fields['description'], 'Notes');
        expect(response?['data']['alreadySubmitted'], true);
      },
    );
  }
  for (final role in ApplicationRole.values) {
    test(
      '$role sends exact documented fields and preserves duplicate response',
      () async {
        final api = _Api();
        final repo = RoleApplicationRepo(apiService: api);
        final result = await repo.submit(
          role,
          code: ' CODE ',
          name: ' Applicant ',
          email: ' applicant@example.com ',
          phone: '+91 9876543210',
          agencyName: 'My Agency',
          front: File('/tmp/front.jpg'),
          back: File('/tmp/back.jpg'),
        );
        expect(api.path, RoleApplicationRepo.endpoint(role));
        final expected = switch (role) {
          ApplicationRole.agency => {'invitedBy', 'name', 'phone', 'ownerName'},
          ApplicationRole.host => {
            'agencyCode',
            'whatsapp',
            'gmail',
            'hostName',
          },
          ApplicationRole.superAdmin => {'fullName', 'email', 'phone'},
        };
        expect(api.fields.keys.toSet(), expected);
        expect(
          api.fields[role == ApplicationRole.host ? 'whatsapp' : 'phone'],
          '919876543210',
        );
        expect(api.uploads.keys.toSet(), {'doc_photo_front', 'doc_photo_back'});
        expect(result?['data']['alreadySubmitted'], true);
      },
    );
    test(
      '$role status lookup escapes query and uses documented endpoint',
      () async {
        final api = _Api();
        await RoleApplicationRepo(apiService: api).status(role, '9876543210');
        final uri = Uri.parse(api.path);
        expect(uri.path, RoleApplicationRepo.endpoint(role, status: true));
        expect(uri.queryParameters, {
          role == ApplicationRole.agency ? 'query' : 'phone': '9876543210',
        });
      },
    );
  }
}
