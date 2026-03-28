import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/mylann/services/mylann_service.dart';
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

  final List<_UiMessage> _messages = <_UiMessage>[
    const _UiMessage(
      text: 'Salut, je suis Mylann. Pose-moi ta question, je suis pret.',
      fromUser: false,
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_UiMessage(text: text, fromUser: true));
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    final userId = AuthService().getUser()?.uid ?? 'user';

    try {
      final reply = await _mylannService.ask(userId: userId, text: text);
      if (!mounted) return;
      setState(() {
        _messages.add(_UiMessage(text: reply, fromUser: false));
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
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
        _messages.add(
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mylann IA'), centerTitle: true),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bubbleColor = message.fromUser
                    ? colorScheme.primaryContainer
                    : message.isError
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainerHighest;

                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ecris a Mylann...',
                        border: OutlineInputBorder(),
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
          ),
        ],
      ),
    );
  }
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
