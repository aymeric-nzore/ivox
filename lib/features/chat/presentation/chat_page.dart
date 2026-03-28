import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivox/features/chat/presentation/voice_call_page.dart';
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
  late final Stream<bool> _typingStream;
  StreamSubscription<Map<String, dynamic>>? _callSignalSubscription;
  final Set<String> _readRequested = <String>{};
  String? _currentUserId;
  String? _error;
  bool _typingSent = false;
  bool _isSending = false;
  bool _isCallDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.getMessages(widget.receiverID);
    _statusStream = _chatService.userStatusStream(widget.receiverID);
    _lastSeenStream = _chatService.userLastSeenStream(widget.receiverID);
    _typingStream = _chatService.userTypingStream(widget.receiverID);
    _bootstrap();

    _callSignalSubscription = _chatService.callEvents.listen((payload) {
      final event = (payload['event'] ?? '').toString();
      if (event != 'call_invite' || !mounted || _isCallDialogOpen) return;

      final fromUserId = (payload['fromUserId'] ?? '').toString();
      final callId = (payload['callId'] ?? '').toString();
      if (fromUserId != widget.receiverID || callId.isEmpty) return;

      _showIncomingCallDialog(
        callId: callId,
        callerName: (payload['callerName'] ?? widget.receiverEmail).toString(),
      );
    });
  }

  Future<void> _showIncomingCallDialog({
    required String callId,
    required String callerName,
  }) async {
    _isCallDialogOpen = true;

    try {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Appel entrant'),
            content: Text('Appel vocal de $callerName'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Refuser'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Accepter'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (accepted == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceCallPage(
              receiverId: widget.receiverID,
              receiverName: widget.receiverEmail,
              receiverPhotoUrl: widget.receiverPhotoUrl,
              isIncoming: true,
              callId: callId,
            ),
          ),
        );
      } else {
        await _chatService.sendCallReject(
          toUserId: widget.receiverID,
          callId: callId,
        );
      }
    } finally {
      _isCallDialogOpen = false;
    }
  }

  Future<void> _startVoiceCall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallPage(
          receiverId: widget.receiverID,
          receiverName: widget.receiverEmail,
          receiverPhotoUrl: widget.receiverPhotoUrl,
          isIncoming: false,
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'Hors ligne';

    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

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
    if (text.isEmpty || _isSending) return;

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      await _chatService.sendTypingStop(widget.receiverID);
      _typingSent = false;
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
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
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
    if (_typingSent) {
      _chatService.sendTypingStop(widget.receiverID);
    }
    _callSignalSubscription?.cancel();
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
              backgroundImage:
                  widget.receiverPhotoUrl != null &&
                      widget.receiverPhotoUrl!.isNotEmpty
                  ? NetworkImage(widget.receiverPhotoUrl!)
                  : null,
              child:
                  widget.receiverPhotoUrl == null ||
                      widget.receiverPhotoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<bool>(
                stream: _typingStream,
                initialData: false,
                builder: (context, typingSnapshot) {
                  final isTyping = typingSnapshot.data ?? false;
                  return StreamBuilder<String>(
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
                          final subtitle = isTyping
                              ? 'En train d\'ecrire...'
                              : (isOnline
                                    ? 'En ligne'
                                    : _formatLastSeen(lastSeenSnapshot.data));
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
                                  color: isTyping
                                      ? Colors.teal
                                      : (isOnline ? Colors.green : Colors.grey),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Appel vocal',
            onPressed: _startVoiceCall,
            icon: const Icon(Icons.call_rounded),
          ),
        ],
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
              if (isCurrentUser) _buildStatusIndicator(message.status),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final isMine = _currentUserId != null && message.sender == _currentUserId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copier le message'),
                onTap: () {
                  Navigator.of(context).pop('copy');
                },
              ),
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop('report');
                    },
                    icon: const Icon(Icons.report),
                    label: const Text('Signaler ce message'),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.message));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message copie')));
      }
      return;
    }

    if (action != 'report') {
      return;
    }

    try {
      await _chatService.reportMessage(message.messageId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message signale')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur signalement: $e')));
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 4,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  final hasText = value.trim().isNotEmpty;
                  if (hasText && !_typingSent) {
                    _typingSent = true;
                    _chatService.sendTypingStart(widget.receiverID);
                  } else if (!hasText && _typingSent) {
                    _typingSent = false;
                    _chatService.sendTypingStop(widget.receiverID);
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Envoyez un message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
