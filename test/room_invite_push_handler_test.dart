import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/services/firebase/room_invite_push_payload.dart';

void main() {
  group('RoomInvitePushPayload', () {
    test('parses room_invite data fields from backend guide', () {
      final payload = RoomInvitePushPayload.tryParse({
        'type': 'room_invite',
        'notification_id': 'notif_7f8a9e0b1c2d3e4f',
        'invitation_id': 'cfc56941-6a51-44f3-bc8f-3c265f436e72',
        'room_id': 'e48f83fd-5559-4f31-8df7-c23355de0a52',
        'room_type': 'audio',
        'room_title': "Yasmin's Lounge",
        'host_id': 'idc6717895',
        'host_name': 'Yasmin',
        'expires_at': '2099-07-16T18:05:00.000Z',
      });

      expect(payload, isNotNull);
      expect(payload!.isDirectInvite, isTrue);
      expect(payload.hasInvitationId, isTrue);
      expect(payload.isExpired, isFalse);
      expect(payload.roomId, 'e48f83fd-5559-4f31-8df7-c23355de0a52');
      expect(payload.roomType, 'audio');
      expect(payload.hostName, 'Yasmin');
    });

    test('marks invite expired when expires_at is in the past', () {
      final payload = RoomInvitePushPayload.tryParse({
        'type': 'room_invite',
        'room_id': 'room-1',
        'invitation_id': 'invite-1',
        'expires_at': '2020-01-01T00:00:00.000Z',
      });

      expect(payload, isNotNull);
      expect(payload!.isExpired, isTrue);
    });

    test('parses room_created broadcast without invitation_id', () {
      final payload = RoomInvitePushPayload.tryParse({
        'type': 'room_created',
        'room_id': 'room-2',
        'room_type': 'video',
        'host_name': 'Yasmin',
      });

      expect(payload, isNotNull);
      expect(payload!.isBroadcastAlert, isTrue);
      expect(payload.hasInvitationId, isFalse);
    });

    test('returns null for unsupported push types', () {
      expect(RoomInvitePushPayload.tryParse({'type': 'chat'}), isNull);
      expect(RoomInvitePushPayload.tryParse({'type': 'room_invite'}), isNull);
    });
  });

  group('PushNotificationService helpers', () {
    test('maps room_invite and room_created to action sets', () {
      expect(
        PushNotificationService.actionSetForData({'type': 'room_invite'}),
        PushNotificationActionSet.joinReject,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'room_created'}),
        PushNotificationActionSet.joinDismiss,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'other'}),
        PushNotificationActionSet.none,
      );
    });

    test('synthesizes display copy for data-only invites', () {
      const message = PushNotificationMessage(
        messageId: '1',
        title: '',
        body: '',
        data: {
          'type': 'room_invite',
          'host_name': 'Yasmin',
          'room_title': "Yasmin's Lounge",
        },
      );

      final display = PushNotificationService.displayCopyFor(message);
      expect(display.title, 'Room Invitation');
      expect(display.body, contains('Yasmin'));
      expect(display.body, contains("Yasmin's Lounge"));
    });

    test('round-trips local notification payload JSON', () {
      const original = PushNotificationMessage(
        messageId: 'msg-1',
        title: 'Room Invitation',
        body: 'Join now',
        data: {
          'type': 'room_invite',
          'room_id': 'room-1',
          'invitation_id': 'invite-1',
        },
      );

      final restored = PushNotificationMessage.fromPayloadJson(
        original.toPayloadJson(),
      );
      expect(restored.messageId, 'msg-1');
      expect(restored.data['invitation_id'], 'invite-1');
      expect(restored.data['type'], 'room_invite');
    });
  });

  group('PushNotificationActions', () {
    test('keeps stable ids matching backend APNs category contract', () {
      expect(PushNotificationActions.roomInviteCategory, 'ROOM_INVITE');
      expect(PushNotificationActions.joinRoom, 'JOIN_ROOM');
      expect(PushNotificationActions.rejectRoom, 'REJECT_ROOM');
      expect(PushNotificationActions.dismissRoom, 'DISMISS_ROOM');
    });
  });
}
