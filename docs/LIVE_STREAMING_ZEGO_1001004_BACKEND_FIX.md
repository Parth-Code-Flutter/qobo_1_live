# Live Streaming Zego 1001004 Backend Fix

## Problem

Audience and host sometimes reach the live streaming screen, but Zego room login fails with:

```text
Unable to join live
Zego room login failed (1001004)
```

This error happens during Zego `loginRoom`, before video playback/rendering starts. It usually means the Zego credential set returned by backend is not internally consistent.

## Most Likely Cause

The Zego token returned by backend is not generated for the exact same:

- `appId`
- `roomId`
- `userId`

that mobile uses for Zego login.

## Current Mobile Status

Mobile has been updated to use Zego Express Token Mode for live streaming when
backend returns `zegoStreaming.token`.

Mobile now follows this rule:

```text
If zegoStreaming.token exists:
  create ZegoExpressEngine with appSign = ''
  loginRoom with ZegoRoomConfig.token = zegoStreaming.token

If zegoStreaming.token is empty:
  create ZegoExpressEngine with appSign fallback
  loginRoom without token
```

So if `1001004` still happens after installing the latest mobile build, backend
must verify the generated token and returned identifiers. The remaining failure
is usually caused by a backend/Zego credential mismatch, not UI rendering.

## Required Backend Rule

For every live streaming create/join response, backend must generate the token using the exact values returned in `zegoStreaming`.

Example:

```json
{
  "zegoStreaming": {
    "appId": 1538269104,
    "roomId": "ls_123456_789",
    "userId": "idc6717895",
    "token": "TOKEN_GENERATED_FOR_EXACT_APP_ROOM_USER",
    "publishStreamId": "stream_host_123",
    "playStreamId": "stream_host_123",
    "hostStreamId": "stream_host_123"
  }
}
```

Token must be generated for:

```text
appId  = 1538269104
roomId = zegoStreaming.roomId
userId = zegoStreaming.userId
```

## API Endpoints To Verify

### 1. Create Live Stream

```http
POST /api/live-streaming/create
```

Backend should:

1. Create live stream.
2. Generate a Zego room id.
3. Generate host user id.
4. Generate token for that exact room id and host user id.
5. Return `zegoStreaming`.

### 2. Join Live Stream

```http
POST /api/live-streaming/join
```

Backend should:

1. Receive `liveStreamingId` and/or `roomId`.
2. Resolve current audience user.
3. Generate a fresh token for this audience user.
4. Return `zegoStreaming.userId` for the audience, not the host.
5. Return the same `roomId` used by host.
6. Return `playStreamId` matching the host publish stream.

Correct audience join response:

```json
{
  "statusCode": 1,
  "message": "Joined live stream",
  "data": {
    "liveStreamingId": "923668d7-113f-463e-8af8-404d5df15306",
    "zegoStreaming": {
      "appId": 1538269104,
      "roomId": "ls_1783940238312_425465",
      "userId": "AUDIENCE_CURRENT_USER_ID",
      "token": "TOKEN_FOR_AUDIENCE_CURRENT_USER_ID",
      "playStreamId": "HOST_PUBLISH_STREAM_ID",
      "hostStreamId": "HOST_PUBLISH_STREAM_ID"
    }
  }
}
```

## Important Checks

### AppID

Live streaming AppID currently used by mobile:

```text
1538269104
```

Backend must generate Zego tokens using this same AppID.

### AppSign

Backend must confirm the live streaming AppSign is the real 64-character Zego AppSign for AppID `1538269104`.

The latest shared documentation had an AppSign value that looked invalid/short.
If backend signs tokens with a wrong AppSign, Zego login can fail with
`1001004`.

Valid AppSign format:

```text
64 lowercase/uppercase hex characters
```

Example valid length:

```text
72022e423995fb9f3bc6d7ef3b084f2eaf421b49477b78048a75dca27ee7d101
```

The previously shared short value was only 57 characters:

```text
72022e423995fb9f3bc084f2eaf421b49477b78048a75dca27ee7d101
```

If backend uses the 57-character value to generate Token04, Zego room login can
fail even when mobile integration is correct.

### User ID

For host:

```text
token userId == zegoStreaming.userId == host user id used by mobile
```

