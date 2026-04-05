import 'dart:convert';

enum ConnectTab { home, chats, calls, settings }
enum ConversationType { direct, group }
enum MessageType { text, attachment, note, secret, totp, system }
enum CallType { audio, video }
enum CallStatus { ongoing, scheduled, completed, declined, missed }
enum Discoverability { public, private, friendsOnly }

String _nameOf(Object value) => value.toString().split('.').last;

T _enumFrom<T>(List<T> values, String? value, T fallback) {
  if (value == null) return fallback;
  for (final candidate in values) {
    if (_nameOf(candidate as Object) == value) return candidate;
  }
  return fallback;
}

List<String> _strings(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return {};
}

class ConnectProfile {
  const ConnectProfile({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.email,
    required this.bio,
    required this.avatar,
    required this.publicKey,
    required this.discoverability,
    required this.allowContact,
    required this.allowMessages,
  });

  final String userId;
  final String displayName;
  final String username;
  final String email;
  final String bio;
  final String avatar;
  final String publicKey;
  final Discoverability discoverability;
  final bool allowContact;
  final bool allowMessages;

  String get shortName => displayName.isNotEmpty ? displayName : username;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'username': username,
        'email': email,
        'bio': bio,
        'avatar': avatar,
        'publicKey': publicKey,
        'discoverability': _nameOf(discoverability),
        'allowContact': allowContact,
        'allowMessages': allowMessages,
      };

  factory ConnectProfile.fromJson(Map<String, dynamic> json) => ConnectProfile(
        userId: json['userId']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        bio: json['bio']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? '',
        publicKey: json['publicKey']?.toString() ?? '',
        discoverability: _enumFrom(Discoverability.values, json['discoverability']?.toString(), Discoverability.public),
        allowContact: json['allowContact'] != false,
        allowMessages: json['allowMessages'] != false,
      );
}

class ConnectConversation {
  const ConnectConversation({
    required this.id,
    required this.type,
    required this.name,
    required this.participantIds,
    required this.creatorId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isEncrypted,
    required this.isPinned,
    required this.settings,
    this.otherUserId = '',
    this.avatarUrl = '',
    this.isSelf = false,
  });

  final String id;
  final ConversationType type;
  final String name;
  final List<String> participantIds;
  final String creatorId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isEncrypted;
  final bool isPinned;
  final Map<String, dynamic> settings;
  final String otherUserId;
  final String avatarUrl;
  final bool isSelf;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': _nameOf(type),
        'name': name,
        'participantIds': participantIds,
        'creatorId': creatorId,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'unreadCount': unreadCount,
        'isEncrypted': isEncrypted,
        'isPinned': isPinned,
        'settings': settings,
        'otherUserId': otherUserId,
        'avatarUrl': avatarUrl,
        'isSelf': isSelf,
      };

  factory ConnectConversation.fromJson(Map<String, dynamic> json) => ConnectConversation(
        id: json['id']?.toString() ?? '',
        type: _enumFrom(ConversationType.values, json['type']?.toString(), ConversationType.direct),
        name: json['name']?.toString() ?? '',
        participantIds: _strings(json['participantIds']),
        creatorId: json['creatorId']?.toString() ?? '',
        lastMessage: json['lastMessage']?.toString() ?? '',
        lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
        unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
        isEncrypted: json['isEncrypted'] == true,
        isPinned: json['isPinned'] == true,
        settings: _map(json['settings']),
        otherUserId: json['otherUserId']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        isSelf: json['isSelf'] == true,
      );
}

class ConnectMessage {
  const ConnectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isEncrypted,
    required this.readBy,
    this.replyToId = '',
    this.attachmentLabel = '',
    this.metadata = const {},
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isEncrypted;
  final List<String> readBy;
  final String replyToId;
  final String attachmentLabel;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': _nameOf(type),
        'createdAt': createdAt.toIso8601String(),
        'isEncrypted': isEncrypted,
        'readBy': readBy,
        'replyToId': replyToId,
        'attachmentLabel': attachmentLabel,
        'metadata': metadata,
      };

  factory ConnectMessage.fromJson(Map<String, dynamic> json) => ConnectMessage(
        id: json['id']?.toString() ?? '',
        conversationId: json['conversationId']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        type: _enumFrom(MessageType.values, json['type']?.toString(), MessageType.text),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        isEncrypted: json['isEncrypted'] == true,
        readBy: _strings(json['readBy']),
        replyToId: json['replyToId']?.toString() ?? '',
        attachmentLabel: json['attachmentLabel']?.toString() ?? '',
        metadata: _map(json['metadata']),
      );
}

