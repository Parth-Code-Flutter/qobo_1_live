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

    test('parses live_streaming_created as Join/Dismiss broadcast', () {
      final payload = RoomInvitePushPayload.tryParse({
        'type': 'live_streaming_created',
        'room_id': 'room-live-1',
        'room_type': 'video',
        'host_name': 'Yasmin',
        'room_title': 'Friday Live',
      });

      expect(payload, isNotNull);
      expect(payload!.isBroadcastAlert, isTrue);
      expect(payload.isDirectInvite, isFalse);
      expect(payload.isLiveStreamAlert, isTrue);
      expect(payload.bannerTitle, 'Live Stream Alert! 🔴');
      expect(payload.bannerBody, contains('is now live'));
    });

    test('parses live_stream_started follower alert from handover guide', () {
      final payload = RoomInvitePushPayload.tryParse(
        {
          'type': 'live_stream_started',
          'event': 'host_live_started',
          'room_id': '63742a9a-645a-42e2-8469-4ba806bfa741',
          'roomId': '63742a9a-645a-42e2-8469-4ba806bfa741',
          'room_type': 'live_stream',
          'host_id': 'idc8991071',
          'host_name': 'Kirit',
          'title': 'Evening Music & Chat',
          'message': 'Kirit is now live! Join the stream.',
        },
        title: 'Live Stream Alert! 🔴',
        body: 'Kirit has started a live stream: "Evening Music & Chat"',
      );

      expect(payload, isNotNull);
      expect(payload!.isLiveStreamAlert, isTrue);
      expect(payload.isBroadcastAlert, isTrue);
      expect(payload.roomId, '63742a9a-645a-42e2-8469-4ba806bfa741');
      expect(payload.roomType, 'live_stream');
      expect(payload.hostName, 'Kirit');
      expect(payload.bannerTitle, 'Live Stream Alert! 🔴');
      expect(payload.bannerBody, contains('Evening Music'));
    });

    test('maps host_live_started event-only payloads to live_stream_started', () {
      final payload = RoomInvitePushPayload.tryParse({
        'event': 'host_live_started',
        'room_id': 'room-live-2',
        'hostName': 'Yasmin',
        'message': 'Yasmin is now live!',
      });

      expect(payload, isNotNull);
      expect(payload!.type, PushNotificationTypes.liveStreamStarted);
      expect(payload.isLiveStreamAlert, isTrue);
      expect(payload.hostName, 'Yasmin');
      expect(payload.bannerBody, 'Yasmin is now live!');
    });

    test('parses general/custom without room_id', () {
      final general = RoomInvitePushPayload.tryParse(
        {'type': 'general', 'notification_id': 'n1'},
        title: 'Promo',
        body: 'Check the mall',
      );
      expect(general, isNotNull);
      expect(general!.isBroadcastAlert, isTrue);
      expect(general.hasRoomId, isFalse);
      expect(general.bannerTitle, 'Promo');
      expect(general.bannerBody, 'Check the mall');

      final custom = RoomInvitePushPayload.tryParse({
        'type': 'custom',
        'room_id': 'room-3',
        'host_name': 'Admin',
      });
      expect(custom, isNotNull);
      expect(custom!.hasRoomId, isTrue);
    });

    test('returns null for unsupported push types or missing room_id', () {
      expect(RoomInvitePushPayload.tryParse({'type': 'chat'}), isNull);
      expect(RoomInvitePushPayload.tryParse({'type': 'room_invite'}), isNull);
      expect(
        RoomInvitePushPayload.tryParse({'type': 'live_streaming_created'}),
        isNull,
      );
    });
  });

  group('PushNotificationService helpers', () {
    test('maps backend notification types to action sets', () {
      expect(
        PushNotificationService.actionSetForData({'type': 'room_invite'}),
        PushNotificationActionSet.joinReject,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'room_created'}),
        PushNotificationActionSet.joinDismiss,
      );
      expect(
        PushNotificationService.actionSetForData({
          'type': 'live_streaming_created',
        }),
        PushNotificationActionSet.joinDismiss,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'general'}),
        PushNotificationActionSet.joinDismiss,
      );
      expect(
        PushNotificationService.actionSetForData({'type': 'custom'}),
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

    test('synthesizes display copy for live_streaming_created', () {
      const message = PushNotificationMessage(
        messageId: '2',
        title: '',
        body: '',
        data: {
          'type': 'live_streaming_created',
          'host_name': 'Yasmin',
          'room_title': 'Friday Live',
        },
      );

      final display = PushNotificationService.displayCopyFor(message);
      expect(display.title, 'Live Stream Alert! 🔴');
      expect(display.body, contains('live video stream'));
      expect(display.body, contains('Friday Live'));
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
      expect(PushNotificationActions.roomBroadcastCategory, 'ROOM_BROADCAST');
      expect(PushNotificationActions.joinRoom, 'JOIN_ROOM');
      expect(PushNotificationActions.rejectRoom, 'REJECT_ROOM');
      expect(PushNotificationActions.dismissRoom, 'DISMISS_ROOM');
    });
  });

  group('PushNotificationTypes', () {
    test('classifies join-reject vs join-dismiss types', () {
      expect(PushNotificationTypes.isDirectInvite('room_invite'), isTrue);
      expect(PushNotificationTypes.isJoinDismiss('room_created'), isTrue);
      expect(
        PushNotificationTypes.isJoinDismiss('live_streaming_created'),
        isTrue,
      );
      expect(
        PushNotificationTypes.isJoinDismiss('live_stream_started'),
        isTrue,
      );
      expect(
        PushNotificationTypes.isLiveStreamAlert('live_stream_started'),
        isTrue,
      );
      expect(PushNotificationTypes.isJoinDismiss('general'), isTrue);
      expect(PushNotificationTypes.isJoinDismiss('custom'), isTrue);
      expect(PushNotificationTypes.requiresRoomId('general'), isFalse);
      expect(PushNotificationTypes.requiresRoomId('room_created'), isTrue);
      expect(
        PushNotificationTypes.requiresRoomId('live_stream_started'),
        isTrue,
      );
    });
  });
}
