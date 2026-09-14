import 'dart:convert';
import 'package:qobo_one_live/app/user_flow/family/controllers/family_controller.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qobo_one_live/repo/family/family_repo.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/services/api_constants.dart';

class _Api extends ApiService {
  final paths = <String>[];
  Map<String, dynamic> body = {};
  Map<String, File>? uploads;
  bool fallback = false;
  String? uploadMethod;
  http.Response respond(String path) {
    paths.add(path);
    return http.Response(
      '{"statusCode":1,"data":{"id":"group-1","logoUrl":"https://example.com/logo.png"}}',
      fallback && paths.length == 1 ? 404 : 200,
    );
  }

  @override
  Future<http.Response?> postRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
    String? bearerToken,
    bool skipUnauthorizedHandling = false,
  }) async {
    body = Map<String, dynamic>.from(requestModel as Map);
    return respond(endPoint);
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
    uploadMethod = method;
    body = fields;
    uploads = namedFiles;
    return respond(endPoint);
  }
}

class _OwnerController extends FamilyController {
  @override
  String get currentUserId => 'owner-1';
}

void main() {
  test('only the owner can update the group photo', () {
    final controller = _OwnerController();
    expect(controller.isFamilyOwner({'adminUserId': 'owner-1'}), isTrue);
    expect(
      controller.isFamilyOwner({
        'adminUserId': 'someone-else',
        'myRole': 'admin',
        'canManageMembers': true,
      }),
      isFalse,
    );
    expect(controller.isFamilyOwner({'myRole': 'member'}), isFalse);
  });
  test(
    'photo update uses multipart PATCH without changing name or description',
    () async {
      final api = _Api();
      final file = File('/tmp/logo.png');
      await FamilyRepo(
        apiService: api,
      ).updateFamily(familyId: 'g1', logoFile: file);
      expect(api.uploadMethod, 'PATCH');
      expect(api.paths, [FamilyEndpoints.groupUpdate('g1')]);
      expect(api.uploads, {'logo': file});
      expect(api.body.containsKey('name'), isFalse);
      expect(api.body.containsKey('description'), isFalse);
    },
  );

  test('JSON creation supports optional description and logo URL', () async {
    final api = _Api();
    final response = await FamilyRepo(apiService: api).createFamily(
      name: ' Family ',
      logo: ' https://example.com/logo.png ',
      initialMemberIds: ['u1'],
    );
    expect(api.paths, [FamilyEndpoints.groups]);
    expect(api.body, {
      'name': 'Family',
      'logo': 'https://example.com/logo.png',
      'joiningCoins': 0,
      'initialMemberIds': ['u1'],
    });
    expect(api.uploads, isNull);
    expect(response?['data']['logoUrl'], 'https://example.com/logo.png');
  });
  test(
    'multipart creation preserves file and encodes member IDs on fallback',
    () async {
      final api = _Api()..fallback = true;
      final file = File('/tmp/family-logo.png');
      await FamilyRepo(apiService: api).createFamily(
        name: 'Family',
        description: ' Welcome ',
        joiningCoins: 1000,
        logoFile: file,
        initialMemberIds: ['u1', 'u2'],
      );
      expect(api.paths, [FamilyEndpoints.groups, FamilyEndpoints.create]);
      expect(api.uploads, {'logo': file});
      expect(api.body['joiningCoins'], '1000');
      expect(api.body['description'], 'Welcome');
      expect(jsonDecode(api.body['initialMemberIds'] as String), ['u1', 'u2']);
      expect(api.body.containsKey('logo'), isFalse);
    },
  );
}
