import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'connect_config.dart';
import 'models/connect_models.dart';
import 'services/connect_api_client.dart';

class ConnectStore extends ChangeNotifier {
  final _uuid = const Uuid();
  final Client _client = Client();
  late final ConnectApiClient api = ConnectApiClient(_client);

  SharedPreferences? _prefs;
  bool _bootstrapped = false;
  bool _loading = true;
  String? _error;

  ConnectSessionInfo _session = const ConnectSessionInfo(
    userId: 'guest',
    userName: 'Guest',
    email: '',
    avatar: '',
  );

  ConnectSettings _settings = const ConnectSettings(
    isLocked: false,
    showPortal: true,
    enablePush: true,
    showActiveStatus: true,
    allowMessages: true,
    allowCalls: true,
    allowShares: true,
    discoverability: Discoverability.public,
  );

  final List<ConnectProfile> _profiles = [];
  final List<ConnectConversation> _conversations = [];
  final List<ConnectMessage> _messages = [];
  final List<ConnectFeedItem> _feed = [];
  final List<ConnectCall> _calls = [];
  final List<ConnectTarget> _targets = [];
  final List<ConnectTarget> _secrets = [];
  final List<ConnectPasskey> _passkeys = [];
  final List<String> _activity = [];

  ConnectTab _tab = ConnectTab.home;
  String? _selectedConversationId;
  String? _selectedCallId;

  bool get isReady => _bootstrapped;
  bool get isLoading => _loading;
  String? get error => _error;
  ConnectSessionInfo get session => _session;
  ConnectSettings get settings => _settings;
  List<ConnectProfile> get profiles => List.unmodifiable(_profiles);
  List<ConnectConversation> get conversations => List.unmodifiable(_conversations);
  List<ConnectMessage> get messages => List.unmodifiable(_messages);
  List<ConnectFeedItem> get feed => List.unmodifiable(_feed);
  List<ConnectCall> get calls => List.unmodifiable(_calls);
  List<ConnectTarget> get notes => List.unmodifiable(_targets);
  List<ConnectTarget> get secrets => List.unmodifiable(_secrets);
  List<ConnectPasskey> get passkeys => List.unmodifiable(_passkeys);
  List<String> get activity => List.unmodifiable(_activity);
  ConnectTab get tab => _tab;
  String? get selectedConversationId => _selectedConversationId;
  String? get selectedCallId => _selectedCallId;

  ConnectConversation? get selectedConversation => _byConversationId(_selectedConversationId);
  ConnectCall? get selectedCall => _byCallId(_selectedCallId);
  ConnectProfile? get me => _byUserId(_session.userId);

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _loading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    _loadLocal();
    _client
      ..setEndpoint(ConnectConfig.endpoint)
      ..setProject(ConnectConfig.projectId);
    await _loadSession();

    if (_profiles.isEmpty) {
      _seed();
      await _persist();
    }

