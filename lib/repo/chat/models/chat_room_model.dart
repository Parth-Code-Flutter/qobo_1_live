/// Parsed response from `POST /api/chat/room`.
class ChatRoomModel {
  const ChatRoomModel({
    required this.roomId,
    this.type = 'direct',
    this.isNew = false,
    this.firestorePath = '',
    this.peerId = '',
    this.peerName = '',
    this.peerDisplayPicture,
  });

  final String roomId;
  final String type;
  final bool isNew;
  final String firestorePath;
  final String peerId;
  final String peerName;
  final String? peerDisplayPicture;

  factory ChatRoomModel.fromResponseData(dynamic data) {
    if (data is! Map) {
      return const ChatRoomModel(roomId: '');
    }
    final json = Map<String, dynamic>.from(data);
    final peer = json['peer'];
    final Map<String, dynamic>? peerMap =
        peer is Map ? Map<String, dynamic>.from(peer) : null;

    return ChatRoomModel(
      roomId: json['roomId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'direct',
      isNew: json['isNew'] == true,
      firestorePath: json['firestorePath']?.toString() ?? '',
      peerId: peerMap?['id']?.toString() ?? '',
      peerName: peerMap?['name']?.toString() ?? '',
      peerDisplayPicture: peerMap?['displayPicture']?.toString(),
    );
  }
}

/// Parsed response from `POST /api/chat/firebase-token`.
class FirebaseTokenModel {
  const FirebaseTokenModel({
    required this.firebaseCustomToken,
    required this.firebaseUid,
  });

  final String firebaseCustomToken;
  final String firebaseUid;

  factory FirebaseTokenModel.fromResponseData(dynamic data) {
    if (data is! Map) {
      return const FirebaseTokenModel(firebaseCustomToken: '', firebaseUid: '');
    }
    final json = Map<String, dynamic>.from(data);
    return FirebaseTokenModel(
      firebaseCustomToken: json['firebaseCustomToken']?.toString() ?? '',
      firebaseUid: json['firebaseUid']?.toString() ?? '',
    );
  }
}