For audience:

```text
token userId == zegoStreaming.userId == audience current user id used by mobile
```

Audience must not receive a token generated for host user id.

### Room ID

For host and audience:

```text
token roomId == zegoStreaming.roomId
```

Audience must join the exact same room id created for the host stream.

### Token Freshness

Backend should return a fresh token from `/api/live-streaming/join`.

Recommended flow:

1. Mobile fetches live list.
2. User taps a live stream.
3. Mobile calls `/api/live-streaming/join`.
4. Backend returns fresh `zegoStreaming`.
5. Mobile logs into Zego using that response.

Avoid relying on old tokens from the list API unless they are generated per requesting user and are not expired.

## Backend Logging Needed

Please add logs around token generation for create and join:

```text
[Live Zego Token]
endpoint=create/join
appId=1538269104
roomId=<room id used for token>
userId=<user id used for token>
tokenLength=<token length>
expireAt=<token expiry time>
publishStreamId=<host publish stream id>
playStreamId=<viewer play stream id>
```

Mobile will log the values it receives before `loginRoom`. Backend and mobile values must match exactly.

## Expected Mobile Usage

Mobile will use:

```text
appId       = zegoStreaming.appId
appSign     = zegoStreaming.appSign if valid, otherwise local fallback
roomId      = zegoStreaming.roomId
userId      = zegoStreaming.userId
token       = zegoStreaming.token
publishId   = zegoStreaming.publishStreamId for host
playId      = zegoStreaming.playStreamId for audience
```

Mobile must not call `/api/room/join` or `/api/room/end` for live streaming.

Live streaming must use only:

```text
/api/live-streaming/create
/api/live-streaming/join
/api/live-streaming/leave
/api/live-streaming/end
/api/live-streaming/list
```

## Acceptance Criteria

1. Host creates live stream and Zego room login succeeds.
2. Host starts publishing with `publishStreamId`.
3. Audience joins via `/api/live-streaming/join`.
4. Audience receives a token generated for audience user id.
5. Audience logs into the same Zego room id.
6. Audience starts playing host `playStreamId`.
7. No `1001004` error on host or audience.

## Quick Backend Debug Checklist

- Is token generated with AppID `1538269104`?
- Is AppSign correct and 64 hex characters?
- Does token `roomId` exactly match `zegoStreaming.roomId`?
- Does token `userId` exactly match `zegoStreaming.userId`?
- For audience join, is token generated for the audience user, not the host?
- Is `zegoStreaming.roomId` the Zego live id such as `ls_...`, not only the
  backend UUID?
- Is token still valid at the moment mobile calls `loginRoom`?

## Backend AI Prompt

Please debug Zego live streaming `loginRoom` error `1001004`.

Mobile is using Flutter Zego Express in Token Mode:

```dart
ZegoExpressEngine.createEngineWithProfile(
  ZegoEngineProfile(
    1538269104,
    ZegoScenario.Broadcast,
    appSign: '',
  ),
);

final config = ZegoRoomConfig.defaultConfig();
config.token = data['zegoStreaming']['token'];

ZegoExpressEngine.instance.loginRoom(
  data['zegoStreaming']['roomId'],
  ZegoUser(data['zegoStreaming']['userId'], userName),
  config: config,
);
```

Backend must fix `/api/live-streaming/create` and `/api/live-streaming/join` so
the token is generated with exactly:

```text
appId  = zegoStreaming.appId
roomId = zegoStreaming.roomId
userId = zegoStreaming.userId
```

For host create:

```text
zegoStreaming.userId must be host user id
publishStreamId/playStreamId/hostStreamId must identify the host stream
```

For audience join:

```text
zegoStreaming.userId must be current audience user id
token must be generated for current audience user id
roomId must match the host Zego room id
playStreamId must match the host publish stream id
```

Do not generate the audience token with the host user id. Do not generate the
token for backend UUID if mobile is asked to login with `ls_...`. Do not return
an invalid/short AppSign from server config.
- For audience join, is `zegoStreaming.userId` the audience id, not host id?
- Is `/api/live-streaming/join` returning a fresh token?
- Is `playStreamId` the host's active publish stream id?
- Is host stream still active when audience joins?
