import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivox/features/chat/services/chat_services.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String? receiverPhotoUrl;
  final String? receiverStatus;
  final DateTime? receiverLastSeen;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    this.receiverPhotoUrl,
    this.receiverStatus,
    this.receiverLastSeen,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatServices _chatService = ChatServices();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final Stream<List<ChatMessage>> _messageStream;
  late final Stream<String> _statusStream;
  late final Stream<DateTime?> _lastSeenStream;
  final Set<String> _readRequested = <String>{};
  String? _currentUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.getMessages(widget.receiverID);
    _statusStream = _chatService.userStatusStream(widget.receiverID);
    _lastSeenStream = _chatService.userLastSeenStream(widget.receiverID);
    _bootstrap();
  }

  String _formatLastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'Hors ligne';

    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;

    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Vu aujourd\'hui a $hh:$mm';
    }

    final dd = dateTime.day.toString().padLeft(2, '0');
    final mo = dateTime.month.toString().padLeft(2, '0');
    return 'Vu le $dd/$mo a $hh:$mm';
  }

  Future<void> _bootstrap() async {
    try {
      await _chatService.loadMessages(widget.receiverID);
      if (mounted) {
        setState(() {
          _currentUserId = _chatService.currentUserId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(widget.receiverID, text);
      _messageController.clear();
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverPhotoUrl != null &&
                      widget.receiverPhotoUrl!.isNotEmpty
                  ? NetworkImage(widget.receiverPhotoUrl!)
                  : null,
              child: widget.receiverPhotoUrl == null ||
                      widget.receiverPhotoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<String>(
                stream: _statusStream,
                builder: (context, snapshot) {
                  final status =
                      (snapshot.data ?? widget.receiverStatus ?? 'offline')
                          .toLowerCase();
                  final isOnline = status == 'online';
                  return StreamBuilder<DateTime?>(
                    stream: _lastSeenStream,
                    initialData: widget.receiverLastSeen,
                    builder: (context, lastSeenSnapshot) {
                      final subtitle = isOnline
                          ? 'En ligne'
                          : _formatLastSeen(lastSeenSnapshot.data);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.receiverEmail,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? <ChatMessage>[];
        _markIncomingMessagesAsRead(messages);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildMessageItem(messages[index]),
        );
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isCurrentUser = message.sender == _currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isCurrentUser
      ? (isDark ? const Color(0xFFE3B341) : Colors.amber)
      : (isDark ? const Color(0xFF2B3138) : Colors.grey.shade300);
    final messageTextColor = isCurrentUser
      ? Colors.black87
      : (isDark ? Colors.white : Colors.black87);
    final timeTextColor = isCurrentUser
      ? Colors.black54
      : (isDark ? Colors.white70 : Colors.grey.shade700);
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(message),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: isCurrentUser
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: messageTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: timeTextColor,
                ),
              ),
              if (isCurrentUser)
                _buildStatusIndicator(message.status),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (_currentUserId != null && message.sender == _currentUserId) {
      return;
    }

    final shouldReport = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.report),
              label: const Text('Signaler ce message'),
            ),
          ),
        );
      },
    );

    if (shouldReport != true) {
      return;
    }

    try {
      await _chatService.reportMessage(message.messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message signale')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur signalement: $e')),
        );
      }
    }
  }

  Widget _buildStatusIndicator(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'read') {
      return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    }

    if (normalized == 'delivered') {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    }

    return const Icon(Icons.check, size: 14, color: Colors.grey);
  }

  void _markIncomingMessagesAsRead(List<ChatMessage> messages) {
    final me = _currentUserId;
    if (me == null || me.isEmpty) return;

    for (final message in messages) {
      final shouldMark =
          message.receiver == me && message.status.toLowerCase() != 'read';
      if (!shouldMark) continue;
      if (_readRequested.contains(message.messageId)) continue;

      _readRequested.add(message.messageId);
      _chatService.markAsRead(message.messageId).catchError((_) {
        _readRequested.remove(message.messageId);
      });
    }
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Envoyez un message...',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
