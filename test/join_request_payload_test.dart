import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/join_request_payload.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';

void main() {
  group('JoinRequestPayload.tryParse', () {
    test('parses host join_request FCM fields', () {
      final payload = JoinRequestPayload.tryParse({
        'type': 'join_request',
        'notification_id': 'n1',
        'request_id': 'req-1',
        'room_id': 'room-1',
        'session_type': 'audio_room',
        'room_title': 'Star Host Room',
        'requester_id': 'u1',
        'requester_name': 'Sunil',
        'requester_avatar': 'https://cdn.example/a.png',
        'expires_at': '2099-01-01T00:00:00.000Z',
      });

      expect(payload, isNotNull);
      expect(payload!.requestId, 'req-1');
      expect(payload.roomId, 'room-1');
      expect(payload.sessionType, 'audio_room');
      expect(payload.requesterName, 'Sunil');
      expect(payload.isHostRequest, isTrue);
      expect(payload.bannerBody, contains('Sunil'));
    });

    test('parses nested user object from list pending API', () {
      final payload = JoinRequestPayload.tryParse({
        'type': 'join_request',
        'request_id': 'req-2',
        'room_id': 'room-2',
        'session_type': 'live_stream',
        'user': {
          'id': 'idc1',
          'name': 'Asha',
          'avatar': 'https://cdn.example/b.png',
        },
      });

      expect(payload, isNotNull);
      expect(payload!.requesterId, 'idc1');
      expect(payload.requesterName, 'Asha');
      expect(payload.isLiveStream, isTrue);
    });

    test('parses join_approved viewer event', () {
      final payload = JoinRequestPayload.tryParse({
        'type': 'join_approved',
        'request_id': 'req-3',
        'room_id': 'room-3',
        'session_type': 'video_room',
        'host_name': 'Host',
      });

      expect(payload, isNotNull);
      expect(payload!.isApproved, isTrue);
      expect(payload.hostName, 'Host');
    });
  });

  group('JoinApprovalService helpers', () {
    test('detects joinApprovalRequired flag casings', () {
      expect(
        JoinApprovalService.isApprovalRequired({
          'joinApprovalRequired': true,
        }),
        isTrue,
      );
      expect(
        JoinApprovalService.isApprovalRequired({
          'join_approval_required': 'true',
        }),
        isTrue,
      );
      expect(
        JoinApprovalService.isApprovalRequired({
          'roomData': {'joinApprovalRequired': 1},
        }),
        isTrue,
      );
      expect(JoinApprovalService.isApprovalRequired({'name': 'x'}), isFalse);
    });

    test('maps session types', () {
      expect(
        JoinApprovalService.sessionTypeFor(roomType: 'AUDIO'),
        'audio_room',
      );
      expect(
        JoinApprovalService.sessionTypeFor(type: 'video'),
        'video_room',
      );
      expect(
        JoinApprovalService.sessionTypeFor(isLiveStream: true),
        'live_stream',
      );
    });

    test('detects APPROVAL_REQUIRED errors', () {
      expect(
        JoinApprovalService.isApprovalRequiredError({
          'statusCode': 0,
          'code': 'APPROVAL_REQUIRED',
        }),
        isTrue,
      );
      expect(
        JoinApprovalService.isApprovalRequiredError({
          'statusCode': 0,
          'message': 'Waiting for host approval',
        }),
        isTrue,
      );
      expect(
        JoinApprovalService.isApprovalRequiredError({
          'statusCode': 0,
          'message': 'Banned',
        }),
        isFalse,
      );
    });
  });

  group('PushNotificationTypes join request', () {
    test('action set is Approve/Reject for join_request', () {
      expect(
        PushNotificationService.actionSetForData({'type': 'join_request'}),
        PushNotificationActionSet.joinApproveReject,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'join_approved'}),
        PushNotificationActionSet.none,
      );
    });
  });
}
