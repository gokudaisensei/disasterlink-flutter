import 'package:flutter/material.dart';

enum MessageType {
  text,
  emergency,
  resource,
  location,
  system,
}

enum MessagePriority {
  low,
  normal,
  high,
  critical,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final MessagePriority priority;
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;
  final String? recipientId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    this.priority = MessagePriority.normal,
    required this.timestamp,
    this.isRead = false,
    this.isSent = true,
    this.recipientId,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessagePriority? priority,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
    String? recipientId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      recipientId: recipientId ?? this.recipientId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatChannel {
  final String id;
  final String name;
  final List<String> participants;
  final List<ChatMessage> messages;
  final bool isGroup;
  final DateTime lastActivity;

  const ChatChannel({
    required this.id,
    required this.name,
    required this.participants,
    this.messages = const [],
    this.isGroup = false,
    required this.lastActivity,
  });

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  int get unreadCount => messages.where((m) => !m.isRead).length;
}

class MessagingStore extends ChangeNotifier {
  final List<ChatChannel> _channels = [];
  final List<ChatMessage> _allMessages = [];
  String? _activeChannelId;
  bool _isConnected = false;

  // Getters
  List<ChatChannel> get channels => _channels;
  List<ChatMessage> get allMessages => _allMessages;
  String? get activeChannelId => _activeChannelId;
  bool get isConnected => _isConnected;

  ChatChannel? get activeChannel {
    if (_activeChannelId == null) return null;
    return _channels.firstWhere((c) => c.id == _activeChannelId!);
  }

  List<ChatMessage> getMessagesForChannel(String channelId) {
    return _allMessages.where((m) => m.recipientId == channelId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void initializeMessaging() {
    _isConnected = true;
    _loadMockData();
    notifyListeners();
  }

  void _loadMockData() {
    // Create mock channels
    _channels.addAll([
      ChatChannel(
        id: 'emergency_broadcast',
        name: 'Emergency Broadcast',
        participants: ['all'],
        isGroup: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatChannel(
        id: 'medical_team',
        name: 'Medical Team',
        participants: ['user_1', 'current_user'],
        isGroup: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatChannel(
        id: 'rescue_coordination',
        name: 'Rescue Coordination',
        participants: ['user_2', 'user_4', 'current_user'],
        isGroup: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ]);

    // Create mock messages
    _allMessages.addAll([
      ChatMessage(
        id: 'msg_1',
        senderId: 'system',
        senderName: 'System',
        content: 'Emergency network established. All units report status.',
        type: MessageType.system,
        priority: MessagePriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        recipientId: 'emergency_broadcast',
      ),
      ChatMessage(
        id: 'msg_2',
        senderId: 'user_1',
        senderName: 'Dr. Sarah Chen',
        content: 'Medical station is operational. Ready to receive patients.',
        type: MessageType.text,
        priority: MessagePriority.normal,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        recipientId: 'medical_team',
      ),
      ChatMessage(
        id: 'msg_3',
        senderId: 'user_4',
        senderName: 'Captain James Wilson',
        content: 'Fire truck en route to sector 7. ETA 5 minutes.',
        type: MessageType.text,
        priority: MessagePriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        recipientId: 'rescue_coordination',
      ),
      ChatMessage(
        id: 'msg_4',
        senderId: 'user_6',
        senderName: 'David Kim',
        content: 'EMERGENCY: Trapped in building collapse at Apartment Complex D!',
        type: MessageType.emergency,
        priority: MessagePriority.critical,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        recipientId: 'emergency_broadcast',
      ),
    ]);
  }

  Future<void> sendMessage(String content, String channelId, {
    MessageType type = MessageType.text,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'Emergency Coordinator',
      content: content,
      type: type,
      priority: priority,
      timestamp: DateTime.now(),
      recipientId: channelId,
      isSent: false,
    );

    _allMessages.add(message);
    notifyListeners();

    // Simulate sending delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Update message as sent
    final index = _allMessages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _allMessages[index] = message.copyWith(isSent: true);
      notifyListeners();
    }
  }

  void setActiveChannel(String channelId) {
    _activeChannelId = channelId;
    // Mark messages as read
    for (int i = 0; i < _allMessages.length; i++) {
      if (_allMessages[i].recipientId == channelId && !_allMessages[i].isRead) {
        _allMessages[i] = _allMessages[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void createDirectChannel(String userId, String userName) {
    final channelId = 'direct_$userId';
    if (_channels.any((c) => c.id == channelId)) return;

    _channels.add(ChatChannel(
      id: channelId,
      name: userName,
      participants: [userId, 'current_user'],
      isGroup: false,
      lastActivity: DateTime.now(),
    ));
    notifyListeners();
  }

  // New methods for peer messaging
  void openConversation(String userId) {
    createDirectChannel(userId, 'User ${userId.substring(0, 8)}');
    setActiveChannel('direct_$userId');
  }

  List<Map<String, dynamic>> getMessages(String userId) {
    final channelId = 'direct_$userId';
    return getMessagesForChannel(channelId).map((message) => {
      'id': message.id,
      'content': message.content,
      'timestamp': message.timestamp,
      'isFromMe': message.senderId == 'current_user',
      'type': message.type.toString(),
      'priority': message.priority.toString(),
    }).toList();
  }

  void sendDirectMessage(String userId, String content) {
    final channelId = 'direct_$userId';
    sendMessage(content, channelId);
  }

  void sendEmergencyMessage(String userId) {
    final channelId = 'direct_$userId';
    sendMessage(
      '🚨 EMERGENCY ALERT: Need immediate assistance!',
      channelId,
      type: MessageType.emergency,
      priority: MessagePriority.critical,
    );
  }

  void clearConversation(String userId) {
    final channelId = 'direct_$userId';
    _allMessages.removeWhere((message) => message.recipientId == channelId);
    notifyListeners();
  }

  List<Map<String, dynamic>> get conversations {
    return _channels.where((channel) => !channel.isGroup).map((channel) {
      final messages = getMessagesForChannel(channel.id);
      final lastMessage = messages.isNotEmpty ? messages.last : null;
      final unreadCount = messages.where((m) => !m.isRead && m.senderId != 'current_user').length;
      
      return {
        'userId': channel.id.replaceFirst('direct_', ''),
        'userName': channel.name,
        'lastMessage': lastMessage?.content,
        'lastMessageTime': lastMessage?.timestamp,
        'unreadCount': unreadCount,
      };
    }).toList();
  }

  List<ChatMessage> getEmergencyMessages() {
    return _allMessages
        .where((m) => m.type == MessageType.emergency || m.priority == MessagePriority.critical)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int get totalUnreadCount {
    return _allMessages.where((m) => !m.isRead && m.senderId != 'current_user').length;
  }

  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }
}
