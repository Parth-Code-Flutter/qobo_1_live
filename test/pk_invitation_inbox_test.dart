import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/services/pk/pk_invitation_inbox.dart';

void main() {
  test('reads a nested socket invitation', () {
    final invitation = PkInvitation.fromJson(
      pkInvitationFields({
        'event': 'PK_INVITATION_RECEIVED',
        'data': {
          'invitation': {
            'id': 'inv-1',
            'fromUserName': 'Mic King',
            'durationSec': 120,
            'status': 'PENDING',
          },
        },
      }),
    );

    expect(invitation.invitationId, 'inv-1');
    expect(invitation.fromUserName, 'Mic King');
    expect(invitation.durationSec, 120);
  });

  test('reads a legacy pk_request payload', () {
    final invitation = PkInvitation.fromJson(
      pkInvitationFields({
        'type': 'pk_request',
        'request_id': 'req-9',
        'sender_host_name': 'Host A',
        'sender_avatar': 'https://cdn.example/a.png',
        'battle_duration': '300',
        'expires_at': '2099-01-01T00:00:00.000Z',
      }),
    );

    expect(invitation.invitationId, 'req-9');
    expect(invitation.fromUserName, 'Host A');
    expect(invitation.fromUserAvatar, 'https://cdn.example/a.png');
    expect(invitation.durationSec, 300);
  });

  test('incoming list keeps only pending invites', () {
    final invites = pendingIncomingPkInvitations({
      'success': true,
      'data': {
        'invitations': [
          {'invitationId': 'keep', 'status': 'PENDING'},
          {'invitationId': 'done', 'status': 'ACCEPTED'},
          {
            'invitationId': 'old',
            'status': 'PENDING',
            'expiresAt': '2000-01-01T00:00:00.000Z',
          },
        ],
      },
    });

    expect(invites.map((invite) => invite.invitationId), ['keep']);
  });

  test('a data array is accepted', () {
    final invites = pendingIncomingPkInvitations({
      'data': [
        {'invitation_id': 'a', 'status': 'pending'},
        {'invitation_id': 'a', 'status': 'pending'},
      ],
    });

    expect(invites, hasLength(1));
    expect(invites.single.invitationId, 'a');
  });

  test('an error envelope is not an invitation', () {
    expect(
      pendingIncomingPkInvitations({
        'success': false,
        'message': 'Unauthorized',
        'data': null,
      }),
      isEmpty,
    );
  });

  test('waiting stays up while the outgoing invite is pending', () {
    final decision = outgoingInvitationWaitDecision(
      invitationId: 'inv-1',
      body: {
        'data': {
          'invitations': [
            {
              'invitationId': 'inv-1',
              'status': 'PENDING',
              'pkId': 'reserved-later',
            },
          ],
        },
      },
    );

    expect(decision.action, PkOutgoingWaitAction.keepWaiting);
  });

  test('an accepted outgoing invite opens that battle', () {
    final decision = outgoingInvitationWaitDecision(
      invitationId: 'inv-1',
      body: {
        'success': true,
        'data': [
          {
            'invitationId': 'inv-1',
            'status': 'ACCEPTED',
            'session': {'pkId': 'pk-42'},
          },
        ],
      },
    );

    expect(decision.action, PkOutgoingWaitAction.startBattle);
    expect(decision.pkId, 'pk-42');
  });

  test('a different invite does not start this wait', () {
    final decision = outgoingInvitationWaitDecision(
      invitationId: 'inv-1',
      body: {
        'data': {
          'invitations': [
            {'invitationId': 'inv-2', 'status': 'ACCEPTED', 'pkId': 'pk-9'},
          ],
        },
      },
    );

    expect(decision.action, PkOutgoingWaitAction.keepWaiting);
  });

  test('decline and timeout leave the waiting screen', () {
    expect(
      outgoingInvitationWaitDecision(
        invitationId: 'inv-1',
        body: {
          'data': {
            'invitationId': 'inv-1',
            'status': 'REJECTED',
          },
        },
      ).action,
      PkOutgoingWaitAction.declined,
    );
    expect(
      outgoingInvitationWaitDecision(
        invitationId: 'inv-1',
        body: {
          'data': {
            'invitationId': 'inv-1',
            'status': 'EXPIRED',
          },
        },
      ).action,
      PkOutgoingWaitAction.timedOut,
    );
  });

  test('accepted invite without a separate pk id still starts', () {
    final decision = outgoingInvitationWaitDecision(
      invitationId: 'inv-1',
      body: {
        'data': {
          'invitationId': 'inv-1',
          'status': 'ACCEPTED',
        },
      },
    );

    expect(decision.action, PkOutgoingWaitAction.startBattle);
    expect(decision.pkId, 'inv-1');
  });

  test('active room battle is the id that ends the wait', () {
    const pending = {
      'statusCode': 1,
      'data': {
        'request': {'request_id': 'req-1', 'status': 'pending'},
        'battle': null,
      },
    };
    expect(activeBattleIdFromRoomPk(pending), isEmpty);

    const active = {
      'statusCode': 1,
      'data': {
        'request': null,
        'battle': {
          'id': 'battle-7',
          'battle_id': 'battle-7',
          'status': 'active',
          'room1Id': 'room-a',
          'room2Id': 'room-b',
          'room1Score': 1,
          'room2Score': 2,
          'duration': 120,
          'remainingSeconds': 90,
        },
      },
    };
    expect(activeBattleIdFromRoomPk(active), 'battle-7');

    final session = legacyBattleAsSession(
      body: active,
      selfRoomId: 'room-b',
      selfName: 'Me',
      opponentName: 'Mic King',
    );
    expect(session['pkId'], 'battle-7');
    expect(session['status'], 'ACTIVE');
    expect((session['sideA'] as Map)['roomId'], 'room-b');
    expect((session['sideA'] as Map)['displayName'], 'Me');
    expect((session['sideB'] as Map)['displayName'], 'Mic King');
    expect((session['sideB'] as Map)['score'], 1);
  });

  test('socket accept payload can carry a nested pk id', () {
    expect(
      pkIdFromPkPayload({
        'event': 'PK_INVITATION_ACCEPTED',
        'data': {'pk_id': 'pk-7'},
      }),
      'pk-7',
    );
  });
}