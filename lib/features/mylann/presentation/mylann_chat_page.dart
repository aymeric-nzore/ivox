import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/mylann/services/mylann_service.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';
import 'package:ivox/shared/walkthrough/mascot_walkthrough_overlay.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';

class MylannChatPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MylannChatPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<MylannChatPage> createState() => _MylannChatPageState();
}

class _MylannChatPageState extends State<MylannChatPage> {
  final MylannService _mylannService = MylannService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final GlobalKey _introBubbleKey = GlobalKey();

  final List<_ChatSession> _sessions = <_ChatSession>[];
  late String _activeSessionId;

  bool _isSending = false;

  _ChatSession get _activeSession =>
      _sessions.firstWhere((session) => session.id == _activeSessionId);

  @override
  void initState() {
    super.initState();
    final firstSession = _buildSession();
    _sessions.add(firstSession);
    _activeSessionId = firstSession.id;
  }

  _ChatSession _buildSession() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return _ChatSession(
      id: id,
      title: 'Nouvelle session',
      updatedAt: DateTime.now(),
      messages: <_UiMessage>[
        const _UiMessage(
          text:
              'Salut, je suis Mylann. Pose-moi ta question, je suis prete a t\'aider.',
          fromUser: false,
        ),
      ],
    );
  }

  void _createSession() {
    setState(() {
      final session = _buildSession();
      _sessions.insert(0, session);
      _activeSessionId = session.id;
      _messageController.clear();
    });
    Navigator.of(context).maybePop();
  }

  void _openSession(String sessionId) {
    if (sessionId == _activeSessionId) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _activeSessionId = sessionId;
    });
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      final session = _activeSession;
      session.messages.add(_UiMessage(text: text, fromUser: true));
      session.updatedAt = DateTime.now();
      if (session.title == 'Nouvelle session') {
        session.title = text.length > 28 ? '${text.substring(0, 28)}...' : text;
      }
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    final userId = AuthService().getUser()?.uid ?? 'user';

    try {
      final rawReply = await _mylannService.ask(userId: userId, text: text);
      final reply = _normalizeText(rawReply);
      if (!mounted) return;
      setState(() {
        final session = _activeSession;
        session.messages.add(_UiMessage(text: reply, fromUser: false));
        session.updatedAt = DateTime.now();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _activeSession.messages.add(
          _UiMessage(
            text:
                'Mylann est indisponible pour le moment (${e.response?.statusCode ?? 'reseau'}).',
            fromUser: false,
            isError: true,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeSession.messages.add(
          const _UiMessage(
            text: 'Une erreur est survenue. Reessaie dans quelques secondes.',
            fromUser: false,
            isError: true,
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  String _normalizeText(String value) {
    return value
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã¨', 'e')
        .replaceAll('Ã', 'a')
        .replaceAll('ð', '')
        .replaceAll('\r\n', '\n')
        .trim();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reponse copiee dans le presse-papiers')),
    );
  }

  Future<void> _showMessageActions(_UiMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copier le message'),
                onTap: () => Navigator.of(context).pop('copy'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'copy') {
      await _copyToClipboard(message.text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessions = List<_ChatSession>.from(_sessions)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mylann IA'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Nouvelle session',
            onPressed: _createSession,
            icon: const Icon(Icons.add_comment_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.smart_toy_rounded),
                ),
                title: const Text('Sessions Mylann'),
                subtitle: const Text('Historique des conversations'),
                trailing: IconButton(
                  tooltip: 'Nouvelle',
                  onPressed: _createSession,
                  icon: const Icon(Icons.add),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isActive = session.id == _activeSessionId;
                    return ListTile(
                      selected: isActive,
                      leading: Icon(
                        isActive
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${session.messages.length} messages',
                        maxLines: 1,
                      ),
                      onTap: () => _openSession(session.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount:
                      _activeSession.messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isSending && index == _activeSession.messages.length) {
                      return const _TypingBubble();
                    }

                    final message = _activeSession.messages[index];
                    final bubbleColor = message.fromUser
                        ? colorScheme.primaryContainer
                        : message.isError
                        ? colorScheme.errorContainer
                        : colorScheme.surfaceContainerHighest;

                    final bubble = Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            message.text,
                            style: const TextStyle(height: 1.4),
                          ),
                          if (!message.fromUser && !message.isError)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: 'Copier',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                onPressed: () => _copyToClipboard(message.text),
                              ),
                            ),
                        ],
                      ),
                    );

                    return Align(
                      alignment: message.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        key:
                            (!message.fromUser &&
                                !message.isError &&
                                index == 0)
                            ? _introBubbleKey
                            : null,
                        onLongPress: () => _showMessageActions(message),
                        child: bubble,
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _inputFocusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText: 'Demande quelque chose a Mylann...',
                              border: InputBorder.none,
                              isCollapsed: true,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          MascotWalkthroughOverlay(
            page: WalkthroughPage.mylann,
            targets: {'mylann_intro': _introBubbleKey},
            onTabSelected: widget.onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _ChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  final List<_UiMessage> messages;

  _ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });
}

class _UiMessage {
  final String text;
  final bool fromUser;
  final bool isError;

  const _UiMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
  });
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final t = ((value * 3) - index).clamp(0.0, 1.0);
            final opacity = 0.25 + (t * 0.75);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