    _loading = false;
    notifyListeners();
  }

  void _loadLocal() {
    final prefs = _prefs;
    if (prefs == null) return;
    _settings = _readObject(prefs, 'connect.settings', ConnectSettings.fromJson, _settings);
    _session = _readObject(prefs, 'connect.session', ConnectSessionInfo.fromJson, _session);
    _profiles
      ..clear()
      ..addAll(_readList(prefs, 'connect.profiles', ConnectProfile.fromJson));
    _conversations
      ..clear()
      ..addAll(_readList(prefs, 'connect.conversations', ConnectConversation.fromJson));
    _messages
      ..clear()
      ..addAll(_readList(prefs, 'connect.messages', ConnectMessage.fromJson));
    _feed
      ..clear()
      ..addAll(_readList(prefs, 'connect.feed', ConnectFeedItem.fromJson));
    _calls
      ..clear()
      ..addAll(_readList(prefs, 'connect.calls', ConnectCall.fromJson));
    _targets
      ..clear()
      ..addAll(_readList(prefs, 'connect.targets', ConnectTarget.fromJson));
    _secrets
      ..clear()
      ..addAll(_readList(prefs, 'connect.secrets', ConnectTarget.fromJson));
    _passkeys
      ..clear()
      ..addAll(_readList(prefs, 'connect.passkeys', ConnectPasskey.fromJson));
    _activity
      ..clear()
      ..addAll(prefs.getStringList('connect.activity') ?? const []);
    _selectedConversationId = prefs.getString('connect.selectedConversationId');
    _selectedCallId = prefs.getString('connect.selectedCallId');
    _tab = _tabFromString(prefs.getString('connect.tab'));
  }

  T _readObject<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) parser,
    T fallback,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return fallback;
    return parser(decodeJsonObject(raw));
  }

  List<T> _readList<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((item) => parser(Map<String, dynamic>.from(item))).toList(growable: false);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await Future.wait([
      prefs.setString('connect.settings', jsonEncode(_settings.toJson())),
      prefs.setString('connect.session', jsonEncode(_session.toJson())),
      prefs.setString('connect.profiles', jsonEncode(_profiles.map((e) => e.toJson()).toList())),
      prefs.setString('connect.conversations', jsonEncode(_conversations.map((e) => e.toJson()).toList())),
      prefs.setString('connect.messages', jsonEncode(_messages.map((e) => e.toJson()).toList())),
      prefs.setString('connect.feed', jsonEncode(_feed.map((e) => e.toJson()).toList())),
      prefs.setString('connect.calls', jsonEncode(_calls.map((e) => e.toJson()).toList())),
      prefs.setString('connect.targets', jsonEncode(_targets.map((e) => e.toJson()).toList())),
      prefs.setString('connect.secrets', jsonEncode(_secrets.map((e) => e.toJson()).toList())),
      prefs.setString('connect.passkeys', jsonEncode(_passkeys.map((e) => e.toJson()).toList())),
      prefs.setStringList('connect.activity', _activity),
      prefs.setString('connect.tab', _tab.name),
      prefs.setString('connect.selectedConversationId', _selectedConversationId ?? ''),
      prefs.setString('connect.selectedCallId', _selectedCallId ?? ''),
    ]);
  }

  Future<void> _loadSession() async {
    try {
      final account = Account(_client);
      final dynamic info = await account.get();
      _session = ConnectSessionInfo(
        userId: info.$id,
        userName: info.name,
        email: info.email,
        avatar: '',
      );
    } catch (_) {
      return;
    }
  }

  void _seed() {
    final now = DateTime.now();
    _profiles.addAll([
      const ConnectProfile(
        userId: 'user-you',
        displayName: 'You',
        username: 'you',
        email: 'you@kylrix.space',
        bio: 'Porting Connect one surface at a time.',
        avatar: '',
        publicKey: 'pub-you',
        discoverability: Discoverability.public,
        allowContact: true,
        allowMessages: true,
      ),
      const ConnectProfile(
        userId: 'user-ava',
        displayName: 'Ava Stone',
        username: 'ava',
        email: 'ava@kylrix.space',
        bio: 'Design and ecosystem flows.',
        avatar: '',
        publicKey: 'pub-ava',
        discoverability: Discoverability.public,
        allowContact: true,
        allowMessages: true,
      ),
      const ConnectProfile(
        userId: 'user-milo',
        displayName: 'Milo Chen',
        username: 'milo',
        email: 'milo@kylrix.space',
        bio: 'Calls, signals, and realtime plumbing.',
        avatar: '',
        publicKey: 'pub-milo',
        discoverability: Discoverability.friendsOnly,
        allowContact: true,
        allowMessages: true,
      ),
    ]);

    _conversations.addAll([
      ConnectConversation(
        id: 'conv-self',
        type: ConversationType.direct,
        name: 'You (Self Chat)',
        participantIds: const ['user-you'],
        creatorId: 'user-you',
        lastMessage: 'Pinned password drop for future me.',
        lastMessageAt: now.subtract(const Duration(minutes: 18)),
        unreadCount: 0,
        isEncrypted: true,
        isPinned: true,
        settings: const {'clearedAt': {}},
        otherUserId: 'user-you',
        isSelf: true,
      ),
      ConnectConversation(
        id: 'conv-ava',
        type: ConversationType.direct,
        name: 'Ava Stone',
        participantIds: const ['user-you', 'user-ava'],
        creatorId: 'user-you',
        lastMessage: 'Send the new shell mockups?',
        lastMessageAt: now.subtract(const Duration(minutes: 4)),
        unreadCount: 2,
        isEncrypted: true,
        isPinned: false,
        settings: const {'clearedAt': {}},
        otherUserId: 'user-ava',
      ),
      ConnectConversation(
        id: 'conv-team',
        type: ConversationType.group,
        name: 'Kylrix Team',
        participantIds: const ['user-you', 'user-ava', 'user-milo'],
        creatorId: 'user-milo',
        lastMessage: 'Call begins at the top of the hour.',
        lastMessageAt: now.subtract(const Duration(minutes: 11)),
        unreadCount: 5,
        isEncrypted: true,
        isPinned: false,
        settings: const {'clearedAt': {}},
      ),
    ]);

    _messages.addAll([
      ConnectMessage(
        id: 'msg-1',
        conversationId: 'conv-self',
        senderId: 'user-you',
        senderName: 'You',
        content: 'Pinned password drop for future me.',
        type: MessageType.secret,
        createdAt: now.subtract(const Duration(minutes: 23)),
        isEncrypted: true,
        readBy: const ['user-you'],
        attachmentLabel: 'Password',
        metadata: const {'source': 'vault'},
      ),
      ConnectMessage(
        id: 'msg-2',
        conversationId: 'conv-ava',
        senderId: 'user-ava',
        senderName: 'Ava Stone',
        content: 'Send the new shell mockups?',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isEncrypted: true,
        readBy: const ['user-ava'],
      ),
      ConnectMessage(
        id: 'msg-3',
        conversationId: 'conv-team',
        senderId: 'user-milo',
        senderName: 'Milo Chen',
        content: 'Call begins at the top of the hour.',
        type: MessageType.system,
        createdAt: now.subtract(const Duration(minutes: 11)),
        isEncrypted: false,
        readBy: const ['user-milo'],
      ),
    ]);

    _feed.addAll([
      ConnectFeedItem(
        id: 'feed-1',
        kind: 'message',
        title: 'New private signal',
        body: 'Ava mentioned the shell mockups and a direct call.',
        author: 'Ava Stone',
        createdAt: now.subtract(const Duration(minutes: 8)),
        tags: const ['chat', 'design'],
      ),
      ConnectFeedItem(
        id: 'feed-2',
        kind: 'call',
        title: 'Team call scheduled',
        body: 'Kylrix Team call begins at the top of the hour.',
        author: 'Milo Chen',
        createdAt: now.subtract(const Duration(minutes: 28)),
        tags: const ['call', 'team'],
      ),
      ConnectFeedItem(
        id: 'feed-3',
        kind: 'share',
        title: 'Password shared in chat',
        body: 'A self-chat secret attachment was created for later use.',
        author: 'You',
        createdAt: now.subtract(const Duration(minutes: 42)),
        tags: const ['vault', 'secure-share'],
      ),
    ]);

    _calls.addAll([
      ConnectCall(
        id: 'call-1',
        title: 'Ava direct call',
        type: CallType.video,
        status: CallStatus.ongoing,
        createdAt: now.subtract(const Duration(minutes: 7)),
        expiresAt: now.add(const Duration(hours: 1)),
        participantIds: const ['user-you', 'user-ava'],
        callerId: 'user-you',
        conversationId: 'conv-ava',
        isLink: false,
        metadata: const {'receiverId': 'user-ava'},
      ),
      ConnectCall(
        id: 'call-2',
        title: 'Team planning room',
        type: CallType.audio,
        status: CallStatus.completed,
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(hours: 1)),
        participantIds: const ['user-you', 'user-ava', 'user-milo'],
        callerId: 'user-milo',
        conversationId: 'conv-team',
        isLink: true,
        metadata: const {'status': 'completed'},
      ),
    ]);

    _targets.addAll([
      ConnectTarget(id: 'note-1', label: 'Launch retrospective', subtitle: 'Updated 2h ago', type: 'note', updatedAt: now.subtract(const Duration(hours: 2))),
      ConnectTarget(id: 'note-2', label: 'Password handoff', subtitle: 'Encrypted link only', type: 'note', updatedAt: now.subtract(const Duration(days: 1))),
    ]);

    _secrets.addAll([
      ConnectTarget(id: 'secret-1', label: 'GitHub token', subtitle: 'Personal', type: 'secret', updatedAt: now.subtract(const Duration(days: 2))),
      ConnectTarget(id: 'totp-1', label: 'Kylrix Admin', subtitle: 'TOTP', type: 'totp', updatedAt: now.subtract(const Duration(hours: 6))),
    ]);

    _passkeys.addAll([
      const ConnectPasskey(id: 'pk-1', name: 'MacBook Pro', active: true),
      const ConnectPasskey(id: 'pk-2', name: 'iPhone', active: true),
    ]);

    _activity.addAll([
      'Self-chat initialized for secure drops.',
      'Direct call waiting on Ava.',
      'Team call recorded in history.',
    ]);

    _selectedConversationId = 'conv-ava';
    _selectedCallId = 'call-1';
  }

  void setTab(ConnectTab tab) {
    _tab = tab;
    _persist();
    notifyListeners();
  }

  void openConversation(String id) {
    _selectedConversationId = id;
    _tab = ConnectTab.chats;
    _persist();
    notifyListeners();
  }

  void openCall(String id) {
    _selectedCallId = id;
    _tab = ConnectTab.calls;
    _persist();
    notifyListeners();
  }

  void addActivity(String message) {
    _activity.insert(0, message);
    if (_activity.length > 30) {
      _activity.removeRange(30, _activity.length);
    }
    _persist();
    notifyListeners();
  }

  void toggleLock() {
    _settings = ConnectSettings(
      isLocked: !_settings.isLocked,
      showPortal: _settings.showPortal,
      enablePush: _settings.enablePush,
      showActiveStatus: _settings.showActiveStatus,
      allowMessages: _settings.allowMessages,
      allowCalls: _settings.allowCalls,
      allowShares: _settings.allowShares,
      discoverability: _settings.discoverability,
    );
    _persist();
    notifyListeners();
  }

  void unlock() {
    if (!_settings.isLocked) return;
    _settings = ConnectSettings(
      isLocked: false,
      showPortal: _settings.showPortal,
      enablePush: _settings.enablePush,
      showActiveStatus: _settings.showActiveStatus,
      allowMessages: _settings.allowMessages,
      allowCalls: _settings.allowCalls,
      allowShares: _settings.allowShares,
      discoverability: _settings.discoverability,
    );
    _persist();
    notifyListeners();
  }

  void updateSettings(ConnectSettings settings) {
    _settings = settings;
    _persist();
    notifyListeners();
  }

  void updateProfile(ConnectProfile profile) {
    final index = _profiles.indexWhere((item) => item.userId == profile.userId);
    if (index == -1) {
      _profiles.add(profile);
    } else {
      _profiles[index] = profile;
    }
    _persist();
    notifyListeners();
  }

  void sendMessage({
    required String conversationId,
    required String content,
    required MessageType type,
    String attachmentLabel = '',
    Map<String, dynamic> metadata = const {},
    String replyToId = '',
  }) {
    final conversation = _byConversationId(conversationId);
    if (conversation == null) return;
    final meProfile = me;
    final now = DateTime.now();
    final msg = ConnectMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: _session.userId,
      senderName: meProfile?.shortName ?? _session.userName,
      content: content,
      type: type,
      createdAt: now,
      isEncrypted: conversation.isEncrypted,
      readBy: [_session.userId],
      replyToId: replyToId,
      attachmentLabel: attachmentLabel,
      metadata: metadata,
    );
    _messages.add(msg);
    final index = _conversations.indexWhere((item) => item.id == conversationId);
    if (index != -1) {
      _conversations[index] = ConnectConversation(
        id: conversation.id,
        type: conversation.type,
        name: conversation.name,
        participantIds: conversation.participantIds,
        creatorId: conversation.creatorId,
        lastMessage: content,
        lastMessageAt: now,
        unreadCount: conversation.unreadCount,
        isEncrypted: conversation.isEncrypted,
        isPinned: conversation.isPinned,
        settings: conversation.settings,
        otherUserId: conversation.otherUserId,
        avatarUrl: conversation.avatarUrl,
        isSelf: conversation.isSelf,
      );
    }
    addActivity('Sent ${type.name} in ${conversation.name}.');
    _persist();
    notifyListeners();
  }

  void markConversationRead(String conversationId) {
    final index = _conversations.indexWhere((item) => item.id == conversationId);
    if (index == -1) return;
    final conversation = _conversations[index];
    _conversations[index] = ConnectConversation(
      id: conversation.id,
      type: conversation.type,
      name: conversation.name,
      participantIds: conversation.participantIds,
      creatorId: conversation.creatorId,
      lastMessage: conversation.lastMessage,
      lastMessageAt: conversation.lastMessageAt,
      unreadCount: 0,
      isEncrypted: conversation.isEncrypted,
      isPinned: conversation.isPinned,
      settings: conversation.settings,
      otherUserId: conversation.otherUserId,
      avatarUrl: conversation.avatarUrl,
      isSelf: conversation.isSelf,
    );
    _persist();
    notifyListeners();
  }

  void createConversation(ConnectProfile profile) {
    final existing = _conversations.where((item) => item.type == ConversationType.direct && item.participantIds.contains(profile.userId)).toList();
    if (existing.isNotEmpty) {
      openConversation(existing.first.id);
      return;
    }
    final conversation = ConnectConversation(
      id: _uuid.v4(),
      type: ConversationType.direct,
      name: profile.shortName,
      participantIds: [_session.userId, profile.userId],
      creatorId: _session.userId,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
      isEncrypted: true,
      isPinned: false,
      settings: const {'clearedAt': {}},
      otherUserId: profile.userId,
    );
    _conversations.insert(0, conversation);
    openConversation(conversation.id);
    addActivity('Opened chat with ${profile.shortName}.');
    _persist();
    notifyListeners();
  }

  void createGroupConversation(String name, List<String> participantIds) {
    final conversation = ConnectConversation(
      id: _uuid.v4(),
      type: ConversationType.group,
      name: name,
      participantIds: participantIds,
      creatorId: _session.userId,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
      isEncrypted: true,
      isPinned: false,
      settings: const {'clearedAt': {}},
    );
    _conversations.insert(0, conversation);
    openConversation(conversation.id);
    addActivity('Created group chat "$name".');
    _persist();
    notifyListeners();
  }

  void createCall({
    required String title,
    required CallType type,
    required String conversationId,
    required bool isLink,
  }) {
    final call = ConnectCall(
      id: _uuid.v4(),
      title: title,
      type: type,
      status: CallStatus.ongoing,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      participantIds: const [],
      callerId: _session.userId,
      conversationId: conversationId,
      isLink: isLink,
      metadata: const {},
    );
    _calls.insert(0, call);
    _selectedCallId = call.id;
    addActivity('Created call "$title".');
    _persist();
    notifyListeners();
  }

  void updateCallStatus(String callId, CallStatus status) {
    final index = _calls.indexWhere((item) => item.id == callId);
    if (index == -1) return;
    final call = _calls[index];
    _calls[index] = ConnectCall(
      id: call.id,
      title: call.title,
      type: call.type,
      status: status,
      createdAt: call.createdAt,
      expiresAt: status == CallStatus.ongoing ? call.expiresAt : DateTime.now(),
      participantIds: call.participantIds,
      callerId: call.callerId,
      conversationId: call.conversationId,
      isLink: call.isLink,
        metadata: {...call.metadata, 'status': status.name},
      );
    _persist();
    notifyListeners();
  }

  List<ConnectProfile> searchUsers(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    return _profiles.where((profile) {
      return profile.displayName.toLowerCase().contains(normalized) ||
          profile.username.toLowerCase().contains(normalized) ||
          profile.email.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  Future<void> grantShare({
    required String rowId,
    required String permission,
    required List<String> targetUserIds,
    required String databaseId,
    required String tableId,
  }) async {
    await api.updatePermissions(
      rowId: rowId,
      permission: permission,
      targetUserIds: targetUserIds,
      databaseId: databaseId,
      tableId: tableId,
    );
  }

  Future<void> reclaimGhostNotes() async {
    await api.reclaimGhostNotes(_session.userId);
  }

  ConnectTab _tabFromString(String? value) {
    for (final tab in ConnectTab.values) {
      if (tab.name == value) return tab;
    }
    return ConnectTab.home;
  }

  ConnectConversation? _byConversationId(String? id) {
    if (id == null) return null;
    for (final item in _conversations) {
      if (item.id == id) return item;
    }
    return null;
  }

  ConnectCall? _byCallId(String? id) {
    if (id == null) return null;
    for (final item in _calls) {
      if (item.id == id) return item;
    }
    return null;
  }

  ConnectProfile? _byUserId(String? id) {
    if (id == null) return null;
    for (final item in _profiles) {
      if (item.userId == id) return item;
    }
    return null;
  }
}