class ConnectFeedItem {
  const ConnectFeedItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
    required this.tags,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'body': body,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
      };

  factory ConnectFeedItem.fromJson(Map<String, dynamic> json) => ConnectFeedItem(
        id: json['id']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'post',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        tags: _strings(json['tags']),
      );
}

class ConnectCall {
  const ConnectCall({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.participantIds,
    required this.callerId,
    required this.conversationId,
    required this.isLink,
    required this.metadata,
  });

  final String id;
  final String title;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> participantIds;
  final String callerId;
  final String conversationId;
  final bool isLink;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': _nameOf(type),
        'status': _nameOf(status),
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'participantIds': participantIds,
        'callerId': callerId,
        'conversationId': conversationId,
        'isLink': isLink,
        'metadata': metadata,
      };

  factory ConnectCall.fromJson(Map<String, dynamic> json) => ConnectCall(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        type: _enumFrom(CallType.values, json['type']?.toString(), CallType.video),
        status: _enumFrom(CallStatus.values, json['status']?.toString(), CallStatus.ongoing),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 2)),
        participantIds: _strings(json['participantIds']),
        callerId: json['callerId']?.toString() ?? '',
        conversationId: json['conversationId']?.toString() ?? '',
        isLink: json['isLink'] == true,
        metadata: _map(json['metadata']),
      );
}

class ConnectTarget {
  const ConnectTarget({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.type,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String subtitle;
  final String type;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'subtitle': subtitle,
        'type': type,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ConnectTarget.fromJson(Map<String, dynamic> json) => ConnectTarget(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        type: json['type']?.toString() ?? 'note',
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ConnectPasskey {
  const ConnectPasskey({required this.id, required this.name, required this.active});
  final String id;
  final String name;
  final bool active;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'active': active};
  factory ConnectPasskey.fromJson(Map<String, dynamic> json) => ConnectPasskey(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        active: json['active'] == true,
      );
}

class ConnectSettings {
  const ConnectSettings({
    required this.isLocked,
    required this.showPortal,
    required this.enablePush,
    required this.showActiveStatus,
    required this.allowMessages,
    required this.allowCalls,
    required this.allowShares,
    required this.discoverability,
  });

  final bool isLocked;
  final bool showPortal;
  final bool enablePush;
  final bool showActiveStatus;
  final bool allowMessages;
  final bool allowCalls;
  final bool allowShares;
  final Discoverability discoverability;

  Map<String, dynamic> toJson() => {
        'isLocked': isLocked,
        'showPortal': showPortal,
        'enablePush': enablePush,
        'showActiveStatus': showActiveStatus,
        'allowMessages': allowMessages,
        'allowCalls': allowCalls,
        'allowShares': allowShares,
        'discoverability': _nameOf(discoverability),
      };

  factory ConnectSettings.fromJson(Map<String, dynamic> json) => ConnectSettings(
        isLocked: json['isLocked'] == true,
        showPortal: json['showPortal'] != false,
        enablePush: json['enablePush'] != false,
        showActiveStatus: json['showActiveStatus'] != false,
        allowMessages: json['allowMessages'] != false,
        allowCalls: json['allowCalls'] != false,
        allowShares: json['allowShares'] != false,
        discoverability: _enumFrom(Discoverability.values, json['discoverability']?.toString(), Discoverability.public),
      );
}

class ConnectSessionInfo {
  const ConnectSessionInfo({
    required this.userId,
    required this.userName,
    required this.email,
    required this.avatar,
  });

  final String userId;
  final String userName;
  final String email;
  final String avatar;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'email': email,
        'avatar': avatar,
      };

  factory ConnectSessionInfo.fromJson(Map<String, dynamic> json) => ConnectSessionInfo(
        userId: json['userId']?.toString() ?? 'guest',
        userName: json['userName']?.toString() ?? 'Guest',
        email: json['email']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? '',
      );
}

Map<String, dynamic> decodeJsonObject(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  return {};
}
