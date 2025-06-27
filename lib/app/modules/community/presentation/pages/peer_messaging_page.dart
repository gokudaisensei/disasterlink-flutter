import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/messaging_store.dart';
import '../stores/community_store.dart';

class PeerMessagingPage extends StatefulWidget {
  final String? userId;
  
  const PeerMessagingPage({super.key, this.userId});

  @override
  State<PeerMessagingPage> createState() => _PeerMessagingPageState();
}

class _PeerMessagingPageState extends State<PeerMessagingPage> {
  final MessagingStore _messagingStore = Modular.get<MessagingStore>();
  final CommunityStore _communityStore = Modular.get<CommunityStore>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagingStore.addListener(_onStoreChanged);
    _communityStore.addListener(_onStoreChanged);
    if (widget.userId != null) {
      _messagingStore.openConversation(widget.userId!);
    }
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userId != null ? 'Chat with User' : 'Messages',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.userId != null)
              Text(
                'ID: ${widget.userId!.substring(0, 8)}...',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (widget.userId != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    // TODO: Show user profile
                    break;
                  case 'emergency':
                    _sendEmergencyMessage();
                    break;
                  case 'clear':
                    _messagingStore.clearConversation(widget.userId!);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('View Profile'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'emergency',
                  child: ListTile(
                    leading: Icon(Icons.warning, color: Colors.red),
                    title: Text('Send Emergency Alert'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear Chat'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Builder(
            builder: (context) {
              final isConnected = widget.userId != null 
                ? _communityStore.isUserConnected(widget.userId!) 
                : _communityStore.connectedPeers.isNotEmpty;
                
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected via mesh' : 'Connection unstable',
                      style: textTheme.bodySmall?.copyWith(
                        color: isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Messages List or Conversations List
          Expanded(
            child: widget.userId != null 
              ? _buildMessagesList()
              : _buildConversationsList(),
          ),
          
          // Message Input (only for specific user chat)
          if (widget.userId != null)
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = _messagingStore.getMessages(widget.userId!);
    
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet'),
            Text('Start a conversation!'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isFromMe = message['isFromMe'] ?? false;
        
        return _buildMessageBubble(message, isFromMe);
      },
    );
  }

  Widget _buildConversationsList() {
    final conversations = _messagingStore.conversations;
    
    if (conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No conversations yet'),
            Text('Discover users to start chatting!'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromMe 
            ? colorScheme.primary 
            : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isFromMe 
                  ? colorScheme.onPrimary 
                  : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['timestamp']),
              style: TextStyle(
                fontSize: 11,
                color: (isFromMe 
                  ? colorScheme.onPrimary 
                  : colorScheme.onSurfaceVariant).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            conversation['userId'].substring(0, 2).toUpperCase(),
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text('User ${conversation['userId'].substring(0, 8)}'),
        subtitle: Text(
          conversation['lastMessage'] ?? 'No messages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(conversation['lastMessageTime']),
              style: theme.textTheme.bodySmall,
            ),
            if (conversation['unreadCount'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation['unreadCount']}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PeerMessagingPage(userId: conversation['userId']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && widget.userId != null) {
      _messagingStore.sendDirectMessage(widget.userId!, text);
      _messageController.clear();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendEmergencyMessage() {
    if (widget.userId != null) {
      _messagingStore.sendEmergencyMessage(widget.userId!);
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime time = timestamp is DateTime 
      ? timestamp 
      : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
      
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  @override
  void dispose() {
    _messagingStore.removeListener(_onStoreChanged);
    _communityStore.removeListener(_onStoreChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
