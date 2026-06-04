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
          backgroundColor: Color(0xFF1C1C1E),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF262626), width: 1),
        ),
        title: const Text('Clear Chat History?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete all messages?',
          style: TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          TextButton(
            onPressed: () {
              provider.clearChatHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared.'),
                  backgroundColor: Color(0xFF1C1C1E),
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Color(0xFFFF453A))),
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
            backgroundColor: Colors.black,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: const Color(0xFF1C1C1E),
                height: 1.0,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Local AI Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLocal 
                            ? (activeModel != null ? Colors.white : const Color(0xFFFF453A)) 
                            : const Color(0xFF30D158),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLocal 
                          ? (activeModel != null ? 'Local: ${activeModel.name}' : 'Local: No Active Model') 
                          : 'Online (Backend)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFF8E8E93),
                iconSize: 22,
                onPressed: () => _confirmClearChat(context, provider),
                tooltip: 'Clear Chat History',
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: Colors.white,
                iconSize: 22,
                onPressed: () => ModelListDialog.show(context),
                tooltip: 'Model Manager',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: provider.messages.isEmpty
                        ? _buildEmptyState(isLocal, activeModel)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1C1C1E)),
              ),
              child: Icon(
                isLocal ? Icons.terminal_rounded : Icons.offline_bolt_outlined,
                size: 32,
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLocal 
                  ? (activeModel != null ? 'Local Instance Active' : 'Model Required') 
                  : 'Connected to Cloud',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLocal 
                  ? (activeModel != null 
                      ? 'Running ${activeModel.name} on-device. Your conversations are secure and private.' 
                      : 'Open the Model Manager (top-right control) to configure a local LLM.')
                  : 'Forwarding messages to your FastAPI server running Ollama / NIM.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
                height: 1.4,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1C1C1E))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: isLocalMode ? 'Message local model...' : 'Message backend...',
                hintStyle: const TextStyle(color: Color(0xFF48484A), fontSize: 15),
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF262626)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF262626)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF48484A)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            width: 44,
            child: TextButton(
              onPressed: canSend ? onSend : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: canSend ? Colors.white : const Color(0xFF1C1C1E),
                foregroundColor: canSend ? Colors.black : const Color(0xFF48484A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 22),
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
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : const Color(0xFF0D0D0D),
          border: isUser ? null : Border.all(color: const Color(0xFF1C1C1E), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text.isEmpty ? '...' : message.text,
          style: TextStyle(
            color: isUser ? Colors.black : const Color(0xFFE5E5E5),
            fontSize: 14.5,
            height: 1.45,
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thinking',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0x99FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
