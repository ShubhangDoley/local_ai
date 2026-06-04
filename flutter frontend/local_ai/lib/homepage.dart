import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'providers/model_provider.dart';
import 'widgets/model_list_dialog.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onSend(ChatProvider provider) async {
    final String inputText = _inputController.text;
    if (inputText.trim().isEmpty || provider.isSending) {
      return;
    }

    _inputController.clear();
    provider.updateInput('');
    await provider.sendUserMessage(inputText);
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _confirmClearChat(BuildContext context, ChatProvider provider) {
    if (provider.messages.length <= 1 && provider.messages.first.role == ChatRole.assistant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history is already empty.'),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Clear Chat History?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete all messages? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              provider.clearChatHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = Provider.of<ModelProvider>(context);
    final isLocal = modelProvider.isLocalMode;
    final activeModel = modelProvider.activeModel;

    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider provider, Widget? child) {
        if (_lastMessageCount != provider.messages.length) {
          _lastMessageCount = provider.messages.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToLatest();
          });
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            elevation: 0,
            backgroundColor: const Color(0xFF020617),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Local AI Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLocal 
                            ? (activeModel != null ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444)) 
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLocal 
                          ? (activeModel != null ? 'Local: ${activeModel.name}' : 'Local: No Active Model') 
                          : 'Online (Backend)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocal ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                color: const Color(0xFFEF4444),
                iconSize: 26,
                onPressed: () => _confirmClearChat(context, provider),
                tooltip: 'Clear Chat History',
              ),
              IconButton(
                icon: const Icon(Icons.settings_suggest_rounded),
                color: const Color(0xFF0EA5E9),
                iconSize: 26,
                onPressed: () => ModelListDialog.show(context),
                tooltip: 'Model Manager',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF020617), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: provider.messages.isEmpty
                        ? _buildEmptyState(isLocal, activeModel)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            itemCount:
                                provider.messages.length + (provider.isSending ? 1 : 0),
                            itemBuilder: (BuildContext context, int index) {
                              if (index >= provider.messages.length) {
                                return const _TypingBubble();
                              }

                              final ChatMessage message = provider.messages[index];
                              return _MessageBubble(message: message);
                            },
                          ),
                  ),
                  _InputBar(
                    controller: _inputController,
                    canSend: provider.canSend,
                    isLocalMode: isLocal,
                    onChanged: provider.updateInput,
                    onSend: () => _onSend(provider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isLocal, LocalModel? activeModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocal ? Icons.offline_bolt_rounded : Icons.cloud_done_rounded,
              size: 64,
              color: const Color(0xFF1E293B),
            ),
            const SizedBox(height: 16),
            Text(
              isLocal 
                  ? (activeModel != null ? 'Local Session Ready' : 'Select a Model') 
                  : 'Connected to Backend AI',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLocal 
                  ? (activeModel != null 
                      ? 'You are running ${activeModel.name} completely on-device. No internet required!' 
                      : 'Open the Model Manager (top-right icon) to download and select a local model.')
                  : 'Messages will be forwarded to your fastapi backend running Ollama.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.isLocalMode,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool isLocalMode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF090D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isLocalMode ? 'Message local AI...' : 'Message backend AI...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF020617),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: canSend ? onSend : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0EA5E9) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text.isEmpty ? '...' : message.text,
          style: TextStyle(
            color: isUser ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assistant is thinking',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF0EA5E9).withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
